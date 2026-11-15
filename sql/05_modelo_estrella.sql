USE MesaAyuda;
GO

DROP TABLE IF EXISTS dwh.fact_tickets;
DROP TABLE IF EXISTS dwh.dim_fecha;
DROP TABLE IF EXISTS dwh.dim_usuario;
DROP TABLE IF EXISTS dwh.dim_tecnico;
DROP TABLE IF EXISTS dwh.dim_categoria;
DROP TABLE IF EXISTS dwh.dim_prioridad;
GO




CREATE TABLE dwh.dim_categoria (
    categoria_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre       NVARCHAR(100) NOT NULL UNIQUE
);
GO

CREATE TABLE dwh.dim_usuario (
    usuario_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre     NVARCHAR(100) NOT NULL UNIQUE
);
GO

CREATE TABLE dwh.dim_tecnico (
    tecnico_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre     NVARCHAR(100) NOT NULL UNIQUE
);
GO

CREATE TABLE dwh.dim_prioridad (
    prioridad_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre       NVARCHAR(50) NOT NULL UNIQUE,
    sla_horas    INT NOT NULL
);
GO

INSERT INTO dwh.dim_prioridad (nombre, sla_horas)
VALUES ('Alta', 4), ('Media', 24), ('Baja', 72);
GO

CREATE TABLE dwh.dim_fecha (
    fecha_id   INT PRIMARY KEY,
    fecha      DATE NOT NULL,
    anio       INT NOT NULL,
    mes        INT NOT NULL,
    nombre_mes NVARCHAR(20) NOT NULL,
    dia_semana NVARCHAR(20) NOT NULL
);
GO

WITH fechas AS (
    SELECT CAST('2025-10-01' AS DATE) AS f
    UNION ALL
    SELECT DATEADD(DAY, 1, f) FROM fechas WHERE f < '2026-12-31'
)
INSERT INTO dwh.dim_fecha (fecha_id, fecha, anio, mes, nombre_mes, dia_semana)
SELECT CONVERT(INT, CONVERT(CHAR(8), f, 112)), f, YEAR(f), MONTH(f),
       DATENAME(MONTH, f), DATENAME(WEEKDAY, f)
FROM fechas
OPTION (MAXRECURSION 0);
GO



CREATE TABLE dwh.fact_tickets (
    ticket_id         INT PRIMARY KEY,
    fecha_apertura_id INT NOT NULL REFERENCES dwh.dim_fecha(fecha_id),
    fecha_cierre_id   INT NULL     REFERENCES dwh.dim_fecha(fecha_id),
    usuario_id        INT NOT NULL REFERENCES dwh.dim_usuario(usuario_id),
    tecnico_id        INT NOT NULL REFERENCES dwh.dim_tecnico(tecnico_id),
    categoria_id      INT NOT NULL REFERENCES dwh.dim_categoria(categoria_id),
    prioridad_id      INT NOT NULL REFERENCES dwh.dim_prioridad(prioridad_id),
    estado            NVARCHAR(20) NOT NULL,
    horas_resolucion  DECIMAL(10,2) NULL,
    cumplio_sla       BIT NULL,
    reabierto         BIT NOT NULL DEFAULT 0
);
GO



IF OBJECT_ID('dwh.tickets_rechazados', 'U') IS NULL
CREATE TABLE dwh.tickets_rechazados (
    id          INT IDENTITY(1,1) PRIMARY KEY,
    ticket_id   NVARCHAR(50) NULL,
    motivo      NVARCHAR(200) NOT NULL,
    fecha_carga DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID('dwh.bitacora_cargas', 'U') IS NULL
CREATE TABLE dwh.bitacora_cargas (
    carga_id         INT IDENTITY(1,1) PRIMARY KEY,
    inicio           DATETIME2 NOT NULL,
    fin              DATETIME2 NULL,
    filas_leidas     INT NULL,
    filas_cargadas   INT NULL,
    filas_rechazadas INT NULL,
    estado           NVARCHAR(20) NOT NULL,
    mensaje          NVARCHAR(500) NULL
);
GO



SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dwh';
SELECT COUNT(*) AS dias FROM dwh.dim_fecha;
SELECT * FROM dwh.dim_prioridad;



