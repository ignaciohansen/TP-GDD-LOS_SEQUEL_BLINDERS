USE [GD1C2020]
GO

/* -------------------------------------------------------------------------------------------------
 * Chequeamos si existe el esquema.
 *   Si no existe, lo creamos.
 *   Si existe, lo limpiamos.
 * -------------------------------------------------------------------------------------------------
 */

DECLARE @Schema VARCHAR(30) = 'LOS_SEQUEL_BLINDERS_BI'
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

CREATE PROCEDURE LOS_SEQUEL_BLINDERS_BI.sp_borrar_tabla (@tabla VARCHAR(30)) AS
BEGIN
	DECLARE @SqlDel VARCHAR(MAX), @esquema VARCHAR(30) = 'LOS_SEQUEL_BLINDERS_BI'
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
		print @SqlDel
	END
END
GO

/* -------------------------------------------------------------------------------------------------
 * Borramos las tablas en el orden correcto para no tener problemas con las FK
 * -------------------------------------------------------------------------------------------------
 */
exec LOS_SEQUEL_BLINDERS_BI.sp_borrar_tabla 'COMPRA';
exec LOS_SEQUEL_BLINDERS_BI.sp_borrar_tabla 'VENTA';

CREATE TABLE LOS_SEQUEL_BLINDERS_BI.COMPRA(
	PROVEEDOR_ID INT,
	RUTA_ID INT,
	A�O_MES_ID INT,
	TIPO_HABITACION_COD INT,
	AVION_IDENTIFICADOR INT,
	BUTACA_TIPO INT,
	TRANSACCION_PRODUCTO INT,
	MONTO DECIMAL(18,2),
	CANTIDAD_COMPRAS INT,
	CANTIDAD_CAMAS INT
 )

CREATE TABLE LOS_SEQUEL_BLINDERS_BI.VENTA(
	CLIENTE_ID INT,
	RUTA_ID INT,
	A�O_MES_ID CHAR(6),
	TIPO_HABITACION_COD INT,
	AVION_IDENTIFICADOR INT,
	BUTACA_TIPO INT,
	SUCURSAL_ID INT,
	TRANSACCION_PRODUCTO INT,
	MONTO DECIMAL(18,2),
	CANTIDAD_COMPRAS INT,
	CANTIDAD_CAMAS INT,
	MONTO_GANANCIAS DECIMAL(18,2)
)

-- INSERT COMPRAS
INSERT INTO LOS_SEQUEL_BLINDERS_BI.COMPRA
SELECT
	CO.EMPRESA_ID																	AS PROVEEDOR_ID,
	VU.RUTA_ID																		AS RUTA_ID,
	YEAR(CO.COMPRA_FECHA) + FORMAT(MONTH(CO.COMPRA_FECHA),'00')						AS A�O_MES_ID,
	HA.TIPO_HABITACION_CODIGO														AS TIPO_HABITACION_COD,
	VU.AVION_IDENTIFICADOR															AS AVION_IDENTIFICADOR,
	BU.BUTACA_TIPO_ID																AS BUTACA_TIPO,
	1	AS TRANSACCION_PRODUCTO,
	SUM(ES.ESTADIA_COSTO)+SUM(PA.PASAJE_COSTO)										AS MONTO,
	COUNT(DISTINCT CO.COMPRA_NRO)													AS CANTIDAD_COMPRAS,
	1																				AS CANTIDAD_CAMAS
FROM LOS_SEQUEL_BLINDERS.OPERACION_X_PRODUCTO OXP
JOIN LOS_SEQUEL_BLINDERS.COMPRA CO ON CO.COMPRA_NRO = OXP.COMPRA_NRO
LEFT JOIN LOS_SEQUEL_BLINDERS.ESTADIA ES ON ES.ESTADIA_CODIGO = OXP.ESTADIA_CODIGO
LEFT JOIN LOS_SEQUEL_BLINDERS.PASAJE PA ON PA.PASAJE_CODIGO = OXP.PASAJE_CODIGO
LEFT JOIN LOS_SEQUEL_BLINDERS.VUELO VU ON VU.VUELO_CODIGO = PA.VUELO_CODIGO
LEFT JOIN LOS_SEQUEL_BLINDERS.HABITACION HA ON HA.HABITACION_ID = ES.HABITACION_ID
LEFT JOIN LOS_SEQUEL_BLINDERS.BUTACA BU ON BU.BUTACA_ID = PA.BUTACA_ID
LEFT JOIN LOS_SEQUEL_BLINDERS.TIPO_HABITACION TH ON TH.TIPO_HABITACION_CODIGO = HA.TIPO_HABITACION_CODIGO
GROUP BY EMPRESA_ID, RUTA_ID, HA.TIPO_HABITACION_CODIGO, VU.AVION_IDENTIFICADOR, BU.BUTACA_TIPO_ID, YEAR(CO.COMPRA_FECHA),MONTH(CO.COMPRA_FECHA)

-- INSERT VENTAS