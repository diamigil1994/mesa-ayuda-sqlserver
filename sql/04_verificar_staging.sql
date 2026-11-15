USE MesaAyuda;
GO

SELECT COUNT(*) AS total_filas FROM stg.tickets;

SELECT TOP 10 * FROM stg.tickets;

SELECT ticket_id, COUNT(*) AS veces
FROM stg.tickets
GROUP BY ticket_id
HAVING COUNT(*) > 1;



SELECT DISTINCT reabierto, LEN(reabierto) AS largo
FROM stg.tickets;