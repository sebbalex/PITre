USE [PCM_DEPOSITO_1]
GO
/****** Object:  UserDefinedFunction [DOCSADM].[checkSecurity]    Script Date: 04/11/2013 15:54:17 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [DOCSADM].[fn_ARCHIVE_getNomeSchemaCorrente]
(
)
RETURNS VARCHAR(200)
AS

BEGIN

	DECLARE @retValue VARCHAR(200)

	SET @retValue = ''

	SELECT @retValue=[VALUE] FROM [DOCSADM].ARCHIVE_CONFIGURATION
	WHERE [KEY] = 'NOME_SCHEMA_CORRENTE'

	RETURN @retValue
	
END
