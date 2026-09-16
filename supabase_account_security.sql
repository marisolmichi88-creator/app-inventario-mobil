-- ============================================================================
-- CUENTAS SEGURAS Y PERFILES CONSISTENTES
--
-- Ejecutar una vez en Supabase SQL Editor antes de distribuir el nuevo APK.
-- Es idempotente y no cambia los roles ni el estado de usuarios existentes.
-- ============================================================================

begin;

-- Cada cuenta de Auth debe apuntar como máximo a un perfil.
create unique index if not exists user_profiles_auth_user_id_uidx
  on public.user_profiles (auth_user_id);

-- Los registros públicos jamás nacen activos ni con privilegios. La pantalla
-- administrativa completa y activa el perfil después de crear Auth.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profiles
    (auth_user_id, name, email, role, is_active)
  values
    (
      new.id,
      coalesce(nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
               'Cuenta pendiente'),
      new.email,
      'operador',
      false
    )
  on conflict (auth_user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

revoke all on function public.handle_new_user() from public, anon, authenticated;

-- Consulta de rol centralizada. SECURITY DEFINER evita recursión al evaluar
-- políticas de la propia tabla user_profiles.
create or replace function public.current_user_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
      from public.user_profiles p
     where p.auth_user_id = auth.uid()
       and p.role = 'admin'
       and p.is_active is true
  );
$$;

revoke all on function public.current_user_is_admin() from public, anon;
grant execute on function public.current_user_is_admin() to authenticated;

alter table public.user_profiles enable row level security;

-- Elimina las políticas históricas abiertas de esta tabla antes de instalar
-- las reglas por rol.
do $$
declare
  policy_record record;
begin
  for policy_record in
    select policyname
      from pg_policies
     where schemaname = 'public'
       and tablename = 'user_profiles'
  loop
    execute format(
      'drop policy if exists %I on public.user_profiles',
      policy_record.policyname
    );
  end loop;
end $$;

create policy user_profiles_select_self_or_admin
  on public.user_profiles
  for select
  to authenticated
  using (
    auth_user_id = auth.uid()
    or public.current_user_is_admin()
  );

create policy user_profiles_insert_admin
  on public.user_profiles
  for insert
  to authenticated
  with check (public.current_user_is_admin());

create policy user_profiles_update_admin
  on public.user_profiles
  for update
  to authenticated
  using (public.current_user_is_admin())
  with check (public.current_user_is_admin());

create policy user_profiles_delete_admin
  on public.user_profiles
  for delete
  to authenticated
  using (public.current_user_is_admin());

revoke all on public.user_profiles from anon;
grant select, insert, update, delete on public.user_profiles to authenticated;

-- Los usuarios no administradores pueden cambiar únicamente su nombre. No se
-- expone una actualización de fila con la que pudieran cambiar rol o estado.
create or replace function public.update_own_profile_name(p_name text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if nullif(trim(p_name), '') is null then
    raise exception 'El nombre no puede estar vacío';
  end if;

  update public.user_profiles
     set name = trim(p_name)
   where auth_user_id = auth.uid()
     and is_active is true;

  if not found then
    raise exception 'No existe un perfil activo para esta cuenta';
  end if;
end;
$$;

revoke all on function public.update_own_profile_name(text) from public, anon;
grant execute on function public.update_own_profile_name(text) to authenticated;

commit;

-- Verificación: ninguna política de user_profiles debe incluir al rol anon.
select policyname, cmd, roles
  from pg_policies
 where schemaname = 'public'
   and tablename = 'user_profiles'
 order by policyname;

