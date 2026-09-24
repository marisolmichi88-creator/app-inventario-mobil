-- ============================================================================
-- DIAGNÓSTICO DE ALTAS DE USUARIO  (solo lectura, no modifica nada)
--
-- Pegar completo en Supabase > SQL Editor y ejecutar. Devuelve una tabla
-- chequeo / resultado. Todo lo que salga con ❌ es una causa posible de que
-- "crear usuario" falle o de que el usuario nuevo no pueda ingresar.
-- ============================================================================
with checks as (
  select 1 as n, 'Trigger en auth.users' as chequeo,
    coalesce((
      select string_agg(t.tgname || ' -> ' || p.proname, ', ')
        from pg_trigger t
        join pg_proc p on p.oid = t.tgfoid
        join pg_class c on c.oid = t.tgrelid
        join pg_namespace ns on ns.oid = c.relnamespace
       where ns.nspname = 'auth' and c.relname = 'users' and not t.tgisinternal
    ), '❌ NO HAY TRIGGER (el perfil nunca se crea solo)') as resultado

  union all select 2, 'Funciones de seguridad',
    coalesce((
      select string_agg(p.proname, ', ' order by p.proname)
        from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
       where ns.nspname = 'public'
         and p.proname in ('handle_new_user',
                           'current_user_is_admin',
                           'update_own_profile_name')
    ), '❌ NINGUNA (falta ejecutar supabase_account_security.sql)')

  union all select 3, 'Indice unico de auth_user_id',
    coalesce((
      select '✅ ' || indexname from pg_indexes
       where schemaname = 'public' and tablename = 'user_profiles'
         and indexdef like '%UNIQUE%' and indexdef like '%auth_user_id%'
       limit 1
    ), '❌ FALTA (permite perfiles duplicados por cuenta)')

  union all select 4, 'RLS en user_profiles',
    coalesce((
      select case when relrowsecurity then '✅ activada'
                  else '❌ DESACTIVADA (cualquiera se puede hacer admin)' end
        from pg_class c join pg_namespace ns on ns.oid = c.relnamespace
       where ns.nspname = 'public' and c.relname = 'user_profiles'
    ), '❌ LA TABLA NO EXISTE')

  union all select 5, 'Politicas de user_profiles',
    coalesce((
      select string_agg(policyname || ' (' || cmd || ')', ', '
                        order by policyname)
        from pg_policies
       where schemaname = 'public' and tablename = 'user_profiles'
    ), '❌ SIN POLITICAS (con RLS activa, bloquea todo en silencio)')

  union all select 6, 'Columnas obligatorias que la app NO envia',
    coalesce((
      select string_agg(column_name, ', ')
        from information_schema.columns
       where table_schema = 'public' and table_name = 'user_profiles'
         and is_nullable = 'NO' and column_default is null
         and column_name not in ('id', 'auth_user_id', 'name',
                                 'email', 'role', 'is_active')
    ), '✅ ninguna')

  union all select 7, 'Totales',
    (select count(*) from auth.users)::text || ' cuentas en Auth / ' ||
    (select count(*) from public.user_profiles)::text || ' perfiles'

  union all select 8, 'Cuentas de Auth SIN perfil',
    coalesce((
      select count(*)::text || ' -> ' || string_agg(u.email, ', ')
        from auth.users u
        left join public.user_profiles p on p.auth_user_id = u.id
       where p.id is null
    ), '✅ ninguna')

  union all select 9, 'Perfiles FANTASMA (sin cuenta de Auth)',
    coalesce((
      select count(*)::text || ' -> ' || string_agg(p.email, ', ')
        from public.user_profiles p
        left join auth.users u on u.id = p.auth_user_id
       where u.id is null
    ), '✅ ninguno')

  union all select 10, 'Cuentas que NO confirmaron el correo',
    coalesce((
      select count(*)::text || ' -> ' || string_agg(u.email, ', ')
        from auth.users u where u.email_confirmed_at is null
    ), '✅ ninguna')

  union all select 11, 'Correos repetidos en user_profiles',
    coalesce((
      select string_agg(email || ' x' || veces::text, ', ') from (
        select lower(email) as email, count(*) as veces
          from public.user_profiles group by lower(email) having count(*) > 1
      ) d
    ), '✅ ninguno')

  union all select 12, 'Administradores activos',
    coalesce((
      select string_agg(email, ', ') from public.user_profiles
       where role = 'admin' and is_active::text in ('true', '1')
    ), '❌ NINGUNO (nadie pasa current_user_is_admin)')
)
select chequeo, resultado from checks order by n;
