USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_BE_GetProjectsByTransferPolicyList]    Script Date: 07/04/2013 16:37:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================
-- Author:		Giovanni Olivari
-- Create date: 29/04/2013
-- Description:	Restituisce la lista dei fascicoli aggregati
-- =========================================================
ALTER PROCEDURE [DOCSADM].[sp_ARCHIVE_BE_GetProjectsByDisposalID]
(	
	@disposalID INT
)
AS
BEGIN

	DECLARE @sql_string nvarchar(MAX)
	DECLARE @countDistinct int = 0

	-- Conteggio DISTINCT dei fascicoli
	--
	SELECT @countDistinct = COUNT(DISTINCT Project_ID) 
	FROM ARCHIVE_TEMPPROJECTDISPOSAL F 
	WHERE F.DISPOSAL_ID = @disposalID

	PRINT @countDistinct



	SET @sql_string = CAST(N'
		SELECT REGISTRO, TITOLARIO, CLASSETITOLARIO, TIPOLOGIA, ANNO_CHIUSURA
		, COUNT(*) TOTALE, ' AS NVARCHAR(MAX)) + CAST(@countDistinct AS NVARCHAR(MAX)) + CAST(' COUNTDISTINCT
		FROM
		(
		SELECT 
			R.VAR_CODICE REGISTRO
			, CASE TIT.CHA_STATO
				WHEN ''A'' THEN ''Titolario attivo''
				WHEN ''C'' THEN ''Titolario in vigore dal '' + CONVERT(VARCHAR(10), tit.DTA_ATTIVAZIONE, 103) + '' al '' + CONVERT(VARCHAR(10), tit.DTA_CESSAZIONE, 103)
				WHEN ''D'' THEN ''Titolario in definizione''
				ELSE ''Stato titolario sconosciuto''
			END TITOLARIO
			, CT.VAR_CODICE CLASSETITOLARIO
			, TF.VAR_DESC_FASC TIPOLOGIA
			, YEAR(P.DTA_CHIUSURA) ANNO_CHIUSURA
		FROM ARCHIVE_TEMPPROJECTDISPOSAL TP INNER JOIN PROJECT P ON TP.PROJECT_ID = P.SYSTEM_ID
		LEFT OUTER JOIN PROJECT CT ON P.ID_PARENT = CT.SYSTEM_ID
		LEFT OUTER JOIN PROJECT TIT ON P.ID_TITOLARIO = TIT.SYSTEM_ID
		LEFT OUTER JOIN DPA_TIPO_FASC TF ON P.ID_TIPO_FASC = TF.SYSTEM_ID
		LEFT OUTER JOIN DPA_EL_REGISTRI R ON P.ID_REGISTRO = R.SYSTEM_ID
		WHERE TP.DISPOSAL_ID = ' AS NVARCHAR(MAX)) + CAST(@disposalID AS NVARCHAR(MAX)) + CAST('
		AND TP.DASCARTARE = 1
		) T1
		GROUP BY REGISTRO, TITOLARIO, CLASSETITOLARIO, TIPOLOGIA, ANNO_CHIUSURA'AS NVARCHAR(MAX))

	PRINT @sql_string

	EXECUTE sp_executesql @sql_string;

END