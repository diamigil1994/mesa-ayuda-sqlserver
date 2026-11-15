USE MesaAyuda;
GO
DROP TABLE IF EXISTS stg.tickets;
GO
CREATE TABLE stg.tickets (
    ticket_id      NVARCHAR(50),
    fecha_apertura NVARCHAR(50),
    fecha_cierre   NVARCHAR(50),
    usuario        NVARCHAR(100),
    tecnico        NVARCHAR(100),
    categoria      NVARCHAR(100),
    prioridad      NVARCHAR(50),
    estado         NVARCHAR(50),
    reabierto      NVARCHAR(10)
);
GO