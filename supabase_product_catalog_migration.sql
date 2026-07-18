-- Ejecutar una sola vez en el SQL Editor de Supabase.
-- Amplía el catálogo sin modificar ni eliminar los productos existentes.

alter table public.products
  add column if not exists internal_qr text,
  add column if not exists subtype text,
  add column if not exists brand text,
  add column if not exists model text,
  add column if not exists attributes jsonb not null default '{}'::jsonb;

create unique index if not exists products_internal_qr_unique
  on public.products (internal_qr)
  where internal_qr is not null;

-- Existencias por almacén. El saldo inicial se conserva desde products; antes
-- de activar una sincronización automática se debe conciliar con movimientos.
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

comment on column public.products.code is
  'Código de fábrica, código de barras o SKU que identifica el tipo de producto.';
comment on column public.products.internal_qr is
  'Código QR generado por Proenergim solo para productos sin código de fábrica.';
comment on column public.products.serial_number is
  'Número de serie de una unidad física individual; no sustituye al código del producto.';
comment on column public.products.attributes is
  'Características variables del producto, por ejemplo potencia, voltaje, calibre, talla o dimensiones.';
