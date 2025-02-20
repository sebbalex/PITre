-- =============================================
-- Author:		FRANCESCO FONZO
-- Create date: 05/03/2013
-- Description:	CONVERSIONE DA ORACLE A SQL SERVER
-- HASROLEMACRO
-- =============================================

CREATE FUNCTION [DOCSADM].[HASROLEMACRO]
(
	@ROLE_ID	INT
	, @CODICE	VARCHAR(128)
)
RETURNS VARCHAR(128)
AS
BEGIN
	DECLARE @OUTVALUE	VARCHAR(128)
	DECLARE @NUM		INT
	
	SELECT @NUM = COUNT('X') 
	FROM DOCSADM.DPA_CORR_GLOBALI AS CG_RUOLO
		RIGHT OUTER JOIN DOCSADM.DPA_TIPO_F_RUOLO AS TRF ON TRF.ID_RUOLO_IN_UO = CG_RUOLO.SYSTEM_ID
		RIGHT OUTER JOIN DOCSADM.DPA_TIPO_FUNZIONE AS TF ON TRF.ID_TIPO_FUNZ = TF.SYSTEM_ID
	WHERE CG_RUOLO.SYSTEM_ID = @ROLE_ID
		AND TF.VAR_COD_TIPO = @CODICE
		
	IF @NUM > 0
		SET @OUTVALUE = 'SI'
	ELSE
		SET @OUTVALUE = 'NO'
		
	RETURN @OUTVALUE

END 

