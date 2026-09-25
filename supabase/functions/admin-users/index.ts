// ============================================================================
// Edge Function: admin-users
//
// Crea cuentas, cambia el correo de acceso y elimina usuarios del panel.
//
// Existe porque esas tres operaciones exigen la service_role key, y esa llave
// no puede vivir dentro del APK: cualquiera la extrae del instalador y se
// queda con la base entera. Aqui la llave vive en Supabase y nunca sale; la
// app solo manda el token de sesion del administrador, que esta funcion
// verifica antes de hacer nada.
// ============================================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const ANON_KEY =
  Deno.env.get('SUPABASE_ANON_KEY') ??
  Deno.env.get('SUPABASE_PUBLISHABLE_KEY')!;
const SERVICE_KEY =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
  Deno.env.get('SUPABASE_SECRET_KEY')!;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  });
}

// Los mensajes de GoTrue llegan en ingles y con jerga.
function traducir(mensaje: string): string {
  const m = mensaje.toLowerCase();
  if (m.includes('already registered') || m.includes('already exists')) {
    return 'Ese correo ya tiene una cuenta.';
  }
  if (m.includes('password') && (m.includes('short') || m.includes('least'))) {
    return 'La contrasena es demasiado corta.';
  }
  if (m.includes('invalid') && m.includes('email')) {
    return 'El correo electronico no es valido.';
  }
  if (m.includes('rate') || m.includes('too many')) {
    return 'Demasiados intentos seguidos. Espera unos minutos.';
  }
  return mensaje;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });
  if (req.method !== 'POST') return json({ error: 'Metodo no permitido.' }, 405);

  const authHeader = req.headers.get('Authorization') ?? '';
  if (!authHeader.startsWith('Bearer ')) {
    return json({ error: 'Falta la sesion del administrador.' }, 401);
  }

  // Quien llama se resuelve con SU token, nunca con la llave de servicio.
  const caller = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const {
    data: { user },
    error: userError,
  } = await caller.auth.getUser();

  if (userError || !user) {
    return json({ error: 'Tu sesion expiro. Vuelve a iniciar sesion.' }, 401);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // El rol se lee con la llave de servicio, para que no dependa de las
  // politicas de RLS ni de lo que la app afirme sobre si misma.
  const { data: perfil } = await admin
    .from('user_profiles')
    .select('id, role, is_active, email')
    .eq('auth_user_id', user.id)
    .maybeSingle();

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: 'El cuerpo de la peticion no es JSON valido.' }, 400);
  }

  const action = String(body.action ?? '');
  const email = String(body.email ?? '').trim().toLowerCase();
  const name = String(body.name ?? '').trim();
  const role = String(body.role ?? '').trim();
  const id = String(body.id ?? '').trim();

  // --------------------------------------------------------- perfil propio
  // Editar el correo o el nombre de UNO MISMO no requiere ser administrador:
  // cualquiera puede corregir su propia ficha. Va antes del control de rol y
  // nunca toca `role` ni `is_active`, asi que no sirve para ascenderse.
  if (action === 'update_self') {
    if (!perfil) return json({ error: 'Tu perfil ya no existe.' }, 404);

    try {
      if (email && email !== String(perfil.email ?? '').toLowerCase()) {
        const { error: emailError } = await admin.auth.admin.updateUserById(
          user.id,
          { email, email_confirm: true },
        );
        if (emailError) {
          return json({ error: traducir(emailError.message) }, 400);
        }
      }

      const patch: Record<string, unknown> = {};
      if (name) patch.name = name;
      if (email) patch.email = email;

      if (Object.keys(patch).length > 0) {
        const { error: updateError } = await admin
          .from('user_profiles')
          .update(patch)
          .eq('id', perfil.id);
        if (updateError) return json({ error: updateError.message }, 400);
      }

      return json({ ok: true });
    } catch (e) {
      const mensaje = e instanceof Error ? e.message : String(e);
      return json({ error: traducir(mensaje) }, 500);
    }
  }

  if (!perfil || perfil.role !== 'admin' || perfil.is_active !== true) {
    return json(
      { error: 'Solo un administrador activo puede gestionar usuarios.' },
      403,
    );
  }

  try {
    // ------------------------------------------------------------- crear
    if (action === 'create') {
      const password = String(body.password ?? '');
      if (!email || !password) {
        return json(
          { error: 'El correo y la contrasena son obligatorios.' },
          400,
        );
      }

      const { data: creada, error: createError } =
        await admin.auth.admin.createUser({
          email,
          password,
          // El administrador responde por la cuenta, asi que no hace falta
          // que el usuario confirme nada para poder entrar.
          email_confirm: true,
          user_metadata: { name, role },
        });

      if (createError || !creada?.user) {
        return json(
          {
            error: traducir(
              createError?.message ?? 'No se pudo crear la cuenta.',
            ),
          },
          400,
        );
      }

      const authUserId = creada.user.id;

      // El trigger deja el perfil inactivo y como operador; aqui se completa.
      const { data: perfilNuevo, error: perfilError } = await admin
        .from('user_profiles')
        .upsert(
          {
            auth_user_id: authUserId,
            name,
            email,
            role: role || 'operador',
            is_active: true,
          },
          { onConflict: 'auth_user_id' },
        )
        .select()
        .maybeSingle();

      if (perfilError) {
        // Si el perfil no queda bien, se deshace la cuenta. Una cuenta de
        // acceso sin perfil es el huerfano invisible que costo una noche.
        await admin.auth.admin.deleteUser(authUserId);
        return json(
          {
            error:
              'La cuenta se deshizo porque su perfil fallo: ' +
              perfilError.message,
          },
          400,
        );
      }

      return json({ ok: true, profile: perfilNuevo });
    }

    // ------------------------------------------------------------ editar
    if (action === 'update') {
      if (!id) return json({ error: 'Falta indicar el usuario.' }, 400);

      const { data: actual } = await admin
        .from('user_profiles')
        .select('auth_user_id, email')
        .eq('id', id)
        .maybeSingle();

      if (!actual) return json({ error: 'Ese usuario ya no existe.' }, 404);

      // El correo de acceso vive en Auth. Cambiarlo solo en el perfil dejaria
      // la pantalla mostrando uno con el que nadie puede iniciar sesion.
      if (email && email !== String(actual.email ?? '').toLowerCase()) {
        const { error: emailError } = await admin.auth.admin.updateUserById(
          actual.auth_user_id,
          { email, email_confirm: true },
        );
        if (emailError) {
          return json({ error: traducir(emailError.message) }, 400);
        }
      }

      const patch: Record<string, unknown> = {};
      if (name) patch.name = name;
      if (role) patch.role = role;
      if (email) patch.email = email;
      if (typeof body.is_active === 'boolean') patch.is_active = body.is_active;

      if (Object.keys(patch).length > 0) {
        const { error: updateError } = await admin
          .from('user_profiles')
          .update(patch)
          .eq('id', id);
        if (updateError) return json({ error: updateError.message }, 400);
      }

      return json({ ok: true });
    }

    // ---------------------------------------------------------- eliminar
    if (action === 'delete') {
      if (!id) return json({ error: 'Falta indicar el usuario.' }, 400);

      const { data: actual } = await admin
        .from('user_profiles')
        .select('auth_user_id, email')
        .eq('id', id)
        .maybeSingle();

      if (!actual) return json({ error: 'Ese usuario ya no existe.' }, 404);
      if (actual.auth_user_id === user.id) {
        return json({ error: 'No puedes eliminar tu propia cuenta.' }, 400);
      }

      // El perfil PRIMERO. Al reves no funciona: user_profiles.auth_user_id
      // apunta a auth.users con una clave foranea, asi que mientras el perfil
      // exista Postgres rechaza borrar la cuenta y GoTrue devuelve el
      // generico "Database error deleting user".
      const { error: perfilError } = await admin
        .from('user_profiles')
        .delete()
        .eq('id', id);

      if (perfilError) {
        // Lo habitual aqui es que el usuario tenga movimientos registrados
        // que lo referencian. Borrarlo partiria el historial del inventario.
        return json(
          {
            error:
              'No se puede eliminar a este usuario porque tiene registros ' +
              'asociados, como movimientos de inventario. Desactivalo con el ' +
              'interruptor de la lista: deja de entrar y el historial queda ' +
              'intacto. Detalle: ' + perfilError.message,
          },
          400,
        );
      }

      const { error: authError } = await admin.auth.admin.deleteUser(
        actual.auth_user_id,
      );

      if (authError) {
        return json(
          {
            error:
              'La ficha se elimino, pero la cuenta de acceso de ' +
              actual.email +
              ' quedo en Authentication > Users y hay que borrarla ahi a ' +
              'mano. Detalle: ' + authError.message,
          },
          500,
        );
      }

      return json({ ok: true });
    }

    return json({ error: 'Accion desconocida: ' + action }, 400);
  } catch (e) {
    const mensaje = e instanceof Error ? e.message : String(e);
    return json({ error: traducir(mensaje) }, 500);
  }
});
