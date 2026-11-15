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

        -- (Parte 2, mañana: dimensiones y tabla de hechos)

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