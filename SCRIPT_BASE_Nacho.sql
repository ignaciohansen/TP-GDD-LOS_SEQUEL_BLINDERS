USE [GD1C2020]
GO

DECLARE @vEsquema VARCHAR(30)
SET @vEsquema = 'LOS_SEQUEL_BLINDERS'

if not exists (select * from sys.schemas where name = @vEsquema)
begin
	exec ('CREATE SCHEMA '+@vEsquema)
	print 'Esquema creado!'
end
else
begin
	-- BORRO TODO LO QUE HAYA EN EL ESQUEMA
	DECLARE @Sql VARCHAR(MAX)
		  , @Schema varchar(20)

	SET @Schema = 'LOS_SEQUEL_BLINDERS'

	--tables
	SELECT @Sql = COALESCE(@Sql,'') + 'DROP TABLE %SCHEMA%.' + TABLE_NAME + ';' + CHAR(13)
	FROM INFORMATION_SCHEMA.TABLES
	WHERE TABLE_SCHEMA = @Schema
		AND TABLE_TYPE = 'BASE TABLE'
	ORDER BY TABLE_NAME

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
	exec sp_sqlexec @Sql
end
go


-- CREO TABLAS

CREATE TABLE LOS_SEQUEL_BLINDERS.EMPRESA(
	EMPRESA_ID int PRIMARY KEY IDENTITY,
	EMPRESA_RAZON_SOCIAL NVARCHAR(255) NOT NULL
)

CREATE TABLE LOS_SEQUEL_BLINDERS.COMPRA(
	COMPRA_NRO decimal(18, 0) PRIMARY KEY,
	EMPRESA_ID int FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.EMPRESA(EMPRESA_ID),
	COMPRA_FECHA datetime2(3) NOT NULL
)

CREATE TABLE LOS_SEQUEL_BLINDERS.CLIENTE(
	
	[CLIENTE_ID] int PRIMARY KEY IDENTITY,
	[CLIENTE_APELLIDO] [nvarchar](255) NOT NULL,
	[CLIENTE_NOMBRE] [nvarchar](255) NOT NULL,
	[CLIENTE_DNI] [decimal](18, 0) NOT NULL,
	[CLIENTE_FECHA_NAC] [datetime2](3) NOT NULL,
	[CLIENTE_MAIL] [nvarchar](255) NOT NULL,
	[CLIENTE_TELEFONO] [int] NOT NULL,
)

CREATE TABLE LOS_SEQUEL_BLINDERS.SUCURSAL(
	
	[SUCURSAL_ID] int PRIMARY KEY IDENTITY,
	[SUCURSAL_DIR] [nvarchar](255) NOT NULL,
	[SUCURSAL_MAIL] [nvarchar](255) NOT NULL,
	[SUCURSAL_TELEFONO] [decimal](18, 0) NOT NULL
)

CREATE TABLE LOS_SEQUEL_BLINDERS.FACTURA(
	
	[FACTURA_NRO] [decimal](18, 0) PRIMARY KEY,
	[FACTURA_FECHA] [datetime2](3) NOT NULL,
	[SUCURSAL_ID] int FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.SUCURSAL(SUCURSAL_ID),
	[CLIENTE_ID] int FOREIGN KEY REFERENCES LOS_SEQUEL_BLINDERS.CLIENTE(CLIENTE_ID),
)




-- CARGO REGISTROS

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

-- CLIENTES
INSERT INTO LOS_SEQUEL_BLINDERS.CLIENTE
SELECT DISTINCT
	CLIENTE_APELLIDO,
	CLIENTE_NOMBRE,
	CLIENTE_DNI,
	CLIENTE_FECHA_NAC,
	CLIENTE_MAIL,
	CLIENTE_TELEFONO
FROM gd_esquema.Maestra
WHERE CLIENTE_NOMBRE is not null and CLIENTE_APELLIDO is not null;


-- SUCURSALES
INSERT INTO LOS_SEQUEL_BLINDERS.SUCURSAL
SELECT DISTINCT
	SUCURSAL_DIR,
	SUCURSAL_MAIL,
	SUCURSAL_TELEFONO
FROM gd_esquema.Maestra
WHERE SUCURSAL_DIR is not null;

-- FACTURAS
INSERT INTO LOS_SEQUEL_BLINDERS.FACTURA
SELECT DISTINCT
	M.FACTURA_NRO,
	M.FACTURA_FECHA,
	S.SUCURSAL_ID,
	C.CLIENTE_ID
FROM gd_esquema.Maestra M 
join LOS_SEQUEL_BLINDERS.SUCURSAL S on M.SUCURSAL_DIR = S.SUCURSAL_DIR AND M.SUCURSAL_MAIL = S.SUCURSAL_MAIL
join LOS_SEQUEL_BLINDERS.CLIENTE C on M.CLIENTE_APELLIDO = C.CLIENTE_APELLIDO AND M.CLIENTE_NOMBRE = C.CLIENTE_NOMBRE AND M.CLIENTE_DNI = C.CLIENTE_DNI
WHERE M.FACTURA_NRO is not null;





---  CHEQUEOS -----

--CLIENTES: 82 con mail aaron.. en maestra , 82 tmb en sequel papa
SELECT
	CLIENTE_APELLIDO,
	CLIENTE_NOMBRE,
	CLIENTE_DNI,
	CLIENTE_FECHA_NAC,
	CLIENTE_MAIL,
	CLIENTE_TELEFONO
FROM gd_esquema.Maestra
WHERE CLIENTE_APELLIDO IS NOT NULL AND CLIENTE_MAIL = 'aaron@gmail.com' ORDER BY CLIENTE_MAIL


select * from LOS_SEQUEL_BLINDERS.CLIENTE WHERE CLIENTE_MAIL = 'aaron@gmail.com' ORDER BY CLIENTE_MAIL

--SUCURSAL:
SELECT DISTINCT
	SUCURSAL_DIR,
	SUCURSAL_MAIL,
	SUCURSAL_TELEFONO
FROM gd_esquema.Maestra WHERE SUCURSAL_DIR IS NOT NULL


select * from LOS_SEQUEL_BLINDERS.SUCURSAL

--FACTURAS:

SELECT DISTINCT
	FACTURA_NRO,
	FACTURA_FECHA,
	SUCURSAL_MAIL,
	CLIENTE_NOMBRE
FROM gd_esquema.Maestra M WHERE FACTURA_NRO IS NOT NULL
ORDER BY FACTURA_NRO
--EXCEPT -- La resta entre los 2 da vacio
select factura_nro,factura_fecha,sucursal_mail,cliente_nombre from LOS_SEQUEL_BLINDERS.FACTURA F
join LOS_SEQUEL_BLINDERS.CLIENTE C on F.CLIENTE_ID = C.CLIENTE_ID 
join LOS_SEQUEL_BLINDERS.SUCURSAL S on F.SUCURSAL_ID = S.SUCURSAL_ID
ORDER BY FACTURA_NRO


---  CHEQUEOS -----