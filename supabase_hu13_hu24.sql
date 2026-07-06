-- ============================================================================
--  Proenergim Stock — SQL para completar HU13 (cliente) y HU24 (auditoría)
--  Cómo usar: abre Supabase → SQL Editor → pega TODO esto → RUN.
--  Es seguro de correr varias veces (usa IF NOT EXISTS / evita duplicados).
--  La app ya funciona sin esto; correrlo solo ACTIVA la persistencia de
--  estas dos funciones. No borra ni modifica datos existentes.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- HU13: columna "cliente" y "presupuesto" en proyectos
-- ----------------------------------------------------------------------------
ALTER TABLE projects ADD COLUMN IF NOT EXISTS client text;
ALTER TABLE projects ADD COLUMN IF NOT EXISTS budget numeric DEFAULT 0;


-- ----------------------------------------------------------------------------
-- HU24: tabla de auditoría inalterable de movimientos.
-- Guarda una copia permanente de cada movimiento. Aunque el movimiento se
-- borre del historial con el botón eliminar, aquí NO se borra, para que
-- siga apareciendo en el reporte de auditoría semanal/mensual.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS movement_audit (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  movement_id  uuid,
  product_id   uuid,
  warehouse_id uuid,
  project_id   uuid,
  user_id      uuid,
  type         text,
  quantity     integer,
  date         text,
  notes        text,
  created_at   timestamptz DEFAULT now()
);

-- Sembrar la auditoría con los movimientos que YA existen (una sola vez).
-- Evita duplicados si se corre de nuevo.
INSERT INTO movement_audit
  (movement_id, product_id, warehouse_id, project_id, user_id, type, quantity, date, notes)
SELECT
  m.id, m.product_id, m.warehouse_id, m.project_id, m.user_id, m.type, m.quantity,
  m.date::text, m.notes
FROM movements m
WHERE NOT EXISTS (
  SELECT 1 FROM movement_audit a WHERE a.movement_id = m.id
);

-- Permisos (RLS). Si tus otras tablas tienen políticas abiertas para la app,
-- estas líneas dejan que la app pueda leer y escribir en movement_audit.
-- Si te da error de "policy already exists", ignóralo: ya está creada.
ALTER TABLE movement_audit ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'movement_audit' AND policyname = 'movement_audit_all'
  ) THEN
    CREATE POLICY movement_audit_all ON movement_audit
      FOR ALL USING (true) WITH CHECK (true);
  END IF;
END $$;
