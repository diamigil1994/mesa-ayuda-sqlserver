# Mesa de Ayuda de TI: almacén de datos en SQL Server

Proyecto personal de ingeniería de datos que construye un almacén de datos (modelo estrella) a partir de datos sintéticos de tickets de una mesa de ayuda de TI. Incluye ETL con procedimientos almacenados en T-SQL, validación de calidad de datos, vistas de reporte, reportes con PIVOT, índices y un job automático.

## Objetivo

Practicar y demostrar el flujo completo de un proyecto de datos: datos crudos, limpieza y validación, modelado, carga repetible, reportes y automatización. Se inspira en mi experiencia administrando una mesa de servicio en GLPI.

## Tecnologías

- SQL Server 2022 (Docker)
- T-SQL: procedimientos almacenados, vistas, PIVOT, índices
- SQL Server Agent (job de carga)
- Python (generación de datos sintéticos)
- Metabase (tablero, opcional)
- Git y GitHub

## Estado del proyecto

- [x] Entorno: SQL Server en Docker y conexión desde VS Code
- [ ] Generación de datos sintéticos con Python
- [ ] Carga a staging con BULK INSERT
- [ ] Modelo estrella (hechos y dimensiones)
- [ ] Procedimiento almacenado de carga (idempotente, con rechazados y bitácora)
- [ ] Vistas de reporte
- [ ] Reporte con PIVOT
- [ ] Índices y comparación de planes de ejecución
- [ ] Job con SQL Server Agent
- [ ] Tablero en Metabase (opcional)

## Cómo ejecutarlo

1. Clona el repositorio.
2. Copia `.env.example` como `.env` y escribe tu propia clave.
3. Levanta SQL Server con Docker (instrucciones completas próximamente).
4. Ejecuta los scripts de la carpeta `sql/` en orden numérico.

## Estructura del repositorio

- `data/`: generador de datos sintéticos
- `sql/`: scripts numerados en orden de ejecución
- `docs/`: diagramas y capturas

## Autora

Diana Gil, estudiante de Ingeniería de Software (UNIMINUTO), orientada a datos.
