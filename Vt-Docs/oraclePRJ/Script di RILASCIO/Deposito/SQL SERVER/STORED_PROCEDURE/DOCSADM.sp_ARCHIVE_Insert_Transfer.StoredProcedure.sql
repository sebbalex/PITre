USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Insert_Transfer]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Insert_Transfer]  (  @Description varchar (200) , 
														@Note varchar (2000) , 
														@ID_Amministrazione int, 
														@TransferStateType_ID int , 
														@System_ID int OUTPUT )
AS

DECLARE @errorCode INT
DECLARE @log VARCHAR(2000)
DECLARE @logType VARCHAR(10)
DECLARE @logObject VARCHAR(50) = OBJECT_NAME(@@PROCID)

BEGIN
	
	BEGIN TRANSACTION T1
		
		BEGIN
			INSERT INTO [DOCSADM].[ARCHIVE_Transfer] ( [Description], [Note],[ID_Amministrazione] ) 
			VALUES ( @Description, @Note, @ID_Amministrazione ) 
			SET @System_ID = SCOPE_IDENTITY()

			INSERT INTO [DOCSADM].[ARCHIVE_TransferState] ( [Transfer_ID], [TransferStateType_ID], [DateTime] ) 
			VALUES ( @System_ID, @TransferStateType_ID, CONVERT(date,getdate(),103) ) 
	    END
	
	
		set @errorCode = @@ERROR

		IF @errorCode <> 0
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Errore durante l''insert  per la tabella ARCHIVE_TRANSFER' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END
	
	COMMIT TRANSACTION T1

END
GO
