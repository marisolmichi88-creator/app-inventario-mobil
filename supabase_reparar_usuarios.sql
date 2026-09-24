-- ============================================================================
-- REPARACIÓN DE CUENTAS  (Supabase > SQL Editor)
--
-- IMPORTANTE: ejecuta UN PASO A LA VEZ. Selecciona con el mouse solo el bloque
-- que quieras correr y pulsa Run: el editor ejecuta únicamente lo seleccionado,
-- y además solo muestra el resultado de la última sentencia.
--
-- Los pasos 1 y 2 abren transacción a propósito: miras el resultado y recién
-- entonces escribes commit; (o rollback; si algo no cuadra).
-- ============================================================================


-- ############################################################################
-- PASO 0 — VER a quién afecta cada cosa. Solo lectura, no cambia nada.
-- ############################################################################
select
  u.email,
  case when p.id is null then '❌ HUÉRFANA (paso 2 la borra)'
       else '✅ tiene perfil' end                     as perfil,
  case when u.email_confirmed_at is null then '❌ sin confirmar'
       else 'confirmada' end                          as correo,
  case when p.id is null then '—' else p.role end     as rol,
  u.created_at::date                                  as creada
from auth.users u
left join public.user_profiles p on p.auth_user_id = u.id
order by (p.id is null) desc, u.created_at;


-- ############################################################################
-- PASO 1 — CONFIRMAR el correo de las cuentas que SÍ tienen perfil.
--
-- Solo toca a los usuarios reales de la app; deja en paz a las huérfanas
-- porque esas se van en el paso 2. No hace falta tocar confirmed_at: es una
-- columna generada que se recalcula sola a partir de email_confirmed_at.
-- ############################################################################
begin;

update auth.users u
   set email_confirmed_at = now()
  from public.user_profiles p
 where p.auth_user_id = u.id
   and u.email_confirmed_at is null;

-- Revisa que solo aparezcan los que esperabas:
select u.email, u.email_confirmed_at, p.role, p.is_active
  from auth.users u
  join public.user_profiles p on p.auth_user_id = u.id
 order by p.role, u.email;

-- Si está bien:  commit;
-- Si no:         rollback;


-- ############################################################################
-- PASO 2 — BORRAR las cuentas de Auth que quedaron sin perfil.
--
-- ⚠️ ESTO NO SE PUEDE DESHACER una vez que hagas commit.
--
-- Antes de correrlo, mira la lista del paso 0: si alguno de esos correos es
-- tuyo o lo quieres conservar, NO lo borres. Añádelo a la lista de excepciones
-- de abajo y después vuelve a crearlo desde la app, que le creará su perfil.
--
-- Ninguna de estas cuentas tiene datos asociados en la app: los movimientos
-- apuntan a user_profiles, y estas no tienen perfil. Por eso es seguro.
-- ############################################################################
begin;

delete from auth.users u
 where not exists (
         select 1 from public.user_profiles p where p.auth_user_id = u.id
       )
   -- Excepciones: descomenta y escribe aquí los correos que quieras SALVAR.
   -- and u.email not in ('emedinada@ucvvirtual.edu.pe')
   ;

-- Debe quedar una cuenta de Auth por cada perfil, y ninguna sin confirmar:
select (select count(*) from auth.users)          as cuentas_auth,
       (select count(*) from public.user_profiles) as perfiles,
       (select count(*) from auth.users
         where email_confirmed_at is null)         as sin_confirmar;

-- Si está bien:  commit;
-- Si no:         rollback;


-- ############################################################################
-- PASO 3 — Comprobación final (después de los commit).
-- ############################################################################
select u.email, p.name, p.role, p.is_active,
       u.email_confirmed_at is not null as correo_confirmado
  from auth.users u
  left join public.user_profiles p on p.auth_user_id = u.id
 order by p.role nulls first, u.email;
