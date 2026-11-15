-- Ejecuta el job manualmente y muestra la última carga
EXEC msdb.dbo.sp_start_job N'MesaAyuda - Carga diaria de tickets';
WAITFOR DELAY '00:00:05';
USE MesaAyuda;
SELECT TOP 3 * FROM dwh.bitacora_cargas ORDER BY carga_id DESC;