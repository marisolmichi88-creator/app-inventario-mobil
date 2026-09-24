-- ============================================================================
-- REPARACIÓN DE CUENTAS  (Supabase > SQL Editor)
--
-- IMPORTANTE: en el SQL Editor cada Run es una transacción independiente. Un
-- commit; escrito en un Run posterior NO confirma el begin; de un Run anterior:
-- ese ya se revirtió al terminar la petición. Por eso begin y commit tienen que
-- viajar SIEMPRE en la misma ejecución, como están aquí abajo.
-- ============================================================================


-- ############################################################################
-- PASO 0 — VER a quién afecta. Solo lectura, no cambia nada.
-- ############################################################################
select
  u.email,
  case when p.id is null then 'HUERFANA (el paso 1 la borra)'
       else 'tiene perfil' end                        as perfil,
  case when u.email_confirmed_at is null then 'sin confirmar'
       else 'confirmada' end                          as correo,
  case when p.id is null then '-' else p.role end     as rol,
  u.created_at::date                                  as creada
from auth.users u
left join public.user_profiles p on p.auth_user_id = u.id
order by (p.id is null) desc, u.created_at;


-- ############################################################################
-- PASO 1 — REPARAR. Selecciona este bloque COMPLETO (desde begin; hasta
-- commit;) y pulsa Run una sola vez.
--
-- Hace dos cosas: confirma el correo de las cuentas que sí tienen perfil, y
-- borra las que no tienen ninguno.
--
-- ⚠️ El borrado NO se puede deshacer. Corre antes el PASO 0 y revisa la lista.
--    Si quieres salvar algún correo, quítale los -- a la línea de excepciones.
-- ############################################################################
begin;

update auth.users u
   set email_confirmed_at = now()
  from public.user_profiles p
 where p.auth_user_id = u.id
   and u.email_confirmed_at is null;

delete from auth.users u
 where not exists (
         select 1 from public.user_profiles p where p.auth_user_id = u.id
       )
   -- and u.email not in ('emedinada@ucvvirtual.edu.pe')
   ;

commit;


-- ############################################################################
-- PASO 2 — COMPROBAR que quedó de verdad. Ejecútalo por separado.
--
-- Tiene que salir: cuentas_auth = perfiles, y sin_confirmar = 0.
-- ############################################################################
select (select count(*) from auth.users)           as cuentas_auth,
       (select count(*) from public.user_profiles) as perfiles,
       (select count(*) from auth.users
         where email_confirmed_at is null)          as sin_confirmar;


-- ############################################################################
-- PASO 3 — Detalle final, quién quedó y cómo.
-- ############################################################################
select u.email, p.name, p.role, p.is_active,
       u.email_confirmed_at is not null as correo_confirmado
  from auth.users u
  left join public.user_profiles p on p.auth_user_id = u.id
 order by p.role nulls first, u.email;
