USE MesaAyuda;
GO
TRUNCATE TABLE stg.tickets;
GO
BULK INSERT stg.tickets
FROM '/var/opt/mssql/data/tickets.csv'
WITH (FORMAT = 'CSV', FIRSTROW = 2, ROWTERMINATOR = '0x0d0a');
GO