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

exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'PASAJE';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'BUTACA';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'BUTACA_TIPO';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'VUELO';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'RUTA';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'CIUDAD';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'AVION'
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'COMPRA';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'EMPRESA';
exec LOS_SEQUEL_BLINDERS.sp_borrar_tabla 'BUTACA';

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

CREATE TABLE LOS_SEQUEL_BLINDERS.AVION(
	AVION_IDENTIFICADOR NVARCHAR(50) PRIMARY KEY,
	AVION_MODELO NVARCHAR(50)
)

CREATE TABLE LOS_SEQUEL_BLINDERS.CIUDAD(
	CIUDAD_ID INT PRIMARY KEY IDENTITY,
	CIUDAD_NOMBRE NVARCHAR(255) NOT NULL
)

CREATE TABLE LOS_SEQUEL_BLINDERS.RUTA(
	RUTA_ID INT PRIMARY KEY IDENTITY,
	RUTA_AEREA_CODIGO DECIMAL(18,0) NOT NULL,
	CIU_ORIG_ID INT FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.CIUDAD(CIUDAD_ID),
	CIU_DEST_ID INT FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.CIUDAD(CIUDAD_ID)
)

CREATE TABLE LOS_SEQUEL_BLINDERS.VUELO(
	VUELO_CODIGO DECIMAL(19,0) PRIMARY KEY,
	VUELO_FECHA_SALIDA DATETIME2(3),
	VUELO_FECHA_LLEGADA DATETIME2(3),
	RUTA_ID INT FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.RUTA(RUTA_ID),
	AVION_IDENTIFICADOR NVARCHAR(50) FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.AVION(AVION_IDENTIFICADOR)
)



CREATE TABLE LOS_SEQUEL_BLINDERS.BUTACA_TIPO(
	BUTACA_TIPO_ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	BUTACA_TIPO_DESC NVARCHAR(255) NOT NULL
)


CREATE TABLE LOS_SEQUEL_BLINDERS.BUTACA(
	BUTACA_ID INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
	BUTACA_NRO DECIMAL(18,0) NOT NULL,
	BUTACA_TIPO_ID INT FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.BUTACA_TIPO(BUTACA_TIPO_ID)
)

CREATE TABLE LOS_SEQUEL_BLINDERS.PASAJE(
	PASAJE_CODIGO DECIMAL(18,0) PRIMARY KEY NOT NULL,
	PASAJE_COSTO DECIMAL(18,2) NOT NULL,
	PASAJE_PRECIO DECIMAL(18,2) NOT NULL,
	BUTACA_ID INT FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.BUTACA(BUTACA_ID),
	VUELO_CODIGO DECIMAL(19,0) FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.VUELO(VUELO_CODIGO)
)



/* -------------------------------------------------------------------------------------------------
 * Cargamos los datos en las tablas
 * -------------------------------------------------------------------------------------------------
 */
 
-- AVIONES
INSERT INTO LOS_SEQUEL_BLINDERS.AVION
SELECT DISTINCT
	AVION_IDENTIFICADOR,
	AVION_MODELO
FROM gd_esquema.Maestra
WHERE AVION_IDENTIFICADOR IS NOT NULL;

-- CIUDADES
INSERT INTO LOS_SEQUEL_BLINDERS.CIUDAD
SELECT DISTINCT
	RUTA_AEREA_CIU_DEST
FROM gd_esquema.Maestra
WHERE RUTA_AEREA_CIU_DEST IS NOT NULL
UNION
SELECT DISTINCT
	RUTA_AEREA_CIU_ORIG
FROM gd_esquema.Maestra
WHERE RUTA_AEREA_CIU_ORIG IS NOT NULL

-- RUTAS
INSERT INTO LOS_SEQUEL_BLINDERS.RUTA
SELECT DISTINCT
	M.RUTA_AEREA_CODIGO			AS RUTA_AEREA_CODIGO,
	CO.CIUDAD_ID				AS CIU_ORIG_ID,
	CD.CIUDAD_ID				AS CIU_DEST_ID
FROM gd_esquema.Maestra M 
LEFT JOIN LOS_SEQUEL_BLINDERS.CIUDAD CO
	ON M.RUTA_AEREA_CIU_ORIG = CO.CIUDAD_NOMBRE
