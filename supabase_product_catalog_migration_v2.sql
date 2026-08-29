-- ============================================================
-- PASO 1 de 2: ampliar la tabla products
-- ============================================================
-- Ejecutar UNA SOLA VEZ en el SQL Editor de Supabase, ANTES de
-- carga_catalogo_132_CORREGIDO.sql.
--
-- No modifica ni elimina productos existentes: solo agrega columnas.
-- Es seguro volver a ejecutarlo (todo usa "if not exists").
--
-- Diferencia con la version anterior: aquella ponia un comentario sobre la
-- columna serial_number sin crearla antes, y fallaba si no existia.
-- ============================================================

begin;

-- 1) Columnas nuevas del catalogo.
--    serial_number va aqui porque la app ya la envia al guardar un producto
--    (ProductModel.toMap), pero ningun script la creaba.
alter table public.products
  add column if not exists serial_number text,
  add column if not exists internal_qr text,
  add column if not exists subtype text,
  add column if not exists brand text,
  add column if not exists model text,
  add column if not exists attributes jsonb not null default '{}'::jsonb;

-- 2) El QR interno no se puede repetir entre productos.
create unique index if not exists products_internal_qr_unique
  on public.products (internal_qr)
  where internal_qr is not null;

-- 3) Existencias por almacen. Hoy la app todavia no lee esta tabla: el saldo
--    vigente sigue viviendo en products.stock. Se deja preparada para cuando
--    se maneje un mismo producto en varios almacenes.
create table if not exists public.product_warehouses (
  product_id uuid not null references public.products(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  stock integer not null default 0 check (stock >= 0),
  updated_at timestamptz not null default now(),
  primary key (product_id, warehouse_id)
);

insert into public.product_warehouses (product_id, warehouse_id, stock)
select id, warehouse_id, greatest(stock, 0)
from public.products
where warehouse_id is not null
on conflict (product_id, warehouse_id) do nothing;

-- 4) Documentacion de las columnas.
comment on column public.products.code is
  'Código de fábrica, código de barras o SKU que identifica el tipo de producto.';
comment on column public.products.internal_qr is
  'Código QR generado por Proenergim solo para productos sin código de fábrica.';
comment on column public.products.serial_number is
  'Número de serie de una unidad física individual; no sustituye al código del producto.';
comment on column public.products.attributes is
  'Características variables del producto, por ejemplo potencia, voltaje, calibre, talla o dimensiones.';

-- ============================================================
-- Verificacion: las 6 columnas deben aparecer listadas.
-- ============================================================
select column_name, data_type
from information_schema.columns
where table_schema = 'public'
  and table_name = 'products'
  and column_name in
      ('serial_number', 'internal_qr', 'subtype', 'brand', 'model', 'attributes')
order by column_name;

commit;
