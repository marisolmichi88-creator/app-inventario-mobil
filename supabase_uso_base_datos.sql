-- ============================================================================
--  Consumo de la base de datos, para mostrarlo dentro de la app.
--
--  Ejecutar en Supabase → SQL Editor. Es seguro correrlo varias veces.
--  No crea tablas ni modifica datos: solo agrega una función de lectura.
--
--  Hace falta porque la clave pública de la app no puede leer las funciones
--  del sistema de Postgres (pg_database_size). Con "security definer" la
--  función corre con los permisos de su dueño y devuelve solo estos números,
--  sin exponer nada más.
-- ============================================================================

create or replace function public.get_database_usage()
returns json
language sql
security definer
set search_path = public, pg_catalog
as $$
  select json_build_object(
    'size_bytes',  pg_database_size(current_database()),
    'productos',   (select count(*) from public.products),
    'movimientos', (select count(*) from public.movements),
    'auditoria',   (select count(*) from public.movement_audit),
    -- Momento del último cambio guardado, para mostrar que el respaldo
    -- está al día. Se toma el más reciente entre el catálogo y la auditoría.
    'ultimo_cambio', (
      select max(t) from (
        select max(updated_at) as t from public.products
        union all
        select max(created_at) from public.movement_audit
      ) cambios
    ),
    'consultado_en', now()
  );
$$;

comment on function public.get_database_usage() is
  'Devuelve el espacio usado por la base y el conteo de filas de las tablas '
  'principales. Solo lectura, para el panel de administración de la app.';

-- La app la llama con la clave pública.
grant execute on function public.get_database_usage() to anon, authenticated;

-- ============================================================================
-- Verificación: debe devolver un JSON con los cuatro valores.
-- ============================================================================
select public.get_database_usage();
