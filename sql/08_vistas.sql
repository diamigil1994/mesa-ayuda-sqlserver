USE MesaAyuda;
GO

-- Cumplimiento de SLA por categoría (solo tickets cerrados)
CREATE OR ALTER VIEW dwh.vw_sla_por_categoria AS
SELECT
    c.nombre AS categoria,
    COUNT(*) AS tickets_cerrados,
    SUM(CAST(f.cumplio_sla AS INT)) AS cumplieron_sla,
    CAST(100.0 * SUM(CAST(f.cumplio_sla AS INT)) / COUNT(*) AS DECIMAL(5,2)) AS pct_cumplimiento,
    CAST(AVG(f.horas_resolucion) AS DECIMAL(10,2)) AS horas_promedio
FROM dwh.fact_tickets f
JOIN dwh.dim_categoria c ON c.categoria_id = f.categoria_id
WHERE f.cumplio_sla IS NOT NULL
GROUP BY c.nombre;
GO

-- Carga de trabajo por técnico
CREATE OR ALTER VIEW dwh.vw_tickets_por_tecnico AS
SELECT
    t.nombre AS tecnico,
    COUNT(*) AS total_tickets,
    SUM(CASE WHEN f.estado = 'Cerrado' THEN 1 ELSE 0 END) AS cerrados,
    SUM(CASE WHEN f.estado <> 'Cerrado' THEN 1 ELSE 0 END) AS pendientes,
    SUM(CAST(f.reabierto AS INT)) AS reabiertos,
    CAST(AVG(f.horas_resolucion) AS DECIMAL(10,2)) AS horas_promedio
FROM dwh.fact_tickets f
JOIN dwh.dim_tecnico t ON t.tecnico_id = f.tecnico_id
GROUP BY t.nombre;
GO


