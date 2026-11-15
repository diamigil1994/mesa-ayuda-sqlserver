USE MesaAyuda;
GO

-- Acelera consultas que filtran tickets por fecha y categoría 
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'ix_fact_fecha_categoria'
                 AND object_id = OBJECT_ID('dwh.fact_tickets'))
    CREATE NONCLUSTERED INDEX ix_fact_fecha_categoria
    ON dwh.fact_tickets (fecha_apertura_id, categoria_id);
GO