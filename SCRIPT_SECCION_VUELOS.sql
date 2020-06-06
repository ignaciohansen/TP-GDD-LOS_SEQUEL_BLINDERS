USE [GD1C2020]
GO


-- CREO TABLAS

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


-- CARGO REGISTROS

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


-- VALIDACIONES
DECLARE @FILAS_ESPERADAS INT, @FILAS_REALES INT;

-- Cantidad de aviones
SELECT
	@FILAS_ESPERADAS = COUNT(*)
FROM(
	SELECT DISTINCT
		AVION_IDENTIFICADOR
	FROM gd_esquema.Maestra
	WHERE AVION_IDENTIFICADOR IS NOT NULL) T

SELECT
	@FILAS_REALES = COUNT(*)
FROM(
	SELECT
		AVION_IDENTIFICADOR
	FROM LOS_SEQUEL_BLINDERS.AVION) T

IF @FILAS_REALES = @FILAS_REALES
	PRINT 'ok!'
ELSE
	PRINT 'error!'

-- Cantidad de rutas
SELECT
	@FILAS_ESPERADAS = COUNT(*)
FROM(
	SELECT DISTINCT
		RUTA_AEREA_CODIGO,
		RUTA_AEREA_CIU_DEST,
		RUTA_AEREA_CIU_ORIG
	FROM gd_esquema.Maestra
	WHERE RUTA_AEREA_CODIGO IS NOT NULL) T

SELECT
	@FILAS_REALES = COUNT(*)
FROM(
	SELECT
		RUTA_ID
	FROM LOS_SEQUEL_BLINDERS.RUTA) T

IF @FILAS_REALES = @FILAS_REALES
	PRINT 'ok!'
ELSE
	PRINT 'error!'


-- Cantidad de vuelos por avion
SELECT
	AVION_IDENTIFICADOR,
	COUNT(VUELO_CODIGO)	AS CANT_VUELOS
FROM (SELECT DISTINCT AVION_IDENTIFICADOR, VUELO_CODIGO FROM gd_esquema.Maestra WHERE AVION_IDENTIFICADOR IS NOT NULL) T
GROUP BY AVION_IDENTIFICADOR
EXCEPT
SELECT
	AVION_IDENTIFICADOR,
	(SELECT COUNT(*)
	FROM LOS_SEQUEL_BLINDERS.VUELO 
	WHERE AVION_IDENTIFICADOR = A.AVION_IDENTIFICADOR)	AS CANT_VUELOS
FROM LOS_SEQUEL_BLINDERS.AVION A
ORDER BY 2 DESC;

if @@ROWCOUNT = 0
	PRINT 'ok!'
ELSE
	PRINT 'error!'