# Mesa de Ayuda de TI: almacén de datos en SQL Server

Proyecto personal de ingeniería de datos que construye un almacén de datos (modelo estrella) a partir de datos sintéticos de tickets de una mesa de ayuda de TI. Incluye ETL con procedimientos almacenados en T-SQL, validación de calidad de datos, vistas de reporte, reportes con PIVOT, índices y un job automático.

## Objetivo

Practicar y demostrar el flujo completo de un proyecto de datos: datos crudos, limpieza y validación, modelado, carga repetible, reportes y automatización. Se inspira en mi experiencia administrando una mesa de servicio en GLPI.

## Tecnologías

- SQL Server 2022 (Docker)
- T-SQL: procedimientos almacenados, vistas, PIVOT, índices
- SQL Server Agent (job de carga)
- Python (generación de datos sintéticos)
- Metabase 
- Git y GitHub

## Estado del proyecto

- [x] Entorno: SQL Server en Docker y conexión desde VS Code
- [x] Generación de datos sintéticos con Python (con errores de calidad intencionales)
- [x] Carga a staging con BULK INSERT
- [x] Modelo estrella (hechos y dimensiones)
- [ ] Procedimiento almacenado de carga (idempotente, con rechazados y bitácora)
- [ ] Vistas de reporte
- [ ] Reporte con PIVOT
- [ ] Índices y comparación de planes de ejecución
- [ ] Job con SQL Server Agent
- [ ] Tablero en Metabase (opcional)

## Cómo ejecutarlo

1. Clona el repositorio y copia `.env.example` como `.env`, con tu propia clave.
2. Levanta SQL Server con Docker (una sola línea):

```
docker run -e 'ACCEPT_EULA=Y' -e 'MSSQL_SA_PASSWORD=<TU_CLAVE>' -e 'MSSQL_PID=Developer' -e 'MSSQL_AGENT_ENABLED=true' -p 1433:1433 -v sqldata:/var/opt/mssql --name sqlserver -d mcr.microsoft.com/mssql/server:2022-latest
```

3. Genera los datos de ejemplo: `python data/generar_tickets.py`
4. Copia el CSV al contenedor:

```
docker cp data\tickets.csv sqlserver:/var/opt/mssql/data/tickets.csv
```

5. Conéctate con la extensión SQL Server (mssql) de VS Code (servidor `localhost`, puerto 1433, usuario `sa`) y ejecuta en orden los scripts de `sql/`: `01`, `02`, `03` y `05`. El `04` sirve para verificar la carga.

Si Docker se reinicia y el contenedor desaparece, repite los pasos 2 a 5.

## Calidad de datos

El generador introduce errores a propósito en cerca del 3 % de los tickets, para que el proceso de limpieza tenga qué detectar:

- Fecha de apertura inválida (`31/02/2026`)
- Fecha de cierre anterior a la apertura
- Categoría inexistente en el catálogo
- Usuario vacío
- `ticket_id` duplicado

Los tickets con estos errores serán enviados a una tabla de rechazados, con el motivo, durante la carga al modelo.

## Estructura del repositorio

- `data/`: generador de datos sintéticos
- `sql/`: scripts numerados en orden de ejecución
- `docs/`: diagramas y capturas

## Problemas encontrados

- **`CODEPAGE` no soportado en Linux:** `BULK INSERT` en SQL Server para Linux rechaza esa opción. La quité, porque los datos no tienen caracteres especiales.
- **Retorno de carro pegado a la última columna:** el CSV generado en Windows termina las filas en `\r\n`, y la carga dejaba un `\r` invisible en `reabierto`. Lo detecté porque `LEN(reabierto)` daba 2 en vez de 1, y lo resolví con `ROWTERMINATOR = '0x0d0a'`.
- **Contenedor de Docker desaparecido:** al reiniciar Docker Desktop, el contenedor se borró. Por eso el proyecto se puede reconstruir completo con los scripts numerados.

## Autora

Diana Gil, estudiante de Ingeniería de Software (UNIMINUTO), orientada a datos.