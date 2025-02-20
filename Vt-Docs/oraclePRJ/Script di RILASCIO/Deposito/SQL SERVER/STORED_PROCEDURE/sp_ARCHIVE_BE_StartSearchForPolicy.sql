USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_InitTempAnaliysForPolicy]    Script Date: 04/17/2013 15:36:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================
-- Author:		Giovanni Olivari
-- Create date: 15/04/2013
-- Description:	Inizializza le tabelle temporanee utilizzate
--              per l'analisi di impatto della policy
-- =========================================================
ALTER PROCEDURE [DOCSADM].[sp_ARCHIVE_BE_StartSearchForPolicy] 
	@PolicyID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @log VARCHAR(2000)
	DECLARE @logType VARCHAR(10)
	DECLARE @logObject VARCHAR(50) = OBJECT_NAME(@@PROCID)
	DECLARE @logObjectType_TransferPolicy int = 2 -- 'TransferPolicy'
	DECLARE @logObjectID int = @PolicyID
	DECLARE @errorCode int

	DECLARE @sql_string nvarchar(MAX)
	DECLARE @nomeSchemaCorrente varchar(200) 
	DECLARE @nomeUtenteCorrente varchar(200) 
	DECLARE @nomeUtenteDeposito varchar(200) 
	
	DECLARE @tipoPolicy VARCHAR(50)
	DECLARE @idRegistro int
	DECLARE @idUO int
	DECLARE @includiSottoalberoUO int
	DECLARE @idTipologia int
	DECLARE @idTitolario int
	DECLARE @classeTitolario varchar(100)
	DECLARE @includiSottoalberoClasseTitolario int
	DECLARE @annoCreazione_da int
	DECLARE @annoCreazione_a int
	DECLARE @annoProtocollazione_da int
	DECLARE @annoProtocollazione_a int
	DECLARE @annoChiusura_da int
	DECLARE @annoChiusura_a int
	DECLARE @idAmministrazione int
	DECLARE @daTrasferire int
	DECLARE @policyDB INT = 0
		
	DECLARE @profileType_id int
	DECLARE @almenoUnFiltroSulTipoDocumento int
	DECLARE @tipoProtocollo_arrivo int = 0
	DECLARE @tipoProtocollo_partenza int = 0
	DECLARE @tipoProtocollo_interno int = 0
	DECLARE @tipoProtocollo_nonProtocollato int = 0
	DECLARE @tipoProtocollo_stampaRegProtocollo int = 0
	DECLARE @tipoProtocollo_stampaRepertorio int = 0

	-- Lettura parametri di configurazione
	--
	--set @nomeSchemaCorrente = fn_ARCHIVE_getNomeSchemaCorrente()
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
	
	
	
	BEGIN TRANSACTION T1



	-- Pulizia tabelle temporanee per la policy @PolicyID (per sicurezza anche se dovrebbe essere pulita)
	--
	DELETE FROM ARCHIVE_Temp_Project_Profile WHERE TransferPolicy_ID = @PolicyID
	
	DELETE FROM ARCHIVE_TempCateneDoc WHERE TransferPolicy_ID = @PolicyID
	
	DELETE FROM ARCHIVE_TempProfile WHERE TransferPolicy_ID = @PolicyID
	
	DELETE FROM ARCHIVE_TempProject WHERE TransferPolicy_ID = @PolicyID
	

	set @errorCode = @@ERROR

	IF @errorCode <> 0
	BEGIN
		-- Rollback the transaction
		ROLLBACK
		
		set @logType = 'ERROR'
		set @log = 'Errore durante la pulizia delle tabelle temporanee per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
		
		EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

		-- Raise an error and return
		RAISERROR (@log, 16, 1)
		RETURN
	END
	
	set @logType = 'INFO'
	set @log = 'Pulizia tabelle temporanee per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
	
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID
	
	
	
	-- Get dati policy
	--
	SELECT @policyDB = ISNULL(TP.System_ID, 0), @tipoPolicy = TPT.Name, @idRegistro = TP.Registro_ID, @idUO = TP.UO_ID, @idTipologia = TP.Tipologia_ID, @idTitolario = TP.Titolario_ID, @classeTitolario = TP.ClasseTitolario
	, @annoCreazione_da = TP.AnnoCreazioneDa, @annoCreazione_a = TP.AnnoCreazioneA, @annoChiusura_da = TP.AnnoChiusuraDa, @annoChiusura_a = TP.AnnoChiusuraA
	, @includiSottoalberoUO = ISNULL(TP.IncludiSottoalberoUO, 0), @includiSottoalberoClasseTitolario = ISNULL(TP.IncludiSottoalberoClasseTit, 0)
	, @idAmministrazione = T.ID_AMMINISTRAZIONE
	, @annoProtocollazione_da = TP.AnnoProtocollazioneDa, @annoProtocollazione_a = TP.AnnoProtocollazioneA
	FROM ARCHIVE_TransferPolicy TP INNER JOIN ARCHIVE_TransferPolicyType TPT ON TP.TransferPolicyType_ID = TPT.System_ID
	INNER JOIN ARCHIVE_Transfer T ON TP.Transfer_ID = T.System_ID
	WHERE TP.System_ID = @PolicyID

	print 'Parametro PolicyID: ' + cast(@PolicyID as varchar(10))
	print 'DB PolicyID: ' + cast(@policyDB as varchar(10))

	IF (@policyDB = 0)
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Policy non trovata - Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END



	-- Chiude e dealloca eventuali cursori rimasti aperti
	--
	execute sp_ARCHIVE_BE_CleanUpCursor 'profileType_cursor'



	-- Get filtro tipo documento
	--
	-- 1 – ARRIVO
	-- 2 – PARTENZA
	-- 3 – INTERNO
	-- 4 – NON PROTOCOLLATO
	-- 5 – STAMPA REGISTRO PROTOCOLLO
	-- 6 – STAMPA REPERTORIO
	--
	DECLARE profileType_cursor CURSOR FOR 
	SELECT PT.PROFILETYPE_ID
	FROM ARCHIVE_TRANSFERPOLICY_PROFILETYPE PT
	WHERE PT.TRANSFERPOLICY_ID = @PolicyID
	
	OPEN profileType_cursor;

	FETCH NEXT FROM profileType_cursor INTO @profileType_id;
	
	IF @@FETCH_STATUS <> 0 
		SET @almenoUnFiltroSulTipoDocumento = 0
	ELSE
		SET @almenoUnFiltroSulTipoDocumento = 1
	
    PRINT 'Almeno un filtro per il tipo documento: ' + CAST(@almenoUnFiltroSulTipoDocumento AS NVARCHAR(MAX))
        
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (@profileType_id = 1) SET @tipoProtocollo_arrivo = 1
		ELSE IF (@profileType_id = 2) SET @tipoProtocollo_partenza = 1
		ELSE IF (@profileType_id = 3) SET @tipoProtocollo_interno = 1
		ELSE IF (@profileType_id = 4) SET @tipoProtocollo_nonProtocollato = 1
		ELSE IF (@profileType_id = 5) SET @tipoProtocollo_stampaRegProtocollo = 1
		ELSE IF (@profileType_id = 6) SET @tipoProtocollo_stampaRepertorio = 1
		ELSE
			PRINT 'WARNING: Tipo documento non riconosciuto - Valore: ' + CAST(@profileType_id AS NVARCHAR(MAX))
	
		FETCH NEXT FROM profileType_cursor INTO @profileType_id;
	END
	
	CLOSE profileType_cursor;
	DEALLOCATE profileType_cursor;

	print 'Filtro tipo doc arrivo: ' + CAST(@tipoProtocollo_arrivo AS NVARCHAR(MAX))
	print 'Filtro tipo doc partenza: ' + CAST(@tipoProtocollo_partenza AS NVARCHAR(MAX))
	print 'Filtro tipo doc interno: ' + CAST(@tipoProtocollo_interno AS NVARCHAR(MAX))
	print 'Filtro tipo doc non protocollato: ' + CAST(@tipoProtocollo_nonProtocollato AS NVARCHAR(MAX))
	print 'Filtro tipo doc Stampa Reg. Protocollo: ' + CAST(@tipoProtocollo_stampaRegProtocollo AS NVARCHAR(MAX))
	print 'Filtro tipo doc Stamp Repertorio: ' + CAST(@tipoProtocollo_stampaRepertorio AS NVARCHAR(MAX))



	-- Impostazione stato policy: Ricerca in corso (2)
	--
	UPDATE ARCHIVE_TransferPolicy
	SET TransferPolicyState_ID = 2
	WHERE System_ID = @PolicyID

	set @errorCode = @@ERROR

	IF @errorCode <> 0
	BEGIN
		-- Rollback the transaction
		ROLLBACK

		set @logType = 'ERROR'
		set @log = 'Errore durante l''aggiornamento dello stato per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
		
		EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

		-- Raise an error and return
		RAISERROR (@log, 16, 1)
		RETURN
	END
	
	set @logType = 'INFO'
	set @log = 'Aggiornamento stato per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
	
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID



	IF (@tipoPolicy = 'Fascicoli')
		BEGIN
			-- Sono trasferibili soltanto i fascicoli procedimentali chiusi, quelli aperti vengono ignorati e lasciati sul corrente.
			-- Un fascicolo è chiuso se: il campo DTA_CHIUSURA è != NULL e si trova nello stato Chiuso (CHA_STATO = C).
			-- Un fascicolo è procedimentale se: CHA_TIPO_FASCICOLO = 'P'
			-- Attenzione: lo stato del fascicolo è sul fascicolo principale

			set @daTrasferire = 1

			-- Selezione dei fascicoli
			--
			SET @sql_string = CAST(N'INSERT INTO [ARCHIVE_TempProject]
			   ([TransferPolicy_ID]
			   ,[Project_ID]
			   ,[ProjectCode]
			   ,[ProjectType]
			   ,[Registro]
			   ,[UO]
			   ,[Titolario]
			   ,[Tipologia]
			   ,[ClasseTitolario]
			   ,[DataChiusura]
			   ,[DaTrasferire]
			   ,[InConservazione])
			SELECT DISTINCT ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) 
			+ CAST(', P.SYSTEM_ID PROJECT_ID
			, P.VAR_CODICE PROJECT_CODE
			, P.CHA_TIPO_FASCICOLO PROJECT_TYPE
			, R.VAR_CODICE REGISTRO
			, CG.VAR_CODICE
			, CASE TIT.CHA_STATO
				WHEN ''A'' THEN ''Titolario attivo''
				WHEN ''C'' THEN ''Titolario in vigore dal '' + CONVERT(VARCHAR(10), tit.DTA_ATTIVAZIONE, 103) + '' al '' + CONVERT(VARCHAR(10), tit.DTA_CESSAZIONE, 103)
				WHEN ''D'' THEN ''Titolario in definizione''
				ELSE ''Stato titolario sconosciuto''
			END TITOLARIO
			, TF.VAR_DESC_FASC TIPOLOGIA
			, CT.VAR_CODICE CLASSE_TITOLARIO
			, P.DTA_CHIUSURA DATA_CHIUSURA
			, ' AS NVARCHAR(MAX)) + CAST(@daTrasferire AS NVARCHAR(MAX)) + CAST(N' DA_TRASFERIRE
			, CASE WHEN ISNULL(IC.ID_PROJECT,0)>0 THEN 1 ELSE 0 END IN_CONSERVAZIONE
			FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P
			LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_EL_REGISTRI R ON P.ID_REGISTRO = R.SYSTEM_ID
			LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TIPO_FASC TF ON P.ID_TIPO_FASC = TF.SYSTEM_ID
			LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT TIT ON P.ID_TITOLARIO = TIT.SYSTEM_ID
			LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT CT ON P.ID_PARENT = CT.SYSTEM_ID
			LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_CORR_GLOBALI CG ON P.ID_UO_CREATORE = CG.SYSTEM_ID
			LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_ITEMS_CONSERVAZIONE IC ON P.SYSTEM_ID = IC.ID_PROJECT
			WHERE 
			P.ID_AMM = ' AS NVARCHAR(MAX)) + CAST(@idAmministrazione AS NVARCHAR(MAX)) + CAST(N'
			AND (P.DTA_CHIUSURA IS NOT NULL AND P.CHA_STATO = ''C'') 
			AND 
			P.CHA_TIPO_FASCICOLO = ''P'' ' AS NVARCHAR(MAX)) -- Fascicolo procedimentale e chiuso, appartenente all'amministrazione @idAmministrazione
			
			-- Costruzione filtro
			--
			IF (@idRegistro is not null)
				SET @sql_string = @sql_string + CAST(' AND P.ID_REGISTRO = ' AS NVARCHAR(MAX)) + CAST(@idRegistro AS NVARCHAR(MAX))
			
			IF (@idUO is not null)
				BEGIN
					IF (@includiSottoalberoUO = 0)
						SET @sql_string = @sql_string + CAST(' AND P.ID_UO_CREATORE = ' AS NVARCHAR(MAX)) + CAST(@idUO AS NVARCHAR(MAX))
					ELSE
						SET @sql_string = @sql_string + CAST(' AND P.ID_UO_CREATORE IN (SELECT SYSTEM_ID FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.FN_ARCHIVE_GETSOTTOALBEROUO(' AS NVARCHAR(MAX)) + CAST(@idUO AS NVARCHAR(MAX)) + CAST(')) ' AS NVARCHAR(MAX))
				END
			
			IF (@idTipologia is not null)
				SET @sql_string = @sql_string + CAST(' AND P.ID_TIPO_FASC = ' AS NVARCHAR(MAX)) + CAST(@idTipologia AS NVARCHAR(MAX))
			
			IF (@idTitolario is not null AND @classeTitolario is null)
				SET @sql_string = @sql_string + CAST(' AND P.ID_TITOLARIO = ' AS NVARCHAR(MAX)) + CAST(@idTitolario AS NVARCHAR(MAX))
			
			IF (@idTitolario is not null AND @classeTitolario is not null)
				BEGIN
					IF (@includiSottoalberoClasseTitolario = 0)
						SET @sql_string = @sql_string + CAST(' AND P.ID_PARENT IN (SELECT SYSTEM_ID FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P WHERE P.VAR_CODICE = ''' AS NVARCHAR(MAX)) + CAST(@classeTitolario AS NVARCHAR(MAX)) 
														+ CAST(''' AND P.ID_TITOLARIO = ' AS NVARCHAR(MAX)) + CAST(@idTitolario AS NVARCHAR(MAX)) + CAST(')' AS NVARCHAR(MAX))
					ELSE
						SET @sql_string = @sql_string + CAST(' AND P.ID_PARENT IN (SELECT SYSTEM_ID FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.FN_ARCHIVE_GETSOTTOALBEROCLASSETITOLARIO(' AS NVARCHAR(MAX)) + CAST(@idTitolario AS NVARCHAR(MAX)) + CAST(', ''' AS NVARCHAR(MAX)) + CAST(@classeTitolario AS NVARCHAR(MAX)) + CAST(''' ))' AS NVARCHAR(MAX))
				END
			
			IF (@annoCreazione_da is not null)
				SET @sql_string = @sql_string + CAST(' AND YEAR(P.DTA_CREAZIONE) >= ' AS NVARCHAR(MAX)) + CAST(@annoCreazione_da AS NVARCHAR(MAX))
			
			IF (@annoCreazione_a is not null)
				SET @sql_string = @sql_string + CAST(' AND YEAR(P.DTA_CREAZIONE) <= ' AS NVARCHAR(MAX)) + CAST(@annoCreazione_a AS NVARCHAR(MAX))
			
			IF (@annoChiusura_da is not null)
				SET @sql_string = @sql_string + CAST(' AND YEAR(P.DTA_CHIUSURA) >= ' AS NVARCHAR(MAX)) + CAST(@annoChiusura_da AS NVARCHAR(MAX))
			
			IF (@annoChiusura_a is not null)
				SET @sql_string = @sql_string + CAST(' AND YEAR(P.DTA_CHIUSURA) <= ' AS NVARCHAR(MAX)) + CAST(@annoChiusura_a AS NVARCHAR(MAX))
								
			PRINT @sql_string;

			EXECUTE sp_executesql @sql_string;
	

			set @errorCode = @@ERROR

			IF @errorCode <> 0
			BEGIN
				-- Rollback the transaction
				ROLLBACK
				
				set @logType = 'ERROR'
				set @log = 'Errore durante l''inserimento fascicoli per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

				-- Raise an error and return
				RAISERROR (@log, 16, 1)
				RETURN
			END
			
			set @logType = 'INFO'
			set @log = 'Inserimento fascicoli per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

			-- Documenti appartenenti ai fascicoli selezionati
			-- Condizioni:
			--		- non sono in cestino
			--		- solo documenti principali
			--		- non sono in checkout
			--			
			SET @sql_string = CAST(N'INSERT INTO [ARCHIVE_TempProfile]
					   ([TransferPolicy_ID]
					   ,[Profile_ID]
					   ,[OggettoDocumento]
					   ,[TipoDocumento]
					   ,[Timestamp]
					   ,[Registro]
					   ,[UO]
					   ,[Tipologia]
					   ,[DataCreazione]
					   ,[DataUltimoAccesso]
					   ,[NumeroUtentiAccedutiUltimoAnno]
					   ,[NumeroAccessiUltimoAnno]
					   ,[InConservazione]
					   ,[MantieniCopia]
					   )
			SELECT DISTINCT
				  ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST(' TRANSFERPOLICY_ID
				  , P.SYSTEM_ID PROFILE_ID
				  , P.VAR_PROF_OGGETTO OGGETTODOCUMENTO
				  , P.CHA_TIPO_PROTO TIPODOCUMENTO
				  , GETDATE() TIMESTAMP
				  , R.VAR_CODICE REGISTRO
				  , CG.VAR_CODICE UO
				  , TA.VAR_DESC_ATTO TIPOLOGIA
				  , P.CREATION_DATE DATACREAZIONE
				  , DATA_ULTIMO_ACCESSO.DATA_ULTIMO_ACCESSO DATAULTIMOACCESSO
				  , DATI_ULTIMO_ANNO.NUMERO_UTENTI_ULTIMO_ANNO NUMEROUTENTIACCEDUTIULTIMOANNO
				  , DATI_ULTIMO_ANNO.NUMERO_ACCESSI_ULTIMO_ANNO NUMEROACCESSIULTIMOANNO
				  , CASE WHEN ISNULL(IC.ID_PROFILE,0)>0 THEN 1 ELSE 0 END IN_CONSERVAZIONE
				  , 0
			FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[PROFILE] P 
				LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TIPO_ATTO TA ON P.ID_TIPO_ATTO = TA.SYSTEM_ID
				LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_EL_REGISTRI R ON P.ID_REGISTRO = R.SYSTEM_ID
				LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_CORR_GLOBALI CG ON P.ID_UO_CREATORE = CG.SYSTEM_ID
				LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_ITEMS_CONSERVAZIONE IC ON P.SYSTEM_ID = IC.ID_PROFILE
				LEFT OUTER JOIN 
				(
				SELECT ID_OGGETTO, COUNT(*) NUMERO_ACCESSI_ULTIMO_ANNO, COUNT(DISTINCT ID_PEOPLE_OPERATORE) NUMERO_UTENTI_ULTIMO_ANNO
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_LOG L
				WHERE VAR_OGGETTO = ''DOCUMENTO''
				AND VAR_COD_AZIONE = ''OPEN_DET_DOC''
				AND DTA_AZIONE > DATEADD(YEAR, -1, GETDATE())
				GROUP BY ID_OGGETTO
				) DATI_ULTIMO_ANNO ON P.SYSTEM_ID = DATI_ULTIMO_ANNO.ID_OGGETTO
				LEFT OUTER JOIN
				(
				SELECT ID_OGGETTO, MAX(DTA_AZIONE) DATA_ULTIMO_ACCESSO
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_LOG L
				WHERE VAR_OGGETTO = ''DOCUMENTO''
				AND VAR_COD_AZIONE = ''OPEN_DET_DOC''
				GROUP BY ID_OGGETTO
				) DATA_ULTIMO_ACCESSO ON P.SYSTEM_ID = DATA_ULTIMO_ACCESSO.ID_OGGETTO
			WHERE ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.GETIDAMM(P.AUTHOR) = ' AS NVARCHAR(MAX)) + CAST(@idAmministrazione AS NVARCHAR(MAX)) + CAST(N'
			AND ISNULL(P.CHA_IN_CESTINO, 0) != 1
			AND P.ID_DOCUMENTO_PRINCIPALE IS NULL 
			AND P.SYSTEM_ID NOT IN
				(
				SELECT ID_DOCUMENT FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_CHECKIN_CHECKOUT
				)
			AND P.SYSTEM_ID IN
				(
				SELECT DISTINCT LINK ID_DOCUMENTO
				FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT_COMPONENTS PC
				WHERE PC.PROJECT_ID IN
					(SELECT P.SYSTEM_ID FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P WHERE P.ID_FASCICOLO IN 
						(SELECT PROJECT_ID FROM ARCHIVE_TEMPPROJECT WHERE TRANSFERPOLICY_ID = ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST('))
				)' AS NVARCHAR(MAX))
								
			PRINT @sql_string;

			EXECUTE sp_executesql @sql_string;
				

			set @errorCode = @@ERROR

			IF @errorCode <> 0
				BEGIN
				-- Rollback the transaction
				ROLLBACK

				set @logType = 'ERROR'
				set @log = 'Errore durante l''inserimento documenti appartenenti ai fascicoli per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

				-- Raise an error and return
				RAISERROR (@log, 16, 1)
				RETURN
			END
			
			set @logType = 'INFO'
			set @log = 'Inserimento documenti appartenenti ai fascicoli per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID
			
			-- Relazione Fascicoli/Documenti
			--			
			SET @sql_string = CAST(N'INSERT INTO [ARCHIVE_TEMP_PROJECT_PROFILE]
			   ([PROJECT_ID]
			   ,[PROFILE_ID]
			   ,[TRANSFERPOLICY_ID]
			   ,[POLICYASSOCIATION])
			SELECT DISTINCT
				P.ID_FASCICOLO P_ID_FASCICOLO
				, LINK ID_DOCUMENTO
				, ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST('
				,CASE WHEN P.ID_FASCICOLO = TP.PROJECT_ID THEN 1 ELSE 0 END POLICY_ASSOCIATION
			FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT_COMPONENTS PC 
			INNER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P ON PC.PROJECT_ID = P.SYSTEM_ID
			LEFT OUTER JOIN ARCHIVE_TEMPPROJECT TP ON P.ID_FASCICOLO = TP.PROJECT_ID
			WHERE PC.LINK IN
				(SELECT PROFILE_ID FROM ARCHIVE_TEMPPROFILE WHERE TRANSFERPOLICY_ID = ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST(')' AS NVARCHAR(MAX))
								
			PRINT @sql_string;

			EXECUTE sp_executesql @sql_string;
				

			set @errorCode = @@ERROR

			IF @errorCode <> 0
			BEGIN
				-- Rollback the transaction
				ROLLBACK

				set @logType = 'ERROR'
				set @log = 'Errore durante l''inserimento relazione documenti-fascicoli per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

				-- Raise an error and return
				RAISERROR (@log, 16, 1)
				RETURN
			END

			set @logType = 'INFO'
			set @log = 'Inserimento relazione documenti-fascicoli per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID
			
		END
	ELSE 
		BEGIN
			IF (@tipoPolicy = 'Documenti')
				BEGIN

					-- Selezione dei documenti
					-- Condizioni:
					--		- non sono in cestino
					--		- solo documenti principali
					--		- non sono in checkout
					--		
					SET @sql_string = CAST(N'INSERT INTO [ARCHIVE_TempProfile]
							   ([TransferPolicy_ID]
							   ,[Profile_ID]
							   ,[OggettoDocumento]
							   ,[TipoDocumento]
							   ,[Timestamp]
							   ,[Registro]
							   ,[UO]
							   ,[Tipologia]
							   ,[DataCreazione]
							   ,[DataUltimoAccesso]
							   ,[NumeroUtentiAccedutiUltimoAnno]
							   ,[NumeroAccessiUltimoAnno]
							   ,[InConservazione]
							   ,[MantieniCopia]
							   )
					SELECT DISTINCT
						  ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST(' TRANSFERPOLICY_ID
						  , P.SYSTEM_ID PROFILE_ID
						  , P.VAR_PROF_OGGETTO OGGETTODOCUMENTO
						  , P.CHA_TIPO_PROTO TIPODOCUMENTO
						  , GETDATE() TIMESTAMP
						  , R.VAR_CODICE REGISTRO
						  , CG.VAR_CODICE UO
						  , TA.VAR_DESC_ATTO TIPOLOGIA
						  , P.CREATION_DATE DATACREAZIONE
						  , DATA_ULTIMO_ACCESSO.DATA_ULTIMO_ACCESSO DATAULTIMOACCESSO
						  , DATI_ULTIMO_ANNO.NUMERO_UTENTI_ULTIMO_ANNO NUMEROUTENTIACCEDUTIULTIMOANNO
						  , DATI_ULTIMO_ANNO.NUMERO_ACCESSI_ULTIMO_ANNO NUMEROACCESSIULTIMOANNO
						  , CASE WHEN ISNULL(IC.ID_PROFILE,0)>0 THEN 1 ELSE 0 END IN_CONSERVAZIONE
						  , 0
					FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.[PROFILE] P 
						LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TIPO_ATTO TA ON P.ID_TIPO_ATTO = TA.SYSTEM_ID
						LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_EL_REGISTRI R ON P.ID_REGISTRO = R.SYSTEM_ID
						LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_CORR_GLOBALI CG ON P.ID_UO_CREATORE = CG.SYSTEM_ID
						LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_ITEMS_CONSERVAZIONE IC ON P.SYSTEM_ID = IC.ID_PROFILE
						LEFT OUTER JOIN 
						(
						SELECT ID_OGGETTO, COUNT(*) NUMERO_ACCESSI_ULTIMO_ANNO, COUNT(DISTINCT ID_PEOPLE_OPERATORE) NUMERO_UTENTI_ULTIMO_ANNO
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_LOG L
						WHERE VAR_OGGETTO = ''DOCUMENTO''
						AND VAR_COD_AZIONE = ''OPEN_DET_DOC''
						AND DTA_AZIONE > DATEADD(YEAR, -1, GETDATE())
						GROUP BY ID_OGGETTO
						) DATI_ULTIMO_ANNO ON P.SYSTEM_ID = DATI_ULTIMO_ANNO.ID_OGGETTO
						LEFT OUTER JOIN
						(
						SELECT ID_OGGETTO, MAX(DTA_AZIONE) DATA_ULTIMO_ACCESSO
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_LOG L
						WHERE VAR_OGGETTO = ''DOCUMENTO''
						AND VAR_COD_AZIONE = ''OPEN_DET_DOC''
						GROUP BY ID_OGGETTO
						) DATA_ULTIMO_ACCESSO ON P.SYSTEM_ID = DATA_ULTIMO_ACCESSO.ID_OGGETTO
					WHERE ISNULL(P.CHA_IN_CESTINO, 0) != 1
					AND P.SYSTEM_ID NOT IN
						(
						SELECT ID_DOCUMENT FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_CHECKIN_CHECKOUT
						)					
					AND P.ID_DOCUMENTO_PRINCIPALE IS NULL ' AS NVARCHAR(MAX))
					
					-- Costruzione filtro
					--
					IF (@idRegistro is not null)
						SET @sql_string = @sql_string + CAST(' AND P.ID_REGISTRO = ' AS NVARCHAR(MAX)) + CAST(@idRegistro AS NVARCHAR(MAX))
					
					IF (@idUO is not null)
						BEGIN
							IF (@includiSottoalberoUO = 0)
								SET @sql_string = @sql_string + CAST(' AND P.ID_UO_CREATORE = ' AS NVARCHAR(MAX)) + CAST(@idUO AS NVARCHAR(MAX))
							ELSE
								SET @sql_string = @sql_string + CAST(' AND P.ID_UO_CREATORE IN (SELECT SYSTEM_ID FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.FN_ARCHIVE_GETSOTTOALBEROUO(' AS NVARCHAR(MAX)) + CAST(@idUO AS NVARCHAR(MAX)) + CAST(')) ' AS NVARCHAR(MAX))
						END
					
					IF (@idTipologia is not null)
						SET @sql_string = @sql_string + CAST(' AND P.ID_TIPO_ATTO = ' AS NVARCHAR(MAX)) + CAST(@idTipologia AS NVARCHAR(MAX))
					
					IF (@idTitolario is not null and @classeTitolario is null)
						SET @sql_string = @sql_string + CAST(' AND P.SYSTEM_ID IN (SELECT PC.LINK ID_DOCUMENTO
								FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT_COMPONENTS PC 
								INNER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P ON PC.PROJECT_ID = P.SYSTEM_ID
								WHERE P.ID_TITOLARIO = ' AS NVARCHAR(MAX)) + CAST(@idTitolario AS NVARCHAR(MAX)) + CAST(')' AS NVARCHAR(MAX))
					
					IF (@idTitolario is not null and @classeTitolario is not null)
						BEGIN
							IF (@includiSottoalberoClasseTitolario = 0)
								SET @sql_string = @sql_string + CAST(' AND P.SYSTEM_ID IN (SELECT PC.LINK ID_DOCUMENTO 
									FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT_COMPONENTS PC WHERE PC.PROJECT_ID IN
									(
										SELECT P.SYSTEM_ID FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P WHERE P.ID_PARENT IN
										(
											SELECT P.SYSTEM_ID
											FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P
											WHERE P.VAR_CODICE = ''' AS NVARCHAR(MAX)) + CAST(@classeTitolario AS NVARCHAR(MAX)) + CAST('''
											AND P.ID_TITOLARIO = ' AS NVARCHAR(MAX)) + CAST(@idTitolario AS NVARCHAR(MAX)) + CAST('
											AND P.CHA_TIPO_FASCICOLO = ''G''
										)
									))' AS NVARCHAR(MAX))				
							ELSE
								SET @sql_string = @sql_string + CAST(' AND P.SYSTEM_ID IN (SELECT PC.LINK ID_DOCUMENTO 
									FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT_COMPONENTS PC WHERE PC.PROJECT_ID IN
									(
										SELECT P.SYSTEM_ID FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P WHERE P.ID_PARENT IN
										(
											SELECT P.SYSTEM_ID
											FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P
											WHERE P.SYSTEM_ID IN 
												(
												SELECT SYSTEM_ID 
												FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.FN_ARCHIVE_GETSOTTOALBEROCLASSETITOLARIO(' AS NVARCHAR(MAX)) + CAST(@idTitolario AS NVARCHAR(MAX)) + CAST(', ''' AS NVARCHAR(MAX)) + CAST(@classeTitolario AS NVARCHAR(MAX)) + CAST(''') 
												WHERE CHA_TIPO_FASCICOLO = ''G''
												)
										)
									))' AS NVARCHAR(MAX))				
						END
											
					IF (@annoCreazione_da is not null)
						SET @sql_string = @sql_string + CAST(' AND YEAR(P.CREATION_DATE) >= ' AS NVARCHAR(MAX)) + CAST(@annoCreazione_da AS NVARCHAR(MAX))
					
					IF (@annoCreazione_a is not null)
						SET @sql_string = @sql_string + CAST(' AND YEAR(P.CREATION_DATE) <= ' AS NVARCHAR(MAX)) + CAST(@annoCreazione_a AS NVARCHAR(MAX))
					
					IF (@annoProtocollazione_da is not null)
						SET @sql_string = @sql_string + CAST(' AND YEAR(P.DTA_PROTO) >= ' AS NVARCHAR(MAX)) + CAST(@annoProtocollazione_da AS NVARCHAR(MAX))
					
					IF (@annoProtocollazione_a is not null)
						SET @sql_string = @sql_string + CAST(' AND YEAR(P.DTA_PROTO) <= ' AS NVARCHAR(MAX)) + CAST(@annoProtocollazione_a AS NVARCHAR(MAX))
					
					-- Filtro tipo documento
					--					
					IF (@almenoUnFiltroSulTipoDocumento = 1)
						BEGIN
							SET @sql_string = @sql_string + CAST(' AND P.CHA_TIPO_PROTO IN (''-1''' AS NVARCHAR(MAX)) -- Utilizzo il valore -1 per iniziare la lista dei valori
						
							IF (@tipoProtocollo_arrivo = 1)
								SET @sql_string = @sql_string + CAST(',''A''' AS NVARCHAR(MAX))
						
							IF (@tipoProtocollo_partenza = 1)
								SET @sql_string = @sql_string + CAST(',''P''' AS NVARCHAR(MAX))
						
							IF (@tipoProtocollo_interno = 1)
								SET @sql_string = @sql_string + CAST(',''I''' AS NVARCHAR(MAX))
						
							IF (@tipoProtocollo_nonProtocollato = 1)
								SET @sql_string = @sql_string + CAST(',''G''' AS NVARCHAR(MAX))
						
							IF (@tipoProtocollo_stampaRegProtocollo = 1)
								SET @sql_string = @sql_string + CAST(',''R''' AS NVARCHAR(MAX))
						
							IF (@tipoProtocollo_stampaRepertorio = 1)
								SET @sql_string = @sql_string + CAST(',''C''' AS NVARCHAR(MAX))
								
							SET @sql_string = @sql_string + CAST(')' AS NVARCHAR(MAX))
						END
										
					PRINT @sql_string;

					EXECUTE sp_executesql @sql_string;
						

					set @errorCode = @@ERROR

					IF @errorCode <> 0
						BEGIN
						-- Rollback the transaction
						ROLLBACK

						set @logType = 'ERROR'
						set @log = 'Errore durante l''inserimento documenti per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
						
						EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

						-- Raise an error and return
						RAISERROR (@log, 16, 1)
						RETURN
					END
					
					set @logType = 'INFO'
					set @log = 'Inserimento documenti per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID
					
					-- Inserimento relazione Documento-Fascicolo
					--
					SET @sql_string = CAST(N'INSERT INTO [ARCHIVE_TEMP_PROJECT_PROFILE]
						   ([PROJECT_ID]
						   ,[PROFILE_ID]
						   ,[TRANSFERPOLICY_ID]
						   ,[POLICYASSOCIATION])
					   SELECT DISTINCT
							P.ID_FASCICOLO P_ID_FASCICOLO
							, LINK ID_DOCUMENTO
							, ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST('
							, CASE WHEN P.ID_FASCICOLO = TP.PROJECT_ID THEN 1 ELSE 0 END POLICY_ASSOCIATION
						FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT_COMPONENTS PC 
						INNER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P ON PC.PROJECT_ID = P.SYSTEM_ID
						LEFT OUTER JOIN ARCHIVE_TEMPPROJECT TP ON P.ID_FASCICOLO = TP.PROJECT_ID
						WHERE PC.LINK IN
							(SELECT PROFILE_ID FROM ARCHIVE_TEMPPROFILE WHERE TRANSFERPOLICY_ID = ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST(')' AS NVARCHAR(MAX))
										
					PRINT @sql_string;

					EXECUTE sp_executesql @sql_string;
						

					set @errorCode = @@ERROR

					IF @errorCode <> 0
					BEGIN
						-- Rollback the transaction
						ROLLBACK

						set @logType = 'ERROR'
						set @log = 'Errore durante l''inserimento della relazione documento-fascicolo per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
						
						EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

						-- Raise an error and return
						RAISERROR (@log, 16, 1)
						RETURN
					END
					
					set @logType = 'INFO'
					set @log = 'Inserimento relazione documento-fascicolo per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID
					
										
					
					set @daTrasferire = 0
						
					-- Fascicoli collegati ai documenti
					--
					SET @sql_string = CAST(N'INSERT INTO [ARCHIVE_TempProject]
					   ([TransferPolicy_ID]
					   ,[Project_ID]
					   ,[ProjectCode]
					   ,[ProjectType]
					   ,[Registro]
					   ,[UO]
					   ,[Titolario]
					   ,[Tipologia]
					   ,[ClasseTitolario]
					   ,[DataChiusura]
					   ,[DaTrasferire]
					   ,[InConservazione])
					SELECT DISTINCT ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) 
					+ CAST(', P.SYSTEM_ID PROJECT_ID
					, P.VAR_CODICE PROJECT_CODE
					, P.CHA_TIPO_FASCICOLO PROJECT_TYPE
					, R.VAR_CODICE REGISTRO
					, CG.VAR_CODICE
					, CASE TIT.CHA_STATO
						WHEN ''A'' THEN ''Titolario attivo''
						WHEN ''C'' THEN ''Titolario in vigore dal '' + CONVERT(VARCHAR(10), tit.DTA_ATTIVAZIONE, 103) + '' al '' + CONVERT(VARCHAR(10), tit.DTA_CESSAZIONE, 103)
						WHEN ''D'' THEN ''Titolario in definizione''
						ELSE ''Stato titolario sconosciuto''
					END TITOLARIO
					, TF.VAR_DESC_FASC TIPOLOGIA
					, CT.VAR_CODICE CLASSE_TITOLARIO
					, P.DTA_CHIUSURA DATA_CHIUSURA
					, ' AS NVARCHAR(MAX)) + CAST(@daTrasferire AS NVARCHAR(MAX)) + CAST(N' DA_TRASFERIRE
					, CASE WHEN ISNULL(IC.ID_PROJECT,0)>0 THEN 1 ELSE 0 END IN_CONSERVAZIONE
					FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT P
					LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_EL_REGISTRI R ON P.ID_REGISTRO = R.SYSTEM_ID
					LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_TIPO_FASC TF ON P.ID_TIPO_FASC = TF.SYSTEM_ID
					LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT TIT ON P.ID_TITOLARIO = TIT.SYSTEM_ID
					LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROJECT CT ON P.ID_PARENT = CT.SYSTEM_ID
					LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_CORR_GLOBALI CG ON P.ID_UO_CREATORE = CG.SYSTEM_ID
					LEFT OUTER JOIN ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.DPA_ITEMS_CONSERVAZIONE IC ON P.SYSTEM_ID = IC.ID_PROJECT
					WHERE P.SYSTEM_ID IN
						(
						SELECT DISTINCT PROJECT_ID 
						FROM ARCHIVE_TEMP_PROJECT_PROFILE 
						WHERE TRANSFERPOLICY_ID = ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST('
						)' AS NVARCHAR(MAX))
										
					PRINT @sql_string;

					EXECUTE sp_executesql @sql_string;
						

					set @errorCode = @@ERROR

					IF @errorCode <> 0
					BEGIN
						-- Rollback the transaction
						ROLLBACK

						set @logType = 'ERROR'
						set @log = 'Errore durante l''inserimento fascicoli per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
						
						EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

						-- Raise an error and return
						RAISERROR (@log, 16, 1)
						RETURN
					END
					
					set @logType = 'INFO'
					set @log = 'Inserimento fascicoli per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID
					
					
					
					
					
					
					
					
				END
			ELSE
				BEGIN
					set @logType = 'ERROR'
					set @log = 'Errore - Tipo policy sconosciuto: ' + @tipoPolicy
					
					EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID
				END
		END

	
	
	-- Catene documentali
	-- Per tutti i documenti importati nella sessione corrente, vengono memorizzate le relazioni delle catene documentali
	--
	SET @sql_string = CAST(N'INSERT INTO [ARCHIVE_TEMPCATENEDOC]
		([TRANSFERPOLICY_ID]
		,[PROFILE_ID]
		,[LINKEDDOC_ID])
	SELECT DISTINCT
		' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST(N'
		, P.SYSTEM_ID
		, P.ID_PARENT
	FROM ' AS NVARCHAR(MAX)) + CAST(@nomeSchemaCorrente AS NVARCHAR(MAX)) + CAST(N'.PROFILE P
	WHERE 
	(
	P.SYSTEM_ID IN 
		(
		SELECT P.PROFILE_ID
		FROM ARCHIVE_TEMPPROFILE P
		WHERE P.TRANSFERPOLICY_ID = ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST(N'
		) 
	AND ISNULL(P.ID_PARENT,0)<>0
	)
	OR
	(
	P.ID_PARENT IN 
		(
		SELECT P.PROFILE_ID
		FROM ARCHIVE_TEMPPROFILE P
		WHERE P.TRANSFERPOLICY_ID = ' AS NVARCHAR(MAX)) + CAST(@PolicyID AS NVARCHAR(MAX)) + CAST(N'
		)
	)' AS NVARCHAR(MAX))

	PRINT @sql_string;

	EXECUTE sp_executesql @sql_string;


	set @errorCode = @@ERROR

	IF @errorCode <> 0
	BEGIN
		-- Rollback the transaction
		ROLLBACK
		
		set @logType = 'ERROR'
		set @log = 'Errore durante l''inserimento nella tabella ARCHIVE_TEMPCATENEDOC' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
		
		EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

		-- Raise an error and return
		RAISERROR (@log, 16, 1)
		RETURN
	END
	
	set @logType = 'INFO'
	set @log = 'Aggiornamento tabella ARCHIVE_TEMPCATENEDOC'
	
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID



	-- Impostazione stato policy: Ricerca completata (3)
	--
	UPDATE ARCHIVE_TransferPolicy
	SET TransferPolicyState_ID = 3
	WHERE System_ID = @PolicyID


	set @errorCode = @@ERROR

	IF @errorCode <> 0
	BEGIN
		-- Rollback the transaction
		ROLLBACK

		set @logType = 'ERROR'
		set @log = 'Errore durante l''aggiornamento dello stato per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
		
		EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID

		-- Raise an error and return
		RAISERROR (@log, 16, 1)
		RETURN
	END
	
	set @logType = 'INFO'
	set @log = 'Aggiornamento stato per la Policy: ' + CAST(@PolicyID AS NVARCHAR(MAX))
	
	EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_TransferPolicy, @logObjectID



	COMMIT TRANSACTION T1

END