LEFT JOIN LOS_SEQUEL_BLINDERS.CIUDAD CD
	ON M.RUTA_AEREA_CIU_DEST = CD.CIUDAD_NOMBRE
WHERE RUTA_AEREA_CODIGO IS NOT NULL;

-- VUELOS
INSERT INTO LOS_SEQUEL_BLINDERS.VUELO
SELECT DISTINCT
	VUELO_CODIGO,
	VUELO_FECHA_SALUDA,
	VUELO_FECHA_LLEGADA,
	R.RUTA_ID,
	AVION_IDENTIFICADOR
FROM gd_esquema.Maestra M
LEFT JOIN LOS_SEQUEL_BLINDERS.CIUDAD CD
ON	M.RUTA_AEREA_CIU_DEST = CD.CIUDAD_NOMBRE
LEFT JOIN LOS_SEQUEL_BLINDERS.CIUDAD CO
ON	M.RUTA_AEREA_CIU_ORIG = CO.CIUDAD_NOMBRE
LEFT JOIN LOS_SEQUEL_BLINDERS.RUTA R
ON  M.RUTA_AEREA_CODIGO = R.RUTA_AEREA_CODIGO
AND R.CIU_DEST_ID = CD.CIUDAD_ID
AND R.CIU_ORIG_ID = CO.CIUDAD_ID
WHERE VUELO_CODIGO IS NOT NULL

-- EMPRESAS
INSERT INTO LOS_SEQUEL_BLINDERS.EMPRESA 
SELECT DISTINCT
	EMPRESA_RAZON_SOCIAL
FROM gd_esquema.Maestra
WHERE EMPRESA_RAZON_SOCIAL IS NOT NULL;

-- COMPRAS
INSERT INTO LOS_SEQUEL_BLINDERS.COMPRA
SELECT DISTINCT
	COMPRA_NUMERO,
	E.EMPRESA_ID,
	COMPRA_FECHA
FROM gd_esquema.Maestra M 
LEFT JOIN LOS_SEQUEL_BLINDERS.EMPRESA E ON
	 M.EMPRESA_RAZON_SOCIAL = E.EMPRESA_RAZON_SOCIAL
WHERE COMPRA_NUMERO IS NOT NULL;

--BUTACA_TIPO
INSERT INTO LOS_SEQUEL_BLINDERS.BUTACA_TIPO
SELECT DISTINCT
	M.BUTACA_TIPO
FROM gd_esquema.Maestra M
WHERE BUTACA_NUMERO IS NOT NULL
ORDER BY 1

--BUTACA
INSERT INTO LOS_SEQUEL_BLINDERS.BUTACA
SELECT DISTINCT
	BUTACA_NUMERO			AS BUTACA_NRO,
	B.BUTACA_TIPO_ID		AS BUTACA_TIPO_ID
FROM gd_esquema.Maestra M 
LEFT JOIN LOS_SEQUEL_BLINDERS.BUTACA_TIPO B
ON M.BUTACA_TIPO = B.BUTACA_TIPO_DESC
WHERE BUTACA_NUMERO IS NOT NULL
ORDER BY 1

-- PASAJE
INSERT INTO LOS_SEQUEL_BLINDERS.PASAJE
SELECT DISTINCT 
	M.PASAJE_CODIGO,
	M.PASAJE_COSTO,			
	M.PASAJE_PRECIO,			
	B.BUTACA_ID AS BUTACA_ID,				
	V.VUELO_CODIGO			
FROM gd_esquema.Maestra M
LEFT JOIN LOS_SEQUEL_BLINDERS.BUTACA_TIPO BT
ON M.BUTACA_TIPO = BT.BUTACA_TIPO_DESC
LEFT JOIN LOS_SEQUEL_BLINDERS.BUTACA B 
ON M.BUTACA_NUMERO = B.BUTACA_NRO
AND B.BUTACA_TIPO_ID = BT.BUTACA_TIPO_ID
LEFT JOIN LOS_SEQUEL_BLINDERS.VUELO V 
ON M.AVION_IDENTIFICADOR = V.AVION_IDENTIFICADOR
AND M.VUELO_CODIGO = V.VUELO_CODIGO
WHERE  PASAJE_CODIGO IS NOT NULL
ORDER BY 1
