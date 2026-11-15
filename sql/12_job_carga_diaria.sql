USE msdb;
GO

-- Si el job ya existe, lo borra para poder recrearlo
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'MesaAyuda - Carga diaria de tickets')
    EXEC msdb.dbo.sp_delete_job @job_name = N'MesaAyuda - Carga diaria de tickets';
GO

-- 1. El job
EXEC msdb.dbo.sp_add_job
    @job_name = N'MesaAyuda - Carga diaria de tickets',
    @description = N'Ejecuta el ETL de tickets: valida, carga dimensiones y hechos.';

-- 2. El paso: qué ejecuta
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'MesaAyuda - Carga diaria de tickets',
    @step_name = N'Ejecutar sp_cargar_tickets',
    @subsystem = N'TSQL',
    @database_name = N'MesaAyuda',
    @command = N'EXEC dwh.sp_cargar_tickets;';

-- 3. El horario: todos los días a las 2:00 AM
EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Diario 2:00 AM',
    @freq_type = 4,
    @freq_interval = 1,
    @active_start_time = 020000;

EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'MesaAyuda - Carga diaria de tickets',
    @schedule_name = N'Diario 2:00 AM';

-- 4. Asignarlo a este servidor
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'MesaAyuda - Carga diaria de tickets',
    @server_name = N'(local)';
GO