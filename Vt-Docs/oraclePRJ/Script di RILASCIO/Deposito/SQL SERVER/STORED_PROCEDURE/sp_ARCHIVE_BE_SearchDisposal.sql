USE [PCM_DEPOSITO_FINGER]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================
-- Author:		Giovanni Olivari
-- Create date: 31/05/2013
-- Description:	Ricerca degli scarti con filtro sugli stati
-- ==========================================================
ALTER PROCEDURE [DOCSADM].[sp_ARCHIVE_BE_SearchDisposal] 
	@filtro_InDefinizione VARCHAR(1000),
	@filtro_RicercaCompletata VARCHAR(1000),
	@filtro_Proposto VARCHAR(1000),
	@filtro_Approvato VARCHAR(1000),
	@filtro_InEsecuzione VARCHAR(1000),
	@filtro_Effettuato VARCHAR(1000),
	@filtro_InErrore VARCHAR(1000),
	@tipoStatoEsecuzione INT -- 1 -> ESEGUITO; 2 -> ERRORE; 3 -> TUTTI
AS
BEGIN

	-- Log test
	--
	DECLARE @log VARCHAR(2000)
	DECLARE @logType VARCHAR(10)
	DECLARE @logObject VARCHAR(50) = OBJECT_NAME(@@PROCID)

	set @logType = 'INFO'
	
	set @log = '@filtro_InDefinizione: ' + CAST(ISNULL(@filtro_InDefinizione, 'NULL') AS NVARCHAR(MAX))
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

	set @log = '@filtro_RicercaCompletata: ' + CAST(ISNULL(@filtro_RicercaCompletata, 'NULL') AS NVARCHAR(MAX))
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

	set @log = '@filtro_Proposto: ' + CAST(ISNULL(@filtro_Proposto, 'NULL') AS NVARCHAR(MAX))
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

	set @log = '@filtro_Approvato: ' + CAST(ISNULL(@filtro_Approvato, 'NULL') AS NVARCHAR(MAX))
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

	set @log = '@filtro_InEsecuzione: ' + CAST(ISNULL(@filtro_InEsecuzione, 'NULL') AS NVARCHAR(MAX))
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

	set @log = '@filtro_Effettuato: ' + CAST(ISNULL(@filtro_Effettuato, 'NULL') AS NVARCHAR(MAX))
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

	set @log = '@filtro_InErrore: ' + CAST(ISNULL(@filtro_InErrore, 'NULL') AS NVARCHAR(MAX))	
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject
	--
	


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @sql_string nvarchar(MAX)
	DECLARE @sql_string_select nvarchar(MAX)
	DECLARE @sql_string_from nvarchar(MAX)
	DECLARE @sql_string_where nvarchar(MAX)
	DECLARE @sql_string_filtroStati nvarchar(MAX) = ''
	DECLARE @sql_string_filtroStatiEsecuzione nvarchar(MAX) = ''

	SET @sql_string_select = CAST(N'
		SELECT 
			A.SYSTEM_ID ID_SCARTO,
			A.ID_AMMINISTRAZIONE,
			A.DESCRIPTION DESCRIZIONE,
			TST.NAME STATO,
			TS.DATETIME DATA,
			NUM_DOC.NUM_DOC_SCARTATI NUM_DOCUMENTI_SCARTATI 
		' AS NVARCHAR(MAX))

	SET @sql_string_from = CAST(N' 
		FROM 
			ARCHIVE_DISPOSAL A,
			ARCHIVE_DISPOSALSTATE TS,
			ARCHIVE_DISPOSALSTATETYPE TST,
			(
			SELECT 
				DISPOSAL_ID,
				COUNT(*) NUM_DOC_SCARTATI
			FROM
				ARCHIVE_TEMPPROFILEDISPOSAL
			WHERE
				DASCARTARE = 1
			GROUP BY DISPOSAL_ID
			) NUM_DOC,
			(
			SELECT T.DISPOSAL_ID, T.DISPOSALSTATETYPE_ID, T.DATETIME
			FROM
				(
				SELECT TS.DISPOSAL_ID, TS.DISPOSALSTATETYPE_ID, TS.DATETIME
				, RN = ROW_NUMBER() OVER (PARTITION BY TS.DISPOSAL_ID ORDER BY TS.DATETIME DESC)
				FROM ARCHIVE_DISPOSALSTATE TS
				) T
			WHERE T.RN = 1
			) STATO_CORRENTE 			
		' AS NVARCHAR(MAX))
	
	SET @sql_string_where = CAST(N' 
		WHERE 
			A.SYSTEM_ID = TS.DISPOSAL_ID
			AND TS.DISPOSALSTATETYPE_ID = TST.SYSTEM_ID 
			AND A.SYSTEM_ID = NUM_DOC.DISPOSAL_ID
			AND A.SYSTEM_ID = STATO_CORRENTE.DISPOSAL_ID
		' AS NVARCHAR(MAX))
	
	SELECT @sql_string_filtroStatiEsecuzione = CASE @tipoStatoEsecuzione
		WHEN 1 THEN ' AND STATO_CORRENTE.DISPOSALSTATETYPE_ID = 6 '
		WHEN 2 THEN ' AND STATO_CORRENTE.DISPOSALSTATETYPE_ID = 7 '
		WHEN 3 THEN ' AND STATO_CORRENTE.DISPOSALSTATETYPE_ID IN (6,7) '
		ELSE ''
	END
	
	IF (ISNULL(@sql_string_filtroStatiEsecuzione, '') = '')
		BEGIN
			DECLARE @message VARCHAR(200) = 'Valore non previsto per il parametro @tipoStatoEsecuzione - Valori accettati: (1,2,3) - Fornito: ' + + CAST(@tipoStatoEsecuzione AS NVARCHAR(MAX))
			RAISERROR (@message, 16, 1)
			RETURN			
		END
	
	-- 1 - IN DEFINIZIONE
	--
	IF (ISNULL(@filtro_InDefinizione, '') <> '')
		BEGIN
			
			SET @sql_string_from = @sql_string_from + CAST(',' AS NVARCHAR(MAX)) + CAST(@filtro_InDefinizione AS NVARCHAR(MAX)) + CAST(' T1 ' AS NVARCHAR(MAX))
		
			SET @sql_string_where = @sql_string_where + CAST(N' AND A.SYSTEM_ID = T1.DISPOSAL_ID ' AS NVARCHAR(MAX))
			
			--SET @sql_string_filtroStati = @sql_string_filtroStati + CAST(N',1' AS NVARCHAR(MAX))
			
		END
	
	-- 2 - RICERCA COMPLETATA
	--
	IF (ISNULL(@filtro_RicercaCompletata, '') <> '')
		BEGIN
		
			SET @sql_string_from = @sql_string_from + CAST(',' AS NVARCHAR(MAX)) + CAST(@filtro_RicercaCompletata AS NVARCHAR(MAX)) + CAST(' T2 ' AS NVARCHAR(MAX))
		
			SET @sql_string_where = @sql_string_where + CAST(N' AND A.SYSTEM_ID = T2.DISPOSAL_ID ' AS NVARCHAR(MAX))
			
			--SET @sql_string_filtroStati = @sql_string_filtroStati + CAST(N',2' AS NVARCHAR(MAX))
			
		END
	
	-- 3 - PROPOSTO
	--
	IF (ISNULL(@filtro_Proposto, '') <> '')
		BEGIN
		
			SET @sql_string_from = @sql_string_from + CAST(',' AS NVARCHAR(MAX)) + CAST(@filtro_Proposto AS NVARCHAR(MAX)) + CAST(' T3 ' AS NVARCHAR(MAX))
		
			SET @sql_string_where = @sql_string_where + CAST(N' AND A.SYSTEM_ID = T3.DISPOSAL_ID ' AS NVARCHAR(MAX))
			
			--SET @sql_string_filtroStati = @sql_string_filtroStati + CAST(N',3' AS NVARCHAR(MAX))
			
		END
	
	-- 4 - APPROVATO
	--
	IF (ISNULL(@filtro_Approvato, '') <> '')
		BEGIN
		
			SET @sql_string_from = @sql_string_from + CAST(',' AS NVARCHAR(MAX)) + CAST(@filtro_Approvato AS NVARCHAR(MAX)) + CAST(' T4 ' AS NVARCHAR(MAX))
		
			SET @sql_string_where = @sql_string_where + CAST(N' AND A.SYSTEM_ID = T4.DISPOSAL_ID ' AS NVARCHAR(MAX))
			
			--SET @sql_string_filtroStati = @sql_string_filtroStati + CAST(N',4' AS NVARCHAR(MAX))
			
		END
	
	-- 5 - IN ESECUZIONE
	--
	IF (ISNULL(@filtro_InEsecuzione, '') <> '')
		BEGIN
		
			SET @sql_string_from = @sql_string_from + CAST(',' AS NVARCHAR(MAX)) + CAST(@filtro_InEsecuzione AS NVARCHAR(MAX)) + CAST(' T5 ' AS NVARCHAR(MAX))
		
			SET @sql_string_where = @sql_string_where + CAST(N' AND A.SYSTEM_ID = T5.DISPOSAL_ID ' AS NVARCHAR(MAX))
			
			--SET @sql_string_filtroStati = @sql_string_filtroStati + CAST(N',5' AS NVARCHAR(MAX))
			
		END
	
	-- 6 - EFFETTUATO
	--
	IF (ISNULL(@filtro_Effettuato, '') <> '')
		BEGIN
		
			SET @sql_string_from = @sql_string_from + CAST(',' AS NVARCHAR(MAX)) + CAST(@filtro_Effettuato AS NVARCHAR(MAX)) + CAST(' T6 ' AS NVARCHAR(MAX))
		
			SET @sql_string_where = @sql_string_where + CAST(N' AND A.SYSTEM_ID = T6.DISPOSAL_ID ' AS NVARCHAR(MAX))
			
			--SET @sql_string_filtroStati = @sql_string_filtroStati + CAST(N',6' AS NVARCHAR(MAX))
			
		END
	
	-- 7 - IN ERRORE
	--
	IF (ISNULL(@filtro_InErrore, '') <> '')
		BEGIN
		
			SET @sql_string_from = @sql_string_from + CAST(',' AS NVARCHAR(MAX)) + CAST(@filtro_InErrore AS NVARCHAR(MAX)) + CAST(' T7 ' AS NVARCHAR(MAX))
		
			SET @sql_string_where = @sql_string_where + CAST(N' AND A.SYSTEM_ID = T7.DISPOSAL_ID ' AS NVARCHAR(MAX))
			
			--SET @sql_string_filtroStati = @sql_string_filtroStati + CAST(N',7' AS NVARCHAR(MAX))
			
		END



	SET @sql_string_filtroStati = CAST(N'6,7' AS NVARCHAR(MAX))

	IF (ISNULL(@sql_string_filtroStati, '') <> '')
		BEGIN
			
			SET @sql_string_where = @sql_string_where + CAST(N' AND TS.DISPOSALSTATETYPE_ID IN (' AS NVARCHAR(MAX)) + CAST(@sql_string_filtroStati AS NVARCHAR(MAX)) + CAST(')' AS NVARCHAR(MAX))
			
		END

	SET @sql_string = 
		CAST(@sql_string_select AS NVARCHAR(MAX)) 
		+ CAST(@sql_string_from AS NVARCHAR(MAX)) 
		+ CAST(@sql_string_where AS NVARCHAR(MAX))
		+ CAST(@sql_string_filtroStatiEsecuzione AS NVARCHAR(MAX));
	
	PRINT @sql_string;
	
	EXECUTE sp_executesql @sql_string;

END
