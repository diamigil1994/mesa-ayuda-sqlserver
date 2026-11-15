USE MesaAyuda;
GO

-- PARTE A: medir "ANTES" (sin índice)
-- se mide antes de crear el indice para ver la diferencia de performance 
DROP INDEX IF EXISTS ix_fact_fecha_categoria ON dwh.fact_tickets;
GO
SET STATISTICS IO ON;
SELECT COUNT(*) AS tickets
FROM dwh.fact_tickets
WHERE fecha_apertura_id BETWEEN 20260101 AND 20260131
  AND categoria_id = 1;
GO

-- PARTE B: medir "DESPUÉS"
-- Primero ejecuta 10_indices.sql, y luego SOLO esta consulta
SELECT COUNT(*) AS tickets
FROM dwh.fact_tickets
WHERE fecha_apertura_id BETWEEN 20260101 AND 20260131
  AND categoria_id = 1;