-- ============================================================================
--  SALIDAS: foto y destino
--
--  QUÉ RESUELVE
--  En cada salida el operador indica a dónde va el material y toma una foto
--  de lo que retira. La app guarda el destino como texto y la foto en
--  Supabase Storage; el movimiento solo guarda la ruta de la foto.
--
--  QUÉ HACE
--  1. Agrega las columnas `destination` y `photo_path` a `movements` y a
--     `movement_audit` (la auditoría copia cada movimiento: sin las columnas
--     esa copia fallaría en silencio).
--  2. Crea el bucket privado `movement-photos` (máximo 5 MB, solo imágenes).
--  3. Permite subir y ver fotos solo con sesión iniciada. Nadie puede
--     reemplazarlas ni borrarlas desde la app: son la constancia de la salida.
--
--  CÓMO EJECUTARLO
--  Pégalo completo en el editor SQL de Supabase y ejecútalo. Se puede volver
--  a ejecutar sin problema.
--
--  MIENTRAS NO SE EJECUTE
--  Las entradas siguen funcionando. Las salidas muestran el aviso de que
--  falta ejecutar este script.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1. Columnas nuevas
-- ----------------------------------------------------------------------------
alter table public.movements
  add column if not exists destination text,
  add column if not exists photo_path  text;

alter table if exists public.movement_audit
  add column if not exists destination text,
  add column if not exists photo_path  text;

comment on column public.movements.destination is
  'Lugar a donde va el material en una salida (texto libre).';
comment on column public.movements.photo_path is
  'Ruta de la foto de la salida dentro del bucket movement-photos.';

-- ----------------------------------------------------------------------------
-- 2. Bucket de fotos
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'movement-photos',
  'movement-photos',
  false,
  5 * 1024 * 1024,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ----------------------------------------------------------------------------
-- 3. Permisos: subir y ver con sesión iniciada; sin modificar ni borrar.
-- ----------------------------------------------------------------------------
drop policy if exists movement_photos_insert on storage.objects;
create policy movement_photos_insert on storage.objects
  for insert to authenticated
  with check (bucket_id = 'movement-photos');

drop policy if exists movement_photos_select on storage.objects;
create policy movement_photos_select on storage.objects
  for select to authenticated
  using (bucket_id = 'movement-photos');

commit;

-- ============================================================================
-- Verificación
-- ============================================================================
select table_name, column_name
from information_schema.columns
where table_schema = 'public'
  and table_name in ('movements', 'movement_audit')
  and column_name in ('destination', 'photo_path')
order by table_name, column_name;

select id, public, file_size_limit, allowed_mime_types
from storage.buckets
where id = 'movement-photos';

select policyname, cmd
from pg_policies
where schemaname = 'storage' and tablename = 'objects'
  and policyname like 'movement_photos_%'
order by policyname;
