-- =============================================
-- Author:		FRANCESCO FONZO
-- Create date: 22/02/2013
-- Description:	CONVERSIONE DA ORACLE A SQL SERVER
-- CHECKPROFILEDATA
-- =============================================
   
   
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DOCSADM].[CHECKPROFILEDATA]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [DOCSADM].[CHECKPROFILEDATA]
GO

CREATE FUNCTION [DOCSADM].[CHECKPROFILEDATA]
(
	@numProto	INT,
	@dataProt	DATETIME
)
RETURNS INT
AS

BEGIN
 
	DECLARE @tmpVar		INT
	DECLARE @minProto	INT
	DECLARE @maxProto	INT
	
	SET @tmpVar = 0
	SET @minProto = 0
	SET @maxProto = 0

	SELECT @minProto = A.MINIMO, @maxProto = B.MASSIMO
	FROM (SELECT ISNULL(MAX(ID_VECCHIO_DOCUMENTO),0) AS MINIMO FROM DOCSADM.PROFILE WHERE CONVERT(VARCHAR(12),CREATION_DATE, 110) < CONVERT(VARCHAR(12),CREATION_DATE, 110)) AS A,
		(SELECT ISNULL(MIN(ID_VECCHIO_DOCUMENTO),999999999) AS MASSIMO FROM DOCSADM.PROFILE WHERE CONVERT(VARCHAR(12),CREATION_DATE, 110) > CONVERT(VARCHAR(12),CREATION_DATE, 110)) AS B

	
	IF (@numProto < @minProto OR @numProto > @maxProto)
		SET @tmpVar = @numProto
	ELSE
		SET @tmpVar = 0
		
		
	RETURN @tmpVar
	
END
GO
