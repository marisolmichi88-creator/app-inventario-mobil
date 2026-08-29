-- ============================================================================
--  SEGURIDAD: Row Level Security en las tablas del negocio
--
--  QUÉ RESUELVE
--  La clave publicable va dentro del APK. Cualquiera que reciba el archivo
--  puede extraerla y consultar la base directamente, sin pasar por el login.
--  Sin RLS eso significa leer y modificar todo el inventario.
--
--  QUÉ HACE
--  Deja el acceso solo para sesiones autenticadas (rol `authenticated`), que
--  es lo que obtiene alguien tras iniciar sesión en la app. El rol `anon`
--  —quien tiene la clave pero no inició sesión— queda sin acceso.
--
--  ANTES DE EJECUTAR
--  1. La app debe estar en la versión que ya NO trae el bloque de "migración
--     temporal" de main.dart: ese escribía en la base antes del login y con
--     RLS activo dejaría de funcionar.
--  2. Ejecuta el bloque de diagnóstico de abajo primero para ver cómo está
--     tu base hoy.
--
--  SI ALGO SALE MAL
--  Está todo dentro de una transacción y el commit va comentado al final:
--  revisa la verificación y solo entonces confirma. Para revertir una tabla
--  después de confirmar:
--      alter table public.NOMBRE disable row level security;
-- ============================================================================


-- ############################################################################
-- PASO 1 — DIAGNÓSTICO. Ejecuta SOLO esto primero, en una pestaña aparte.
-- ############################################################################
-- select c.relname as tabla,
--        c.relrowsecurity as rls_activo,
--        count(p.policyname) as politicas
-- from pg_class c
-- join pg_namespace n on n.oid = c.relnamespace
-- left join pg_policies p on p.schemaname = 'public' and p.tablename = c.relname
-- where n.nspname = 'public' and c.relkind = 'r'
-- group by c.relname, c.relrowsecurity
-- order by c.relname;


-- ############################################################################
-- PASO 2 — APLICAR. Ejecuta todo esto junto.
-- ############################################################################

begin;

-- Tablas del negocio: acceso completo solo con sesión iniciada.
do $$
declare
  t text;
  tablas text[] := array[
    'products', 'movements', 'warehouses', 'categories',
    'projects', 'user_profiles', 'product_warehouses'
  ];
begin
  foreach t in array tablas loop
    -- Se salta las que no existan en esta base.
    if not exists (select 1 from information_schema.tables
                   where table_schema = 'public' and table_name = t) then
      raise notice 'La tabla % no existe, se omite.', t;
      continue;
    end if;

    execute format('alter table public.%I enable row level security', t);

    -- Quita políticas abiertas previas con este mismo nombre, para que
    -- volver a ejecutar el script no acumule definiciones distintas.
    execute format('drop policy if exists %I on public.%I', t || '_authenticated', t);

    execute format(
      'create policy %I on public.%I for all to authenticated using (true) with check (true)',
      t || '_authenticated', t);

    -- El rol anónimo no debe tocar nada de negocio.
    execute format('revoke all on public.%I from anon', t);

    raise notice 'RLS activado en %', t;
  end loop;
end $$;

-- movement_audit ya tiene sus políticas propias (insertar y leer, nunca
-- modificar ni borrar). Solo se restringe a sesiones autenticadas.
do $$
begin
  if exists (select 1 from information_schema.tables
             where table_schema = 'public' and table_name = 'movement_audit') then
    drop policy if exists movement_audit_insert on public.movement_audit;
    drop policy if exists movement_audit_select on public.movement_audit;

    create policy movement_audit_insert on public.movement_audit
      for insert to authenticated with check (true);
    create policy movement_audit_select on public.movement_audit
      for select to authenticated using (true);

    revoke all on public.movement_audit from anon;
    revoke update, delete on public.movement_audit from authenticated;
  end if;
end $$;

-- Las funciones siguen disponibles para la app autenticada.
revoke execute on function public.get_database_usage() from anon;
revoke execute on function public.ajustar_stock(uuid, integer) from anon;


-- ############################################################################
-- PASO 3 — VERIFICACIÓN. Revisa esto ANTES de confirmar.
-- ############################################################################
-- Todas las tablas deben salir con rls_activo = true y al menos 1 política.
select c.relname as tabla,
       c.relrowsecurity as rls_activo,
       count(p.policyname) as politicas
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_policies p on p.schemaname = 'public' and p.tablename = c.relname
where n.nspname = 'public' and c.relkind = 'r'
  and c.relname in ('products', 'movements', 'warehouses', 'categories',
                    'projects', 'user_profiles', 'product_warehouses',
                    'movement_audit')
group by c.relname, c.relrowsecurity
order by c.relname;

-- Si todo está en true y con políticas, escribe:  commit;
-- Si algo no cuadra, escribe:                     rollback;

-- commit;


-- ############################################################################
-- PASO 4 — PROBAR EN LA APP (después del commit)
-- ############################################################################
-- Cierra sesión y vuelve a entrar. Debes poder ver el inventario, registrar
-- un movimiento y abrir los reportes con normalidad.
--
-- Si algo dejó de cargar, revierte esa tabla con:
--     alter table public.NOMBRE disable row level security;
-- y avísame cuál fue.
