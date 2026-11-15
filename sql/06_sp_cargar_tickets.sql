USE MesaAyuda;
GO

IF COL_LENGTH('dwh.tickets_rechazados', 'carga_id') IS NULL
    ALTER TABLE dwh.tickets_rechazados ADD carga_id INT NULL;
GO


CREATE OR ALTER PROCEDURE dwh.sp_cargar_tickets
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @carga_id INT, @leidas INT, @rechazadas INT = 0, @cargadas INT = 0;

    -- La bitácora se escribe ANTES de la transacción, para que sobreviva a un error
    INSERT INTO dwh.bitacora_cargas (inicio, estado) VALUES (SYSDATETIME(), 'EN_CURSO');
    SET @carga_id = SCOPE_IDENTITY();

    BEGIN TRY
        BEGIN TRAN;

        -- 1. Copia de trabajo con un número de fila propio
        SELECT *, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS fila
        INTO #base
        FROM stg.tickets;
        SET @leidas = @@ROWCOUNT;

        -- 2. Evaluar cada fila: la primera regla que falle da el motivo
        SELECT fila, ticket_id,
            CASE
                WHEN TRY_CONVERT(INT, ticket_id) IS NULL
                    THEN 'ticket_id invalido'
                WHEN ROW_NUMBER() OVER (PARTITION BY ticket_id ORDER BY fila) > 1
                    THEN 'ticket_id duplicado'
                WHEN TRY_CONVERT(DATETIME2, fecha_apertura) IS NULL
                    THEN 'fecha_apertura invalida'
                WHEN NULLIF(LTRIM(RTRIM(fecha_cierre)), '') IS NOT NULL
                    AND TRY_CONVERT(DATETIME2, fecha_cierre) IS NULL
                    THEN 'fecha_cierre invalida'
                WHEN NULLIF(LTRIM(RTRIM(fecha_cierre)), '') IS NOT NULL
                    AND TRY_CONVERT(DATETIME2, fecha_cierre) < TRY_CONVERT(DATETIME2, fecha_apertura)
                    THEN 'cierre anterior a apertura'
                WHEN NULLIF(LTRIM(RTRIM(usuario)), '') IS NULL
                    THEN 'usuario vacio'
                WHEN NULLIF(LTRIM(RTRIM(tecnico)), '') IS NULL
                    THEN 'tecnico vacio'
                WHEN NULLIF(LTRIM(RTRIM(categoria)), '') IS NULL
                    THEN 'categoria vacia'
                WHEN LTRIM(RTRIM(categoria)) NOT IN (SELECT nombre FROM dwh.dim_categoria)
                    THEN 'categoria desconocida'
                WHEN NULLIF(LTRIM(RTRIM(prioridad)), '') IS NULL
                    THEN 'prioridad vacia'
                WHEN LTRIM(RTRIM(prioridad)) NOT IN (SELECT nombre FROM dwh.dim_prioridad)
                    THEN 'prioridad desconocida'
                WHEN estado NOT IN ('Abierto', 'En proceso', 'Cerrado')
                    THEN 'estado desconocido'
                WHEN REPLACE(reabierto, CHAR(13), '') NOT IN ('0', '1')
                    THEN 'reabierto desconocido'
                ELSE NULL
            END AS motivo
        INTO #evaluada
        FROM #base;

        -- 3. Mandar los rechazos a su tabla
        INSERT INTO dwh.tickets_rechazados (ticket_id, motivo, carga_id)
        SELECT ticket_id, motivo, @carga_id
        FROM #evaluada
        WHERE motivo IS NOT NULL;
        SET @rechazadas = @@ROWCOUNT;


        -- 4. Dimensiones: agregar usuarios y técnicos que aún no existen
        INSERT INTO dwh.dim_usuario (nombre)
        SELECT DISTINCT LTRIM(RTRIM(b.usuario))
        FROM #base b
        JOIN #evaluada e ON e.fila = b.fila
        WHERE e.motivo IS NULL
        AND NOT EXISTS (SELECT 1 FROM dwh.dim_usuario u
                        WHERE u.nombre = LTRIM(RTRIM(b.usuario)));

        INSERT INTO dwh.dim_tecnico (nombre)
        SELECT DISTINCT LTRIM(RTRIM(b.tecnico))
        FROM #base b
        JOIN #evaluada e ON e.fila = b.fila
        WHERE e.motivo IS NULL
        AND NOT EXISTS (SELECT 1 FROM dwh.dim_tecnico t
                        WHERE t.nombre = LTRIM(RTRIM(b.tecnico)));


       -- 5. Hechos: cargar los tickets buenos que aún no están en fact_tickets
        INSERT INTO dwh.fact_tickets
            (ticket_id, fecha_apertura_id, fecha_cierre_id, usuario_id, tecnico_id,
            categoria_id, prioridad_id, estado, horas_resolucion, cumplio_sla, reabierto)
        SELECT
            TRY_CONVERT(INT, b.ticket_id),
            CONVERT(INT, CONVERT(CHAR(8), TRY_CONVERT(DATETIME2, b.fecha_apertura), 112)),
            CASE WHEN NULLIF(LTRIM(RTRIM(b.fecha_cierre)), '') IS NULL THEN NULL
                ELSE CONVERT(INT, CONVERT(CHAR(8), TRY_CONVERT(DATETIME2, b.fecha_cierre), 112))
            END,
            u.usuario_id,
            t.tecnico_id,
            c.categoria_id,
            p.prioridad_id,
            b.estado,
            CASE WHEN NULLIF(LTRIM(RTRIM(b.fecha_cierre)), '') IS NULL THEN NULL
                ELSE CAST(DATEDIFF(MINUTE, TRY_CONVERT(DATETIME2, b.fecha_apertura),
                                            TRY_CONVERT(DATETIME2, b.fecha_cierre)) / 60.0
                        AS DECIMAL(10,2))
            END,
            CASE WHEN NULLIF(LTRIM(RTRIM(b.fecha_cierre)), '') IS NULL THEN NULL
                WHEN DATEDIFF(MINUTE, TRY_CONVERT(DATETIME2, b.fecha_apertura),
                                    TRY_CONVERT(DATETIME2, b.fecha_cierre)) / 60.0 <= p.sla_horas
                    THEN 1
                ELSE 0
            END,
            CAST(REPLACE(b.reabierto, CHAR(13), '') AS BIT)
        FROM #base b
        JOIN #evaluada e        ON e.fila = b.fila
        JOIN dwh.dim_usuario u  ON u.nombre = LTRIM(RTRIM(b.usuario))
        JOIN dwh.dim_tecnico t  ON t.nombre = LTRIM(RTRIM(b.tecnico))
        JOIN dwh.dim_categoria c ON c.nombre = LTRIM(RTRIM(b.categoria))
        JOIN dwh.dim_prioridad p ON p.nombre = LTRIM(RTRIM(b.prioridad))
        WHERE e.motivo IS NULL
        AND NOT EXISTS (SELECT 1 FROM dwh.fact_tickets f
                        WHERE f.ticket_id = TRY_CONVERT(INT, b.ticket_id));
        SET @cargadas = @@ROWCOUNT;


        COMMIT;

        UPDATE dwh.bitacora_cargas
        SET fin = SYSDATETIME(), filas_leidas = @leidas, filas_cargadas = @cargadas,
            filas_rechazadas = @rechazadas, estado = 'OK'
        WHERE carga_id = @carga_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        UPDATE dwh.bitacora_cargas
        SET fin = SYSDATETIME(), estado = 'ERROR', mensaje = LEFT(ERROR_MESSAGE(), 500)
        WHERE carga_id = @carga_id;
    END CATCH
END;
GO


EXEC dwh.sp_cargar_tickets;

SELECT * FROM dwh.bitacora_cargas;

SELECT motivo, COUNT(*) AS filas
FROM dwh.tickets_rechazados
GROUP BY motivo
ORDER BY filas DESC;
