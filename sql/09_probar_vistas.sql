-- Script de prueba: Consulta las vistas de reportes

-- Cumplimiento de SLA por categoria
-- Pregunta que responde: ¿Qué porcentaje de tickets se resolvió dentro del tiempo prometido (SLA), según el tipo de problema?
SELECT * FROM dwh.vw_sla_por_categoria ORDER BY pct_cumplimiento;

-- Carga de trabajo por tecnico
-- Pregunta que responde: ¿Cómo se reparte el trabajo entre los técnicos?
SELECT * FROM dwh.vw_tickets_por_tecnico ORDER BY total_tickets DESC;

-- Pivot : tickets por categoria y prioridad
-- Pregunta que responde: ¿Cuántos tickets de cada prioridad tiene cada categoría?
SELECT * FROM dwh.vw_pivot_prioridad_categoria;
