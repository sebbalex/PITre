USE [PCM_DEPOSITO_1]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ================================================================================================
-- Author:		Giovanni Olivari
-- Create date: 12/09/2013
-- Description:	Verifica se per il versamento corrente sia stati spostati regolarmente tutti i file
-- ================================================================================================
ALTER PROCEDURE [DOCSADM].[sp_ARCHIVE_BE_CheckCurrentFileManagerProcess] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @log VARCHAR(2000)
	DECLARE @logType VARCHAR(10)
	DECLARE @logObject VARCHAR(50) = OBJECT_NAME(@@PROCID)
	DECLARE @logObjectType VARCHAR(50)
	DECLARE @logObjectType_Transfer INT = 1 -- 'Transfer'
	DECLARE @logObjectID INT --= @TransferID
	DECLARE @errorCode INT
	
	DECLARE @system_ID INT
	DECLARE	@return_value INT
	DECLARE @transferStateType_EFFETTUATO_COMPRESI_FILE int = 8 -- EFFETTUATO COMPRESI FILE

	DECLARE @transferID INT
	DECLARE @numTransfer INT
	DECLARE @numTransferDaProcessare INT
	
	DECLARE @sql_string nvarchar(MAX)
	
	-- Verifica il versamento corrente
	--
	SELECT @numTransfer = COUNT(DISTINCT TRANSFER_ID) FROM ARCHIVE_TEMPTRANSFERFILE
	
	-- Se ci sono più Transfer è una situazione inconsistente
	--
	IF @numTransfer > 1
	BEGIN
		set @logType = 'ERROR'
		set @log = 'Impossibile effettuare il check dello spostamento file; nella tabella ARCHIVE_TEMPTRANSFERFILE sono presenti dati di più Transfer'
		
		EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject
		print @log

		-- Raise an error and return
		RAISERROR (@log, 16, 1)
		RETURN
	END
	
	-- Se c'è un solo Transfer, viene elaborato, altrimenti non fa niente
	--
	IF @numTransfer = 1
	BEGIN
		SELECT DISTINCT @transferID = TRANSFER_ID FROM ARCHIVE_TEMPTRANSFERFILE
		
		SET @logObjectID = @transferID
		
		
		-- Verifica se sono stati processati tutti i file
		--
		SELECT @numTransferDaProcessare = COUNT(*) 
		FROM ARCHIVE_TEMPTRANSFERFILE
		WHERE 
		Processed = 0
		OR
		(
		Processed = 1 AND ProcessResult = 0
		)
		
		IF @numTransferDaProcessare = 0
		BEGIN
		
			BEGIN TRANSACTION T1
			
			
			
			-- Elimina tutti i record dalla tabella ARCHIVE_TempTransferFile
			--
			SET @sql_string = CAST(N'DELETE FROM ARCHIVE_TEMPTRANSFERFILE' AS NVARCHAR(MAX))
			
			PRINT @sql_string;
		
			EXECUTE sp_executesql @sql_string;
			
			set @errorCode = @@ERROR

			IF @errorCode <> 0
			BEGIN
				-- Rollback the transaction
				ROLLBACK
				
				set @logType = 'ERROR'
				set @log = 'Errore durante la cancellazione dei record dalla tabella ARCHIVE_TempTransferFile - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

				-- Raise an error and return
				RAISERROR (@log, 16, 1)
				RETURN
			END
			
			set @logType = 'INFO'
			set @log = 'Cancellazione tabella ARCHIVE_TempTransferFile'
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID


			
			-- Aggiorna lo stato del versamento a EFFETTUATO COMPRESI FILE
			--	
			EXEC	@return_value = [sp_ARCHIVE_Insert_TransferState]
					@Transfer_ID = @transferID,
					@TransferStateType_ID = @transferStateType_EFFETTUATO_COMPRESI_FILE,
					@System_ID = @system_ID OUTPUT

			set @errorCode = @@ERROR

			IF @errorCode <> 0
			BEGIN
				-- Rollback the transaction
				ROLLBACK

				set @logType = 'ERROR'
				set @log = 'Errore durante l''aggiornamento dello stato a EFFETTUATO COMPRESI FILE il Transfer: ' + CAST(@transferID AS NVARCHAR(MAX)) + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
				
				EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

				-- Raise an error and return
				RAISERROR (@log, 16, 1)
				RETURN
			END
					
			set @logType = 'INFO'
			set @log = 'Aggiornamento stato a Effettuato Compresi File per il Transfer: ' + CAST(@transferID AS NVARCHAR(MAX))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID

			
			
			COMMIT TRANSACTION T1
			
		END
		
		ELSE
		BEGIN
			set @logType = 'INFO'
			set @log = 'Impossibile chiudere il processo di versamento, ci sono ancora file da spostare per il Transfer: ' + CAST(@transferID AS NVARCHAR(MAX))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject, @logObjectType_Transfer, @logObjectID
			
			PRINT @log;
			
		END
		
	END
	
	
END
