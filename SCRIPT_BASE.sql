USE [GD1C2020]
GO

/* -------------------------------------------------------------------------------------------------
 * Chequeamos si existe el esquema.
 *   Si no existe, lo creamos.
 *   Si existe, lo limpiamos.
 * -------------------------------------------------------------------------------------------------
 */

DECLARE @Schema VARCHAR(30) = 'LOS_SEQUEL_BLINDERS'
IF NOT EXISTS (select * from sys.schemas where name = @Schema)
BEGIN
	EXEC ('CREATE SCHEMA ' + @Schema)
	PRINT 'Esquema creado!'
END
ELSE
BEGIN
	-- BORRO TODO LO QUE HAYA EN EL ESQUEMA
	DECLARE @Sql VARCHAR(MAX);

	--views
	SELECT @Sql = COALESCE(@Sql,'') + 'DROP VIEW %SCHEMA%.' + QUOTENAME(TABLE_NAME) + ';' + CHAR(13)
	FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_SCHEMA = @Schema
		AND TABLE_TYPE = 'VIEW'
	ORDER BY TABLE_NAME

	--Procedures
	SELECT @Sql = COALESCE(@Sql,'') + 'DROP PROCEDURE %SCHEMA%.' + QUOTENAME(ROUTINE_NAME) + ';' + CHAR(13)
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_SCHEMA = @Schema
		AND ROUTINE_TYPE = 'PROCEDURE'
	ORDER BY ROUTINE_NAME

	--Functions
	SELECT @Sql = COALESCE(@Sql,'') + 'DROP FUNCTION %SCHEMA%.' + QUOTENAME(ROUTINE_NAME) + ';' + CHAR(13)
	FROM INFORMATION_SCHEMA.ROUTINES
	WHERE ROUTINE_SCHEMA = @Schema
		AND ROUTINE_TYPE = 'FUNCTION'
	ORDER BY ROUTINE_NAME

	SELECT @Sql = COALESCE(REPLACE(@Sql,'%SCHEMA%',@Schema), '')
	EXEC sp_sqlexec @Sql
END
GO


/* -------------------------------------------------------------------------------------------------
 * Creamos los store procedures
 * -------------------------------------------------------------------------------------------------
 */

CREATE PROCEDURE LOS_SEQUEL_BLINDERS.sp_borrar_tabla (@tabla VARCHAR(30)) AS
BEGIN
	DECLARE @SqlDel VARCHAR(MAX), @esquema VARCHAR(30) = 'LOS_SEQUEL_BLINDERS'
	IF ( EXISTS(
		SELECT 
			TABLE_NAME
		FROM INFORMATION_SCHEMA.TABLES
		WHERE TABLE_NAME = @tabla
		AND	  TABLE_SCHEMA = @esquema)
	)
	BEGIN
		SET @SqlDel = 'DROP TABLE ['+ @esquema +'].' + QUOTENAME(@tabla) + ';'
		EXEC sp_sqlexec @SqlDel
	END
END
GO

/* -------------------------------------------------------------------------------------------------
 * Borramos las tablas en el orden correcto para no tener problemas con las FK
 * -------------------------------------------------------------------------------------------------
 */

exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'VUELO';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'RUTA';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'CIUDAD';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'AVION'
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'COMPRA';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'EMPRESA';

/* -------------------------------------------------------------------------------------------------
 * Creamos las tablas
 * -------------------------------------------------------------------------------------------------
 */

CREATE TABLE LOS_SEQUEL_BLINDERS.EMPRESA(
	EMPRESA_ID int PRIMARY KEY IDENTITY,
	EMPRESA_RAZON_SOCIAL NVARCHAR(255) NOT NULL
)

CREATE TABLE LOS_SEQUEL_BLINDERS.COMPRA(
	COMPRA_NRO decimal(18, 0) PRIMARY KEY,
	EMPRESA_ID int FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.EMPRESA(EMPRESA_ID),
	COMPRA_FECHA datetime2(3) NOT NULL
)


/* -------------------------------------------------------------------------------------------------
 * Cargamos los datos en las tablas
 * -------------------------------------------------------------------------------------------------
 */

-- EMPRESAS
INSERT INTO LOS_SEQUEL_BLINDERS.EMPRESA 
SELECT DISTINCT
	EMPRESA_RAZON_SOCIAL
FROM gd_esquema.Maestra
WHERE EMPRESA_RAZON_SOCIAL is not null;

-- COMPRAS
INSERT INTO LOS_SEQUEL_BLINDERS.COMPRA
SELECT DISTINCT
	COMPRA_NUMERO,
	E.EMPRESA_ID,
	COMPRA_FECHA
FROM gd_esquema.Maestra M 
LEFT JOIN LOS_SEQUEL_BLINDERS.EMPRESA E on
	 M.EMPRESA_RAZON_SOCIAL = E.EMPRESA_RAZON_SOCIAL
WHERE COMPRA_NUMERO is not null;
