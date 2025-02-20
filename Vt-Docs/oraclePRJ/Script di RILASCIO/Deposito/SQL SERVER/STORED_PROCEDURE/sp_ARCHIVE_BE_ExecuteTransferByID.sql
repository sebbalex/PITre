USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [sp_ARCHIVE_ExecuteTransferByID]    Script Date: 05/02/2013 09:51:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Giovanni Olivari
-- Create date: 29/04/2013
-- Description:	Esegue il versamento
-- =============================================
ALTER PROCEDURE DOCSADM.sp_ARCHIVE_BE_ExecuteTransferByID
	@TransferID INT,
	@NumberOfObjectsPerTransaction INT, -- Numero di oggetti logici (documenti e fascicoli) per cui viene effettuato il commit della transazione DB; deve essere > 0 o -1 per indicare tutti gli oggetti
	@DatetimeLimit Datetime -- Limite temporale oltre il quale la procedura si interrompe; se NULL procede finchè non è terminato il trasferimento
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @log VARCHAR(2000)
	DECLARE @logType VARCHAR(10)
	DECLARE @logObject VARCHAR(50) = OBJECT_NAME(@@PROCID)
	DECLARE @logObjectType VARCHAR(50)
	DECLARE @logObjectType_Transfer int = 1 -- 'Transfer'
	DECLARE @logObjectType_TransferPolicy int = 2 --'TransferPolicy'
	DECLARE @logObjectID int = @TransferID
	DECLARE @errorCode int
	
	DECLARE @sql_string nvarchar(MAX)
	DECLARE @nomeSchemaCorrente varchar(200) 
	DECLARE @nomeUtenteCorrente varchar(200) 
	DECLARE @nomeUtenteDeposito varchar(200) 
	DECLARE @tipoPolicy int
	DECLARE @statoPolicy int
	DECLARE @statoPolicy_RICERCA_COMPLETATA int = 3 -- RICERCA COMPLETATA
	DECLARE @statoPolicy_ANALISI_COMPLETATA int = 5 -- ANALISI COMPLETATA
	DECLARE @transferState int
	DECLARE @transferStateType_IN_ESECUZIONE int = 5 -- IN ESECUZIONE
	DECLARE @transferStateType_EFFETTUATO int = 6 -- EFFETTUATO
	DECLARE @transferStateType_EFFETTUATO_COMPRESI_FILE int = 8 -- EFFETTUATO COMPRESI FILE
	DECLARE @transferStateType_IN_ERRORE int = 7 -- IN ERRORE

	DECLARE	@return_value int
	DECLARE	@System_ID int
	DECLARE	@now datetime = GETDATE()
	DECLARE @hasNext INT
	DECLARE @transactionObjetcs INT
	DECLARE @sql_filtroProject VARCHAR(MAX)
	DECLARE @sql_filtroProfile VARCHAR(MAX)
	DECLARE @trasferimentoCompleto INT
	DECLARE @timeLimit DATETIME
	DECLARE @returnValue INT = 0-- 0: Procedura di trasferimento non completata; 1: Procedura di trasferimento completata
	
	
	-- Impostazione data limite per l'esecuzione
	--
	IF (@DatetimeLimit IS NULL)
		SET @timeLimit = DATEADD(YEAR, 1, GETDATE()) -- aggiungo un anno per avere una data tale che mi permetta di terminare il trasferimento senza limiti di tempo
	ELSE
		SET @timeLimit = @DatetimeLimit



	-- Lettura parametri di configurazione
	--
	SELECT @nomeSchemaCorrente=[VALUE] FROM ARCHIVE_CONFIGURATION
	WHERE [KEY] = 'NOME_SCHEMA_CORRENTE'
	
	SELECT @nomeUtenteCorrente=[VALUE] FROM ARCHIVE_CONFIGURATION
	WHERE [KEY] = 'NOME_UTENTE_CORRENTE'
	
	SELECT @nomeUtenteDeposito=[VALUE] FROM ARCHIVE_CONFIGURATION
	WHERE [KEY] = 'NOME_UTENTE_DEPOSITO'
	
	print 'Nome schema corrente: ' + @nomeSchemaCorrente
	print 'Nome utente corrente: ' + @nomeUtenteCorrente
	print 'Nome utente deposito: ' + @nomeUtenteDeposito
	
	SET @nomeSchemaCorrente = @nomeSchemaCorrente + '.' + @nomeUtenteCorrente
	print 'Schema/Utente corrente: ' + @nomeSchemaCorrente
	
	
	
	-- Verifica che il versamento sia nello stato IN ESECUZIONE, altrimenti non può essere avviato
	--
	SELECT @transferState=TRANSFERSTATETYPE_ID FROM
	(
	SELECT TS.TRANSFER_ID, TS.TRANSFERSTATETYPE_ID, TS.DATETIME
	, RN = ROW_NUMBER() OVER (PARTITION BY TS.TRANSFER_ID ORDER BY TS.DATETIME DESC)
	FROM ARCHIVE_TRANSFERSTATE TS
	WHERE TS.TRANSFER_ID = @TransferID
	) T
	WHERE T.RN = 1
	
	IF (@transferState <> @transferStateType_IN_ESECUZIONE)
	BEGIN
		set @logType = 'ERROR'
		set @log = 'Transfer in stato non compatibile con l''avvio del trasferimento - TransferID: ' + CAST(@TransferID AS NVARCHAR(MAX))
		
		EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
		print @log

		-- Raise an error and return
		RAISERROR (@log, 16, 1)
		RETURN
	END
	
	
	
	-- Verifica che tutte le policy abilitate appartenenti al versamento siano almeno nello stato RICERCA COMPLETATA
	--
	DECLARE @numPolicyInconsistenti INT
	
	SELECT @numPolicyInconsistenti = COUNT(*) --SYSTEM_ID, TransferPolicyType_ID, TransferPolicyState_ID 
	FROM ARCHIVE_TransferPolicy 
	WHERE Transfer_ID = @TransferID
	AND ENABLED = 1
	AND TransferPolicyState_ID NOT IN (@statoPolicy_RICERCA_COMPLETATA, @statoPolicy_ANALISI_COMPLETATA)
	
	IF (@numPolicyInconsistenti > 0)
		BEGIN
			set @logType = 'ERROR'
			set @log = 'Policy in stato non compatibile con l''avvio del trasferimento'
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
			print @log

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		
		END



	-- Inserimento degli ID nelle tabelle temp.
	-- Potrebbe non essere il primo avvio del trasferimento, quindi escludo quelli già inseriti nella tabella temp e non trasferiti
	--
	-- PROJECT
	--
	INSERT INTO ARCHIVE_TEMPTRANSFERPROJECT (PROJECT_ID, TRANSFER_ID)
	SELECT DISTINCT F.PROJECT_ID, P.TRANSFER_ID
	FROM ARCHIVE_TEMPPROJECT F INNER JOIN ARCHIVE_TRANSFERPOLICY P ON F.TRANSFERPOLICY_ID = P.SYSTEM_ID
	WHERE P.TRANSFER_ID = @TransferID
	AND P.ENABLED = 1
	AND F.DATRASFERIRE = 1
	AND F.PROJECT_ID NOT IN (SELECT PROJECT_ID FROM ARCHIVE_TEMPTRANSFERPROJECT) -- Non è già pronto per il trasferimento
	AND F.PROJECT_ID NOT IN (SELECT SYSTEM_ID FROM PROJECT) -- Non è già stato trasferito

	-- PROFILE
	--
	INSERT INTO ARCHIVE_TEMPTRANSFERPROFILE (PROFILE_ID, TRANSFER_ID)
	SELECT DISTINCT D.PROFILE_ID, P.TRANSFER_ID
	FROM ARCHIVE_TEMPPROFILE D INNER JOIN ARCHIVE_TRANSFERPOLICY P ON D.TRANSFERPOLICY_ID = P.SYSTEM_ID
	WHERE P.TRANSFER_ID = @TransferID
	AND P.ENABLED = 1
	AND D.PROFILE_ID NOT IN (SELECT PROFILE_ID FROM ARCHIVE_TEMPTRANSFERPROFILE) -- Non è già pronto per il trasferimento
	AND D.PROFILE_ID NOT IN (SELECT SYSTEM_ID FROM PROFILE) -- Non è già stato trasferito



	-- Creazione #temp table
	--
	IF OBJECT_ID('tempdb..#oggettiDaTrasferire') IS NOT NULL DROP TABLE #oggettiDaTrasferire
	CREATE TABLE #oggettiDaTrasferire
	(
		ID int
	)



	-- ***************************************************************************************
	-- FASCICOLI: tutti i fascicoli procedimentali, comprese le root folder e i sottofascicoli
	-- ***************************************************************************************

	-- Finchè ci sono oggetti da trasferire e non è passato il tempo limite
	--
	SET @hasNext = 1

	WHILE (@hasNext = 1 AND GETDATE()<@timeLimit)
		BEGIN
	
		-- Appoggio gli oggetti da trasferire in una tabella #temp
		--
		DELETE FROM #oggettiDaTrasferire

		IF (@NumberOfObjectsPerTransaction > 0)
			SET @sql_string = CAST(N'
				INSERT INTO #oggettiDaTrasferire (ID)
				SELECT TOP ' AS NVARCHAR(MAX)) + CAST(@NumberOfObjectsPerTransaction AS NVARCHAR(MAX)) + CAST(N' PROJECT_ID
				FROM ARCHIVE_TEMPTRANSFERPROJECT 
				WHERE TRANSFER_ID = ' AS NVARCHAR(MAX)) + CAST(@TransferID AS NVARCHAR(MAX))
		ELSE
			SET @sql_string = CAST(N'
				INSERT INTO #oggettiDaTrasferire (ID)
				SELECT PROJECT_ID
				FROM ARCHIVE_TEMPTRANSFERPROJECT 
				WHERE TRANSFER_ID = ' AS NVARCHAR(MAX)) + CAST(@TransferID AS NVARCHAR(MAX))		

		print @sql_string
		
		EXECUTE sp_executesql @sql_string;

		
		
		SELECT @transactionObjetcs=COUNT(*) FROM #oggettiDaTrasferire
		
		print 'Transaction object (project):' + cast(@transactionObjetcs as varchar(10))
		
		IF (@transactionObjetcs > 0)
			BEGIN
			
				SET @sql_filtroProject = 'SELECT ID FROM #oggettiDaTrasferire'
			
				BEGIN TRANSACTION T1
				
				PRINT 'Numero oggetti trasferiti in questa transazione: ' + cast(@transactionObjetcs as varchar(10))
				
				
				
				-- *******
				-- PROJECT
				-- *******
				
				SET @sql_string = CAST(N'
				WITH GERARCHIA_FASCICOLO AS
				(
				SELECT P.SYSTEM_ID, P.ID_PARENT, P.ID_FASCICOLO, P.VAR_CODICE, P.CHA_TIPO_FASCICOLO, P.CHA_TIPO_PROJ, P.ID_REGISTRO, P.VAR_COD_LIV1
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P
				WHERE P.SYSTEM_ID IN (' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(')
				UNION ALL
				SELECT P.SYSTEM_ID, P.ID_PARENT, P.ID_FASCICOLO, P.VAR_CODICE, P.CHA_TIPO_FASCICOLO, P.CHA_TIPO_PROJ, P.ID_REGISTRO, P.VAR_COD_LIV1
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P INNER JOIN GERARCHIA_FASCICOLO GCT ON GCT.SYSTEM_ID = P.ID_PARENT
				)
				MERGE PROJECT AS TARGET
					USING (SELECT [SYSTEM_ID]
				  ,[DESCRIPTION]
				  ,[ICONIZED]
				  ,[PROFILE_ID]
				  ,[CHA_TIPO_PROJ]
				  ,[VAR_CODICE]
				  ,[ID_AMM]
				  ,[ID_REGISTRO]
				  ,[NUM_LIVELLO]
				  ,[CHA_TIPO_FASCICOLO]
				  ,[ID_FASCICOLO]
				  ,[ID_PARENT]
				  ,[VAR_NOTE]
				  ,[DTA_APERTURA]
				  ,[DTA_CHIUSURA]
				  ,[CHA_STATO]
				  ,[VAR_COD_ULTIMO]
				  ,[VAR_COD_LIV1]
				  ,[ET_TITOLARIO]
				  ,[ET_LIVELLO1]
				  ,[ET_LIVELLO2]
				  ,[ET_LIVELLO3]
				  ,[ET_LIVELLO4]
				  ,[ET_LIVELLO5]
				  ,[ET_LIVELLO6]
				  ,[ID_TIPO_PROC]
				  ,[ID_LEGISLATURA]
				  ,[ETDOC_RANDOM_ID]
				  ,[DTA_Creazione]
				  ,[Num_fascicolo]
				  ,[Anno_creazione]
				  ,[CHA_RW]
				  ,[ID_UO_REF]
				  ,[ID_UO_LF]
				  ,[DTA_UO_LF]
				  ,[NUM_MESI_CONSERVAZIONE]
				  ,[var_chiave_fasc]
				  ,[CARTACEO]
				  ,[CHA_PRIVATO]
				  ,[ID_TIPO_FASC]
				  ,[CHA_BLOCCA_FASC]
				  ,[ID_TITOLARIO]
				  ,[DTA_ATTIVAZIONE]
				  ,[DTA_CESSAZIONE]
				  ,[DTA_SCADENZA]
				  ,[CHA_IN_ARCHIVIO]
				  ,[AUTHOR]
				  ,[ID_RUOLO_CREATORE]
				  ,[ID_UO_CREATORE]
				  ,[NUM_PROT_TIT]
				  ,[CHA_CONTA_PROT_TIT]
				  ,[CHA_BLOCCA_FIGLI]
				  ,[MAX_LIV_TIT]
				  ,[ID_PEOPLE_DELEGATO]
				  ,[CHA_CONTROLLATO]
				  ,[CHA_CONSENTI_CLASS]
				  ,[ID_RUOLO_CHIUSURA]
				  ,[ID_UO_CHIUSURA]
				  ,[ID_AUTHOR_CHIUSURA]
				  ,[CHA_COD_T_A]
				  ,[COD_EXT_APP]
			  FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[PROJECT] WITH (NOLOCK) WHERE SYSTEM_ID IN 
					(
					SELECT DISTINCT P.SYSTEM_ID 
					FROM GERARCHIA_FASCICOLO P
					)
				) 
			AS SOURCE ([SYSTEM_ID]
				  ,[DESCRIPTION]
				  ,[ICONIZED]
				  ,[PROFILE_ID]
				  ,[CHA_TIPO_PROJ]
				  ,[VAR_CODICE]
				  ,[ID_AMM]
				  ,[ID_REGISTRO]
				  ,[NUM_LIVELLO]
				  ,[CHA_TIPO_FASCICOLO]
				  ,[ID_FASCICOLO]
				  ,[ID_PARENT]
				  ,[VAR_NOTE]
				  ,[DTA_APERTURA]
				  ,[DTA_CHIUSURA]
				  ,[CHA_STATO]
				  ,[VAR_COD_ULTIMO]
				  ,[VAR_COD_LIV1]
				  ,[ET_TITOLARIO]
				  ,[ET_LIVELLO1]
				  ,[ET_LIVELLO2]
				  ,[ET_LIVELLO3]
				  ,[ET_LIVELLO4]
				  ,[ET_LIVELLO5]
				  ,[ET_LIVELLO6]
				  ,[ID_TIPO_PROC]
				  ,[ID_LEGISLATURA]
				  ,[ETDOC_RANDOM_ID]
				  ,[DTA_Creazione]
				  ,[Num_fascicolo]
				  ,[Anno_creazione]
				  ,[CHA_RW]
				  ,[ID_UO_REF]
				  ,[ID_UO_LF]
				  ,[DTA_UO_LF]
				  ,[NUM_MESI_CONSERVAZIONE]
				  ,[var_chiave_fasc]
				  ,[CARTACEO]
				  ,[CHA_PRIVATO]
				  ,[ID_TIPO_FASC]
				  ,[CHA_BLOCCA_FASC]
				  ,[ID_TITOLARIO]
				  ,[DTA_ATTIVAZIONE]
				  ,[DTA_CESSAZIONE]
				  ,[DTA_SCADENZA]
				  ,[CHA_IN_ARCHIVIO]
				  ,[AUTHOR]
				  ,[ID_RUOLO_CREATORE]
				  ,[ID_UO_CREATORE]
				  ,[NUM_PROT_TIT]
				  ,[CHA_CONTA_PROT_TIT]
				  ,[CHA_BLOCCA_FIGLI]
				  ,[MAX_LIV_TIT]
				  ,[ID_PEOPLE_DELEGATO]
				  ,[CHA_CONTROLLATO]
				  ,[CHA_CONSENTI_CLASS]
				  ,[ID_RUOLO_CHIUSURA]
				  ,[ID_UO_CHIUSURA]
				  ,[ID_AUTHOR_CHIUSURA]
				  ,[CHA_COD_T_A]
				  ,[COD_EXT_APP])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
						  ,[DESCRIPTION] = SOURCE.[DESCRIPTION]
						  ,[ICONIZED] = SOURCE.[ICONIZED]
						  ,[PROFILE_ID] = SOURCE.[PROFILE_ID]
						  ,[CHA_TIPO_PROJ] = SOURCE.[CHA_TIPO_PROJ]
						  ,[VAR_CODICE] = SOURCE.[VAR_CODICE]
						  ,[ID_AMM] = SOURCE.[ID_AMM]
						  ,[ID_REGISTRO] = SOURCE.[ID_REGISTRO]
						  ,[NUM_LIVELLO] = SOURCE.[NUM_LIVELLO]
						  ,[CHA_TIPO_FASCICOLO] = SOURCE.[CHA_TIPO_FASCICOLO]
						  ,[ID_FASCICOLO] = SOURCE.[ID_FASCICOLO]
						  ,[ID_PARENT] = SOURCE.[ID_PARENT]
						  ,[VAR_NOTE] = SOURCE.[VAR_NOTE]
						  ,[DTA_APERTURA] = SOURCE.[DTA_APERTURA]
						  ,[DTA_CHIUSURA] = SOURCE.[DTA_CHIUSURA]
						  ,[CHA_STATO] = SOURCE.[CHA_STATO]
						  ,[VAR_COD_ULTIMO] = SOURCE.[VAR_COD_ULTIMO]
						  ,[VAR_COD_LIV1] = SOURCE.[VAR_COD_LIV1]
						  ,[ET_TITOLARIO] = SOURCE.[ET_TITOLARIO]
						  ,[ET_LIVELLO1] = SOURCE.[ET_LIVELLO1]
						  ,[ET_LIVELLO2] = SOURCE.[ET_LIVELLO2]
						  ,[ET_LIVELLO3] = SOURCE.[ET_LIVELLO3]
						  ,[ET_LIVELLO4] = SOURCE.[ET_LIVELLO4]
						  ,[ET_LIVELLO5] = SOURCE.[ET_LIVELLO5]
						  ,[ET_LIVELLO6] = SOURCE.[ET_LIVELLO6]
						  ,[ID_TIPO_PROC] = SOURCE.[ID_TIPO_PROC]
						  ,[ID_LEGISLATURA] = SOURCE.[ID_LEGISLATURA]
						  ,[ETDOC_RANDOM_ID] = SOURCE.[ETDOC_RANDOM_ID]
						  ,[DTA_Creazione] = SOURCE.[DTA_Creazione]
						  ,[Num_fascicolo] = SOURCE.[Num_fascicolo]
						  ,[Anno_creazione] = SOURCE.[Anno_creazione]
						  ,[CHA_RW] = SOURCE.[CHA_RW]
						  ,[ID_UO_REF] = SOURCE.[ID_UO_REF]
						  ,[ID_UO_LF] = SOURCE.[ID_UO_LF]
						  ,[DTA_UO_LF] = SOURCE.[DTA_UO_LF]
						  ,[NUM_MESI_CONSERVAZIONE] = SOURCE.[NUM_MESI_CONSERVAZIONE]
						  ,[var_chiave_fasc] = SOURCE.[var_chiave_fasc]
						  ,[CARTACEO] = SOURCE.[CARTACEO]
						  ,[CHA_PRIVATO] = SOURCE.[CHA_PRIVATO]
						  ,[ID_TIPO_FASC] = SOURCE.[ID_TIPO_FASC]
						  ,[CHA_BLOCCA_FASC] = SOURCE.[CHA_BLOCCA_FASC]
						  ,[ID_TITOLARIO] = SOURCE.[ID_TITOLARIO]
						  ,[DTA_ATTIVAZIONE] = SOURCE.[DTA_ATTIVAZIONE]
						  ,[DTA_CESSAZIONE] = SOURCE.[DTA_CESSAZIONE]
						  ,[DTA_SCADENZA] = SOURCE.[DTA_SCADENZA]
						  ,[CHA_IN_ARCHIVIO] = SOURCE.[CHA_IN_ARCHIVIO]
						  ,[AUTHOR] = SOURCE.[AUTHOR]
						  ,[ID_RUOLO_CREATORE] = SOURCE.[ID_RUOLO_CREATORE]
						  ,[ID_UO_CREATORE] = SOURCE.[ID_UO_CREATORE]
						  ,[NUM_PROT_TIT] = SOURCE.[NUM_PROT_TIT]
						  ,[CHA_CONTA_PROT_TIT] = SOURCE.[CHA_CONTA_PROT_TIT]
						  ,[CHA_BLOCCA_FIGLI] = SOURCE.[CHA_BLOCCA_FIGLI]
						  ,[MAX_LIV_TIT] = SOURCE.[MAX_LIV_TIT]
						  ,[ID_PEOPLE_DELEGATO] = SOURCE.[ID_PEOPLE_DELEGATO]
						  ,[CHA_CONTROLLATO] = SOURCE.[CHA_CONTROLLATO]
						  ,[CHA_CONSENTI_CLASS] = SOURCE.[CHA_CONSENTI_CLASS]
						  ,[ID_RUOLO_CHIUSURA] = SOURCE.[ID_RUOLO_CHIUSURA]
						  ,[ID_UO_CHIUSURA] = SOURCE.[ID_UO_CHIUSURA]
						  ,[ID_AUTHOR_CHIUSURA] = SOURCE.[ID_AUTHOR_CHIUSURA]
						  ,[CHA_COD_T_A] = SOURCE.[CHA_COD_T_A]
						  ,[COD_EXT_APP] = SOURCE.[COD_EXT_APP]
					WHEN NOT MATCHED THEN
						INSERT ([SYSTEM_ID]
							  ,[DESCRIPTION]
							  ,[ICONIZED]
							  ,[PROFILE_ID]
							  ,[CHA_TIPO_PROJ]
							  ,[VAR_CODICE]
							  ,[ID_AMM]
							  ,[ID_REGISTRO]
							  ,[NUM_LIVELLO]
							  ,[CHA_TIPO_FASCICOLO]
							  ,[ID_FASCICOLO]
							  ,[ID_PARENT]
							  ,[VAR_NOTE]
							  ,[DTA_APERTURA]
							  ,[DTA_CHIUSURA]
							  ,[CHA_STATO]
							  ,[VAR_COD_ULTIMO]
							  ,[VAR_COD_LIV1]
							  ,[ET_TITOLARIO]
							  ,[ET_LIVELLO1]
							  ,[ET_LIVELLO2]
							  ,[ET_LIVELLO3]
							  ,[ET_LIVELLO4]
							  ,[ET_LIVELLO5]
							  ,[ET_LIVELLO6]
							  ,[ID_TIPO_PROC]
							  ,[ID_LEGISLATURA]
							  ,[ETDOC_RANDOM_ID]
							  ,[DTA_Creazione]
							  ,[Num_fascicolo]
							  ,[Anno_creazione]
							  ,[CHA_RW]
							  ,[ID_UO_REF]
							  ,[ID_UO_LF]
							  ,[DTA_UO_LF]
							  ,[NUM_MESI_CONSERVAZIONE]
							  ,[var_chiave_fasc]
							  ,[CARTACEO]
							  ,[CHA_PRIVATO]
							  ,[ID_TIPO_FASC]
							  ,[CHA_BLOCCA_FASC]
							  ,[ID_TITOLARIO]
							  ,[DTA_ATTIVAZIONE]
							  ,[DTA_CESSAZIONE]
							  ,[DTA_SCADENZA]
							  ,[CHA_IN_ARCHIVIO]
							  ,[AUTHOR]
							  ,[ID_RUOLO_CREATORE]
							  ,[ID_UO_CREATORE]
							  ,[NUM_PROT_TIT]
							  ,[CHA_CONTA_PROT_TIT]
							  ,[CHA_BLOCCA_FIGLI]
							  ,[MAX_LIV_TIT]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_CONTROLLATO]
							  ,[CHA_CONSENTI_CLASS]
							  ,[ID_RUOLO_CHIUSURA]
							  ,[ID_UO_CHIUSURA]
							  ,[ID_AUTHOR_CHIUSURA]
							  ,[CHA_COD_T_A]
							  ,[COD_EXT_APP])
						VALUES (SOURCE.[SYSTEM_ID]
							  , SOURCE.[DESCRIPTION]
							  , SOURCE.[ICONIZED]
							  , SOURCE.[PROFILE_ID]
							  , SOURCE.[CHA_TIPO_PROJ]
							  , SOURCE.[VAR_CODICE]
							  , SOURCE.[ID_AMM]
							  , SOURCE.[ID_REGISTRO]
							  , SOURCE.[NUM_LIVELLO]
							  , SOURCE.[CHA_TIPO_FASCICOLO]
							  , SOURCE.[ID_FASCICOLO]
							  , SOURCE.[ID_PARENT]
							  , SOURCE.[VAR_NOTE]
							  , SOURCE.[DTA_APERTURA]
							  , SOURCE.[DTA_CHIUSURA]
							  , SOURCE.[CHA_STATO]
							  , SOURCE.[VAR_COD_ULTIMO]
							  , SOURCE.[VAR_COD_LIV1]
							  , SOURCE.[ET_TITOLARIO]
							  , SOURCE.[ET_LIVELLO1]
							  , SOURCE.[ET_LIVELLO2]
							  , SOURCE.[ET_LIVELLO3]
							  , SOURCE.[ET_LIVELLO4]
							  , SOURCE.[ET_LIVELLO5]
							  , SOURCE.[ET_LIVELLO6]
							  , SOURCE.[ID_TIPO_PROC]
							  , SOURCE.[ID_LEGISLATURA]
							  , SOURCE.[ETDOC_RANDOM_ID]
							  , SOURCE.[DTA_Creazione]
							  , SOURCE.[Num_fascicolo]
							  , SOURCE.[Anno_creazione]
							  , SOURCE.[CHA_RW]
							  , SOURCE.[ID_UO_REF]
							  , SOURCE.[ID_UO_LF]
							  , SOURCE.[DTA_UO_LF]
							  , SOURCE.[NUM_MESI_CONSERVAZIONE]
							  , SOURCE.[var_chiave_fasc]
							  , SOURCE.[CARTACEO]
							  , SOURCE.[CHA_PRIVATO]
							  , SOURCE.[ID_TIPO_FASC]
							  , SOURCE.[CHA_BLOCCA_FASC]
							  , SOURCE.[ID_TITOLARIO]
							  , SOURCE.[DTA_ATTIVAZIONE]
							  , SOURCE.[DTA_CESSAZIONE]
							  , SOURCE.[DTA_SCADENZA]
							  , SOURCE.[CHA_IN_ARCHIVIO]
							  , SOURCE.[AUTHOR]
							  , SOURCE.[ID_RUOLO_CREATORE]
							  , SOURCE.[ID_UO_CREATORE]
							  , SOURCE.[NUM_PROT_TIT]
							  , SOURCE.[CHA_CONTA_PROT_TIT]
							  , SOURCE.[CHA_BLOCCA_FIGLI]
							  , SOURCE.[MAX_LIV_TIT]
							  , SOURCE.[ID_PEOPLE_DELEGATO]
							  , SOURCE.[CHA_CONTROLLATO]
							  , SOURCE.[CHA_CONSENTI_CLASS]
							  , SOURCE.[ID_RUOLO_CHIUSURA]
							  , SOURCE.[ID_UO_CHIUSURA]
							  , SOURCE.[ID_AUTHOR_CHIUSURA]
							  , SOURCE.[CHA_COD_T_A]
							  , SOURCE.[COD_EXT_APP]);' AS NVARCHAR(MAX))
						  
				PRINT @sql_string;
			
				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella PROJECT - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella PROJECT'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ***********************
				-- DPA_ITEMS_CONSERVAZIONE
				-- ***********************
				
				SET @sql_string = CAST(N'
				WITH GERARCHIA_FASCICOLO AS
				(
				SELECT P.SYSTEM_ID, P.ID_PARENT, P.ID_FASCICOLO, P.VAR_CODICE, P.CHA_TIPO_FASCICOLO, P.CHA_TIPO_PROJ, P.ID_REGISTRO, P.VAR_COD_LIV1
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P
				WHERE P.SYSTEM_ID IN (' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(')
				UNION ALL
				SELECT P.SYSTEM_ID, P.ID_PARENT, P.ID_FASCICOLO, P.VAR_CODICE, P.CHA_TIPO_FASCICOLO, P.CHA_TIPO_PROJ, P.ID_REGISTRO, P.VAR_COD_LIV1
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P INNER JOIN GERARCHIA_FASCICOLO GCT ON GCT.SYSTEM_ID = P.ID_PARENT
				)
				MERGE DPA_ITEMS_CONSERVAZIONE AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
						,[ID_CONSERVAZIONE]
						,[ID_PROFILE]
						,[ID_PROJECT]
						,[CHA_TIPO_DOC]
						,[VAR_OGGETTO]
						,[ID_REGISTRO]
						,[DATA_INS]
						,[CHA_STATO]
						,[VAR_XML_METADATI]
						,[SIZE_ITEM]
						,[COD_FASC]
						,[DOCNUMBER]
						,[VAR_TIPO_FILE]
						,[NUMERO_ALLEGATI]
						,[CHA_TIPO_OGGETTO]
						,[CHA_ESITO]
						,[VAR_TIPO_ATTO]
						,[POLICY_VALIDA]
						,[VALIDAZIONE_FIRMA]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_ITEMS_CONSERVAZIONE] WITH (NOLOCK)
						WHERE [ID_PROJECT] IN 
							(
							SELECT DISTINCT P.SYSTEM_ID 
							FROM GERARCHIA_FASCICOLO P
							)
						)
					AS SOURCE ([SYSTEM_ID]
						,[ID_CONSERVAZIONE]
						,[ID_PROFILE]
						,[ID_PROJECT]
						,[CHA_TIPO_DOC]
						,[VAR_OGGETTO]
						,[ID_REGISTRO]
						,[DATA_INS]
						,[CHA_STATO]
						,[VAR_XML_METADATI]
						,[SIZE_ITEM]
						,[COD_FASC]
						,[DOCNUMBER]
						,[VAR_TIPO_FILE]
						,[NUMERO_ALLEGATI]
						,[CHA_TIPO_OGGETTO]
						,[CHA_ESITO]
						,[VAR_TIPO_ATTO]
						,[POLICY_VALIDA]
						,[VALIDAZIONE_FIRMA])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_CONSERVAZIONE] = SOURCE.[ID_CONSERVAZIONE]
							,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							,[ID_PROJECT] = SOURCE.[ID_PROJECT]
							,[CHA_TIPO_DOC] = SOURCE.[CHA_TIPO_DOC]
							,[VAR_OGGETTO] = SOURCE.[VAR_OGGETTO]
							,[ID_REGISTRO] = SOURCE.[ID_REGISTRO]
							,[DATA_INS] = SOURCE.[DATA_INS]
							,[CHA_STATO] = SOURCE.[CHA_STATO]
							,[VAR_XML_METADATI] = SOURCE.[VAR_XML_METADATI]
							,[SIZE_ITEM] = SOURCE.[SIZE_ITEM]
							,[COD_FASC] = SOURCE.[COD_FASC]
							,[DOCNUMBER] = SOURCE.[DOCNUMBER]
							,[VAR_TIPO_FILE] = SOURCE.[VAR_TIPO_FILE]
							,[NUMERO_ALLEGATI] = SOURCE.[NUMERO_ALLEGATI]
							,[CHA_TIPO_OGGETTO] = SOURCE.[CHA_TIPO_OGGETTO]
							,[CHA_ESITO] = SOURCE.[CHA_ESITO]
							,[VAR_TIPO_ATTO] = SOURCE.[VAR_TIPO_ATTO]
							,[POLICY_VALIDA] = SOURCE.[POLICY_VALIDA]
							,[VALIDAZIONE_FIRMA] = SOURCE.[VALIDAZIONE_FIRMA]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_CONSERVAZIONE]
							,[ID_PROFILE]
							,[ID_PROJECT]
							,[CHA_TIPO_DOC]
							,[VAR_OGGETTO]
							,[ID_REGISTRO]
							,[DATA_INS]
							,[CHA_STATO]
							,[VAR_XML_METADATI]
							,[SIZE_ITEM]
							,[COD_FASC]
							,[DOCNUMBER]
							,[VAR_TIPO_FILE]
							,[NUMERO_ALLEGATI]
							,[CHA_TIPO_OGGETTO]
							,[CHA_ESITO]
							,[VAR_TIPO_ATTO]
							,[POLICY_VALIDA]
							,[VALIDAZIONE_FIRMA]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_CONSERVAZIONE]
							,SOURCE.[ID_PROFILE]
							,SOURCE.[ID_PROJECT]
							,SOURCE.[CHA_TIPO_DOC]
							,SOURCE.[VAR_OGGETTO]
							,SOURCE.[ID_REGISTRO]
							,SOURCE.[DATA_INS]
							,SOURCE.[CHA_STATO]
							,SOURCE.[VAR_XML_METADATI]
							,SOURCE.[SIZE_ITEM]
							,SOURCE.[COD_FASC]
							,SOURCE.[DOCNUMBER]
							,SOURCE.[VAR_TIPO_FILE]
							,SOURCE.[NUMERO_ALLEGATI]
							,SOURCE.[CHA_TIPO_OGGETTO]
							,SOURCE.[CHA_ESITO]
							,SOURCE.[VAR_TIPO_ATTO]
							,SOURCE.[POLICY_VALIDA]
							,SOURCE.[VALIDAZIONE_FIRMA]
						);' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_ITEMS_CONSERVAZIONE (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_ITEMS_CONSERVAZIONE (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ********
				-- SECURITY
				-- ********
				
				SET @sql_string = CAST(N'
				WITH GERARCHIA_FASCICOLO AS
				(
				SELECT P.SYSTEM_ID, P.ID_PARENT, P.ID_FASCICOLO, P.VAR_CODICE, P.CHA_TIPO_FASCICOLO, P.CHA_TIPO_PROJ, P.ID_REGISTRO, P.VAR_COD_LIV1
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P
				WHERE P.SYSTEM_ID IN (' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(')
				UNION ALL
				SELECT P.SYSTEM_ID, P.ID_PARENT, P.ID_FASCICOLO, P.VAR_CODICE, P.CHA_TIPO_FASCICOLO, P.CHA_TIPO_PROJ, P.ID_REGISTRO, P.VAR_COD_LIV1
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P INNER JOIN GERARCHIA_FASCICOLO GCT ON GCT.SYSTEM_ID = P.ID_PARENT
				)
				MERGE SECURITY AS TARGET
					USING ( 	
					SELECT [THING]
					  ,[PERSONORGROUP]
					  ,[ACCESSRIGHTS]
					  ,[ID_GRUPPO_TRASM]
					  ,[CHA_TIPO_DIRITTO]
					  ,[HIDE_DOC_VERSIONS]
					  ,[TS_INSERIMENTO]
					  ,[VAR_NOTE_SEC]
					FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[SECURITY] WITH (NOLOCK)
					WHERE [THING] IN 
						(
						SELECT DISTINCT P.SYSTEM_ID 
						FROM GERARCHIA_FASCICOLO P
						)
					) 
					AS SOURCE ([THING]
					  ,[PERSONORGROUP]
					  ,[ACCESSRIGHTS]
					  ,[ID_GRUPPO_TRASM]
					  ,[CHA_TIPO_DIRITTO]
					  ,[HIDE_DOC_VERSIONS]
					  ,[TS_INSERIMENTO]
					  ,[VAR_NOTE_SEC])
					ON (TARGET.THING = SOURCE.THING AND TARGET.PERSONORGROUP = SOURCE.PERSONORGROUP AND TARGET.ACCESSRIGHTS = SOURCE.ACCESSRIGHTS)
					WHEN MATCHED THEN
						UPDATE SET
							[THING] = SOURCE.[THING]
						  ,[PERSONORGROUP] = SOURCE.[PERSONORGROUP]
						  ,[ACCESSRIGHTS] = SOURCE.[ACCESSRIGHTS]
						  ,[ID_GRUPPO_TRASM] = SOURCE.[ID_GRUPPO_TRASM]
						  ,[CHA_TIPO_DIRITTO] = SOURCE.[CHA_TIPO_DIRITTO]
						  ,[HIDE_DOC_VERSIONS] = SOURCE.[HIDE_DOC_VERSIONS]
						  ,[TS_INSERIMENTO] = SOURCE.[TS_INSERIMENTO]
						  ,[VAR_NOTE_SEC] = SOURCE.[VAR_NOTE_SEC]
					WHEN NOT MATCHED THEN
						INSERT ([THING]
							  ,[PERSONORGROUP]
							  ,[ACCESSRIGHTS]
							  ,[ID_GRUPPO_TRASM]
							  ,[CHA_TIPO_DIRITTO]
							  ,[HIDE_DOC_VERSIONS]
							  ,[TS_INSERIMENTO]
							  ,[VAR_NOTE_SEC])
						VALUES (SOURCE.[THING]
							  ,SOURCE.[PERSONORGROUP]
							  ,SOURCE.[ACCESSRIGHTS]
							  ,SOURCE.[ID_GRUPPO_TRASM]
							  ,SOURCE.[CHA_TIPO_DIRITTO]
							  ,SOURCE.[HIDE_DOC_VERSIONS]
							  ,SOURCE.[TS_INSERIMENTO]
							  ,SOURCE.[VAR_NOTE_SEC]);' AS NVARCHAR(MAX))
							  
				PRINT @sql_string;
			
				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella SECURITY (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella SECURITY (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ****************
				-- DELETED_SECURITY
				-- ****************
				
				SET @sql_string = CAST(N'
				WITH GERARCHIA_FASCICOLO AS
				(
				SELECT P.SYSTEM_ID, P.ID_PARENT, P.ID_FASCICOLO, P.VAR_CODICE, P.CHA_TIPO_FASCICOLO, P.CHA_TIPO_PROJ, P.ID_REGISTRO, P.VAR_COD_LIV1
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P
				WHERE P.SYSTEM_ID IN (' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(')
				UNION ALL
				SELECT P.SYSTEM_ID, P.ID_PARENT, P.ID_FASCICOLO, P.VAR_CODICE, P.CHA_TIPO_FASCICOLO, P.CHA_TIPO_PROJ, P.ID_REGISTRO, P.VAR_COD_LIV1
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P INNER JOIN GERARCHIA_FASCICOLO GCT ON GCT.SYSTEM_ID = P.ID_PARENT
				)
				MERGE DELETED_SECURITY AS TARGET
				USING ( 	
					SELECT [THING]
					,[PERSONORGROUP]
					,[ACCESSRIGHTS]
					,[ID_GRUPPO_TRASM]
					,[CHA_TIPO_DIRITTO]
					,[NOTE]
					,[DTA_REVOCA]
					,[ID_UTENTE_REV]
					,[ID_RUOLO_REV]
					,[HIDE_DOC_VERSIONS]
					FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DELETED_SECURITY] WITH (NOLOCK)
					WHERE [THING] IN 
						(
						SELECT DISTINCT P.SYSTEM_ID 
						FROM GERARCHIA_FASCICOLO P
						)
					)
				AS SOURCE ([THING]
					,[PERSONORGROUP]
					,[ACCESSRIGHTS]
					,[ID_GRUPPO_TRASM]
					,[CHA_TIPO_DIRITTO]
					,[NOTE]
					,[DTA_REVOCA]
					,[ID_UTENTE_REV]
					,[ID_RUOLO_REV]
					,[HIDE_DOC_VERSIONS])
				ON (TARGET.THING = SOURCE.THING AND TARGET.PERSONORGROUP = SOURCE.PERSONORGROUP AND TARGET.ACCESSRIGHTS = SOURCE.ACCESSRIGHTS)
				WHEN MATCHED THEN
					UPDATE SET
						[THING] = SOURCE.[THING]
						,[PERSONORGROUP] = SOURCE.[PERSONORGROUP]
						,[ACCESSRIGHTS] = SOURCE.[ACCESSRIGHTS]
						,[ID_GRUPPO_TRASM] = SOURCE.[ID_GRUPPO_TRASM]
						,[CHA_TIPO_DIRITTO] = SOURCE.[CHA_TIPO_DIRITTO]
						,[NOTE] = SOURCE.[NOTE]
						,[DTA_REVOCA] = SOURCE.[DTA_REVOCA]
						,[ID_UTENTE_REV] = SOURCE.[ID_UTENTE_REV]
						,[ID_RUOLO_REV] = SOURCE.[ID_RUOLO_REV]
						,[HIDE_DOC_VERSIONS] = SOURCE.[HIDE_DOC_VERSIONS]
				WHEN NOT MATCHED THEN
					INSERT (
						[THING]
						,[PERSONORGROUP]
						,[ACCESSRIGHTS]
						,[ID_GRUPPO_TRASM]
						,[CHA_TIPO_DIRITTO]
						,[NOTE]
						,[DTA_REVOCA]
						,[ID_UTENTE_REV]
						,[ID_RUOLO_REV]
						,[HIDE_DOC_VERSIONS]
						)
					VALUES (
						SOURCE.[THING]
						,SOURCE.[PERSONORGROUP]
						,SOURCE.[ACCESSRIGHTS]
						,SOURCE.[ID_GRUPPO_TRASM]
						,SOURCE.[CHA_TIPO_DIRITTO]
						,SOURCE.[NOTE]
						,SOURCE.[DTA_REVOCA]
						,SOURCE.[ID_UTENTE_REV]
						,SOURCE.[ID_RUOLO_REV]
						,SOURCE.[HIDE_DOC_VERSIONS]
					);' AS NVARCHAR(MAX))
							  
				PRINT @sql_string;
			
				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DELETED_SECURITY (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DELETED_SECURITY (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- **********************
				-- DPA_ASS_TEMPLATES_FASC
				-- **********************
				
				SET @sql_string = CAST(N'MERGE DPA_ASS_TEMPLATES_FASC AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							  ,[ID_OGGETTO]
							  ,[ID_TEMPLATE]
							  ,[ID_PROJECT]
							  ,[VALORE_OGGETTO_DB]
							  ,[ANNO]
							  ,[ID_AOO_RF]
							  ,[CODICE_DB]
							  ,[MANUAL_INSERT]
							  ,[VALORE_SC]
							  ,[DTA_INS]
						  FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_ASS_TEMPLATES_FASC] WITH (NOLOCK)
						  WHERE [ID_PROJECT] IN 
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(N'
							)
						)
					AS SOURCE ([SYSTEM_ID]
							  ,[ID_OGGETTO]
							  ,[ID_TEMPLATE]
							  ,[ID_PROJECT]
							  ,[VALORE_OGGETTO_DB]
							  ,[ANNO]
							  ,[ID_AOO_RF]
							  ,[CODICE_DB]
							  ,[MANUAL_INSERT]
							  ,[VALORE_SC]
							  ,[DTA_INS])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							   [SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							  ,[ID_OGGETTO] = SOURCE.[ID_OGGETTO]
							  ,[ID_TEMPLATE] = SOURCE.[ID_TEMPLATE]
							  ,[ID_PROJECT] = SOURCE.[ID_PROJECT]
							  ,[VALORE_OGGETTO_DB] = SOURCE.[VALORE_OGGETTO_DB]
							  ,[ANNO] = SOURCE.[ANNO]
							  ,[ID_AOO_RF] = SOURCE.[ID_AOO_RF]
							  ,[CODICE_DB] = SOURCE.[CODICE_DB]
							  ,[MANUAL_INSERT] = SOURCE.[MANUAL_INSERT]
							  ,[VALORE_SC] = SOURCE.[VALORE_SC]
							  ,[DTA_INS] = SOURCE.[DTA_INS]
					WHEN NOT MATCHED THEN
						INSERT ([SYSTEM_ID]
							  ,[ID_OGGETTO]
							  ,[ID_TEMPLATE]
							  ,[ID_PROJECT]
							  ,[VALORE_OGGETTO_DB]
							  ,[ANNO]
							  ,[ID_AOO_RF]
							  ,[CODICE_DB]
							  ,[MANUAL_INSERT]
							  ,[VALORE_SC]
							  ,[DTA_INS])
						VALUES (SOURCE.[SYSTEM_ID]
							  ,SOURCE.[ID_OGGETTO]
							  ,SOURCE.[ID_TEMPLATE]
							  ,SOURCE.[ID_PROJECT]
							  ,SOURCE.[VALORE_OGGETTO_DB]
							  ,SOURCE.[ANNO]
							  ,SOURCE.[ID_AOO_RF]
							  ,SOURCE.[CODICE_DB]
							  ,SOURCE.[MANUAL_INSERT]
							  ,SOURCE.[VALORE_SC]
							  ,SOURCE.[DTA_INS]);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_ASS_TEMPLATES_FASC - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_ASS_TEMPLATES_FASC'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ************
				-- TRASMISSIONI
				-- ************
				
				SET @sql_string = CAST(N'MERGE DPA_TRASMISSIONE AS TARGET
					USING ( 	
						  SELECT [SYSTEM_ID]
							  ,[ID_RUOLO_IN_UO]
							  ,[ID_PEOPLE]
							  ,[CHA_TIPO_OGGETTO]
							  ,[ID_PROFILE]
							  ,[ID_PROJECT]
							  ,[DTA_INVIO]
							  ,[VAR_NOTE_GENERALI]
							  ,[CHA_CESSIONE]
							  ,[CHA_SALVATA_CON_CESSIONE]
							  ,[ID_PEOPLE_DELEGATO]
						  FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_TRASMISSIONE] WITH (NOLOCK)
						  WHERE [ID_PROJECT] IN 
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(N'
							)
						)
					AS SOURCE ([SYSTEM_ID]
							  ,[ID_RUOLO_IN_UO]
							  ,[ID_PEOPLE]
							  ,[CHA_TIPO_OGGETTO]
							  ,[ID_PROFILE]
							  ,[ID_PROJECT]
							  ,[DTA_INVIO]
							  ,[VAR_NOTE_GENERALI]
							  ,[CHA_CESSIONE]
							  ,[CHA_SALVATA_CON_CESSIONE]
							  ,[ID_PEOPLE_DELEGATO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							   [SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							  ,[ID_RUOLO_IN_UO] = SOURCE.[ID_RUOLO_IN_UO]
							  ,[ID_PEOPLE] = SOURCE.[ID_PEOPLE]
							  ,[CHA_TIPO_OGGETTO] = SOURCE.[CHA_TIPO_OGGETTO]
							  ,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							  ,[ID_PROJECT] = SOURCE.[ID_PROJECT]
							  ,[DTA_INVIO] = SOURCE.[DTA_INVIO]
							  ,[VAR_NOTE_GENERALI] = SOURCE.[VAR_NOTE_GENERALI]
							  ,[CHA_CESSIONE] = SOURCE.[CHA_CESSIONE]
							  ,[CHA_SALVATA_CON_CESSIONE] = SOURCE.[CHA_SALVATA_CON_CESSIONE]
							  ,[ID_PEOPLE_DELEGATO] = SOURCE.[ID_PEOPLE_DELEGATO]
					WHEN NOT MATCHED THEN
						INSERT ([SYSTEM_ID]
							  ,[ID_RUOLO_IN_UO]
							  ,[ID_PEOPLE]
							  ,[CHA_TIPO_OGGETTO]
							  ,[ID_PROFILE]
							  ,[ID_PROJECT]
							  ,[DTA_INVIO]
							  ,[VAR_NOTE_GENERALI]
							  ,[CHA_CESSIONE]
							  ,[CHA_SALVATA_CON_CESSIONE]
							  ,[ID_PEOPLE_DELEGATO])
						VALUES (SOURCE.[SYSTEM_ID]
							  ,SOURCE.[ID_RUOLO_IN_UO]
							  ,SOURCE.[ID_PEOPLE]
							  ,SOURCE.[CHA_TIPO_OGGETTO]
							  ,SOURCE.[ID_PROFILE]
							  ,SOURCE.[ID_PROJECT]
							  ,SOURCE.[DTA_INVIO]
							  ,SOURCE.[VAR_NOTE_GENERALI]
							  ,SOURCE.[CHA_CESSIONE]
							  ,SOURCE.[CHA_SALVATA_CON_CESSIONE]
							  ,SOURCE.[ID_PEOPLE_DELEGATO]);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della TRASMISSIONI (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella TRASMISSIONI (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- *****************
				-- DPA_TRASM_SINGOLA
				-- *****************
				
				SET @sql_string = CAST(N'MERGE DPA_TRASM_SINGOLA AS TARGET
				USING ( 	
					SELECT [SYSTEM_ID]
						  ,[ID_RAGIONE]
						  ,[ID_TRASMISSIONE]
						  ,[CHA_TIPO_DEST]
						  ,[ID_CORR_GLOBALE]
						  ,[VAR_NOTE_SING]
						  ,[CHA_TIPO_TRASM]
						  ,[DTA_SCADENZA]
						  ,[ID_TRASM_UTENTE]
						  ,[CHA_SET_EREDITA]
						  ,[HIDE_DOC_VERSIONS]
					FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_TRASM_SINGOLA] WITH (NOLOCK)
					WHERE ID_TRASMISSIONE IN 
						(
						SELECT SYSTEM_ID 
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TRASMISSIONE WITH (NOLOCK)
						WHERE [ID_PROJECT] IN 
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(N'
							)
						)			
				)
				AS SOURCE ([SYSTEM_ID]
						  ,[ID_RAGIONE]
						  ,[ID_TRASMISSIONE]
						  ,[CHA_TIPO_DEST]
						  ,[ID_CORR_GLOBALE]
						  ,[VAR_NOTE_SING]
						  ,[CHA_TIPO_TRASM]
						  ,[DTA_SCADENZA]
						  ,[ID_TRASM_UTENTE]
						  ,[CHA_SET_EREDITA]
						  ,[HIDE_DOC_VERSIONS])
				ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
				WHEN MATCHED THEN
					UPDATE SET
						   [SYSTEM_ID] = SOURCE.[SYSTEM_ID]
						  ,[ID_RAGIONE] = SOURCE.[ID_RAGIONE]
						  ,[ID_TRASMISSIONE] = SOURCE.[ID_TRASMISSIONE]
						  ,[CHA_TIPO_DEST] = SOURCE.[CHA_TIPO_DEST]
						  ,[ID_CORR_GLOBALE] = SOURCE.[ID_CORR_GLOBALE]
						  ,[VAR_NOTE_SING] = SOURCE.[VAR_NOTE_SING]
						  ,[CHA_TIPO_TRASM] = SOURCE.[CHA_TIPO_TRASM]
						  ,[DTA_SCADENZA] = SOURCE.[DTA_SCADENZA]
						  ,[ID_TRASM_UTENTE] = SOURCE.[ID_TRASM_UTENTE]
						  ,[CHA_SET_EREDITA] = SOURCE.[CHA_SET_EREDITA]
						  ,[HIDE_DOC_VERSIONS] = SOURCE.[HIDE_DOC_VERSIONS]
				WHEN NOT MATCHED THEN
					INSERT ([SYSTEM_ID]
						  ,[ID_RAGIONE]
						  ,[ID_TRASMISSIONE]
						  ,[CHA_TIPO_DEST]
						  ,[ID_CORR_GLOBALE]
						  ,[VAR_NOTE_SING]
						  ,[CHA_TIPO_TRASM]
						  ,[DTA_SCADENZA]
						  ,[ID_TRASM_UTENTE]
						  ,[CHA_SET_EREDITA]
						  ,[HIDE_DOC_VERSIONS])
					VALUES (SOURCE.[SYSTEM_ID]
						  ,SOURCE.[ID_RAGIONE]
						  ,SOURCE.[ID_TRASMISSIONE]
						  ,SOURCE.[CHA_TIPO_DEST]
						  ,SOURCE.[ID_CORR_GLOBALE]
						  ,SOURCE.[VAR_NOTE_SING]
						  ,SOURCE.[CHA_TIPO_TRASM]
						  ,SOURCE.[DTA_SCADENZA]
						  ,SOURCE.[ID_TRASM_UTENTE]
						  ,SOURCE.[CHA_SET_EREDITA]
						  ,SOURCE.[HIDE_DOC_VERSIONS]);' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_TRASM_SINGOLA (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_TRASM_SINGOLA (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- ****************
				-- DPA_TRASM_UTENTE
				-- ****************
				
				SET @sql_string = CAST(N'MERGE DPA_TRASM_UTENTE AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							  ,[ID_TRASM_SINGOLA]
							  ,[ID_PEOPLE]
							  ,[DTA_VISTA]
							  ,[DTA_ACCETTATA]
							  ,[DTA_RIFIUTATA]
							  ,[DTA_RISPOSTA]
							  ,[CHA_VISTA]
							  ,[CHA_ACCETTATA]
							  ,[CHA_RIFIUTATA]
							  ,[VAR_NOTE_ACC]
							  ,[VAR_NOTE_RIF]
							  ,[CHA_VALIDA]
							  ,[ID_TRASM_RISP_SING]
							  ,[CHA_IN_TODOLIST]
							  ,[DTA_RIMOZIONE_TODOLIST]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_ACCETTATA_DELEGATO]
							  ,[CHA_VISTA_DELEGATO]
							  ,[CHA_RIFIUTATA_DELEGATO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_TRASM_UTENTE] WITH (NOLOCK)
						WHERE ID_TRASM_SINGOLA IN
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TRASM_SINGOLA WITH (NOLOCK)
							WHERE ID_TRASMISSIONE IN 
								(
								SELECT SYSTEM_ID 
								FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TRASMISSIONE WITH (NOLOCK)
								WHERE ID_PROJECT IN
									(
									' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(N'
									)
								)
							)		
						)
					AS SOURCE ([SYSTEM_ID]
							  ,[ID_TRASM_SINGOLA]
							  ,[ID_PEOPLE]
							  ,[DTA_VISTA]
							  ,[DTA_ACCETTATA]
							  ,[DTA_RIFIUTATA]
							  ,[DTA_RISPOSTA]
							  ,[CHA_VISTA]
							  ,[CHA_ACCETTATA]
							  ,[CHA_RIFIUTATA]
							  ,[VAR_NOTE_ACC]
							  ,[VAR_NOTE_RIF]
							  ,[CHA_VALIDA]
							  ,[ID_TRASM_RISP_SING]
							  ,[CHA_IN_TODOLIST]
							  ,[DTA_RIMOZIONE_TODOLIST]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_ACCETTATA_DELEGATO]
							  ,[CHA_VISTA_DELEGATO]
							  ,[CHA_RIFIUTATA_DELEGATO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							   [SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							  ,[ID_TRASM_SINGOLA] = SOURCE.[ID_TRASM_SINGOLA]
							  ,[ID_PEOPLE] = SOURCE.[ID_PEOPLE]
							  ,[DTA_VISTA] = SOURCE.[DTA_VISTA]
							  ,[DTA_ACCETTATA] = SOURCE.[DTA_ACCETTATA]
							  ,[DTA_RIFIUTATA] = SOURCE.[DTA_RIFIUTATA]
							  ,[DTA_RISPOSTA] = SOURCE.[DTA_RISPOSTA]
							  ,[CHA_VISTA] = SOURCE.[CHA_VISTA]
							  ,[CHA_ACCETTATA] = SOURCE.[CHA_ACCETTATA]
							  ,[CHA_RIFIUTATA] = SOURCE.[CHA_RIFIUTATA]
							  ,[VAR_NOTE_ACC] = SOURCE.[VAR_NOTE_ACC]
							  ,[VAR_NOTE_RIF] = SOURCE.[VAR_NOTE_RIF]
							  ,[CHA_VALIDA] = SOURCE.[CHA_VALIDA]
							  ,[ID_TRASM_RISP_SING] = SOURCE.[ID_TRASM_RISP_SING]
							  ,[CHA_IN_TODOLIST] = SOURCE.[CHA_IN_TODOLIST]
							  ,[DTA_RIMOZIONE_TODOLIST] = SOURCE.[DTA_RIMOZIONE_TODOLIST]
							  ,[ID_PEOPLE_DELEGATO] = SOURCE.[ID_PEOPLE_DELEGATO]
							  ,[CHA_ACCETTATA_DELEGATO] = SOURCE.[CHA_ACCETTATA_DELEGATO]
							  ,[CHA_VISTA_DELEGATO] = SOURCE.[CHA_VISTA_DELEGATO]
							  ,[CHA_RIFIUTATA_DELEGATO] = SOURCE.[CHA_RIFIUTATA_DELEGATO]
					WHEN NOT MATCHED THEN
						INSERT ([SYSTEM_ID]
							  ,[ID_TRASM_SINGOLA]
							  ,[ID_PEOPLE]
							  ,[DTA_VISTA]
							  ,[DTA_ACCETTATA]
							  ,[DTA_RIFIUTATA]
							  ,[DTA_RISPOSTA]
							  ,[CHA_VISTA]
							  ,[CHA_ACCETTATA]
							  ,[CHA_RIFIUTATA]
							  ,[VAR_NOTE_ACC]
							  ,[VAR_NOTE_RIF]
							  ,[CHA_VALIDA]
							  ,[ID_TRASM_RISP_SING]
							  ,[CHA_IN_TODOLIST]
							  ,[DTA_RIMOZIONE_TODOLIST]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_ACCETTATA_DELEGATO]
							  ,[CHA_VISTA_DELEGATO]
							  ,[CHA_RIFIUTATA_DELEGATO])
						VALUES (SOURCE.[SYSTEM_ID]
							  ,SOURCE.[ID_TRASM_SINGOLA]
							  ,SOURCE.[ID_PEOPLE]
							  ,SOURCE.[DTA_VISTA]
							  ,SOURCE.[DTA_ACCETTATA]
							  ,SOURCE.[DTA_RIFIUTATA]
							  ,SOURCE.[DTA_RISPOSTA]
							  ,SOURCE.[CHA_VISTA]
							  ,SOURCE.[CHA_ACCETTATA]
							  ,SOURCE.[CHA_RIFIUTATA]
							  ,SOURCE.[VAR_NOTE_ACC]
							  ,SOURCE.[VAR_NOTE_RIF]
							  ,SOURCE.[CHA_VALIDA]
							  ,SOURCE.[ID_TRASM_RISP_SING]
							  ,SOURCE.[CHA_IN_TODOLIST]
							  ,SOURCE.[DTA_RIMOZIONE_TODOLIST]
							  ,SOURCE.[ID_PEOPLE_DELEGATO]
							  ,SOURCE.[CHA_ACCETTATA_DELEGATO]
							  ,SOURCE.[CHA_VISTA_DELEGATO]
							  ,SOURCE.[CHA_RIFIUTATA_DELEGATO]);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_TRASM_UTENTE (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_TRASM_UTENTE (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
					
				
				
				-- ********
				-- DPA_NOTE
				-- ********
				
				SET @sql_string = CAST(N'MERGE DPA_NOTE AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[TESTO]
							,[DATACREAZIONE]
							,[IDUTENTECREATORE]
							,[IDRUOLOCREATORE]
							,[TIPOVISIBILITA]
							,[TIPOOGGETTOASSOCIATO]
							,[IDOGGETTOASSOCIATO]
							,[IDPEOPLEDELEGATO]
							,[IDRFASSOCIATO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_NOTE] WITH (NOLOCK)
						WHERE [TIPOOGGETTOASSOCIATO] = ''F''
						AND [IDOGGETTOASSOCIATO] IN
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(N'
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[TESTO]
							,[DATACREAZIONE]
							,[IDUTENTECREATORE]
							,[IDRUOLOCREATORE]
							,[TIPOVISIBILITA]
							,[TIPOOGGETTOASSOCIATO]
							,[IDOGGETTOASSOCIATO]
							,[IDPEOPLEDELEGATO]
							,[IDRFASSOCIATO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[TESTO] = SOURCE.[TESTO]
							,[DATACREAZIONE] = SOURCE.[DATACREAZIONE]
							,[IDUTENTECREATORE] = SOURCE.[IDUTENTECREATORE]
							,[IDRUOLOCREATORE] = SOURCE.[IDRUOLOCREATORE]
							,[TIPOVISIBILITA] = SOURCE.[TIPOVISIBILITA]
							,[TIPOOGGETTOASSOCIATO] = SOURCE.[TIPOOGGETTOASSOCIATO]
							,[IDOGGETTOASSOCIATO] = SOURCE.[IDOGGETTOASSOCIATO]
							,[IDPEOPLEDELEGATO] = SOURCE.[IDPEOPLEDELEGATO]
							,[IDRFASSOCIATO] = SOURCE.[IDRFASSOCIATO]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[TESTO]
							,[DATACREAZIONE]
							,[IDUTENTECREATORE]
							,[IDRUOLOCREATORE]
							,[TIPOVISIBILITA]
							,[TIPOOGGETTOASSOCIATO]
							,[IDOGGETTOASSOCIATO]
							,[IDPEOPLEDELEGATO]
							,[IDRFASSOCIATO]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[TESTO]
							,SOURCE.[DATACREAZIONE]
							,SOURCE.[IDUTENTECREATORE]
							,SOURCE.[IDRUOLOCREATORE]
							,SOURCE.[TIPOVISIBILITA]
							,SOURCE.[TIPOOGGETTOASSOCIATO]
							,SOURCE.[IDOGGETTOASSOCIATO]
							,SOURCE.[IDPEOPLEDELEGATO]
							,SOURCE.[IDRFASSOCIATO]
						);' AS NVARCHAR(MAX))
						
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_NOTE (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_NOTE (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- *******************
				-- DPA_LOG (Fascicoli)
				-- *******************
				
				SET @sql_string = CAST(N'MERGE DPA_LOG AS TARGET
					USING ( 	
						SELECT 
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							,[ID_TRASM_SINGOLA]
							,[CHECK_NOTIFY]
							,[DESC_PRODUCER]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_LOG] WITH (NOLOCK)
						WHERE [VAR_OGGETTO] = ''FASCICOLO''
						AND [ID_OGGETTO] IN
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(N'
							)
						)
					AS SOURCE (
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							,[ID_TRASM_SINGOLA]
							,[CHECK_NOTIFY]
							,[DESC_PRODUCER]
							)
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[USERID_OPERATORE] = SOURCE.[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE] = SOURCE.[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE] = SOURCE.[ID_GRUPPO_OPERATORE]
							,[ID_AMM] = SOURCE.[ID_AMM]
							,[DTA_AZIONE] = SOURCE.[DTA_AZIONE]
							,[VAR_OGGETTO] = SOURCE.[VAR_OGGETTO]
							,[ID_OGGETTO] = SOURCE.[ID_OGGETTO]
							,[VAR_DESC_OGGETTO] = SOURCE.[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE] = SOURCE.[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE] = SOURCE.[VAR_DESC_AZIONE]
							,[CHA_ESITO] = SOURCE.[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION] = SOURCE.[VAR_COD_WORKING_APPLICATION]
							,[ID_TRASM_SINGOLA] = SOURCE.[ID_TRASM_SINGOLA]
							,[CHECK_NOTIFY] = SOURCE.[CHECK_NOTIFY]
							,[DESC_PRODUCER] = SOURCE.[DESC_PRODUCER]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							,[ID_TRASM_SINGOLA]
							,[CHECK_NOTIFY]
							,[DESC_PRODUCER]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[USERID_OPERATORE]
							,SOURCE.[ID_PEOPLE_OPERATORE]
							,SOURCE.[ID_GRUPPO_OPERATORE]
							,SOURCE.[ID_AMM]
							,SOURCE.[DTA_AZIONE]
							,SOURCE.[VAR_OGGETTO]
							,SOURCE.[ID_OGGETTO]
							,SOURCE.[VAR_DESC_OGGETTO]
							,SOURCE.[VAR_COD_AZIONE]
							,SOURCE.[VAR_DESC_AZIONE]
							,SOURCE.[CHA_ESITO]
							,SOURCE.[VAR_COD_WORKING_APPLICATION]
							,SOURCE.[ID_TRASM_SINGOLA]
							,SOURCE.[CHECK_NOTIFY]
							,SOURCE.[DESC_PRODUCER]
						);' AS NVARCHAR(MAX))
						
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_LOG (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_LOG (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- ***************************
				-- DPA_LOG_STORICO (Fascicoli)
				-- ***************************

				
				SET @sql_string = CAST(N'MERGE DPA_LOG_STORICO AS TARGET
					USING ( 	
						SELECT 
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_LOG_STORICO] WITH (NOLOCK)
						WHERE [VAR_OGGETTO] = ''FASCICOLO''
						AND [ID_OGGETTO] IN
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(N'
							)
						)
					AS SOURCE (
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							)
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[USERID_OPERATORE] = SOURCE.[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE] = SOURCE.[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE] = SOURCE.[ID_GRUPPO_OPERATORE]
							,[ID_AMM] = SOURCE.[ID_AMM]
							,[DTA_AZIONE] = SOURCE.[DTA_AZIONE]
							,[VAR_OGGETTO] = SOURCE.[VAR_OGGETTO]
							,[ID_OGGETTO] = SOURCE.[ID_OGGETTO]
							,[VAR_DESC_OGGETTO] = SOURCE.[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE] = SOURCE.[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE] = SOURCE.[VAR_DESC_AZIONE]
							,[CHA_ESITO] = SOURCE.[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION] = SOURCE.[VAR_COD_WORKING_APPLICATION]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[USERID_OPERATORE]
							,SOURCE.[ID_PEOPLE_OPERATORE]
							,SOURCE.[ID_GRUPPO_OPERATORE]
							,SOURCE.[ID_AMM]
							,SOURCE.[DTA_AZIONE]
							,SOURCE.[VAR_OGGETTO]
							,SOURCE.[ID_OGGETTO]
							,SOURCE.[VAR_DESC_OGGETTO]
							,SOURCE.[VAR_COD_AZIONE]
							,SOURCE.[VAR_DESC_AZIONE]
							,SOURCE.[CHA_ESITO]
							,SOURCE.[VAR_COD_WORKING_APPLICATION]
						);' AS NVARCHAR(MAX))
						
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_LOG_STORICO (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_LOG_STORICO (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID







				-- *************************************************************************
				-- Gestione del flag CHA_IN_ARCHIVIO (1 se è una copia, altrimenti 0)
				-- Imposta a 0 tutti i fascicoli coinvolti e poi a 1 quelli portati in COPIA
				-- *************************************************************************

				SET @sql_string = CAST(N'
					UPDATE PROJECT SET CHA_IN_ARCHIVIO = 0
					WHERE SYSTEM_ID IN
						(
						' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(N'
						)' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento del flag CHA_IN_ARCHIVIO(0) per la tabella PROJECT (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento flag CHA_IN_ARCHIVIO(0) per la tabella PROJECT (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				SET @sql_string = CAST(N'
					UPDATE PROJECT SET CHA_IN_ARCHIVIO = 1
					WHERE SYSTEM_ID IN
						(
						' AS NVARCHAR(MAX)) + CAST(@sql_filtroProject AS NVARCHAR(MAX)) + CAST(N'							
						)
					AND
					SYSTEM_ID IN
						(
						SELECT PROJECT_ID
						FROM ARCHIVE_TEMPPROJECT
						WHERE TIPOTRASFERIMENTO_VERSAMENTO = ''COPIA''
						)' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento del flag CHA_IN_ARCHIVIO(1) per la tabella PROJECT (Fascicoli) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento flag CHA_IN_ARCHIVIO(1) per la tabella PROJECT (Fascicoli)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID








				
				
				-- Elimina gli oggetti trasferiti dalla tabella temp della transazione
				--
				delete from ARCHIVE_TEMPTRANSFERPROJECT where PROJECT_ID in
				(
				select ID from #oggettiDaTrasferire
				)
				
				COMMIT TRANSACTION T1

			END
		ELSE
			SET @hasNext = 0

		

		END






	-- ***************************************************************
	-- DOCUMENTI: tutti i documenti principali e i rispettivi allegati
	-- ***************************************************************

	-- Finchè ci sono oggetti da trasferire e non è passato il tempo limite
	--
	SET @hasNext = 1

	WHILE (@hasNext = 1 AND GETDATE()<@timeLimit)
		BEGIN
	
		-- Appoggio gli oggetti da trasferire in una tabella #temp
		--
		DELETE FROM #oggettiDaTrasferire

		IF (@NumberOfObjectsPerTransaction > 0)
			SET @sql_string = CAST(N'
				INSERT INTO #oggettiDaTrasferire (ID)
				SELECT TOP ' AS NVARCHAR(MAX)) + CAST(@NumberOfObjectsPerTransaction AS NVARCHAR(MAX)) + CAST(N' PROFILE_ID
				FROM ARCHIVE_TEMPTRANSFERPROFILE 
				WHERE TRANSFER_ID = ' AS NVARCHAR(MAX)) + CAST(@TransferID AS NVARCHAR(MAX))
		ELSE
			SET @sql_string = CAST(N'
				INSERT INTO #oggettiDaTrasferire (ID)
				SELECT PROFILE_ID
				FROM ARCHIVE_TEMPTRANSFERPROFILE 
				WHERE TRANSFER_ID = ' AS NVARCHAR(MAX)) + CAST(@TransferID AS NVARCHAR(MAX))		

		print @sql_string

		EXECUTE sp_executesql @sql_string;

		
		
		SELECT @transactionObjetcs=COUNT(*) FROM #oggettiDaTrasferire
		
		print 'Transaction object (profile):' + cast(@transactionObjetcs as varchar(10))
		
		IF (@transactionObjetcs > 0)
			BEGIN
			
				SET @sql_filtroProfile = 'SELECT ID FROM #oggettiDaTrasferire'
			
				BEGIN TRANSACTION T1
				
				PRINT 'Numero oggetti trasferiti in questa transazione: ' + cast(@transactionObjetcs as varchar(10))



				-- ******************
				-- PROJECT_COMPONENTS
				-- ******************
				
				SET @sql_string = CAST(N'
				MERGE PROJECT_COMPONENTS AS TARGET
					USING ( 	
						SELECT [DESCRIPTION]
						  ,[LIBRARY]
						  ,[TYPE]
						  ,[PROJECT_ID]
						  ,[LINK]
						  ,[COMP_ORDER]
						  ,[VAR_CODICE_COMP]
						  ,[PROT_TIT]
						  ,[DTA_CLASS]
						  ,[CHA_FASC_PRIMARIA]
			    FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[PROJECT_COMPONENTS] WITH (NOLOCK)
				WHERE LINK IN (
				' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
				)) 
				AS SOURCE ([DESCRIPTION]
				  ,[LIBRARY]
				  ,[TYPE]
				  ,[PROJECT_ID]
				  ,[LINK]
				  ,[COMP_ORDER]
				  ,[VAR_CODICE_COMP]
				  ,[PROT_TIT]
				  ,[DTA_CLASS]
				  ,[CHA_FASC_PRIMARIA])
					ON (TARGET.PROJECT_ID = SOURCE.PROJECT_ID AND TARGET.LINK = SOURCE.LINK)
					WHEN MATCHED THEN
						UPDATE SET
							[DESCRIPTION] = SOURCE.[DESCRIPTION]
						  ,[LIBRARY] = SOURCE.[LIBRARY]
						  ,[TYPE] = SOURCE.[TYPE]
						  ,[PROJECT_ID] = SOURCE.[PROJECT_ID]
						  ,[LINK] = SOURCE.[LINK]
						  ,[COMP_ORDER] = SOURCE.[COMP_ORDER]
						  ,[VAR_CODICE_COMP] = SOURCE.[VAR_CODICE_COMP]
						  ,[PROT_TIT] = SOURCE.[PROT_TIT]
						  ,[DTA_CLASS] = SOURCE.[DTA_CLASS]
						  ,[CHA_FASC_PRIMARIA] = SOURCE.[CHA_FASC_PRIMARIA]
					WHEN NOT MATCHED THEN
						INSERT ([DESCRIPTION]
							  ,[LIBRARY]
							  ,[TYPE]
							  ,[PROJECT_ID]
							  ,[LINK]
							  ,[COMP_ORDER]
							  ,[VAR_CODICE_COMP]
							  ,[PROT_TIT]
							  ,[DTA_CLASS]
							  ,[CHA_FASC_PRIMARIA])
						VALUES (SOURCE.[DESCRIPTION]
							  ,SOURCE.[LIBRARY]
							  ,SOURCE.[TYPE]
							  ,SOURCE.[PROJECT_ID]
							  ,SOURCE.[LINK]
							  ,SOURCE.[COMP_ORDER]
							  ,SOURCE.[VAR_CODICE_COMP]
							  ,SOURCE.[PROT_TIT]
							  ,SOURCE.[DTA_CLASS]
							  ,SOURCE.[CHA_FASC_PRIMARIA]);' AS NVARCHAR(MAX))
							  
				PRINT @sql_string;
			
				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella PROJECT_COMPONENTS - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella PROJECT_COMPONENTS'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

/*
				WHERE SYSTEM_ID IN
					(
					' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
					)
				OR ID_DOCUMENTO_PRINCIPALE IN
					(
					' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
					)			


				SELECT SYSTEM_ID 
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
				WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=SYSTEM_ID)
				UNION
				SELECT SYSTEM_ID 
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
				WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=ID_DOCUMENTO_PRINCIPALE)
*/

				SET @sql_string = CAST(N'MERGE PROFILE AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							  ,[DOCNUMBER]
							  ,[DOCNAME]
							  ,[TYPIST]
							  ,[AUTHOR]
							  ,[DOCUMENTTYPE]
							  ,[LAST_EDITED_BY]
							  ,[LAST_LOCKED_BY]
							  ,[LAST_ACCESS_ID]
							  ,[APPLICATION]
							  ,[FORM]
							  ,[STORAGETYPE]
							  ,[RETENTION]
							  ,[PROCESS_DATE]
							  ,[CREATION_DATE]
							  ,[CREATION_TIME]
							  ,[LAST_EDIT_DATE]
							  ,[LAST_EDIT_TIME]
							  ,[LAST_ACCESS_DATE]
							  ,[LAST_ACCESS_TIME]
							  ,[ARCHIVE_DATE]
							  ,[ARCHIVE_ID]
							  ,[KEYSTROKES]
							  ,[EDITING_TIME]
							  ,[TYPE_TIME]
							  ,[BILLABLE]
							  ,[FULLTEXT]
							  ,[FULLTEXT_DATE]
							  ,[STATUS]
							  ,[DEFAULT_RIGHTS]
							  ,[ABSTRACT]
							  ,[PATH]
							  ,[DOCSERVER_LOC]
							  ,[DOCSERVER_OS]
							  ,[PREV_SERVER_LOC]
							  ,[PREV_SERVER_OS]
							  ,[KEYWORDS_DISPLAY]
							  ,[READONLY_DATE]
							  ,[RELATED]
							  ,[PD_PRTO_AUTHORITY]
							  ,[MAIL_ID]
							  ,[PARENTMAIL_ID]
							  ,[THREAD_NUM]
							  ,[ATTACH_NUM]
							  ,[MSG_ITEM]
							  ,[DELIVER_REC]
							  ,[EMAIL_RECEIVED]
							  ,[EMAIL_SENT]
							  ,[MAIL_MSG_ID]
							  ,[MAIL_MSG_IDX]
							  ,[VAR_CHIAVE_PROTO]
							  ,[ID_REGISTRO]
							  ,[CHA_TIPO_PROTO]
							  ,[ID_OGGETTO]
							  ,[NUM_PROTO]
							  ,[NUM_ANNO_PROTO]
							  ,[VAR_PROTO_EME]
							  ,[DTA_PROTO_EME]
							  ,[VAR_COGNOME_EME]
							  ,[VAR_NOME_EME]
							  ,[ID_PARENT]
							  ,[DTA_PROTO]
							  ,[CHA_MOD_OGGETTO]
							  ,[CHA_MOD_MITT_DEST]
							  ,[CHA_MOD_MITT_INT]
							  ,[CHA_MOD_DEST_OCC]
							  ,[DTA_PROTO_IN]
							  ,[VAR_PROTO_IN]
							  ,[ID_ANNULLATORE]
							  ,[DTA_ANNULLA]
							  ,[VAR_AUT_ANNULLA]
							  ,[VAR_SEGNATURA]
							  ,[CHA_DA_PROTO]
							  ,[VAR_NOTE]
							  ,[ID_TIPO_ATTO]
							  ,[CHA_ASSEGNATO]
							  ,[CHA_IMG]
							  ,[CHA_FASCICOLATO]
							  ,[CHA_INVIO_CONFERMA]
							  ,[CHA_CONGELATO]
							  ,[CHA_CONSOLIDATO]
							  ,[CHA_PRIVATO]
							  ,[VAR_NUM_OGGETTO]
							  ,[VAR_COMM_REF]
							  ,[CHA_EVIDENZA]
							  ,[VAR_SEDE]
							  ,[VAR_PROF_OGGETTO]
							  ,[ID_PEOPLE_PROT]
							  ,[ID_RUOLO_PROT]
							  ,[ID_UO_PROT]
							  ,[ID_UO_REF]
							  ,[ID_RUOLO_CREATORE]
							  ,[ID_UO_CREATORE]
							  ,[CHA_INTEROP]
							  ,[DTA_SCADENZA]
							  ,[CHA_PERSONALE]
							  ,[CHA_IN_CESTINO]
							  ,[VAR_NOTE_CESTINO]
							  ,[ID_DOCUMENTO_PRINCIPALE]
							  ,[CHA_IN_ARCHIVIO]
							  ,[CHA_FIRMATO]
							  ,[CHA_RIFF_MITT]
							  ,[PROT_TIT]
							  ,[NUM_IN_FASC]
							  ,[ID_FASC_PROT_TIT]
							  ,[NUM_PROT_TIT]
							  ,[ID_TITOLARIO]
							  ,[DTA_PROTO_TIT]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_DOCUMENTO_DA_PEC]
							  ,[CHA_UNLOCKED_FINAL_STATE]
							  ,[CONSOLIDATION_STATE]
							  ,[CONSOLIDATION_AUTHOR]
							  ,[CONSOLIDATION_ROLE]
							  ,[CONSOLIDATION_DATE]
							  ,[LAST_FORWARD]
							  ,[FORWARDING_SOURCE]
							  ,[PRINTS_NUM]
							  ,[CHA_COD_T_A]
							  ,[ID_VECCHIO_DOCUMENTO]
							  ,[COD_EXT_APP]
							  ,[MIS_OBIETTIVO]
							  ,[FASE]
							  ,[ID_TIPO_COMUNICAZIONE]
							  ,[ID_CENTRO_DI_COSTO]
							  ,[ID_OBIETTIVO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[PROFILE] WITH (NOLOCK)
						WHERE SYSTEM_ID IN
							(
							SELECT SYSTEM_ID 
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=SYSTEM_ID)
							UNION
							SELECT SYSTEM_ID 
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=ID_DOCUMENTO_PRINCIPALE)							
							)
						)
					AS SOURCE ([SYSTEM_ID]
							  ,[DOCNUMBER]
							  ,[DOCNAME]
							  ,[TYPIST]
							  ,[AUTHOR]
							  ,[DOCUMENTTYPE]
							  ,[LAST_EDITED_BY]
							  ,[LAST_LOCKED_BY]
							  ,[LAST_ACCESS_ID]
							  ,[APPLICATION]
							  ,[FORM]
							  ,[STORAGETYPE]
							  ,[RETENTION]
							  ,[PROCESS_DATE]
							  ,[CREATION_DATE]
							  ,[CREATION_TIME]
							  ,[LAST_EDIT_DATE]
							  ,[LAST_EDIT_TIME]
							  ,[LAST_ACCESS_DATE]
							  ,[LAST_ACCESS_TIME]
							  ,[ARCHIVE_DATE]
							  ,[ARCHIVE_ID]
							  ,[KEYSTROKES]
							  ,[EDITING_TIME]
							  ,[TYPE_TIME]
							  ,[BILLABLE]
							  ,[FULLTEXT]
							  ,[FULLTEXT_DATE]
							  ,[STATUS]
							  ,[DEFAULT_RIGHTS]
							  ,[ABSTRACT]
							  ,[PATH]
							  ,[DOCSERVER_LOC]
							  ,[DOCSERVER_OS]
							  ,[PREV_SERVER_LOC]
							  ,[PREV_SERVER_OS]
							  ,[KEYWORDS_DISPLAY]
							  ,[READONLY_DATE]
							  ,[RELATED]
							  ,[PD_PRTO_AUTHORITY]
							  ,[MAIL_ID]
							  ,[PARENTMAIL_ID]
							  ,[THREAD_NUM]
							  ,[ATTACH_NUM]
							  ,[MSG_ITEM]
							  ,[DELIVER_REC]
							  ,[EMAIL_RECEIVED]
							  ,[EMAIL_SENT]
							  ,[MAIL_MSG_ID]
							  ,[MAIL_MSG_IDX]
							  ,[VAR_CHIAVE_PROTO]
							  ,[ID_REGISTRO]
							  ,[CHA_TIPO_PROTO]
							  ,[ID_OGGETTO]
							  ,[NUM_PROTO]
							  ,[NUM_ANNO_PROTO]
							  ,[VAR_PROTO_EME]
							  ,[DTA_PROTO_EME]
							  ,[VAR_COGNOME_EME]
							  ,[VAR_NOME_EME]
							  ,[ID_PARENT]
							  ,[DTA_PROTO]
							  ,[CHA_MOD_OGGETTO]
							  ,[CHA_MOD_MITT_DEST]
							  ,[CHA_MOD_MITT_INT]
							  ,[CHA_MOD_DEST_OCC]
							  ,[DTA_PROTO_IN]
							  ,[VAR_PROTO_IN]
							  ,[ID_ANNULLATORE]
							  ,[DTA_ANNULLA]
							  ,[VAR_AUT_ANNULLA]
							  ,[VAR_SEGNATURA]
							  ,[CHA_DA_PROTO]
							  ,[VAR_NOTE]
							  ,[ID_TIPO_ATTO]
							  ,[CHA_ASSEGNATO]
							  ,[CHA_IMG]
							  ,[CHA_FASCICOLATO]
							  ,[CHA_INVIO_CONFERMA]
							  ,[CHA_CONGELATO]
							  ,[CHA_CONSOLIDATO]
							  ,[CHA_PRIVATO]
							  ,[VAR_NUM_OGGETTO]
							  ,[VAR_COMM_REF]
							  ,[CHA_EVIDENZA]
							  ,[VAR_SEDE]
							  ,[VAR_PROF_OGGETTO]
							  ,[ID_PEOPLE_PROT]
							  ,[ID_RUOLO_PROT]
							  ,[ID_UO_PROT]
							  ,[ID_UO_REF]
							  ,[ID_RUOLO_CREATORE]
							  ,[ID_UO_CREATORE]
							  ,[CHA_INTEROP]
							  ,[DTA_SCADENZA]
							  ,[CHA_PERSONALE]
							  ,[CHA_IN_CESTINO]
							  ,[VAR_NOTE_CESTINO]
							  ,[ID_DOCUMENTO_PRINCIPALE]
							  ,[CHA_IN_ARCHIVIO]
							  ,[CHA_FIRMATO]
							  ,[CHA_RIFF_MITT]
							  ,[PROT_TIT]
							  ,[NUM_IN_FASC]
							  ,[ID_FASC_PROT_TIT]
							  ,[NUM_PROT_TIT]
							  ,[ID_TITOLARIO]
							  ,[DTA_PROTO_TIT]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_DOCUMENTO_DA_PEC]
							  ,[CHA_UNLOCKED_FINAL_STATE]
							  ,[CONSOLIDATION_STATE]
							  ,[CONSOLIDATION_AUTHOR]
							  ,[CONSOLIDATION_ROLE]
							  ,[CONSOLIDATION_DATE]
							  ,[LAST_FORWARD]
							  ,[FORWARDING_SOURCE]
							  ,[PRINTS_NUM]
							  ,[CHA_COD_T_A]
							  ,[ID_VECCHIO_DOCUMENTO]
							  ,[COD_EXT_APP]
							  ,[MIS_OBIETTIVO]
							  ,[FASE]
							  ,[ID_TIPO_COMUNICAZIONE]
							  ,[ID_CENTRO_DI_COSTO]
							  ,[ID_OBIETTIVO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							 [SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							  ,[DOCNUMBER] = SOURCE.[DOCNUMBER]
							  ,[DOCNAME] = SOURCE.[DOCNAME]
							  ,[TYPIST] = SOURCE.[TYPIST]
							  ,[AUTHOR] = SOURCE.[AUTHOR]
							  ,[DOCUMENTTYPE] = SOURCE.[DOCUMENTTYPE]
							  ,[LAST_EDITED_BY] = SOURCE.[LAST_EDITED_BY]
							  ,[LAST_LOCKED_BY] = SOURCE.[LAST_LOCKED_BY]
							  ,[LAST_ACCESS_ID] = SOURCE.[LAST_ACCESS_ID]
							  ,[APPLICATION] = SOURCE.[APPLICATION]
							  ,[FORM] = SOURCE.[FORM]
							  ,[STORAGETYPE] = SOURCE.[STORAGETYPE]
							  ,[RETENTION] = SOURCE.[RETENTION]
							  ,[PROCESS_DATE] = SOURCE.[PROCESS_DATE]
							  ,[CREATION_DATE] = SOURCE.[CREATION_DATE]
							  ,[CREATION_TIME] = SOURCE.[CREATION_TIME]
							  ,[LAST_EDIT_DATE] = SOURCE.[LAST_EDIT_DATE]
							  ,[LAST_EDIT_TIME] = SOURCE.[LAST_EDIT_TIME]
							  ,[LAST_ACCESS_DATE] = SOURCE.[LAST_ACCESS_DATE]
							  ,[LAST_ACCESS_TIME] = SOURCE.[LAST_ACCESS_TIME]
							  ,[ARCHIVE_DATE] = SOURCE.[ARCHIVE_DATE]
							  ,[ARCHIVE_ID] = SOURCE.[ARCHIVE_ID]
							  ,[KEYSTROKES] = SOURCE.[KEYSTROKES]
							  ,[EDITING_TIME] = SOURCE.[EDITING_TIME]
							  ,[TYPE_TIME] = SOURCE.[TYPE_TIME]
							  ,[BILLABLE] = SOURCE.[BILLABLE]
							  ,[FULLTEXT] = SOURCE.[FULLTEXT]
							  ,[FULLTEXT_DATE] = SOURCE.[FULLTEXT_DATE]
							  ,[STATUS] = SOURCE.[STATUS]
							  ,[DEFAULT_RIGHTS] = SOURCE.[DEFAULT_RIGHTS]
							  ,[ABSTRACT] = SOURCE.[ABSTRACT]
							  ,[PATH] = SOURCE.[PATH]
							  ,[DOCSERVER_LOC] = SOURCE.[DOCSERVER_LOC]
							  ,[DOCSERVER_OS] = SOURCE.[DOCSERVER_OS]
							  ,[PREV_SERVER_LOC] = SOURCE.[PREV_SERVER_LOC]
							  ,[PREV_SERVER_OS] = SOURCE.[PREV_SERVER_OS]
							  ,[KEYWORDS_DISPLAY] = SOURCE.[KEYWORDS_DISPLAY]
							  ,[READONLY_DATE] = SOURCE.[READONLY_DATE]
							  ,[RELATED] = SOURCE.[RELATED]
							  ,[PD_PRTO_AUTHORITY] = SOURCE.[PD_PRTO_AUTHORITY]
							  ,[MAIL_ID] = SOURCE.[MAIL_ID]
							  ,[PARENTMAIL_ID] = SOURCE.[PARENTMAIL_ID]
							  ,[THREAD_NUM] = SOURCE.[THREAD_NUM]
							  ,[ATTACH_NUM] = SOURCE.[ATTACH_NUM]
							  ,[MSG_ITEM] = SOURCE.[MSG_ITEM]
							  ,[DELIVER_REC] = SOURCE.[DELIVER_REC]
							  ,[EMAIL_RECEIVED] = SOURCE.[EMAIL_RECEIVED]
							  ,[EMAIL_SENT] = SOURCE.[EMAIL_SENT]
							  ,[MAIL_MSG_ID] = SOURCE.[MAIL_MSG_ID]
							  ,[MAIL_MSG_IDX] = SOURCE.[MAIL_MSG_IDX]
							  ,[VAR_CHIAVE_PROTO] = SOURCE.[VAR_CHIAVE_PROTO]
							  ,[ID_REGISTRO] = SOURCE.[ID_REGISTRO]
							  ,[CHA_TIPO_PROTO] = SOURCE.[CHA_TIPO_PROTO]
							  ,[ID_OGGETTO] = SOURCE.[ID_OGGETTO]
							  ,[NUM_PROTO] = SOURCE.[NUM_PROTO]
							  ,[NUM_ANNO_PROTO] = SOURCE.[NUM_ANNO_PROTO]
							  ,[VAR_PROTO_EME] = SOURCE.[VAR_PROTO_EME]
							  ,[DTA_PROTO_EME] = SOURCE.[DTA_PROTO_EME]
							  ,[VAR_COGNOME_EME] = SOURCE.[VAR_COGNOME_EME]
							  ,[VAR_NOME_EME] = SOURCE.[VAR_NOME_EME]
							  ,[ID_PARENT] = SOURCE.[ID_PARENT]
							  ,[DTA_PROTO] = SOURCE.[DTA_PROTO]
							  ,[CHA_MOD_OGGETTO] = SOURCE.[CHA_MOD_OGGETTO]
							  ,[CHA_MOD_MITT_DEST] = SOURCE.[CHA_MOD_MITT_DEST]
							  ,[CHA_MOD_MITT_INT] = SOURCE.[CHA_MOD_MITT_INT]
							  ,[CHA_MOD_DEST_OCC] = SOURCE.[CHA_MOD_DEST_OCC]
							  ,[DTA_PROTO_IN] = SOURCE.[DTA_PROTO_IN]
							  ,[VAR_PROTO_IN] = SOURCE.[VAR_PROTO_IN]
							  ,[ID_ANNULLATORE] = SOURCE.[ID_ANNULLATORE]
							  ,[DTA_ANNULLA] = SOURCE.[DTA_ANNULLA]
							  ,[VAR_AUT_ANNULLA] = SOURCE.[VAR_AUT_ANNULLA]
							  ,[VAR_SEGNATURA] = SOURCE.[VAR_SEGNATURA]
							  ,[CHA_DA_PROTO] = SOURCE.[CHA_DA_PROTO]
							  ,[VAR_NOTE] = SOURCE.[VAR_NOTE]
							  ,[ID_TIPO_ATTO] = SOURCE.[ID_TIPO_ATTO]
							  ,[CHA_ASSEGNATO] = SOURCE.[CHA_ASSEGNATO]
							  ,[CHA_IMG] = SOURCE.[CHA_IMG]
							  ,[CHA_FASCICOLATO] = SOURCE.[CHA_FASCICOLATO]
							  ,[CHA_INVIO_CONFERMA] = SOURCE.[CHA_INVIO_CONFERMA]
							  ,[CHA_CONGELATO] = SOURCE.[CHA_CONGELATO]
							  ,[CHA_CONSOLIDATO] = SOURCE.[CHA_CONSOLIDATO]
							  ,[CHA_PRIVATO] = SOURCE.[CHA_PRIVATO]
							  ,[VAR_NUM_OGGETTO] = SOURCE.[VAR_NUM_OGGETTO]
							  ,[VAR_COMM_REF] = SOURCE.[VAR_COMM_REF]
							  ,[CHA_EVIDENZA] = SOURCE.[CHA_EVIDENZA]
							  ,[VAR_SEDE] = SOURCE.[VAR_SEDE]
							  ,[VAR_PROF_OGGETTO] = SOURCE.[VAR_PROF_OGGETTO]
							  ,[ID_PEOPLE_PROT] = SOURCE.[ID_PEOPLE_PROT]
							  ,[ID_RUOLO_PROT] = SOURCE.[ID_RUOLO_PROT]
							  ,[ID_UO_PROT] = SOURCE.[ID_UO_PROT]
							  ,[ID_UO_REF] = SOURCE.[ID_UO_REF]
							  ,[ID_RUOLO_CREATORE] = SOURCE.[ID_RUOLO_CREATORE]
							  ,[ID_UO_CREATORE] = SOURCE.[ID_UO_CREATORE]
							  ,[CHA_INTEROP] = SOURCE.[CHA_INTEROP]
							  ,[DTA_SCADENZA] = SOURCE.[DTA_SCADENZA]
							  ,[CHA_PERSONALE] = SOURCE.[CHA_PERSONALE]
							  ,[CHA_IN_CESTINO] = SOURCE.[CHA_IN_CESTINO]
							  ,[VAR_NOTE_CESTINO] = SOURCE.[VAR_NOTE_CESTINO]
							  ,[ID_DOCUMENTO_PRINCIPALE] = SOURCE.[ID_DOCUMENTO_PRINCIPALE]
							  ,[CHA_IN_ARCHIVIO] = SOURCE.[CHA_IN_ARCHIVIO]
							  ,[CHA_FIRMATO] = SOURCE.[CHA_FIRMATO]
							  ,[CHA_RIFF_MITT] = SOURCE.[CHA_RIFF_MITT]
							  ,[PROT_TIT] = SOURCE.[PROT_TIT]
							  ,[NUM_IN_FASC] = SOURCE.[NUM_IN_FASC]
							  ,[ID_FASC_PROT_TIT] = SOURCE.[ID_FASC_PROT_TIT]
							  ,[NUM_PROT_TIT] = SOURCE.[NUM_PROT_TIT]
							  ,[ID_TITOLARIO] = SOURCE.[ID_TITOLARIO]
							  ,[DTA_PROTO_TIT] = SOURCE.[DTA_PROTO_TIT]
							  ,[ID_PEOPLE_DELEGATO] = SOURCE.[ID_PEOPLE_DELEGATO]
							  ,[CHA_DOCUMENTO_DA_PEC] = SOURCE.[CHA_DOCUMENTO_DA_PEC]
							  ,[CHA_UNLOCKED_FINAL_STATE] = SOURCE.[CHA_UNLOCKED_FINAL_STATE]
							  ,[CONSOLIDATION_STATE] = SOURCE.[CONSOLIDATION_STATE]
							  ,[CONSOLIDATION_AUTHOR] = SOURCE.[CONSOLIDATION_AUTHOR]
							  ,[CONSOLIDATION_ROLE] = SOURCE.[CONSOLIDATION_ROLE]
							  ,[CONSOLIDATION_DATE] = SOURCE.[CONSOLIDATION_DATE]
							  ,[LAST_FORWARD] = SOURCE.[LAST_FORWARD]
							  ,[FORWARDING_SOURCE] = SOURCE.[FORWARDING_SOURCE]
							  ,[PRINTS_NUM] = SOURCE.[PRINTS_NUM]
							  ,[CHA_COD_T_A] = SOURCE.[CHA_COD_T_A]
							  ,[ID_VECCHIO_DOCUMENTO] = SOURCE.[ID_VECCHIO_DOCUMENTO]
							  ,[COD_EXT_APP] = SOURCE.[COD_EXT_APP]
							  ,[MIS_OBIETTIVO] = SOURCE.[MIS_OBIETTIVO]
							  ,[FASE] = SOURCE.[FASE]
							  ,[ID_TIPO_COMUNICAZIONE] = SOURCE.[ID_TIPO_COMUNICAZIONE]
							  ,[ID_CENTRO_DI_COSTO] = SOURCE.[ID_CENTRO_DI_COSTO]
							  ,[ID_OBIETTIVO] = SOURCE.[ID_OBIETTIVO]
					WHEN NOT MATCHED THEN
						INSERT ([SYSTEM_ID]
							  ,[DOCNUMBER]
							  ,[DOCNAME]
							  ,[TYPIST]
							  ,[AUTHOR]
							  ,[DOCUMENTTYPE]
							  ,[LAST_EDITED_BY]
							  ,[LAST_LOCKED_BY]
							  ,[LAST_ACCESS_ID]
							  ,[APPLICATION]
							  ,[FORM]
							  ,[STORAGETYPE]
							  ,[RETENTION]
							  ,[PROCESS_DATE]
							  ,[CREATION_DATE]
							  ,[CREATION_TIME]
							  ,[LAST_EDIT_DATE]
							  ,[LAST_EDIT_TIME]
							  ,[LAST_ACCESS_DATE]
							  ,[LAST_ACCESS_TIME]
							  ,[ARCHIVE_DATE]
							  ,[ARCHIVE_ID]
							  ,[KEYSTROKES]
							  ,[EDITING_TIME]
							  ,[TYPE_TIME]
							  ,[BILLABLE]
							  ,[FULLTEXT]
							  ,[FULLTEXT_DATE]
							  ,[STATUS]
							  ,[DEFAULT_RIGHTS]
							  ,[ABSTRACT]
							  ,[PATH]
							  ,[DOCSERVER_LOC]
							  ,[DOCSERVER_OS]
							  ,[PREV_SERVER_LOC]
							  ,[PREV_SERVER_OS]
							  ,[KEYWORDS_DISPLAY]
							  ,[READONLY_DATE]
							  ,[RELATED]
							  ,[PD_PRTO_AUTHORITY]
							  ,[MAIL_ID]
							  ,[PARENTMAIL_ID]
							  ,[THREAD_NUM]
							  ,[ATTACH_NUM]
							  ,[MSG_ITEM]
							  ,[DELIVER_REC]
							  ,[EMAIL_RECEIVED]
							  ,[EMAIL_SENT]
							  ,[MAIL_MSG_ID]
							  ,[MAIL_MSG_IDX]
							  ,[VAR_CHIAVE_PROTO]
							  ,[ID_REGISTRO]
							  ,[CHA_TIPO_PROTO]
							  ,[ID_OGGETTO]
							  ,[NUM_PROTO]
							  ,[NUM_ANNO_PROTO]
							  ,[VAR_PROTO_EME]
							  ,[DTA_PROTO_EME]
							  ,[VAR_COGNOME_EME]
							  ,[VAR_NOME_EME]
							  ,[ID_PARENT]
							  ,[DTA_PROTO]
							  ,[CHA_MOD_OGGETTO]
							  ,[CHA_MOD_MITT_DEST]
							  ,[CHA_MOD_MITT_INT]
							  ,[CHA_MOD_DEST_OCC]
							  ,[DTA_PROTO_IN]
							  ,[VAR_PROTO_IN]
							  ,[ID_ANNULLATORE]
							  ,[DTA_ANNULLA]
							  ,[VAR_AUT_ANNULLA]
							  ,[VAR_SEGNATURA]
							  ,[CHA_DA_PROTO]
							  ,[VAR_NOTE]
							  ,[ID_TIPO_ATTO]
							  ,[CHA_ASSEGNATO]
							  ,[CHA_IMG]
							  ,[CHA_FASCICOLATO]
							  ,[CHA_INVIO_CONFERMA]
							  ,[CHA_CONGELATO]
							  ,[CHA_CONSOLIDATO]
							  ,[CHA_PRIVATO]
							  ,[VAR_NUM_OGGETTO]
							  ,[VAR_COMM_REF]
							  ,[CHA_EVIDENZA]
							  ,[VAR_SEDE]
							  ,[VAR_PROF_OGGETTO]
							  ,[ID_PEOPLE_PROT]
							  ,[ID_RUOLO_PROT]
							  ,[ID_UO_PROT]
							  ,[ID_UO_REF]
							  ,[ID_RUOLO_CREATORE]
							  ,[ID_UO_CREATORE]
							  ,[CHA_INTEROP]
							  ,[DTA_SCADENZA]
							  ,[CHA_PERSONALE]
							  ,[CHA_IN_CESTINO]
							  ,[VAR_NOTE_CESTINO]
							  ,[ID_DOCUMENTO_PRINCIPALE]
							  ,[CHA_IN_ARCHIVIO]
							  ,[CHA_FIRMATO]
							  ,[CHA_RIFF_MITT]
							  ,[PROT_TIT]
							  ,[NUM_IN_FASC]
							  ,[ID_FASC_PROT_TIT]
							  ,[NUM_PROT_TIT]
							  ,[ID_TITOLARIO]
							  ,[DTA_PROTO_TIT]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_DOCUMENTO_DA_PEC]
							  ,[CHA_UNLOCKED_FINAL_STATE]
							  ,[CONSOLIDATION_STATE]
							  ,[CONSOLIDATION_AUTHOR]
							  ,[CONSOLIDATION_ROLE]
							  ,[CONSOLIDATION_DATE]
							  ,[LAST_FORWARD]
							  ,[FORWARDING_SOURCE]
							  ,[PRINTS_NUM]
							  ,[CHA_COD_T_A]
							  ,[ID_VECCHIO_DOCUMENTO]
							  ,[COD_EXT_APP]
							  ,[MIS_OBIETTIVO]
							  ,[FASE]
							  ,[ID_TIPO_COMUNICAZIONE]
							  ,[ID_CENTRO_DI_COSTO]
							  ,[ID_OBIETTIVO])
						VALUES (SOURCE.[SYSTEM_ID]
							  ,SOURCE.[DOCNUMBER]
							  ,SOURCE.[DOCNAME]
							  ,SOURCE.[TYPIST]
							  ,SOURCE.[AUTHOR]
							  ,SOURCE.[DOCUMENTTYPE]
							  ,SOURCE.[LAST_EDITED_BY]
							  ,SOURCE.[LAST_LOCKED_BY]
							  ,SOURCE.[LAST_ACCESS_ID]
							  ,SOURCE.[APPLICATION]
							  ,SOURCE.[FORM]
							  ,SOURCE.[STORAGETYPE]
							  ,SOURCE.[RETENTION]
							  ,SOURCE.[PROCESS_DATE]
							  ,SOURCE.[CREATION_DATE]
							  ,SOURCE.[CREATION_TIME]
							  ,SOURCE.[LAST_EDIT_DATE]
							  ,SOURCE.[LAST_EDIT_TIME]
							  ,SOURCE.[LAST_ACCESS_DATE]
							  ,SOURCE.[LAST_ACCESS_TIME]
							  ,SOURCE.[ARCHIVE_DATE]
							  ,SOURCE.[ARCHIVE_ID]
							  ,SOURCE.[KEYSTROKES]
							  ,SOURCE.[EDITING_TIME]
							  ,SOURCE.[TYPE_TIME]
							  ,SOURCE.[BILLABLE]
							  ,SOURCE.[FULLTEXT]
							  ,SOURCE.[FULLTEXT_DATE]
							  ,SOURCE.[STATUS]
							  ,SOURCE.[DEFAULT_RIGHTS]
							  ,SOURCE.[ABSTRACT]
							  ,SOURCE.[PATH]
							  ,SOURCE.[DOCSERVER_LOC]
							  ,SOURCE.[DOCSERVER_OS]
							  ,SOURCE.[PREV_SERVER_LOC]
							  ,SOURCE.[PREV_SERVER_OS]
							  ,SOURCE.[KEYWORDS_DISPLAY]
							  ,SOURCE.[READONLY_DATE]
							  ,SOURCE.[RELATED]
							  ,SOURCE.[PD_PRTO_AUTHORITY]
							  ,SOURCE.[MAIL_ID]
							  ,SOURCE.[PARENTMAIL_ID]
							  ,SOURCE.[THREAD_NUM]
							  ,SOURCE.[ATTACH_NUM]
							  ,SOURCE.[MSG_ITEM]
							  ,SOURCE.[DELIVER_REC]
							  ,SOURCE.[EMAIL_RECEIVED]
							  ,SOURCE.[EMAIL_SENT]
							  ,SOURCE.[MAIL_MSG_ID]
							  ,SOURCE.[MAIL_MSG_IDX]
							  ,SOURCE.[VAR_CHIAVE_PROTO]
							  ,SOURCE.[ID_REGISTRO]
							  ,SOURCE.[CHA_TIPO_PROTO]
							  ,SOURCE.[ID_OGGETTO]
							  ,SOURCE.[NUM_PROTO]
							  ,SOURCE.[NUM_ANNO_PROTO]
							  ,SOURCE.[VAR_PROTO_EME]
							  ,SOURCE.[DTA_PROTO_EME]
							  ,SOURCE.[VAR_COGNOME_EME]
							  ,SOURCE.[VAR_NOME_EME]
							  ,SOURCE.[ID_PARENT]
							  ,SOURCE.[DTA_PROTO]
							  ,SOURCE.[CHA_MOD_OGGETTO]
							  ,SOURCE.[CHA_MOD_MITT_DEST]
							  ,SOURCE.[CHA_MOD_MITT_INT]
							  ,SOURCE.[CHA_MOD_DEST_OCC]
							  ,SOURCE.[DTA_PROTO_IN]
							  ,SOURCE.[VAR_PROTO_IN]
							  ,SOURCE.[ID_ANNULLATORE]
							  ,SOURCE.[DTA_ANNULLA]
							  ,SOURCE.[VAR_AUT_ANNULLA]
							  ,SOURCE.[VAR_SEGNATURA]
							  ,SOURCE.[CHA_DA_PROTO]
							  ,SOURCE.[VAR_NOTE]
							  ,SOURCE.[ID_TIPO_ATTO]
							  ,SOURCE.[CHA_ASSEGNATO]
							  ,SOURCE.[CHA_IMG]
							  ,SOURCE.[CHA_FASCICOLATO]
							  ,SOURCE.[CHA_INVIO_CONFERMA]
							  ,SOURCE.[CHA_CONGELATO]
							  ,SOURCE.[CHA_CONSOLIDATO]
							  ,SOURCE.[CHA_PRIVATO]
							  ,SOURCE.[VAR_NUM_OGGETTO]
							  ,SOURCE.[VAR_COMM_REF]
							  ,SOURCE.[CHA_EVIDENZA]
							  ,SOURCE.[VAR_SEDE]
							  ,SOURCE.[VAR_PROF_OGGETTO]
							  ,SOURCE.[ID_PEOPLE_PROT]
							  ,SOURCE.[ID_RUOLO_PROT]
							  ,SOURCE.[ID_UO_PROT]
							  ,SOURCE.[ID_UO_REF]
							  ,SOURCE.[ID_RUOLO_CREATORE]
							  ,SOURCE.[ID_UO_CREATORE]
							  ,SOURCE.[CHA_INTEROP]
							  ,SOURCE.[DTA_SCADENZA]
							  ,SOURCE.[CHA_PERSONALE]
							  ,SOURCE.[CHA_IN_CESTINO]
							  ,SOURCE.[VAR_NOTE_CESTINO]
							  ,SOURCE.[ID_DOCUMENTO_PRINCIPALE]
							  ,SOURCE.[CHA_IN_ARCHIVIO]
							  ,SOURCE.[CHA_FIRMATO]
							  ,SOURCE.[CHA_RIFF_MITT]
							  ,SOURCE.[PROT_TIT]
							  ,SOURCE.[NUM_IN_FASC]
							  ,SOURCE.[ID_FASC_PROT_TIT]
							  ,SOURCE.[NUM_PROT_TIT]
							  ,SOURCE.[ID_TITOLARIO]
							  ,SOURCE.[DTA_PROTO_TIT]
							  ,SOURCE.[ID_PEOPLE_DELEGATO]
							  ,SOURCE.[CHA_DOCUMENTO_DA_PEC]
							  ,SOURCE.[CHA_UNLOCKED_FINAL_STATE]
							  ,SOURCE.[CONSOLIDATION_STATE]
							  ,SOURCE.[CONSOLIDATION_AUTHOR]
							  ,SOURCE.[CONSOLIDATION_ROLE]
							  ,SOURCE.[CONSOLIDATION_DATE]
							  ,SOURCE.[LAST_FORWARD]
							  ,SOURCE.[FORWARDING_SOURCE]
							  ,SOURCE.[PRINTS_NUM]
							  ,SOURCE.[CHA_COD_T_A]
							  ,SOURCE.[ID_VECCHIO_DOCUMENTO]
							  ,SOURCE.[COD_EXT_APP]
							  ,SOURCE.[MIS_OBIETTIVO]
							  ,SOURCE.[FASE]
							  ,SOURCE.[ID_TIPO_COMUNICAZIONE]
							  ,SOURCE.[ID_CENTRO_DI_COSTO]
							  ,SOURCE.[ID_OBIETTIVO]);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella PROFILE - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella PROFILE'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
			
			
			
				-- **********
				-- COMPONENTS
				-- **********

				SET @sql_string = CAST(N'MERGE COMPONENTS AS TARGET
					USING ( 	
						SELECT [PATH]
						,[LOCKED]
						,[COMPTYPE]
						,[VERSION_ID]
						,[DOCNUMBER]
						,[FILE_SIZE]
						,[ALTERNATE_PATH]
						,[VAR_IMPRONTA]
						,[CHA_FIRMATO]
						,[EXT]
						,[MTEXT_FQN]
						,[VAR_NOMEORIGINALE]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[COMPONENTS] WITH (NOLOCK)
						WHERE DOCNUMBER IN
							(
							SELECT DOCNUMBER FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[PROFILE] WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							)
						)
					AS SOURCE ([PATH]
						,[LOCKED]
						,[COMPTYPE]
						,[VERSION_ID]
						,[DOCNUMBER]
						,[FILE_SIZE]
						,[ALTERNATE_PATH]
						,[VAR_IMPRONTA]
						,[CHA_FIRMATO]
						,[EXT]
						,[MTEXT_FQN]
						,[VAR_NOMEORIGINALE])
					ON (TARGET.DOCNUMBER = SOURCE.DOCNUMBER AND TARGET.VERSION_ID = SOURCE.VERSION_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[PATH] = SOURCE.[PATH]
							,[LOCKED] = SOURCE.[LOCKED]
							,[COMPTYPE] = SOURCE.[COMPTYPE]
							,[VERSION_ID] = SOURCE.[VERSION_ID]
							,[DOCNUMBER] = SOURCE.[DOCNUMBER]
							,[FILE_SIZE] = SOURCE.[FILE_SIZE]
							,[ALTERNATE_PATH] = SOURCE.[ALTERNATE_PATH]
							,[VAR_IMPRONTA] = SOURCE.[VAR_IMPRONTA]
							,[CHA_FIRMATO] = SOURCE.[CHA_FIRMATO]
							,[EXT] = SOURCE.[EXT]
							,[MTEXT_FQN] = SOURCE.[MTEXT_FQN]
							,[VAR_NOMEORIGINALE] = SOURCE.[VAR_NOMEORIGINALE]
					WHEN NOT MATCHED THEN
						INSERT (
						[PATH]
						,[LOCKED]
						,[COMPTYPE]
						,[VERSION_ID]
						,[DOCNUMBER]
						,[FILE_SIZE]
						,[ALTERNATE_PATH]
						,[VAR_IMPRONTA]
						,[CHA_FIRMATO]
						,[EXT]
						,[MTEXT_FQN]
						,[VAR_NOMEORIGINALE])
						VALUES (
						SOURCE.[PATH]
						,SOURCE.[LOCKED]
						,SOURCE.[COMPTYPE]
						,SOURCE.[VERSION_ID]
						,SOURCE.[DOCNUMBER]
						,SOURCE.[FILE_SIZE]
						,SOURCE.[ALTERNATE_PATH]
						,SOURCE.[VAR_IMPRONTA]
						,SOURCE.[CHA_FIRMATO]
						,SOURCE.[EXT]
						,SOURCE.[MTEXT_FQN]
						,SOURCE.[VAR_NOMEORIGINALE]);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella COMPONENTS - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella COMPONENTS'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID		
				
				
				
				-- ********
				-- VERSIONS
				-- ********
				
				SET @sql_string = CAST(N'MERGE VERSIONS AS TARGET
					USING ( 	
						SELECT [VERSION_ID]
						,[DOCNUMBER]
						,[VERSION]
						,[SUBVERSION]
						,[VERSION_LABEL]
						,[AUTHOR]
						,[TYPIST]
						,[LASTEDITDATE]
						,[LASTEDITTIME]
						,[COMMENTS]
						,[FORCE_VERSION_RO]
						,[STATUS]
						,[ARCHIVE_ID]
						,[READONLY_DATE]
						,[NEXT_PUBLISH_VER]
						,[PUBLISH_DATE]
						,[PREV_STATUS]
						,[CONTAINER_TYPE]
						,[MAIL_ID]
						,[PARENTMAIL_ID]
						,[THREAD_NUM]
						,[ATTACH_NUM]
						,[NUM_PAG_ALLEGATI]
						,[DTA_CREAZIONE]
						,[CHA_DA_INVIARE]
						,[DTA_ARRIVO]
						,[V_NAME_FN]
						,[CARTACEO]
						,[SCARTA_FASC_CARTACEA]
						,[ID_PEOPLE_DELEGATO]
						,[CHA_SEGNATURA]
						,[CHA_ALLEGATI_ESTERNO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[VERSIONS] WITH (NOLOCK)
						WHERE DOCNUMBER IN
							(
							SELECT DOCNUMBER FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[PROFILE] WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							)
						)
					AS SOURCE ([VERSION_ID]
						,[DOCNUMBER]
						,[VERSION]
						,[SUBVERSION]
						,[VERSION_LABEL]
						,[AUTHOR]
						,[TYPIST]
						,[LASTEDITDATE]
						,[LASTEDITTIME]
						,[COMMENTS]
						,[FORCE_VERSION_RO]
						,[STATUS]
						,[ARCHIVE_ID]
						,[READONLY_DATE]
						,[NEXT_PUBLISH_VER]
						,[PUBLISH_DATE]
						,[PREV_STATUS]
						,[CONTAINER_TYPE]
						,[MAIL_ID]
						,[PARENTMAIL_ID]
						,[THREAD_NUM]
						,[ATTACH_NUM]
						,[NUM_PAG_ALLEGATI]
						,[DTA_CREAZIONE]
						,[CHA_DA_INVIARE]
						,[DTA_ARRIVO]
						,[V_NAME_FN]
						,[CARTACEO]
						,[SCARTA_FASC_CARTACEA]
						,[ID_PEOPLE_DELEGATO]
						,[CHA_SEGNATURA]
						,[CHA_ALLEGATI_ESTERNO])
					ON (TARGET.VERSION_ID = SOURCE.VERSION_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[VERSION_ID] = SOURCE.[VERSION_ID]
							,[DOCNUMBER] = SOURCE.[DOCNUMBER]
							,[VERSION] = SOURCE.[VERSION]
							,[SUBVERSION] = SOURCE.[SUBVERSION]
							,[VERSION_LABEL] = SOURCE.[VERSION_LABEL]
							,[AUTHOR] = SOURCE.[AUTHOR]
							,[TYPIST] = SOURCE.[TYPIST]
							,[LASTEDITDATE] = SOURCE.[LASTEDITDATE]
							,[LASTEDITTIME] = SOURCE.[LASTEDITTIME]
							,[COMMENTS] = SOURCE.[COMMENTS]
							,[FORCE_VERSION_RO] = SOURCE.[FORCE_VERSION_RO]
							,[STATUS] = SOURCE.[STATUS]
							,[ARCHIVE_ID] = SOURCE.[ARCHIVE_ID]
							,[READONLY_DATE] = SOURCE.[READONLY_DATE]
							,[NEXT_PUBLISH_VER] = SOURCE.[NEXT_PUBLISH_VER]
							,[PUBLISH_DATE] = SOURCE.[PUBLISH_DATE]
							,[PREV_STATUS] = SOURCE.[PREV_STATUS]
							,[CONTAINER_TYPE] = SOURCE.[CONTAINER_TYPE]
							,[MAIL_ID] = SOURCE.[MAIL_ID]
							,[PARENTMAIL_ID] = SOURCE.[PARENTMAIL_ID]
							,[THREAD_NUM] = SOURCE.[THREAD_NUM]
							,[ATTACH_NUM] = SOURCE.[ATTACH_NUM]
							,[NUM_PAG_ALLEGATI] = SOURCE.[NUM_PAG_ALLEGATI]
							,[DTA_CREAZIONE] = SOURCE.[DTA_CREAZIONE]
							,[CHA_DA_INVIARE] = SOURCE.[CHA_DA_INVIARE]
							,[DTA_ARRIVO] = SOURCE.[DTA_ARRIVO]
							,[V_NAME_FN] = SOURCE.[V_NAME_FN]
							,[CARTACEO] = SOURCE.[CARTACEO]
							,[SCARTA_FASC_CARTACEA] = SOURCE.[SCARTA_FASC_CARTACEA]
							,[ID_PEOPLE_DELEGATO] = SOURCE.[ID_PEOPLE_DELEGATO]
							,[CHA_SEGNATURA] = SOURCE.[CHA_SEGNATURA]
							,[CHA_ALLEGATI_ESTERNO] = SOURCE.[CHA_ALLEGATI_ESTERNO]
					WHEN NOT MATCHED THEN
						INSERT (
							[VERSION_ID]
							,[DOCNUMBER]
							,[VERSION]
							,[SUBVERSION]
							,[VERSION_LABEL]
							,[AUTHOR]
							,[TYPIST]
							,[LASTEDITDATE]
							,[LASTEDITTIME]
							,[COMMENTS]
							,[FORCE_VERSION_RO]
							,[STATUS]
							,[ARCHIVE_ID]
							,[READONLY_DATE]
							,[NEXT_PUBLISH_VER]
							,[PUBLISH_DATE]
							,[PREV_STATUS]
							,[CONTAINER_TYPE]
							,[MAIL_ID]
							,[PARENTMAIL_ID]
							,[THREAD_NUM]
							,[ATTACH_NUM]
							,[NUM_PAG_ALLEGATI]
							,[DTA_CREAZIONE]
							,[CHA_DA_INVIARE]
							,[DTA_ARRIVO]
							,[V_NAME_FN]
							,[CARTACEO]
							,[SCARTA_FASC_CARTACEA]
							,[ID_PEOPLE_DELEGATO]
							,[CHA_SEGNATURA]
							,[CHA_ALLEGATI_ESTERNO]
							)
						VALUES (
							SOURCE.[VERSION_ID]
							,SOURCE.[DOCNUMBER]
							,SOURCE.[VERSION]
							,SOURCE.[SUBVERSION]
							,SOURCE.[VERSION_LABEL]
							,SOURCE.[AUTHOR]
							,SOURCE.[TYPIST]
							,SOURCE.[LASTEDITDATE]
							,SOURCE.[LASTEDITTIME]
							,SOURCE.[COMMENTS]
							,SOURCE.[FORCE_VERSION_RO]
							,SOURCE.[STATUS]
							,SOURCE.[ARCHIVE_ID]
							,SOURCE.[READONLY_DATE]
							,SOURCE.[NEXT_PUBLISH_VER]
							,SOURCE.[PUBLISH_DATE]
							,SOURCE.[PREV_STATUS]
							,SOURCE.[CONTAINER_TYPE]
							,SOURCE.[MAIL_ID]
							,SOURCE.[PARENTMAIL_ID]
							,SOURCE.[THREAD_NUM]
							,SOURCE.[ATTACH_NUM]
							,SOURCE.[NUM_PAG_ALLEGATI]
							,SOURCE.[DTA_CREAZIONE]
							,SOURCE.[CHA_DA_INVIARE]
							,SOURCE.[DTA_ARRIVO]
							,SOURCE.[V_NAME_FN]
							,SOURCE.[CARTACEO]
							,SOURCE.[SCARTA_FASC_CARTACEA]
							,SOURCE.[ID_PEOPLE_DELEGATO]
							,SOURCE.[CHA_SEGNATURA]
							,SOURCE.[CHA_ALLEGATI_ESTERNO]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella VERSIONS - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella VERSIONS'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- *****************
				-- DPA_TIMESTAMP_DOC
				-- *****************
				
				SET @sql_string = CAST(N'MERGE DPA_TIMESTAMP_DOC AS TARGET
					USING ( 	
						SELECT 
						[SYSTEM_ID]
						,[DOC_NUMBER]
						,[VERSION_ID]
						,[ID_PEOPLE]
						,[DTA_CREAZIONE]
						,[DTA_SCADENZA]
						,[NUM_SERIE]
						,[S_N_CERTIFICATO]
						,[ALG_HASH]
						,[SOGGETTO]
						,[PAESE]
						,[TSR_FILE]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_TIMESTAMP_DOC] WITH (NOLOCK)
						WHERE DOC_NUMBER IN
							(
							SELECT DOCNUMBER FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[PROFILE] WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							)
						)
					AS SOURCE ([SYSTEM_ID]
						,[DOC_NUMBER]
						,[VERSION_ID]
						,[ID_PEOPLE]
						,[DTA_CREAZIONE]
						,[DTA_SCADENZA]
						,[NUM_SERIE]
						,[S_N_CERTIFICATO]
						,[ALG_HASH]
						,[SOGGETTO]
						,[PAESE]
						,[TSR_FILE])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[DOC_NUMBER] = SOURCE.[DOC_NUMBER]
							,[VERSION_ID] = SOURCE.[VERSION_ID]
							,[ID_PEOPLE] = SOURCE.[ID_PEOPLE]
							,[DTA_CREAZIONE] = SOURCE.[DTA_CREAZIONE]
							,[DTA_SCADENZA] = SOURCE.[DTA_SCADENZA]
							,[NUM_SERIE] = SOURCE.[NUM_SERIE]
							,[S_N_CERTIFICATO] = SOURCE.[S_N_CERTIFICATO]
							,[ALG_HASH] = SOURCE.[ALG_HASH]
							,[SOGGETTO] = SOURCE.[SOGGETTO]
							,[PAESE] = SOURCE.[PAESE]
							,[TSR_FILE] = SOURCE.[TSR_FILE]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[DOC_NUMBER]
							,[VERSION_ID]
							,[ID_PEOPLE]
							,[DTA_CREAZIONE]
							,[DTA_SCADENZA]
							,[NUM_SERIE]
							,[S_N_CERTIFICATO]
							,[ALG_HASH]
							,[SOGGETTO]
							,[PAESE]
							,[TSR_FILE]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[DOC_NUMBER]
							,SOURCE.[VERSION_ID]
							,SOURCE.[ID_PEOPLE]
							,SOURCE.[DTA_CREAZIONE]
							,SOURCE.[DTA_SCADENZA]
							,SOURCE.[NUM_SERIE]
							,SOURCE.[S_N_CERTIFICATO]
							,SOURCE.[ALG_HASH]
							,SOURCE.[SOGGETTO]
							,SOURCE.[PAESE]
							,SOURCE.[TSR_FILE]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_TIMESTAMP_DOC - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_TIMESTAMP_DOC'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ********
				-- SECURITY
				-- ********

/*
						SYSTEM_ID IN
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
							)
						OR ID_DOCUMENTO_PRINCIPALE IN
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
							)			

						SELECT SYSTEM_ID 
						FROM [10.174.68.103].PCM_040413.DOCSADM.PROFILE WITH (NOLOCK)
						WHERE EXISTS (select 'x' from archive_temptransferprofile where
						profile_id=system_id)
						union
						SELECT SYSTEM_ID 
						FROM [10.174.68.103].PCM_040413.DOCSADM.PROFILE WITH (NOLOCK)
						WHERE exists (select 'x' from archive_temptransferprofile where
						profile_id=ID_DOCUMENTO_PRINCIPALE)						
*/
				SET @sql_string = CAST(N'MERGE SECURITY AS TARGET
					USING ( 	
					SELECT [THING]
					  ,[PERSONORGROUP]
					  ,[ACCESSRIGHTS]
					  ,[ID_GRUPPO_TRASM]
					  ,[CHA_TIPO_DIRITTO]
					  ,[HIDE_DOC_VERSIONS]
					  ,[TS_INSERIMENTO]
					  ,[VAR_NOTE_SEC]
					FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[SECURITY] WITH (NOLOCK)
					WHERE [THING] IN 
						(
						SELECT SYSTEM_ID 
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
						WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=SYSTEM_ID)
						UNION
						SELECT SYSTEM_ID 
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
						WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=ID_DOCUMENTO_PRINCIPALE)
						)
					) 
					AS SOURCE ([THING]
					  ,[PERSONORGROUP]
					  ,[ACCESSRIGHTS]
					  ,[ID_GRUPPO_TRASM]
					  ,[CHA_TIPO_DIRITTO]
					  ,[HIDE_DOC_VERSIONS]
					  ,[TS_INSERIMENTO]
					  ,[VAR_NOTE_SEC])
					ON (TARGET.THING = SOURCE.THING AND TARGET.PERSONORGROUP = SOURCE.PERSONORGROUP AND TARGET.ACCESSRIGHTS = SOURCE.ACCESSRIGHTS)
					WHEN MATCHED THEN
						UPDATE SET
							[THING] = SOURCE.[THING]
						  ,[PERSONORGROUP] = SOURCE.[PERSONORGROUP]
						  ,[ACCESSRIGHTS] = SOURCE.[ACCESSRIGHTS]
						  ,[ID_GRUPPO_TRASM] = SOURCE.[ID_GRUPPO_TRASM]
						  ,[CHA_TIPO_DIRITTO] = SOURCE.[CHA_TIPO_DIRITTO]
						  ,[HIDE_DOC_VERSIONS] = SOURCE.[HIDE_DOC_VERSIONS]
						  ,[TS_INSERIMENTO] = SOURCE.[TS_INSERIMENTO]
						  ,[VAR_NOTE_SEC] = SOURCE.[VAR_NOTE_SEC]
					WHEN NOT MATCHED THEN
						INSERT ([THING]
							  ,[PERSONORGROUP]
							  ,[ACCESSRIGHTS]
							  ,[ID_GRUPPO_TRASM]
							  ,[CHA_TIPO_DIRITTO]
							  ,[HIDE_DOC_VERSIONS]
							  ,[TS_INSERIMENTO]
							  ,[VAR_NOTE_SEC])
						VALUES (SOURCE.[THING]
							  ,SOURCE.[PERSONORGROUP]
							  ,SOURCE.[ACCESSRIGHTS]
							  ,SOURCE.[ID_GRUPPO_TRASM]
							  ,SOURCE.[CHA_TIPO_DIRITTO]
							  ,SOURCE.[HIDE_DOC_VERSIONS]
							  ,SOURCE.[TS_INSERIMENTO]
							  ,SOURCE.[VAR_NOTE_SEC]);' AS NVARCHAR(MAX))
							  
				PRINT @sql_string;
			
				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella SECURITY (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella SECURITY (Documenti) '
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ****************
				-- DELETED_SECURITY
				-- ****************
				
				SET @sql_string = CAST(N'
				MERGE DELETED_SECURITY AS TARGET
				USING ( 	
					SELECT [THING]
					,[PERSONORGROUP]
					,[ACCESSRIGHTS]
					,[ID_GRUPPO_TRASM]
					,[CHA_TIPO_DIRITTO]
					,[NOTE]
					,[DTA_REVOCA]
					,[ID_UTENTE_REV]
					,[ID_RUOLO_REV]
					,[HIDE_DOC_VERSIONS]
					FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DELETED_SECURITY] WITH (NOLOCK)
					WHERE [THING] IN 
						(
						SELECT SYSTEM_ID 
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
						WHERE SYSTEM_ID IN
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
							)
						OR ID_DOCUMENTO_PRINCIPALE IN
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
							)			
						)
					)
				AS SOURCE ([THING]
					,[PERSONORGROUP]
					,[ACCESSRIGHTS]
					,[ID_GRUPPO_TRASM]
					,[CHA_TIPO_DIRITTO]
					,[NOTE]
					,[DTA_REVOCA]
					,[ID_UTENTE_REV]
					,[ID_RUOLO_REV]
					,[HIDE_DOC_VERSIONS])
				ON (TARGET.THING = SOURCE.THING AND TARGET.PERSONORGROUP = SOURCE.PERSONORGROUP AND TARGET.ACCESSRIGHTS = SOURCE.ACCESSRIGHTS)
				WHEN MATCHED THEN
					UPDATE SET
						[THING] = SOURCE.[THING]
						,[PERSONORGROUP] = SOURCE.[PERSONORGROUP]
						,[ACCESSRIGHTS] = SOURCE.[ACCESSRIGHTS]
						,[ID_GRUPPO_TRASM] = SOURCE.[ID_GRUPPO_TRASM]
						,[CHA_TIPO_DIRITTO] = SOURCE.[CHA_TIPO_DIRITTO]
						,[NOTE] = SOURCE.[NOTE]
						,[DTA_REVOCA] = SOURCE.[DTA_REVOCA]
						,[ID_UTENTE_REV] = SOURCE.[ID_UTENTE_REV]
						,[ID_RUOLO_REV] = SOURCE.[ID_RUOLO_REV]
						,[HIDE_DOC_VERSIONS] = SOURCE.[HIDE_DOC_VERSIONS]
				WHEN NOT MATCHED THEN
					INSERT (
						[THING]
						,[PERSONORGROUP]
						,[ACCESSRIGHTS]
						,[ID_GRUPPO_TRASM]
						,[CHA_TIPO_DIRITTO]
						,[NOTE]
						,[DTA_REVOCA]
						,[ID_UTENTE_REV]
						,[ID_RUOLO_REV]
						,[HIDE_DOC_VERSIONS]
						)
					VALUES (
						SOURCE.[THING]
						,SOURCE.[PERSONORGROUP]
						,SOURCE.[ACCESSRIGHTS]
						,SOURCE.[ID_GRUPPO_TRASM]
						,SOURCE.[CHA_TIPO_DIRITTO]
						,SOURCE.[NOTE]
						,SOURCE.[DTA_REVOCA]
						,SOURCE.[ID_UTENTE_REV]
						,SOURCE.[ID_RUOLO_REV]
						,SOURCE.[HIDE_DOC_VERSIONS]
					);' AS NVARCHAR(MAX))
							  
				PRINT @sql_string;
			
				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DELETED_SECURITY (Documenti) per la Policy - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DELETED_SECURITY (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- **************
				-- DPA_OGGETTARIO
				-- **************

				--select * from PCM_040413.DPA_OGGETTARIO -- system_id = profile.id_oggetto
				SET @sql_string = CAST(N'MERGE DPA_OGGETTARIO AS TARGET
					USING ( 	
						SELECT 
							[SYSTEM_ID]
							,[ID_REGISTRO]
							,[ID_AMM]
							,[VAR_DESC_OGGETTO]
							,[CHA_OCCASIONALE]
							,[VAR_COD_OGGETTO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_OGGETTARIO] WITH (NOLOCK)
						WHERE SYSTEM_ID IN
							(
							SELECT ID_OGGETTO
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[ID_REGISTRO]
							,[ID_AMM]
							,[VAR_DESC_OGGETTO]
							,[CHA_OCCASIONALE]
							,[VAR_COD_OGGETTO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_REGISTRO] = SOURCE.[ID_REGISTRO]
							,[ID_AMM] = SOURCE.[ID_AMM]
							,[VAR_DESC_OGGETTO] = SOURCE.[VAR_DESC_OGGETTO]
							,[CHA_OCCASIONALE] = SOURCE.[CHA_OCCASIONALE]
							,[VAR_COD_OGGETTO] = SOURCE.[VAR_COD_OGGETTO]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_REGISTRO]
							,[ID_AMM]
							,[VAR_DESC_OGGETTO]
							,[CHA_OCCASIONALE]
							,[VAR_COD_OGGETTO]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_REGISTRO]
							,SOURCE.[ID_AMM]
							,SOURCE.[VAR_DESC_OGGETTO]
							,SOURCE.[CHA_OCCASIONALE]
							,SOURCE.[VAR_COD_OGGETTO]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_OGGETTARIO - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_OGGETTARIO'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

				

				-- ***************
				-- DPA_OGGETTI_STO
				-- ***************
				
				--select * from PCM_040413.DPA_OGGETTI_STO -- id_profile = profile.system_id
				SET @sql_string = CAST(N'MERGE DPA_OGGETTI_STO AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[DTA_MODIFICA]
							,[ID_PROFILE]
							,[ID_OGGETTO]
							,[ID_PEOPLE]
							,[ID_RUOLO_IN_UO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_OGGETTI_STO] WITH (NOLOCK)
						WHERE [ID_PROFILE] IN
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[DTA_MODIFICA]
							,[ID_PROFILE]
							,[ID_OGGETTO]
							,[ID_PEOPLE]
							,[ID_RUOLO_IN_UO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[DTA_MODIFICA] = SOURCE.[DTA_MODIFICA]
							,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							,[ID_OGGETTO] = SOURCE.[ID_OGGETTO]
							,[ID_PEOPLE] = SOURCE.[ID_PEOPLE]
							,[ID_RUOLO_IN_UO] = SOURCE.[ID_RUOLO_IN_UO]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[DTA_MODIFICA]
							,[ID_PROFILE]
							,[ID_OGGETTO]
							,[ID_PEOPLE]
							,[ID_RUOLO_IN_UO]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[DTA_MODIFICA]
							,SOURCE.[ID_PROFILE]
							,SOURCE.[ID_OGGETTO]
							,SOURCE.[ID_PEOPLE]
							,SOURCE.[ID_RUOLO_IN_UO]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_OGGETTI_STO - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_OGGETTI_STO'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ************
				-- DPA_CORR_STO
				-- ************
				
				--select * from PCM_040413.DPA_CORR_STO -- id_profile = profile.system_id
				SET @sql_string = CAST(N'MERGE DPA_CORR_STO AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[ID_PROFILE]
							,[ID_MITT_DEST]
							,[CHA_TIPO_MITT_DES]
							,[DTA_MODIFICA]
							,[ID_PEOPLE]
							,[ID_RUOLO_IN_UO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_CORR_STO] WITH (NOLOCK)
						WHERE [ID_PROFILE] IN
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[ID_PROFILE]
							,[ID_MITT_DEST]
							,[CHA_TIPO_MITT_DES]
							,[DTA_MODIFICA]
							,[ID_PEOPLE]
							,[ID_RUOLO_IN_UO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							,[ID_MITT_DEST] = SOURCE.[ID_MITT_DEST]
							,[CHA_TIPO_MITT_DES] = SOURCE.[CHA_TIPO_MITT_DES]
							,[DTA_MODIFICA] = SOURCE.[DTA_MODIFICA]
							,[ID_PEOPLE] = SOURCE.[ID_PEOPLE]
							,[ID_RUOLO_IN_UO] = SOURCE.[ID_RUOLO_IN_UO]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_PROFILE]
							,[ID_MITT_DEST]
							,[CHA_TIPO_MITT_DES]
							,[DTA_MODIFICA]
							,[ID_PEOPLE]
							,[ID_RUOLO_IN_UO]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_PROFILE]
							,SOURCE.[ID_MITT_DEST]
							,SOURCE.[CHA_TIPO_MITT_DES]
							,SOURCE.[DTA_MODIFICA]
							,SOURCE.[ID_PEOPLE]
							,SOURCE.[ID_RUOLO_IN_UO]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_CORR_STO - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_CORR_STO'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ************
				-- DPA_CORR_STO
				-- ************
				
				--select * from PCM_040413.DPA_CORR_STO -- id_profile = profile.system_id
				SET @sql_string = CAST(N'MERGE DPA_CORR_STO AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[ID_PROFILE]
							,[ID_MITT_DEST]
							,[CHA_TIPO_MITT_DES]
							,[DTA_MODIFICA]
							,[ID_PEOPLE]
							,[ID_RUOLO_IN_UO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_CORR_STO] WITH (NOLOCK)
						WHERE [ID_PROFILE] IN
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[ID_PROFILE]
							,[ID_MITT_DEST]
							,[CHA_TIPO_MITT_DES]
							,[DTA_MODIFICA]
							,[ID_PEOPLE]
							,[ID_RUOLO_IN_UO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							,[ID_MITT_DEST] = SOURCE.[ID_MITT_DEST]
							,[CHA_TIPO_MITT_DES] = SOURCE.[CHA_TIPO_MITT_DES]
							,[DTA_MODIFICA] = SOURCE.[DTA_MODIFICA]
							,[ID_PEOPLE] = SOURCE.[ID_PEOPLE]
							,[ID_RUOLO_IN_UO] = SOURCE.[ID_RUOLO_IN_UO]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_PROFILE]
							,[ID_MITT_DEST]
							,[CHA_TIPO_MITT_DES]
							,[DTA_MODIFICA]
							,[ID_PEOPLE]
							,[ID_RUOLO_IN_UO]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_PROFILE]
							,SOURCE.[ID_MITT_DEST]
							,SOURCE.[CHA_TIPO_MITT_DES]
							,SOURCE.[DTA_MODIFICA]
							,SOURCE.[ID_PEOPLE]
							,SOURCE.[ID_RUOLO_IN_UO]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_CORR_STO - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_CORR_STO'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- *******************
				-- DPA_DATA_ARRIVO_STO
				-- *******************
				
				--select * from PCM_040413.DPA_DATA_ARRIVO_STO -- doc_number = profile.doc_number
				SET @sql_string = CAST(N'MERGE DPA_DATA_ARRIVO_STO AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[DOCNUMBER]
							,[DTA_ARRIVO]
							,[ID_GROUP]
							,[ID_PEOPLE]
							,[DTA_MODIFICA]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_DATA_ARRIVO_STO] WITH (NOLOCK)
						WHERE [DOCNUMBER] IN
							(
							SELECT DOCNUMBER
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[DOCNUMBER]
							,[DTA_ARRIVO]
							,[ID_GROUP]
							,[ID_PEOPLE]
							,[DTA_MODIFICA])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[DOCNUMBER] = SOURCE.[DOCNUMBER]
							,[DTA_ARRIVO] = SOURCE.[DTA_ARRIVO]
							,[ID_GROUP] = SOURCE.[ID_GROUP]
							,[ID_PEOPLE] = SOURCE.[ID_PEOPLE]
							,[DTA_MODIFICA] = SOURCE.[DTA_MODIFICA]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[DOCNUMBER]
							,[DTA_ARRIVO]
							,[ID_GROUP]
							,[ID_PEOPLE]
							,[DTA_MODIFICA]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[DOCNUMBER]
							,SOURCE.[DTA_ARRIVO]
							,SOURCE.[ID_GROUP]
							,SOURCE.[ID_PEOPLE]
							,SOURCE.[DTA_MODIFICA]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_DATA_ARRIVO_STO - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_DATA_ARRIVO_STO'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				

				-- ***************
				-- DPA_STATO_INVIO
				-- ***************
				
				--select * from PCM_040413.DPA_STATO_INVIO -- filtro id_profile = profile.system_id
				SET @sql_string = CAST(N'MERGE DPA_STATO_INVIO AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[ID_CORR_GLOBALE]
							,[ID_PROFILE]
							,[ID_DOC_ARRIVO_PAR]
							,[ID_CANALE]
							,[DTA_SPEDIZIONE]
							,[VAR_INDIRIZZO]
							,[VAR_CAP]
							,[VAR_CITTA]
							,[CHA_INTEROP]
							,[VAR_PROVINCIA]
							,[ID_DOCUMENTTYPE]
							,[VAR_SERVER_SMTP]
							,[NUM_PORTA_SMTP]
							,[VAR_CODICE_AOO]
							,[VAR_CODICE_AMM]
							,[VAR_PROTO_DEST]
							,[DTA_PROTO_DEST]
							,[VAR_MOTIVO_ANNULLA]
							,[CHA_ANNULLATO]
							,[VAR_PROVVEDIMENTO]
							,[STATUS_C_MASK]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_STATO_INVIO] WITH (NOLOCK)
						WHERE [ID_PROFILE] IN
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[ID_CORR_GLOBALE]
							,[ID_PROFILE]
							,[ID_DOC_ARRIVO_PAR]
							,[ID_CANALE]
							,[DTA_SPEDIZIONE]
							,[VAR_INDIRIZZO]
							,[VAR_CAP]
							,[VAR_CITTA]
							,[CHA_INTEROP]
							,[VAR_PROVINCIA]
							,[ID_DOCUMENTTYPE]
							,[VAR_SERVER_SMTP]
							,[NUM_PORTA_SMTP]
							,[VAR_CODICE_AOO]
							,[VAR_CODICE_AMM]
							,[VAR_PROTO_DEST]
							,[DTA_PROTO_DEST]
							,[VAR_MOTIVO_ANNULLA]
							,[CHA_ANNULLATO]
							,[VAR_PROVVEDIMENTO]
							,[STATUS_C_MASK])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_CORR_GLOBALE] = SOURCE.[ID_CORR_GLOBALE]
							,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							,[ID_DOC_ARRIVO_PAR] = SOURCE.[ID_DOC_ARRIVO_PAR]
							,[ID_CANALE] = SOURCE.[ID_CANALE]
							,[DTA_SPEDIZIONE] = SOURCE.[DTA_SPEDIZIONE]
							,[VAR_INDIRIZZO] = SOURCE.[VAR_INDIRIZZO]
							,[VAR_CAP] = SOURCE.[VAR_CAP]
							,[VAR_CITTA] = SOURCE.[VAR_CITTA]
							,[CHA_INTEROP] = SOURCE.[CHA_INTEROP]
							,[VAR_PROVINCIA] = SOURCE.[VAR_PROVINCIA]
							,[ID_DOCUMENTTYPE] = SOURCE.[ID_DOCUMENTTYPE]
							,[VAR_SERVER_SMTP] = SOURCE.[VAR_SERVER_SMTP]
							,[NUM_PORTA_SMTP] = SOURCE.[NUM_PORTA_SMTP]
							,[VAR_CODICE_AOO] = SOURCE.[VAR_CODICE_AOO]
							,[VAR_CODICE_AMM] = SOURCE.[VAR_CODICE_AMM]
							,[VAR_PROTO_DEST] = SOURCE.[VAR_PROTO_DEST]
							,[DTA_PROTO_DEST] = SOURCE.[DTA_PROTO_DEST]
							,[VAR_MOTIVO_ANNULLA] = SOURCE.[VAR_MOTIVO_ANNULLA]
							,[CHA_ANNULLATO] = SOURCE.[CHA_ANNULLATO]
							,[VAR_PROVVEDIMENTO] = SOURCE.[VAR_PROVVEDIMENTO]
							,[STATUS_C_MASK] = SOURCE.[STATUS_C_MASK]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_CORR_GLOBALE]
							,[ID_PROFILE]
							,[ID_DOC_ARRIVO_PAR]
							,[ID_CANALE]
							,[DTA_SPEDIZIONE]
							,[VAR_INDIRIZZO]
							,[VAR_CAP]
							,[VAR_CITTA]
							,[CHA_INTEROP]
							,[VAR_PROVINCIA]
							,[ID_DOCUMENTTYPE]
							,[VAR_SERVER_SMTP]
							,[NUM_PORTA_SMTP]
							,[VAR_CODICE_AOO]
							,[VAR_CODICE_AMM]
							,[VAR_PROTO_DEST]
							,[DTA_PROTO_DEST]
							,[VAR_MOTIVO_ANNULLA]
							,[CHA_ANNULLATO]
							,[VAR_PROVVEDIMENTO]
							,[STATUS_C_MASK]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_CORR_GLOBALE]
							,SOURCE.[ID_PROFILE]
							,SOURCE.[ID_DOC_ARRIVO_PAR]
							,SOURCE.[ID_CANALE]
							,SOURCE.[DTA_SPEDIZIONE]
							,SOURCE.[VAR_INDIRIZZO]
							,SOURCE.[VAR_CAP]
							,SOURCE.[VAR_CITTA]
							,SOURCE.[CHA_INTEROP]
							,SOURCE.[VAR_PROVINCIA]
							,SOURCE.[ID_DOCUMENTTYPE]
							,SOURCE.[VAR_SERVER_SMTP]
							,SOURCE.[NUM_PORTA_SMTP]
							,SOURCE.[VAR_CODICE_AOO]
							,SOURCE.[VAR_CODICE_AMM]
							,SOURCE.[VAR_PROTO_DEST]
							,SOURCE.[DTA_PROTO_DEST]
							,SOURCE.[VAR_MOTIVO_ANNULLA]
							,SOURCE.[CHA_ANNULLATO]
							,SOURCE.[VAR_PROVVEDIMENTO]
							,SOURCE.[STATUS_C_MASK]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_STATO_INVIO - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_STATO_INVIO'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
					
				
				
				-- ********
				-- DPA_NOTE
				-- ********
				
				--select * from PCM_040413.DPA_NOTE -- filtro idOggettoAssociato e TipoOggettoAssociato (D/F), da portare anche sul trasferimento Fascicoli
				SET @sql_string = CAST(N'MERGE DPA_NOTE AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[TESTO]
							,[DATACREAZIONE]
							,[IDUTENTECREATORE]
							,[IDRUOLOCREATORE]
							,[TIPOVISIBILITA]
							,[TIPOOGGETTOASSOCIATO]
							,[IDOGGETTOASSOCIATO]
							,[IDPEOPLEDELEGATO]
							,[IDRFASSOCIATO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_NOTE] WITH (NOLOCK)
						WHERE [TIPOOGGETTOASSOCIATO] = ''D''
						AND [IDOGGETTOASSOCIATO] IN
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[TESTO]
							,[DATACREAZIONE]
							,[IDUTENTECREATORE]
							,[IDRUOLOCREATORE]
							,[TIPOVISIBILITA]
							,[TIPOOGGETTOASSOCIATO]
							,[IDOGGETTOASSOCIATO]
							,[IDPEOPLEDELEGATO]
							,[IDRFASSOCIATO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[TESTO] = SOURCE.[TESTO]
							,[DATACREAZIONE] = SOURCE.[DATACREAZIONE]
							,[IDUTENTECREATORE] = SOURCE.[IDUTENTECREATORE]
							,[IDRUOLOCREATORE] = SOURCE.[IDRUOLOCREATORE]
							,[TIPOVISIBILITA] = SOURCE.[TIPOVISIBILITA]
							,[TIPOOGGETTOASSOCIATO] = SOURCE.[TIPOOGGETTOASSOCIATO]
							,[IDOGGETTOASSOCIATO] = SOURCE.[IDOGGETTOASSOCIATO]
							,[IDPEOPLEDELEGATO] = SOURCE.[IDPEOPLEDELEGATO]
							,[IDRFASSOCIATO] = SOURCE.[IDRFASSOCIATO]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[TESTO]
							,[DATACREAZIONE]
							,[IDUTENTECREATORE]
							,[IDRUOLOCREATORE]
							,[TIPOVISIBILITA]
							,[TIPOOGGETTOASSOCIATO]
							,[IDOGGETTOASSOCIATO]
							,[IDPEOPLEDELEGATO]
							,[IDRFASSOCIATO]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[TESTO]
							,SOURCE.[DATACREAZIONE]
							,SOURCE.[IDUTENTECREATORE]
							,SOURCE.[IDRUOLOCREATORE]
							,SOURCE.[TIPOVISIBILITA]
							,SOURCE.[TIPOOGGETTOASSOCIATO]
							,SOURCE.[IDOGGETTOASSOCIATO]
							,SOURCE.[IDPEOPLEDELEGATO]
							,SOURCE.[IDRFASSOCIATO]
						);' AS NVARCHAR(MAX))
						
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_NOTE (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_NOTE (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ******************
				-- DPA_DOC_ARRIVO_PAR
				-- ******************
				
				--select * from PCM_040413.DPA_DOC_ARRIVO_PAR -- filtro su id_profile
				SET @sql_string = CAST(N'MERGE DPA_DOC_ARRIVO_PAR AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[ID_MITT_DEST]
							,[ID_PROFILE]
							,[CHA_TIPO_MITT_DEST]
							,[ID_DOCUMENTTYPES]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_DOC_ARRIVO_PAR] WITH (NOLOCK)
						WHERE [ID_PROFILE] IN
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[ID_MITT_DEST]
							,[ID_PROFILE]
							,[CHA_TIPO_MITT_DEST]
							,[ID_DOCUMENTTYPES])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_MITT_DEST] = SOURCE.[ID_MITT_DEST]
							,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							,[CHA_TIPO_MITT_DEST] = SOURCE.[CHA_TIPO_MITT_DEST]
							,[ID_DOCUMENTTYPES] = SOURCE.[ID_DOCUMENTTYPES]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_MITT_DEST]
							,[ID_PROFILE]
							,[CHA_TIPO_MITT_DEST]
							,[ID_DOCUMENTTYPES]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_MITT_DEST]
							,SOURCE.[ID_PROFILE]
							,SOURCE.[CHA_TIPO_MITT_DEST]
							,SOURCE.[ID_DOCUMENTTYPES]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_DOC_ARRIVO_PAR - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_DOC_ARRIVO_PAR'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ****************
				-- DPA_CORR_GLOBALI
				-- ****************
				
				--select * from PCM_040413.DPA_CORR_GLOBALI -- filtro su SYSTEM_ID = DPA_DOC_ARRIVO_PAR.ID_MITT_DEST
				SET @sql_string = CAST(N'MERGE DPA_CORR_GLOBALI AS TARGET
					USING (SELECT SYSTEM_ID
							,ID_REGISTRO
							,ID_AMM
							,VAR_COD_RUBRICA
							,VAR_DESC_CORR
							,ID_OLD
							,DTA_INIZIO
							,DTA_FINE
							,ID_PARENT
							,NUM_LIVELLO
							,VAR_CODICE
							,ID_GRUPPO
							,ID_TIPO_RUOLO
							,CHA_DEFAULT_TRASM
							,ID_UO
							,VAR_COGNOME
							,VAR_NOME
							,ID_PEOPLE
							,CHA_TIPO_CORR
							,CHA_TIPO_IE
							,CHA_TIPO_URP
							,CHA_PA
							,VAR_CODICE_AOO
							,VAR_CODICE_AMM
							,VAR_CODICE_ISTAT
							,ID_PESO
							,VAR_EMAIL
							,CHA_DETTAGLI
							,NUM_FIGLI
							,VAR_SMTP
							,NUM_PORTA_SMTP
							,VAR_FAX_USER_LOGIN
							,CHA_RIFERIMENTO
							,ID_PEOPLE_LISTE
							,ID_GRUPPO_LISTE
							,CHA_RESPONSABILE
							,ID_PESO_ORG
							,CHA_SEGRETARIO
							,ID_RF
							,COD_DESC_INTEROP
							,VAR_CHIAVE_AE
							,CHA_DISABLED_TRASM
							,VAR_ORIGINAL_CODE
							,ORIGINAL_ID
							,VAR_INSERT_BY_INTEROP
							,VAR_DESC_CORR_OLD
							,INTEROPRFID
							,CLASSIFICA_UO
							,INTEROPURL
							,INTEROPREGISTRYID
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_CORR_GLOBALI WITH (NOLOCK)
						WHERE SYSTEM_ID IN
							(
							SELECT ID_MITT_DEST
							FROM DPA_DOC_ARRIVO_PAR WITH (NOLOCK)
							WHERE ID_PROFILE IN
								(
								SELECT SYSTEM_ID
								FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
								WHERE SYSTEM_ID IN
									(
									' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
									)
								OR ID_DOCUMENTO_PRINCIPALE IN
									(
									' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
									)								
								)
							)
						) 
					AS SOURCE (SYSTEM_ID
							,ID_REGISTRO
							,ID_AMM
							,VAR_COD_RUBRICA
							,VAR_DESC_CORR
							,ID_OLD
							,DTA_INIZIO
							,DTA_FINE
							,ID_PARENT
							,NUM_LIVELLO
							,VAR_CODICE
							,ID_GRUPPO
							,ID_TIPO_RUOLO
							,CHA_DEFAULT_TRASM
							,ID_UO
							,VAR_COGNOME
							,VAR_NOME
							,ID_PEOPLE
							,CHA_TIPO_CORR
							,CHA_TIPO_IE
							,CHA_TIPO_URP
							,CHA_PA
							,VAR_CODICE_AOO
							,VAR_CODICE_AMM
							,VAR_CODICE_ISTAT
							,ID_PESO
							,VAR_EMAIL
							,CHA_DETTAGLI
							,NUM_FIGLI
							,VAR_SMTP
							,NUM_PORTA_SMTP
							,VAR_FAX_USER_LOGIN
							,CHA_RIFERIMENTO
							,ID_PEOPLE_LISTE
							,ID_GRUPPO_LISTE
							,CHA_RESPONSABILE
							,ID_PESO_ORG
							,CHA_SEGRETARIO
							,ID_RF
							,COD_DESC_INTEROP
							,VAR_CHIAVE_AE
							,CHA_DISABLED_TRASM
							,VAR_ORIGINAL_CODE
							,ORIGINAL_ID
							,VAR_INSERT_BY_INTEROP
							,VAR_DESC_CORR_OLD
							,INTEROPRFID
							,CLASSIFICA_UO
							,INTEROPURL
							,INTEROPREGISTRYID
							)
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							SYSTEM_ID = SOURCE.SYSTEM_ID
							,ID_REGISTRO = SOURCE.ID_REGISTRO
							,ID_AMM = SOURCE.ID_AMM
							,VAR_COD_RUBRICA = SOURCE.VAR_COD_RUBRICA
							,VAR_DESC_CORR = SOURCE.VAR_DESC_CORR
							,ID_OLD = SOURCE.ID_OLD
							,DTA_INIZIO = SOURCE.DTA_INIZIO
							,DTA_FINE = SOURCE.DTA_FINE
							,ID_PARENT = SOURCE.ID_PARENT
							,NUM_LIVELLO = SOURCE.NUM_LIVELLO
							,VAR_CODICE = SOURCE.VAR_CODICE
							,ID_GRUPPO = SOURCE.ID_GRUPPO
							,ID_TIPO_RUOLO = SOURCE.ID_TIPO_RUOLO
							,CHA_DEFAULT_TRASM = SOURCE.CHA_DEFAULT_TRASM
							,ID_UO = SOURCE.ID_UO
							,VAR_COGNOME = SOURCE.VAR_COGNOME
							,VAR_NOME = SOURCE.VAR_NOME
							,ID_PEOPLE = SOURCE.ID_PEOPLE
							,CHA_TIPO_CORR = SOURCE.CHA_TIPO_CORR
							,CHA_TIPO_IE = SOURCE.CHA_TIPO_IE
							,CHA_TIPO_URP = SOURCE.CHA_TIPO_URP
							,CHA_PA = SOURCE.CHA_PA
							,VAR_CODICE_AOO = SOURCE.VAR_CODICE_AOO
							,VAR_CODICE_AMM = SOURCE.VAR_CODICE_AMM
							,VAR_CODICE_ISTAT = SOURCE.VAR_CODICE_ISTAT
							,ID_PESO = SOURCE.ID_PESO
							,VAR_EMAIL = SOURCE.VAR_EMAIL
							,CHA_DETTAGLI = SOURCE.CHA_DETTAGLI
							,NUM_FIGLI = SOURCE.NUM_FIGLI
							,VAR_SMTP = SOURCE.VAR_SMTP
							,NUM_PORTA_SMTP = SOURCE.NUM_PORTA_SMTP
							,VAR_FAX_USER_LOGIN = SOURCE.VAR_FAX_USER_LOGIN
							,CHA_RIFERIMENTO = SOURCE.CHA_RIFERIMENTO
							,ID_PEOPLE_LISTE = SOURCE.ID_PEOPLE_LISTE
							,ID_GRUPPO_LISTE = SOURCE.ID_GRUPPO_LISTE
							,CHA_RESPONSABILE = SOURCE.CHA_RESPONSABILE
							,ID_PESO_ORG = SOURCE.ID_PESO_ORG
							,CHA_SEGRETARIO = SOURCE.CHA_SEGRETARIO
							,ID_RF = SOURCE.ID_RF
							,COD_DESC_INTEROP = SOURCE.COD_DESC_INTEROP
							,VAR_CHIAVE_AE = SOURCE.VAR_CHIAVE_AE
							,CHA_DISABLED_TRASM = SOURCE.CHA_DISABLED_TRASM
							,VAR_ORIGINAL_CODE = SOURCE.VAR_ORIGINAL_CODE
							,ORIGINAL_ID = SOURCE.ORIGINAL_ID
							,VAR_INSERT_BY_INTEROP = SOURCE.VAR_INSERT_BY_INTEROP
							,VAR_DESC_CORR_OLD = SOURCE.VAR_DESC_CORR_OLD
							,INTEROPRFID = SOURCE.INTEROPRFID
							,CLASSIFICA_UO = SOURCE.CLASSIFICA_UO
							,INTEROPURL = SOURCE.INTEROPURL
							,INTEROPREGISTRYID = SOURCE.INTEROPREGISTRYID
					WHEN NOT MATCHED THEN
						INSERT (SYSTEM_ID
								,ID_REGISTRO
								,ID_AMM
								,VAR_COD_RUBRICA
								,VAR_DESC_CORR
								,ID_OLD
								,DTA_INIZIO
								,DTA_FINE
								,ID_PARENT
								,NUM_LIVELLO
								,VAR_CODICE
								,ID_GRUPPO
								,ID_TIPO_RUOLO
								,CHA_DEFAULT_TRASM
								,ID_UO
								,VAR_COGNOME
								,VAR_NOME
								,ID_PEOPLE
								,CHA_TIPO_CORR
								,CHA_TIPO_IE
								,CHA_TIPO_URP
								,CHA_PA
								,VAR_CODICE_AOO
								,VAR_CODICE_AMM
								,VAR_CODICE_ISTAT
								,ID_PESO
								,VAR_EMAIL
								,CHA_DETTAGLI
								,NUM_FIGLI
								,VAR_SMTP
								,NUM_PORTA_SMTP
								,VAR_FAX_USER_LOGIN
								,CHA_RIFERIMENTO
								,ID_PEOPLE_LISTE
								,ID_GRUPPO_LISTE
								,CHA_RESPONSABILE
								,ID_PESO_ORG
								,CHA_SEGRETARIO
								,ID_RF
								,COD_DESC_INTEROP
								,VAR_CHIAVE_AE
								,CHA_DISABLED_TRASM
								,VAR_ORIGINAL_CODE
								,ORIGINAL_ID
								,VAR_INSERT_BY_INTEROP
								,VAR_DESC_CORR_OLD
								,INTEROPRFID
								,CLASSIFICA_UO
								,INTEROPURL
								,INTEROPREGISTRYID
								)
						VALUES (SOURCE.SYSTEM_ID
								,SOURCE.ID_REGISTRO
								,SOURCE.ID_AMM
								,SOURCE.VAR_COD_RUBRICA
								,SOURCE.VAR_DESC_CORR
								,SOURCE.ID_OLD
								,SOURCE.DTA_INIZIO
								,SOURCE.DTA_FINE
								,SOURCE.ID_PARENT
								,SOURCE.NUM_LIVELLO
								,SOURCE.VAR_CODICE
								,SOURCE.ID_GRUPPO
								,SOURCE.ID_TIPO_RUOLO
								,SOURCE.CHA_DEFAULT_TRASM
								,SOURCE.ID_UO
								,SOURCE.VAR_COGNOME
								,SOURCE.VAR_NOME
								,SOURCE.ID_PEOPLE
								,SOURCE.CHA_TIPO_CORR
								,SOURCE.CHA_TIPO_IE
								,SOURCE.CHA_TIPO_URP
								,SOURCE.CHA_PA
								,SOURCE.VAR_CODICE_AOO
								,SOURCE.VAR_CODICE_AMM
								,SOURCE.VAR_CODICE_ISTAT
								,SOURCE.ID_PESO
								,SOURCE.VAR_EMAIL
								,SOURCE.CHA_DETTAGLI
								,SOURCE.NUM_FIGLI
								,SOURCE.VAR_SMTP
								,SOURCE.NUM_PORTA_SMTP
								,SOURCE.VAR_FAX_USER_LOGIN
								,SOURCE.CHA_RIFERIMENTO
								,SOURCE.ID_PEOPLE_LISTE
								,SOURCE.ID_GRUPPO_LISTE
								,SOURCE.CHA_RESPONSABILE
								,SOURCE.ID_PESO_ORG
								,SOURCE.CHA_SEGRETARIO
								,SOURCE.ID_RF
								,SOURCE.COD_DESC_INTEROP
								,SOURCE.VAR_CHIAVE_AE
								,SOURCE.CHA_DISABLED_TRASM
								,SOURCE.VAR_ORIGINAL_CODE
								,SOURCE.ORIGINAL_ID
								,SOURCE.VAR_INSERT_BY_INTEROP
								,SOURCE.VAR_DESC_CORR_OLD
								,SOURCE.INTEROPRFID
								,SOURCE.CLASSIFICA_UO
								,SOURCE.INTEROPURL
								,SOURCE.INTEROPREGISTRYID
								);' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento dell''organigramma - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento organigramma'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ****************
				-- DPA_DETT_GLOBALI
				-- ****************
				
				--select * from PCM_040413.DPA_DETT_GLOBALI -- legati alla tabella DPA_CORR_GLOBALI
				SET @sql_string = CAST(N'MERGE DPA_DETT_GLOBALI AS TARGET
					USING ( 	
					SELECT [SYSTEM_ID]
						  ,[ID_CORR_GLOBALI]
						  ,[VAR_INDIRIZZO]
						  ,[VAR_CAP]
						  ,[VAR_PROVINCIA]
						  ,[VAR_NAZIONE]
						  ,[VAR_COD_FISCALE]
						  ,[VAR_TELEFONO]
						  ,[VAR_TELEFONO2]
						  ,[VAR_FAX]
						  ,[VAR_NOTE]
						  ,[VAR_COD_FISC]
						  ,[VAR_CITTA]
						  ,[VAR_LOCALITA]
						  ,[VAR_LUOGO_NASCITA]
						  ,[VAR_TITOLO]
						  ,[DTA_NASCITA]
						  ,[ID_QUALIFICA_CORR]
						  ,[CHA_SESSO]
						  ,[CHAR_PROVINCIA_NASCITA]
						  ,[VAR_COD_PI]
					  FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_DETT_GLOBALI] WITH (NOLOCK)
					  WHERE [ID_CORR_GLOBALI] IN (SELECT SYSTEM_ID FROM DPA_CORR_GLOBALI WITH (NOLOCK))
					) 
					AS SOURCE ([SYSTEM_ID]
						  ,[ID_CORR_GLOBALI]
						  ,[VAR_INDIRIZZO]
						  ,[VAR_CAP]
						  ,[VAR_PROVINCIA]
						  ,[VAR_NAZIONE]
						  ,[VAR_COD_FISCALE]
						  ,[VAR_TELEFONO]
						  ,[VAR_TELEFONO2]
						  ,[VAR_FAX]
						  ,[VAR_NOTE]
						  ,[VAR_COD_FISC]
						  ,[VAR_CITTA]
						  ,[VAR_LOCALITA]
						  ,[VAR_LUOGO_NASCITA]
						  ,[VAR_TITOLO]
						  ,[DTA_NASCITA]
						  ,[ID_QUALIFICA_CORR]
						  ,[CHA_SESSO]
						  ,[CHAR_PROVINCIA_NASCITA]
						  ,[VAR_COD_PI])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
						   [SYSTEM_ID] = SOURCE.[SYSTEM_ID]
						  ,[ID_CORR_GLOBALI] = SOURCE.[ID_CORR_GLOBALI]
						  ,[VAR_INDIRIZZO] = SOURCE.[VAR_INDIRIZZO]
						  ,[VAR_CAP] = SOURCE.[VAR_CAP]
						  ,[VAR_PROVINCIA] = SOURCE.[VAR_PROVINCIA]
						  ,[VAR_NAZIONE] = SOURCE.[VAR_NAZIONE]
						  ,[VAR_COD_FISCALE] = SOURCE.[VAR_COD_FISCALE]
						  ,[VAR_TELEFONO] = SOURCE.[VAR_TELEFONO]
						  ,[VAR_TELEFONO2] = SOURCE.[VAR_TELEFONO2]
						  ,[VAR_FAX] = SOURCE.[VAR_FAX]
						  ,[VAR_NOTE] = SOURCE.[VAR_NOTE]
						  ,[VAR_COD_FISC] = SOURCE.[VAR_COD_FISC]
						  ,[VAR_CITTA] = SOURCE.[VAR_CITTA]
						  ,[VAR_LOCALITA] = SOURCE.[VAR_LOCALITA]
						  ,[VAR_LUOGO_NASCITA] = SOURCE.[VAR_LUOGO_NASCITA]
						  ,[VAR_TITOLO] = SOURCE.[VAR_TITOLO]
						  ,[DTA_NASCITA] = SOURCE.[DTA_NASCITA]
						  ,[ID_QUALIFICA_CORR] = SOURCE.[ID_QUALIFICA_CORR]
						  ,[CHA_SESSO] = SOURCE.[CHA_SESSO]
						  ,[CHAR_PROVINCIA_NASCITA] = SOURCE.[CHAR_PROVINCIA_NASCITA]
						  ,[VAR_COD_PI] = SOURCE.[VAR_COD_PI]
					WHEN NOT MATCHED THEN
						INSERT ([SYSTEM_ID]
						  ,[ID_CORR_GLOBALI]
						  ,[VAR_INDIRIZZO]
						  ,[VAR_CAP]
						  ,[VAR_PROVINCIA]
						  ,[VAR_NAZIONE]
						  ,[VAR_COD_FISCALE]
						  ,[VAR_TELEFONO]
						  ,[VAR_TELEFONO2]
						  ,[VAR_FAX]
						  ,[VAR_NOTE]
						  ,[VAR_COD_FISC]
						  ,[VAR_CITTA]
						  ,[VAR_LOCALITA]
						  ,[VAR_LUOGO_NASCITA]
						  ,[VAR_TITOLO]
						  ,[DTA_NASCITA]
						  ,[ID_QUALIFICA_CORR]
						  ,[CHA_SESSO]
						  ,[CHAR_PROVINCIA_NASCITA]
						  ,[VAR_COD_PI])
						VALUES (SOURCE.[SYSTEM_ID]
						  ,SOURCE.[ID_CORR_GLOBALI]
						  ,SOURCE.[VAR_INDIRIZZO]
						  ,SOURCE.[VAR_CAP]
						  ,SOURCE.[VAR_PROVINCIA]
						  ,SOURCE.[VAR_NAZIONE]
						  ,SOURCE.[VAR_COD_FISCALE]
						  ,SOURCE.[VAR_TELEFONO]
						  ,SOURCE.[VAR_TELEFONO2]
						  ,SOURCE.[VAR_FAX]
						  ,SOURCE.[VAR_NOTE]
						  ,SOURCE.[VAR_COD_FISC]
						  ,SOURCE.[VAR_CITTA]
						  ,SOURCE.[VAR_LOCALITA]
						  ,SOURCE.[VAR_LUOGO_NASCITA]
						  ,SOURCE.[VAR_TITOLO]
						  ,SOURCE.[DTA_NASCITA]
						  ,SOURCE.[ID_QUALIFICA_CORR]
						  ,SOURCE.[CHA_SESSO]
						  ,SOURCE.[CHAR_PROVINCIA_NASCITA]
						  ,SOURCE.[VAR_COD_PI]);' AS NVARCHAR(MAX))
					
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_DETT_GLOBALI - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_DETT_GLOBALI'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- *********************
				-- DPA_MAIL_CORR_ESTERNI
				-- *********************
				
				--select * from PCM_040413.DPA_MAIL_CORR_ESTERNI -- filtro su ID_CORR
				SET @sql_string = CAST(N'MERGE DPA_MAIL_CORR_ESTERNI AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[ID_CORR]
							,[VAR_EMAIL_REGISTRO]
							,[VAR_PRINCIPALE]
							,[VAR_NOTE]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_MAIL_CORR_ESTERNI] WITH (NOLOCK)
						WHERE [ID_CORR] IN (SELECT SYSTEM_ID FROM DPA_CORR_GLOBALI WITH (NOLOCK))
						)
					AS SOURCE ([SYSTEM_ID]
							,[ID_CORR]
							,[VAR_EMAIL_REGISTRO]
							,[VAR_PRINCIPALE]
							,[VAR_NOTE])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_CORR] = SOURCE.[ID_CORR]
							,[VAR_EMAIL_REGISTRO] = SOURCE.[VAR_EMAIL_REGISTRO]
							,[VAR_PRINCIPALE] = SOURCE.[VAR_PRINCIPALE]
							,[VAR_NOTE] = SOURCE.[VAR_NOTE]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_CORR]
							,[VAR_EMAIL_REGISTRO]
							,[VAR_PRINCIPALE]
							,[VAR_NOTE]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_CORR]
							,SOURCE.[VAR_EMAIL_REGISTRO]
							,SOURCE.[VAR_PRINCIPALE]
							,SOURCE.[VAR_NOTE]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_MAIL_CORR_ESTERNI - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_MAIL_CORR_ESTERNI'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- ***************
				-- DPA_PROF_PAROLE
				-- ***************
				
				--select * from PCM_040413.DPA_PROF_PAROLE
				SET @sql_string = CAST(N'MERGE DPA_PROF_PAROLE AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[ID_PROFILE]
							,[ID_PAROLA]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_PROF_PAROLE] WITH (NOLOCK)
						WHERE [ID_PROFILE] IN 
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[ID_PROFILE]
							,[ID_PAROLA])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							,[ID_PAROLA] = SOURCE.[ID_PAROLA]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_PROFILE]
							,[ID_PAROLA]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_PROFILE]
							,SOURCE.[ID_PAROLA]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_PROF_PAROLE - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_PROF_PAROLE'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID


				
				-- ******************
				-- DPA_STAMPAREGISTRI
				-- ******************
				
				--select * from PCM_040413.DPA_STAMPAREGISTRI -- filtro doc_number
				SET @sql_string = CAST(N'MERGE DPA_STAMPAREGISTRI AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							,[ID_REGISTRO]
							,[NUM_PROTO_START]
							,[NUM_PROTO_END]
							,[NUM_ANNO]
							,[NUM_ORD_FILE]
							,[NUM_PAGINA_END]
							,[DOCNUMBER]
							,[DTA_STAMPA]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_STAMPAREGISTRI] WITH (NOLOCK)
						WHERE [DOCNUMBER] IN 
							(
							SELECT [DOCNUMBER]
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							,[ID_REGISTRO]
							,[NUM_PROTO_START]
							,[NUM_PROTO_END]
							,[NUM_ANNO]
							,[NUM_ORD_FILE]
							,[NUM_PAGINA_END]
							,[DOCNUMBER]
							,[DTA_STAMPA])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_REGISTRO] = SOURCE.[ID_REGISTRO]
							,[NUM_PROTO_START] = SOURCE.[NUM_PROTO_START]
							,[NUM_PROTO_END] = SOURCE.[NUM_PROTO_END]
							,[NUM_ANNO] = SOURCE.[NUM_ANNO]
							,[NUM_ORD_FILE] = SOURCE.[NUM_ORD_FILE]
							,[NUM_PAGINA_END] = SOURCE.[NUM_PAGINA_END]
							,[DOCNUMBER] = SOURCE.[DOCNUMBER]
							,[DTA_STAMPA] = SOURCE.[DTA_STAMPA]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_REGISTRO]
							,[NUM_PROTO_START]
							,[NUM_PROTO_END]
							,[NUM_ANNO]
							,[NUM_ORD_FILE]
							,[NUM_PAGINA_END]
							,[DOCNUMBER]
							,[DTA_STAMPA]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_REGISTRO]
							,SOURCE.[NUM_PROTO_START]
							,SOURCE.[NUM_PROTO_END]
							,SOURCE.[NUM_ANNO]
							,SOURCE.[NUM_ORD_FILE]
							,SOURCE.[NUM_PAGINA_END]
							,SOURCE.[DOCNUMBER]
							,SOURCE.[DTA_STAMPA]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_STAMPAREGISTRI - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_STAMPAREGISTRI'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID


				
				-- ********************
				-- DPA_STAMPA_REPERTORI
				-- ********************
				
				-- filtro doc_number
				SET @sql_string = CAST(N'MERGE DPA_STAMPA_REPERTORI AS TARGET
					USING ( 	
						SELECT 
							[SYSTEM_ID]
							,[ID_REPERTORIO]
							,[NUM_REP_START]
							,[NUM_REP_END]
							,[NUM_ANNO]
							,[DOCNUMBER]
							,[DTA_STAMPA]
							,[REGISTRYID]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_STAMPA_REPERTORI] WITH (NOLOCK)
						WHERE [DOCNUMBER] IN 
							(
							SELECT [DOCNUMBER]
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE (
							[SYSTEM_ID]
							,[ID_REPERTORIO]
							,[NUM_REP_START]
							,[NUM_REP_END]
							,[NUM_ANNO]
							,[DOCNUMBER]
							,[DTA_STAMPA]
							,[REGISTRYID]
							)
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.SYSTEM_ID
							,[ID_REPERTORIO] = SOURCE.ID_REPERTORIO
							,[NUM_REP_START] = SOURCE.NUM_REP_START
							,[NUM_REP_END] = SOURCE.NUM_REP_END
							,[NUM_ANNO] = SOURCE.NUM_ANNO
							,[DOCNUMBER] = SOURCE.DOCNUMBER
							,[DTA_STAMPA] = SOURCE.DTA_STAMPA
							,[REGISTRYID] = SOURCE.REGISTRYID
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_REPERTORIO]
							,[NUM_REP_START]
							,[NUM_REP_END]
							,[NUM_ANNO]
							,[DOCNUMBER]
							,[DTA_STAMPA]
							,[REGISTRYID]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_REPERTORIO]
							,SOURCE.[NUM_REP_START]
							,SOURCE.[NUM_REP_END]
							,SOURCE.[NUM_ANNO]
							,SOURCE.[DOCNUMBER]
							,SOURCE.[DTA_STAMPA]
							,SOURCE.[REGISTRYID]
						);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_STAMPA_REPERTORI - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_STAMPA_REPERTORI'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- ************
				-- TRASMISSIONI
				-- ************
				
				SET @sql_string = CAST(N'MERGE DPA_TRASMISSIONE AS TARGET
					USING ( 	
						  SELECT [SYSTEM_ID]
							  ,[ID_RUOLO_IN_UO]
							  ,[ID_PEOPLE]
							  ,[CHA_TIPO_OGGETTO]
							  ,[ID_PROFILE]
							  ,[ID_PROJECT]
							  ,[DTA_INVIO]
							  ,[VAR_NOTE_GENERALI]
							  ,[CHA_CESSIONE]
							  ,[CHA_SALVATA_CON_CESSIONE]
							  ,[ID_PEOPLE_DELEGATO]
						  FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_TRASMISSIONE] WITH (NOLOCK)
						  WHERE [ID_PROFILE] IN 
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
							  ,[ID_RUOLO_IN_UO]
							  ,[ID_PEOPLE]
							  ,[CHA_TIPO_OGGETTO]
							  ,[ID_PROFILE]
							  ,[ID_PROJECT]
							  ,[DTA_INVIO]
							  ,[VAR_NOTE_GENERALI]
							  ,[CHA_CESSIONE]
							  ,[CHA_SALVATA_CON_CESSIONE]
							  ,[ID_PEOPLE_DELEGATO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							   [SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							  ,[ID_RUOLO_IN_UO] = SOURCE.[ID_RUOLO_IN_UO]
							  ,[ID_PEOPLE] = SOURCE.[ID_PEOPLE]
							  ,[CHA_TIPO_OGGETTO] = SOURCE.[CHA_TIPO_OGGETTO]
							  ,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							  ,[ID_PROJECT] = SOURCE.[ID_PROJECT]
							  ,[DTA_INVIO] = SOURCE.[DTA_INVIO]
							  ,[VAR_NOTE_GENERALI] = SOURCE.[VAR_NOTE_GENERALI]
							  ,[CHA_CESSIONE] = SOURCE.[CHA_CESSIONE]
							  ,[CHA_SALVATA_CON_CESSIONE] = SOURCE.[CHA_SALVATA_CON_CESSIONE]
							  ,[ID_PEOPLE_DELEGATO] = SOURCE.[ID_PEOPLE_DELEGATO]
					WHEN NOT MATCHED THEN
						INSERT ([SYSTEM_ID]
							  ,[ID_RUOLO_IN_UO]
							  ,[ID_PEOPLE]
							  ,[CHA_TIPO_OGGETTO]
							  ,[ID_PROFILE]
							  ,[ID_PROJECT]
							  ,[DTA_INVIO]
							  ,[VAR_NOTE_GENERALI]
							  ,[CHA_CESSIONE]
							  ,[CHA_SALVATA_CON_CESSIONE]
							  ,[ID_PEOPLE_DELEGATO])
						VALUES (SOURCE.[SYSTEM_ID]
							  ,SOURCE.[ID_RUOLO_IN_UO]
							  ,SOURCE.[ID_PEOPLE]
							  ,SOURCE.[CHA_TIPO_OGGETTO]
							  ,SOURCE.[ID_PROFILE]
							  ,SOURCE.[ID_PROJECT]
							  ,SOURCE.[DTA_INVIO]
							  ,SOURCE.[VAR_NOTE_GENERALI]
							  ,SOURCE.[CHA_CESSIONE]
							  ,SOURCE.[CHA_SALVATA_CON_CESSIONE]
							  ,SOURCE.[ID_PEOPLE_DELEGATO]);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della TRASMISSIONI (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella TRASMISSIONI (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				-- *****************
				-- DPA_TRASM_SINGOLA
				-- *****************
				
				SET @sql_string = CAST(N'MERGE DPA_TRASM_SINGOLA AS TARGET
				USING ( 	
					SELECT [SYSTEM_ID]
						  ,[ID_RAGIONE]
						  ,[ID_TRASMISSIONE]
						  ,[CHA_TIPO_DEST]
						  ,[ID_CORR_GLOBALE]
						  ,[VAR_NOTE_SING]
						  ,[CHA_TIPO_TRASM]
						  ,[DTA_SCADENZA]
						  ,[ID_TRASM_UTENTE]
						  ,[CHA_SET_EREDITA]
						  ,[HIDE_DOC_VERSIONS]
					FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_TRASM_SINGOLA] WITH (NOLOCK)
					WHERE ID_TRASMISSIONE IN 
						(
						SELECT SYSTEM_ID 
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TRASMISSIONE WITH (NOLOCK)
						WHERE [ID_PROFILE] IN 
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)			
				)
				AS SOURCE ([SYSTEM_ID]
						  ,[ID_RAGIONE]
						  ,[ID_TRASMISSIONE]
						  ,[CHA_TIPO_DEST]
						  ,[ID_CORR_GLOBALE]
						  ,[VAR_NOTE_SING]
						  ,[CHA_TIPO_TRASM]
						  ,[DTA_SCADENZA]
						  ,[ID_TRASM_UTENTE]
						  ,[CHA_SET_EREDITA]
						  ,[HIDE_DOC_VERSIONS])
				ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
				WHEN MATCHED THEN
					UPDATE SET
						   [SYSTEM_ID] = SOURCE.[SYSTEM_ID]
						  ,[ID_RAGIONE] = SOURCE.[ID_RAGIONE]
						  ,[ID_TRASMISSIONE] = SOURCE.[ID_TRASMISSIONE]
						  ,[CHA_TIPO_DEST] = SOURCE.[CHA_TIPO_DEST]
						  ,[ID_CORR_GLOBALE] = SOURCE.[ID_CORR_GLOBALE]
						  ,[VAR_NOTE_SING] = SOURCE.[VAR_NOTE_SING]
						  ,[CHA_TIPO_TRASM] = SOURCE.[CHA_TIPO_TRASM]
						  ,[DTA_SCADENZA] = SOURCE.[DTA_SCADENZA]
						  ,[ID_TRASM_UTENTE] = SOURCE.[ID_TRASM_UTENTE]
						  ,[CHA_SET_EREDITA] = SOURCE.[CHA_SET_EREDITA]
						  ,[HIDE_DOC_VERSIONS] = SOURCE.[HIDE_DOC_VERSIONS]
				WHEN NOT MATCHED THEN
					INSERT ([SYSTEM_ID]
						  ,[ID_RAGIONE]
						  ,[ID_TRASMISSIONE]
						  ,[CHA_TIPO_DEST]
						  ,[ID_CORR_GLOBALE]
						  ,[VAR_NOTE_SING]
						  ,[CHA_TIPO_TRASM]
						  ,[DTA_SCADENZA]
						  ,[ID_TRASM_UTENTE]
						  ,[CHA_SET_EREDITA]
						  ,[HIDE_DOC_VERSIONS])
					VALUES (SOURCE.[SYSTEM_ID]
						  ,SOURCE.[ID_RAGIONE]
						  ,SOURCE.[ID_TRASMISSIONE]
						  ,SOURCE.[CHA_TIPO_DEST]
						  ,SOURCE.[ID_CORR_GLOBALE]
						  ,SOURCE.[VAR_NOTE_SING]
						  ,SOURCE.[CHA_TIPO_TRASM]
						  ,SOURCE.[DTA_SCADENZA]
						  ,SOURCE.[ID_TRASM_UTENTE]
						  ,SOURCE.[CHA_SET_EREDITA]
						  ,SOURCE.[HIDE_DOC_VERSIONS]);' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_TRASM_SINGOLA (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_TRASM_SINGOLA (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- ****************
				-- DPA_TRASM_UTENTE
				-- ****************
				
				SET @sql_string = CAST(N'MERGE DPA_TRASM_UTENTE AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
							  ,[ID_TRASM_SINGOLA]
							  ,[ID_PEOPLE]
							  ,[DTA_VISTA]
							  ,[DTA_ACCETTATA]
							  ,[DTA_RIFIUTATA]
							  ,[DTA_RISPOSTA]
							  ,[CHA_VISTA]
							  ,[CHA_ACCETTATA]
							  ,[CHA_RIFIUTATA]
							  ,[VAR_NOTE_ACC]
							  ,[VAR_NOTE_RIF]
							  ,[CHA_VALIDA]
							  ,[ID_TRASM_RISP_SING]
							  ,[CHA_IN_TODOLIST]
							  ,[DTA_RIMOZIONE_TODOLIST]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_ACCETTATA_DELEGATO]
							  ,[CHA_VISTA_DELEGATO]
							  ,[CHA_RIFIUTATA_DELEGATO]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_TRASM_UTENTE] WITH (NOLOCK)
						WHERE ID_TRASM_SINGOLA IN
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TRASM_SINGOLA WITH (NOLOCK)
							WHERE ID_TRASMISSIONE IN 
								(
								SELECT SYSTEM_ID 
								FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TRASMISSIONE WITH (NOLOCK)
								WHERE [ID_PROFILE] IN 
									(
									SELECT SYSTEM_ID
									FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
									WHERE SYSTEM_ID IN
										(
										' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
										)
									OR ID_DOCUMENTO_PRINCIPALE IN
										(
										' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
										)								
									)
								)
							)		
						)
					AS SOURCE ([SYSTEM_ID]
							  ,[ID_TRASM_SINGOLA]
							  ,[ID_PEOPLE]
							  ,[DTA_VISTA]
							  ,[DTA_ACCETTATA]
							  ,[DTA_RIFIUTATA]
							  ,[DTA_RISPOSTA]
							  ,[CHA_VISTA]
							  ,[CHA_ACCETTATA]
							  ,[CHA_RIFIUTATA]
							  ,[VAR_NOTE_ACC]
							  ,[VAR_NOTE_RIF]
							  ,[CHA_VALIDA]
							  ,[ID_TRASM_RISP_SING]
							  ,[CHA_IN_TODOLIST]
							  ,[DTA_RIMOZIONE_TODOLIST]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_ACCETTATA_DELEGATO]
							  ,[CHA_VISTA_DELEGATO]
							  ,[CHA_RIFIUTATA_DELEGATO])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							   [SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							  ,[ID_TRASM_SINGOLA] = SOURCE.[ID_TRASM_SINGOLA]
							  ,[ID_PEOPLE] = SOURCE.[ID_PEOPLE]
							  ,[DTA_VISTA] = SOURCE.[DTA_VISTA]
							  ,[DTA_ACCETTATA] = SOURCE.[DTA_ACCETTATA]
							  ,[DTA_RIFIUTATA] = SOURCE.[DTA_RIFIUTATA]
							  ,[DTA_RISPOSTA] = SOURCE.[DTA_RISPOSTA]
							  ,[CHA_VISTA] = SOURCE.[CHA_VISTA]
							  ,[CHA_ACCETTATA] = SOURCE.[CHA_ACCETTATA]
							  ,[CHA_RIFIUTATA] = SOURCE.[CHA_RIFIUTATA]
							  ,[VAR_NOTE_ACC] = SOURCE.[VAR_NOTE_ACC]
							  ,[VAR_NOTE_RIF] = SOURCE.[VAR_NOTE_RIF]
							  ,[CHA_VALIDA] = SOURCE.[CHA_VALIDA]
							  ,[ID_TRASM_RISP_SING] = SOURCE.[ID_TRASM_RISP_SING]
							  ,[CHA_IN_TODOLIST] = SOURCE.[CHA_IN_TODOLIST]
							  ,[DTA_RIMOZIONE_TODOLIST] = SOURCE.[DTA_RIMOZIONE_TODOLIST]
							  ,[ID_PEOPLE_DELEGATO] = SOURCE.[ID_PEOPLE_DELEGATO]
							  ,[CHA_ACCETTATA_DELEGATO] = SOURCE.[CHA_ACCETTATA_DELEGATO]
							  ,[CHA_VISTA_DELEGATO] = SOURCE.[CHA_VISTA_DELEGATO]
							  ,[CHA_RIFIUTATA_DELEGATO] = SOURCE.[CHA_RIFIUTATA_DELEGATO]
					WHEN NOT MATCHED THEN
						INSERT ([SYSTEM_ID]
							  ,[ID_TRASM_SINGOLA]
							  ,[ID_PEOPLE]
							  ,[DTA_VISTA]
							  ,[DTA_ACCETTATA]
							  ,[DTA_RIFIUTATA]
							  ,[DTA_RISPOSTA]
							  ,[CHA_VISTA]
							  ,[CHA_ACCETTATA]
							  ,[CHA_RIFIUTATA]
							  ,[VAR_NOTE_ACC]
							  ,[VAR_NOTE_RIF]
							  ,[CHA_VALIDA]
							  ,[ID_TRASM_RISP_SING]
							  ,[CHA_IN_TODOLIST]
							  ,[DTA_RIMOZIONE_TODOLIST]
							  ,[ID_PEOPLE_DELEGATO]
							  ,[CHA_ACCETTATA_DELEGATO]
							  ,[CHA_VISTA_DELEGATO]
							  ,[CHA_RIFIUTATA_DELEGATO])
						VALUES (SOURCE.[SYSTEM_ID]
							  ,SOURCE.[ID_TRASM_SINGOLA]
							  ,SOURCE.[ID_PEOPLE]
							  ,SOURCE.[DTA_VISTA]
							  ,SOURCE.[DTA_ACCETTATA]
							  ,SOURCE.[DTA_RIFIUTATA]
							  ,SOURCE.[DTA_RISPOSTA]
							  ,SOURCE.[CHA_VISTA]
							  ,SOURCE.[CHA_ACCETTATA]
							  ,SOURCE.[CHA_RIFIUTATA]
							  ,SOURCE.[VAR_NOTE_ACC]
							  ,SOURCE.[VAR_NOTE_RIF]
							  ,SOURCE.[CHA_VALIDA]
							  ,SOURCE.[ID_TRASM_RISP_SING]
							  ,SOURCE.[CHA_IN_TODOLIST]
							  ,SOURCE.[DTA_RIMOZIONE_TODOLIST]
							  ,SOURCE.[ID_PEOPLE_DELEGATO]
							  ,SOURCE.[CHA_ACCETTATA_DELEGATO]
							  ,SOURCE.[CHA_VISTA_DELEGATO]
							  ,SOURCE.[CHA_RIFIUTATA_DELEGATO]);' AS NVARCHAR(MAX))
				
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_TRASM_UTENTE (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_TRASM_UTENTE (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- ***********************
				-- DPA_ITEMS_CONSERVAZIONE
				-- ***********************
				
				SET @sql_string = CAST(N'MERGE DPA_ITEMS_CONSERVAZIONE AS TARGET
					USING ( 	
						SELECT [SYSTEM_ID]
						,[ID_CONSERVAZIONE]
						,[ID_PROFILE]
						,[ID_PROJECT]
						,[CHA_TIPO_DOC]
						,[VAR_OGGETTO]
						,[ID_REGISTRO]
						,[DATA_INS]
						,[CHA_STATO]
						,[VAR_XML_METADATI]
						,[SIZE_ITEM]
						,[COD_FASC]
						,[DOCNUMBER]
						,[VAR_TIPO_FILE]
						,[NUMERO_ALLEGATI]
						,[CHA_TIPO_OGGETTO]
						,[CHA_ESITO]
						,[VAR_TIPO_ATTO]
						,[POLICY_VALIDA]
						,[VALIDAZIONE_FIRMA]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_ITEMS_CONSERVAZIONE] WITH (NOLOCK)
						WHERE [ID_PROFILE] IN 
							(
							SELECT SYSTEM_ID
							FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
							WHERE SYSTEM_ID IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)
							OR ID_DOCUMENTO_PRINCIPALE IN
								(
								' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
								)								
							)
						)
					AS SOURCE ([SYSTEM_ID]
						,[ID_CONSERVAZIONE]
						,[ID_PROFILE]
						,[ID_PROJECT]
						,[CHA_TIPO_DOC]
						,[VAR_OGGETTO]
						,[ID_REGISTRO]
						,[DATA_INS]
						,[CHA_STATO]
						,[VAR_XML_METADATI]
						,[SIZE_ITEM]
						,[COD_FASC]
						,[DOCNUMBER]
						,[VAR_TIPO_FILE]
						,[NUMERO_ALLEGATI]
						,[CHA_TIPO_OGGETTO]
						,[CHA_ESITO]
						,[VAR_TIPO_ATTO]
						,[POLICY_VALIDA]
						,[VALIDAZIONE_FIRMA])
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[ID_CONSERVAZIONE] = SOURCE.[ID_CONSERVAZIONE]
							,[ID_PROFILE] = SOURCE.[ID_PROFILE]
							,[ID_PROJECT] = SOURCE.[ID_PROJECT]
							,[CHA_TIPO_DOC] = SOURCE.[CHA_TIPO_DOC]
							,[VAR_OGGETTO] = SOURCE.[VAR_OGGETTO]
							,[ID_REGISTRO] = SOURCE.[ID_REGISTRO]
							,[DATA_INS] = SOURCE.[DATA_INS]
							,[CHA_STATO] = SOURCE.[CHA_STATO]
							,[VAR_XML_METADATI] = SOURCE.[VAR_XML_METADATI]
							,[SIZE_ITEM] = SOURCE.[SIZE_ITEM]
							,[COD_FASC] = SOURCE.[COD_FASC]
							,[DOCNUMBER] = SOURCE.[DOCNUMBER]
							,[VAR_TIPO_FILE] = SOURCE.[VAR_TIPO_FILE]
							,[NUMERO_ALLEGATI] = SOURCE.[NUMERO_ALLEGATI]
							,[CHA_TIPO_OGGETTO] = SOURCE.[CHA_TIPO_OGGETTO]
							,[CHA_ESITO] = SOURCE.[CHA_ESITO]
							,[VAR_TIPO_ATTO] = SOURCE.[VAR_TIPO_ATTO]
							,[POLICY_VALIDA] = SOURCE.[POLICY_VALIDA]
							,[VALIDAZIONE_FIRMA] = SOURCE.[VALIDAZIONE_FIRMA]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[ID_CONSERVAZIONE]
							,[ID_PROFILE]
							,[ID_PROJECT]
							,[CHA_TIPO_DOC]
							,[VAR_OGGETTO]
							,[ID_REGISTRO]
							,[DATA_INS]
							,[CHA_STATO]
							,[VAR_XML_METADATI]
							,[SIZE_ITEM]
							,[COD_FASC]
							,[DOCNUMBER]
							,[VAR_TIPO_FILE]
							,[NUMERO_ALLEGATI]
							,[CHA_TIPO_OGGETTO]
							,[CHA_ESITO]
							,[VAR_TIPO_ATTO]
							,[POLICY_VALIDA]
							,[VALIDAZIONE_FIRMA]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[ID_CONSERVAZIONE]
							,SOURCE.[ID_PROFILE]
							,SOURCE.[ID_PROJECT]
							,SOURCE.[CHA_TIPO_DOC]
							,SOURCE.[VAR_OGGETTO]
							,SOURCE.[ID_REGISTRO]
							,SOURCE.[DATA_INS]
							,SOURCE.[CHA_STATO]
							,SOURCE.[VAR_XML_METADATI]
							,SOURCE.[SIZE_ITEM]
							,SOURCE.[COD_FASC]
							,SOURCE.[DOCNUMBER]
							,SOURCE.[VAR_TIPO_FILE]
							,SOURCE.[NUMERO_ALLEGATI]
							,SOURCE.[CHA_TIPO_OGGETTO]
							,SOURCE.[CHA_ESITO]
							,SOURCE.[VAR_TIPO_ATTO]
							,SOURCE.[POLICY_VALIDA]
							,SOURCE.[VALIDAZIONE_FIRMA]
						);' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_ITEMS_CONSERVAZIONE (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_ITEMS_CONSERVAZIONE (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- *******************
				-- DPA_LOG (Documenti)
				-- *******************
				
				SET @sql_string = CAST(N'MERGE DPA_LOG AS TARGET
					USING ( 	
						SELECT 
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							,[ID_TRASM_SINGOLA]
							,[CHECK_NOTIFY]
							,[DESC_PRODUCER]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_LOG] WITH (NOLOCK)
						WHERE [VAR_OGGETTO] = ''DOCUMENTO''
						AND [ID_OGGETTO] IN
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
							)
						)
					AS SOURCE (
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							,[ID_TRASM_SINGOLA]
							,[CHECK_NOTIFY]
							,[DESC_PRODUCER]
							)
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[USERID_OPERATORE] = SOURCE.[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE] = SOURCE.[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE] = SOURCE.[ID_GRUPPO_OPERATORE]
							,[ID_AMM] = SOURCE.[ID_AMM]
							,[DTA_AZIONE] = SOURCE.[DTA_AZIONE]
							,[VAR_OGGETTO] = SOURCE.[VAR_OGGETTO]
							,[ID_OGGETTO] = SOURCE.[ID_OGGETTO]
							,[VAR_DESC_OGGETTO] = SOURCE.[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE] = SOURCE.[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE] = SOURCE.[VAR_DESC_AZIONE]
							,[CHA_ESITO] = SOURCE.[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION] = SOURCE.[VAR_COD_WORKING_APPLICATION]
							,[ID_TRASM_SINGOLA] = SOURCE.[ID_TRASM_SINGOLA]
							,[CHECK_NOTIFY] = SOURCE.[CHECK_NOTIFY]
							,[DESC_PRODUCER] = SOURCE.[DESC_PRODUCER]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							,[ID_TRASM_SINGOLA]
							,[CHECK_NOTIFY]
							,[DESC_PRODUCER]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[USERID_OPERATORE]
							,SOURCE.[ID_PEOPLE_OPERATORE]
							,SOURCE.[ID_GRUPPO_OPERATORE]
							,SOURCE.[ID_AMM]
							,SOURCE.[DTA_AZIONE]
							,SOURCE.[VAR_OGGETTO]
							,SOURCE.[ID_OGGETTO]
							,SOURCE.[VAR_DESC_OGGETTO]
							,SOURCE.[VAR_COD_AZIONE]
							,SOURCE.[VAR_DESC_AZIONE]
							,SOURCE.[CHA_ESITO]
							,SOURCE.[VAR_COD_WORKING_APPLICATION]
							,SOURCE.[ID_TRASM_SINGOLA]
							,SOURCE.[CHECK_NOTIFY]
							,SOURCE.[DESC_PRODUCER]
						);' AS NVARCHAR(MAX))
						
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_LOG (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_LOG (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- ***************************
				-- DPA_LOG_STORICO (Documenti)
				-- ***************************

				
				SET @sql_string = CAST(N'MERGE DPA_LOG_STORICO AS TARGET
					USING ( 	
						SELECT 
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[DPA_LOG_STORICO] WITH (NOLOCK)
						WHERE [VAR_OGGETTO] = ''DOCUMENTO''
						AND [ID_OGGETTO] IN
							(
							' AS NVARCHAR(MAX)) + CAST(@sql_filtroProfile AS NVARCHAR(MAX)) + CAST(N'
							)
						)
					AS SOURCE (
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							)
					ON (TARGET.SYSTEM_ID = SOURCE.SYSTEM_ID)
					WHEN MATCHED THEN
						UPDATE SET
							[SYSTEM_ID] = SOURCE.[SYSTEM_ID]
							,[USERID_OPERATORE] = SOURCE.[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE] = SOURCE.[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE] = SOURCE.[ID_GRUPPO_OPERATORE]
							,[ID_AMM] = SOURCE.[ID_AMM]
							,[DTA_AZIONE] = SOURCE.[DTA_AZIONE]
							,[VAR_OGGETTO] = SOURCE.[VAR_OGGETTO]
							,[ID_OGGETTO] = SOURCE.[ID_OGGETTO]
							,[VAR_DESC_OGGETTO] = SOURCE.[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE] = SOURCE.[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE] = SOURCE.[VAR_DESC_AZIONE]
							,[CHA_ESITO] = SOURCE.[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION] = SOURCE.[VAR_COD_WORKING_APPLICATION]
					WHEN NOT MATCHED THEN
						INSERT (
							[SYSTEM_ID]
							,[USERID_OPERATORE]
							,[ID_PEOPLE_OPERATORE]
							,[ID_GRUPPO_OPERATORE]
							,[ID_AMM]
							,[DTA_AZIONE]
							,[VAR_OGGETTO]
							,[ID_OGGETTO]
							,[VAR_DESC_OGGETTO]
							,[VAR_COD_AZIONE]
							,[VAR_DESC_AZIONE]
							,[CHA_ESITO]
							,[VAR_COD_WORKING_APPLICATION]
							)
						VALUES (
							SOURCE.[SYSTEM_ID]
							,SOURCE.[USERID_OPERATORE]
							,SOURCE.[ID_PEOPLE_OPERATORE]
							,SOURCE.[ID_GRUPPO_OPERATORE]
							,SOURCE.[ID_AMM]
							,SOURCE.[DTA_AZIONE]
							,SOURCE.[VAR_OGGETTO]
							,SOURCE.[ID_OGGETTO]
							,SOURCE.[VAR_DESC_OGGETTO]
							,SOURCE.[VAR_COD_AZIONE]
							,SOURCE.[VAR_DESC_AZIONE]
							,SOURCE.[CHA_ESITO]
							,SOURCE.[VAR_COD_WORKING_APPLICATION]
						);' AS NVARCHAR(MAX))
						
				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento della tabella DPA_LOG_STORICO (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento tabella DPA_LOG_STORICO (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- *************************************************************************
				-- Gestione del flag CHA_IN_ARCHIVIO (1 se è una copia, altrimenti 0)
				-- Imposta a 0 tutti i documenti coinvolti e poi a 1 quelli portati in COPIA
				-- *************************************************************************

				SET @sql_string = CAST(N'
					UPDATE PROFILE SET CHA_IN_ARCHIVIO = 0
					WHERE SYSTEM_ID IN
						(
						SELECT SYSTEM_ID 
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
						WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=SYSTEM_ID)
						UNION
						SELECT SYSTEM_ID 
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
						WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=ID_DOCUMENTO_PRINCIPALE)							
						)' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento del flag CHA_IN_ARCHIVIO(0) per la tabella PROFILE (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento flag CHA_IN_ARCHIVIO(0) per la tabella PROFILE (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
				
				
				SET @sql_string = CAST(N'
					UPDATE PROFILE SET CHA_IN_ARCHIVIO = 1
					WHERE SYSTEM_ID IN
						(
						SELECT SYSTEM_ID 
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
						WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=SYSTEM_ID)
						UNION
						SELECT SYSTEM_ID 
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE WITH (NOLOCK)
						WHERE EXISTS (SELECT ''X'' FROM #oggettiDaTrasferire WHERE ID=ID_DOCUMENTO_PRINCIPALE)							
						)
					AND
						(
						SYSTEM_ID IN
							(
							SELECT PROFILE_ID
							FROM ARCHIVE_TEMPPROFILE
							WHERE TIPOTRASFERIMENTO_VERSAMENTO = ''COPIA''
							)
						OR
						ID_DOCUMENTO_PRINCIPALE IN
							(
							SELECT PROFILE_ID
							FROM ARCHIVE_TEMPPROFILE
							WHERE TIPOTRASFERIMENTO_VERSAMENTO = ''COPIA''
							)
						)
					' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento del flag CHA_IN_ARCHIVIO(1) per la tabella PROFILE (Documenti) - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Aggiornamento flag CHA_IN_ARCHIVIO(1) per la tabella PROFILE (Documenti)'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



				-- Elimina gli oggetti trasferiti dalla tabella temp della transazione
				--
				delete from ARCHIVE_TEMPTRANSFERPROFILE where PROFILE_ID in
				(
				select ID from #oggettiDaTrasferire
				)
				
				COMMIT TRANSACTION T1

			END
		ELSE
			SET @hasNext = 0
		END



	-- Se ho trasferito tutti i dati, passo il versamento in stato EFFETTUATO ed elimino i dati dal Corrente
	--
	DECLARE @numeroFascicoliNonTrasferiti INT
	DECLARE @numeroDocumentiNonTrasferiti INT
	
	SELECT @numeroFascicoliNonTrasferiti = COUNT(DISTINCT TP.PROJECT_ID) --DISTINCT TP.PROJECT_ID, TF.PROJECT_ID, F.SYSTEM_ID
	FROM ARCHIVE_TEMPPROJECT TP INNER JOIN ARCHIVE_TRANSFERPOLICY P ON TP.TRANSFERPOLICY_ID = P.SYSTEM_ID
	LEFT OUTER JOIN ARCHIVE_TEMPTRANSFERPROJECT TF ON TP.PROJECT_ID = TF.PROJECT_ID
	LEFT OUTER JOIN PROJECT F ON TP.PROJECT_ID = F.SYSTEM_ID
	WHERE P.TRANSFER_ID = @TransferID
	AND P.ENABLED = 1
	AND TP.DATRASFERIRE = 1
	AND (F.SYSTEM_ID IS NULL OR NOT TF.PROJECT_ID IS NULL)
	
	SELECT @numeroDocumentiNonTrasferiti = COUNT(DISTINCT TP.PROFILE_ID) --DISTINCT TP.PROJECT_ID, TF.PROJECT_ID, F.SYSTEM_ID
	FROM ARCHIVE_TEMPPROFILE TP INNER JOIN ARCHIVE_TRANSFERPOLICY P ON TP.TRANSFERPOLICY_ID = P.SYSTEM_ID
	LEFT OUTER JOIN ARCHIVE_TEMPTRANSFERPROFILE TD ON TP.PROFILE_ID = TD.PROFILE_ID
	LEFT OUTER JOIN PROFILE D ON TP.PROFILE_ID = D.SYSTEM_ID
	WHERE P.TRANSFER_ID = @TransferID
	AND P.ENABLED = 1
	AND (D.SYSTEM_ID IS NULL OR NOT TD.PROFILE_ID IS NULL)
	
	print '@numeroFascicoliNonTrasferiti: ' + cast(@numeroFascicoliNonTrasferiti as varchar(10))
	print '@numeroDocumentiNonTrasferiti: ' + cast(@numeroDocumentiNonTrasferiti as varchar(10))
	
	-- Se sono stati trasferiti tutti i fascicoli e tutti i documenti:
	--		- Inserisce i dati dei file da spostare, solo per i documenti trasferiti effettivamente
	--		- Aggiorna lo stato del versamento a EFFETTUATO
	--		- Elimina i dati dal corrente
	--
	IF (@numeroFascicoliNonTrasferiti = 0 AND @numeroDocumentiNonTrasferiti = 0)
		BEGIN

			BEGIN TRANSACTION T2

			-- Se l'installazione lo prevede, vengono spostati i file dei documenti trasferiti effettivamente.
			-- Legge il valore SPOSTA_FILE dalla tabella di configurazione dell'archivio.
			--
			DECLARE @spostaFile INT
			
			SELECT @spostaFile=[VALUE] FROM ARCHIVE_CONFIGURATION
			WHERE [KEY] = 'SPOSTA_FILE'
			
			IF ISNULL(@spostaFile, 0) = 1
			BEGIN
			
				SET @sql_string = CAST(N'
					INSERT INTO ARCHIVE_TempTransferFile
						(
						  Transfer_ID
						, DocNumber
						, Version_ID
						, OriginalPath
						, OriginalHash
						, Processed
						, ProcessResult
						, ProcessError
						)
					SELECT 
						' AS NVARCHAR(MAX)) + CAST(@TransferID AS NVARCHAR(MAX)) + CAST(N'
						, DOCNUMBER
						, VERSION_ID
						, PATH
						, VAR_IMPRONTA
						, 0
						, NULL
						, NULL
					FROM COMPONENTS
					WHERE DOCNUMBER IN
						(
						SELECT DOCNUMBER
						FROM PROFILE P 
						WHERE SYSTEM_ID IN
							(
							SELECT DISTINCT D.SYSTEM_ID
							FROM PROFILE D INNER JOIN ARCHIVE_TEMPPROFILE T ON D.SYSTEM_ID = T.PROFILE_ID
							INNER JOIN ARCHIVE_TRANSFERPOLICY TP ON T.TRANSFERPOLICY_ID = TP.SYSTEM_ID
							WHERE TP.TRANSFER_ID = ' AS NVARCHAR(MAX)) + CAST(@TransferID AS NVARCHAR(MAX)) + CAST(N'
							AND T.TIPOTRASFERIMENTO_VERSAMENTO = ''TRASFERIMENTO''
							UNION
							SELECT DISTINCT D.SYSTEM_ID
							FROM PROFILE D INNER JOIN ARCHIVE_TEMPPROFILE T ON D.ID_DOCUMENTO_PRINCIPALE = T.PROFILE_ID
							INNER JOIN ARCHIVE_TRANSFERPOLICY TP ON T.TRANSFERPOLICY_ID = TP.SYSTEM_ID
							WHERE TP.TRANSFER_ID = ' AS NVARCHAR(MAX)) + CAST(@TransferID AS NVARCHAR(MAX)) + CAST(N'
							AND T.TIPOTRASFERIMENTO_VERSAMENTO = ''TRASFERIMENTO''
							)
						)
					' AS NVARCHAR(MAX))

				PRINT @sql_string;

				EXECUTE sp_executesql @sql_string;

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK

					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''inserimento dei dati relativi ai file da spostare - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
				
				set @logType = 'INFO'
				set @log = 'Inserimento dati relativi ai file da spostare'
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
			
			END



			-- Aggiorna lo stato del versamento a EFFETTUATO
			--	
			EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
					@Transfer_ID = @TransferID,
					@TransferStateType_ID = @transferStateType_EFFETTUATO,
					@System_ID = @System_ID OUTPUT

			set @errorCode = @@ERROR

			IF @errorCode <> 0
			BEGIN
				-- Rollback the transaction
				ROLLBACK
			
				-- Aggiorna lo stato del versamento a IN ERRORE
				--	
				EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
						@Transfer_ID = @TransferID,
						@TransferStateType_ID = @transferStateType_IN_ERRORE,
						@System_ID = @System_ID OUTPUT
				
				set @logType = 'ERROR'
				set @log = 'Errore durante l''aggiornamento dello stato a EFFETTUATO per il Transfer: ' + CAST(@TransferID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

				-- Raise an error and return
				RAISERROR (@log, 16, 1)
				RETURN
			END
					
			set @logType = 'INFO'
			set @log = 'Aggiornamento stato a EFFETTUATO per il Transfer: ' + CAST(@TransferID AS NVARCHAR(MAX))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID



			-- Se non ci sono file da spostare aggiorna lo stato del versamento a EFFETTUATO COMPRESI FILE,
			-- altrimento lo stato verrà aggiornato dopo il processamento della tabella ARCHIVE_TempTransferFile
			--
			DECLARE @numFilaDaSpostare INT
			
			SELECT @numFilaDaSpostare = COUNT(*) FROM ARCHIVE_TempTransferFile WHERE Transfer_ID = @TransferID
			
			IF @numFilaDaSpostare = 0
			BEGIN
			
				-- Aggiorna lo stato del versamento a EFFETTUATO COMPRESI FILE
				--	
				EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
						@Transfer_ID = @TransferID,
						@TransferStateType_ID = @transferStateType_EFFETTUATO_COMPRESI_FILE,
						@System_ID = @System_ID OUTPUT

				set @errorCode = @@ERROR

				IF @errorCode <> 0
				BEGIN
					-- Rollback the transaction
					ROLLBACK
				
					-- Aggiorna lo stato del versamento a IN ERRORE
					--	
					EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
							@Transfer_ID = @TransferID,
							@TransferStateType_ID = @transferStateType_IN_ERRORE,
							@System_ID = @System_ID OUTPUT
					
					set @logType = 'ERROR'
					set @log = 'Errore durante l''aggiornamento dello stato a EFFETTUATO COMPRESI FILE per il Transfer: ' + CAST(@TransferID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

					-- Raise an error and return
					RAISERROR (@log, 16, 1)
					RETURN
				END
						
				set @logType = 'INFO'
				set @log = 'Aggiornamento stato a EFFETTUATO per il Transfer: ' + CAST(@TransferID AS NVARCHAR(MAX))
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
				
			END



			COMMIT TRANSACTION T2



			-- Dopo aver chiuso la transazione in modo regolare, viene invocata la procedura che cancella e consolida i dati del Corrente
			--
			EXECUTE sp_ARCHIVE_BE_DeleteObjectsFromCurrentScheme @TransferID

			set @returnValue = 1
			RETURN(@returnValue)
			
		END
	
END
