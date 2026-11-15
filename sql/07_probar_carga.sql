-- Script de prueba: ejecuta el ETL y muestra los resultados.
-- Se puede correr varias veces: la carga es idempotente.

USE MesaAyuda;
GO

-- Ejecuta la carga
EXEC dwh.sp_cargar_tickets;

-- Resultado de la carga
SELECT * FROM dwh.bitacora_cargas;

-- Rechazos por motivo
SELECT motivo, COUNT(*) AS filas
FROM dwh.tickets_rechazados
WHERE carga_id = (SELECT MAX(carga_id) FROM dwh.bitacora_cargas)
GROUP BY motivo
ORDER BY filas DESC;

-- Tickets en la tabla de hechos
SELECT COUNT(*) AS tickets_en_hechos FROM dwh.fact_tickets;