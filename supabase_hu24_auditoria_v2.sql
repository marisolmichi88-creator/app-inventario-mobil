-- ============================================================================
--  HU13 (cliente en proyectos) + HU24 (auditoría inalterable de movimientos)
--
--  Ejecutar en Supabase → SQL Editor. Es seguro correrlo varias veces.
--  No borra ni modifica datos existentes.
--
--  Diferencia con supabase_hu13_hu24.sql: aquel creaba la política
--  "FOR ALL USING (true)", que incluye DELETE. Es decir, cualquiera con la
--  clave pública podía borrar la auditoría, que es justo lo que la auditoría
--  debe impedir. Aquí se permite insertar y leer, pero NO modificar ni borrar.
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- HU13: cliente y presupuesto en proyectos
-- ----------------------------------------------------------------------------
alter table public.projects add column if not exists client text;
alter table public.projects add column if not exists budget numeric default 0;

-- ----------------------------------------------------------------------------
-- HU24: copia permanente de cada movimiento.
-- Aunque el movimiento se borre del historial, aquí queda.
-- ----------------------------------------------------------------------------
create table if not exists public.movement_audit (
  id           uuid primary key default gen_random_uuid(),
  movement_id  uuid,
  product_id   uuid,
  warehouse_id uuid,
  project_id   uuid,
  user_id      uuid,
  type         text,
  quantity     integer,
  date         text,
  notes        text,
  created_at   timestamptz default now()
);

create index if not exists movement_audit_movement_id_idx
  on public.movement_audit (movement_id);
create index if not exists movement_audit_created_at_idx
  on public.movement_audit (created_at desc);

-- Sembrar con los movimientos que ya existen. Sin esto, el historial anterior
-- a hoy se quedaria fuera de la auditoria para siempre.
insert into public.movement_audit
  (movement_id, product_id, warehouse_id, project_id, user_id, type, quantity, date, notes)
select
  m.id, m.product_id, m.warehouse_id, m.project_id, m.user_id, m.type, m.quantity,
  m.date::text, m.notes
from public.movements m
where not exists (
  select 1 from public.movement_audit a where a.movement_id = m.id
);

-- ----------------------------------------------------------------------------
-- Permisos: insertar y leer si, modificar y borrar no.
-- ----------------------------------------------------------------------------
alter table public.movement_audit enable row level security;

-- Quita la politica abierta anterior, si quedo de una ejecucion previa.
drop policy if exists movement_audit_all on public.movement_audit;

do $$
begin
  if not exists (select 1 from pg_policies
                 where schemaname = 'public' and tablename = 'movement_audit'
                   and policyname = 'movement_audit_insert') then
    create policy movement_audit_insert on public.movement_audit
      for insert with check (true);
  end if;

  if not exists (select 1 from pg_policies
                 where schemaname = 'public' and tablename = 'movement_audit'
                   and policyname = 'movement_audit_select') then
    create policy movement_audit_select on public.movement_audit
      for select using (true);
  end if;
end $$;

-- Sin politicas de update ni delete, RLS los bloquea por defecto.
-- Se revocan ademas de forma explicita para los roles de la app.
revoke update, delete on public.movement_audit from anon, authenticated;

comment on table public.movement_audit is
  'Registro inalterable de movimientos (HU24). Solo admite insertar y leer: '
  'conserva los movimientos aunque se borren del historial.';

commit;

-- ============================================================================
-- Verificacion
-- ============================================================================
select count(*) as filas_auditoria from public.movement_audit;

select policyname, cmd
from pg_policies
where schemaname = 'public' and tablename = 'movement_audit'
order by policyname;
