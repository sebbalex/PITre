USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Insert_Update_TransferPolicy]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Insert_Update_TransferPolicy]  
	(	@Description varchar (200) , 
		@Enabled int , 
		@Transfer_ID int ,
		@TransferPolicyType_ID int , 
		@TransferPolicyState_ID int ,
		@Registro_ID int , 
		@UO_ID int , 
		@IncludiSottoalberoUO int , 
		@Tipologia_ID int , 
		@Titolario_ID int , 
		@ClasseTitolario varchar (100) , 
		@IncludiSottoalberoClasseTit int , 
		@AnnoCreazioneDa int , 
		@AnnoCreazioneA int , 
		@AnnoProtocollazioneDa int , 
		@AnnoProtocollazioneA int , 
		@AnnoChiusuraDa int , 
		@AnnoChiusuraA int ,
		@IsA int,
		@IsP int,
		@IsI int,
		@IsNonProt int, 
		@IsStRegProt int, 
		@IsStRep int,
		@System_ID int OUTPUT )
AS
BEGIN

	DECLARE @log VARCHAR(2000)
	DECLARE @logType VARCHAR(10)
	DECLARE @logObject VARCHAR(50) = OBJECT_NAME(@@PROCID)
	DECLARE @errorCode INT
	
	DECLARE @selectedSystemID INT = 0

	
	BEGIN TRANSACTION T1

		SELECT @selectedSystemID = ISNULL(System_ID, 0)
		FROM ARCHIVE_TransferPolicy
		WHERE System_ID = @System_ID
		
		IF (ISNULL(@selectedSystemID, 0) = 0)
			BEGIN
			
				INSERT INTO [DOCSADM].[ARCHIVE_TransferPolicy] 
				(	[Description], 
					[Enabled], 
					[Transfer_ID], 
					[TransferPolicyType_ID],
					[TransferPolicyState_ID], 
					[Registro_ID], 
					[UO_ID], 
					[IncludiSottoalberoUO],
					[Tipologia_ID], 
					[Titolario_ID], 
					[ClasseTitolario], 
					[IncludiSottoalberoClasseTit], 
					[AnnoCreazioneDa], 
					[AnnoCreazioneA], 
					[AnnoProtocollazioneDa], 
					[AnnoProtocollazioneA], 
					[AnnoChiusuraDa], 
					[AnnoChiusuraA] ) 
				VALUES 
				( @Description, 
					@Enabled, 
					@Transfer_ID, 
					@TransferPolicyType_ID,
					@TransferPolicyState_ID,
					@Registro_ID, 
					@UO_ID,
					@IncludiSottoalberoUO, 
					@Tipologia_ID,
					@Titolario_ID, 
					@ClasseTitolario, 
					@IncludiSottoalberoClasseTit,
					@AnnoCreazioneDa,
					@AnnoCreazioneA, 
					@AnnoProtocollazioneDa,
					@AnnoProtocollazioneA,
					@AnnoChiusuraDa, 
					@AnnoChiusuraA ) 
				
				SET @System_ID = SCOPE_IDENTITY()
				
				print 'insert - @System_ID: ' + CAST(@System_ID as VARCHAR(10))
			END	
		ELSE
			BEGIN
				UPDATE [DOCSADM].[ARCHIVE_TransferPolicy]
					SET	[Description] = @Description,
						[Enabled] = @Enabled,
						[Transfer_ID] = @Transfer_ID,
						[TransferPolicyType_ID] = @TransferPolicyType_ID,
						[TransferPolicyState_ID] = @TransferPolicyState_ID,
						[Registro_ID] = @Registro_ID,
						[UO_ID] = @UO_ID,
						[IncludiSottoalberoUO] = @IncludiSottoalberoUO,
						[Tipologia_ID] = @Tipologia_ID,
						[Titolario_ID] = @Titolario_ID,
						[ClasseTitolario] = @ClasseTitolario,
						[IncludiSottoalberoClasseTit] = @IncludiSottoalberoClasseTit,
						[AnnoCreazioneDa] = @AnnoCreazioneDa,
						[AnnoCreazioneA] = @AnnoCreazioneA,
						[AnnoProtocollazioneDa] = @AnnoProtocollazioneDa,
						[AnnoProtocollazioneA] = @AnnoProtocollazioneA,
						[AnnoChiusuraDa] = @AnnoChiusuraDa,
						[AnnoChiusuraA] = @AnnoChiusuraA 
					WHERE ( [System_ID] = @System_ID )
				
				print 'update - @System_ID: ' + CAST(@System_ID as VARCHAR(10))
			END
			
		set @errorCode = @@ERROR

		IF @errorCode <> 0
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Errore durante l''istruzione Merge per la tabella ARCHIVE_TransferPolicy' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END
		
		DELETE [DOCSADM].ARCHIVE_TransferPolicy_ProfileType
		WHERE TransferPolicy_ID = @System_ID
		
		set @errorCode = @@ERROR

		IF @errorCode <> 0
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Errore durante l''eliminazione delle relazioni nella tabella ARCHIVE_TransferPolicy_ProfileType' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END
		
		IF @IsA>0
		BEGIN
			INSERT INTO [DOCSADM].[ARCHIVE_TransferPolicy_ProfileType] 
			(	[TransferPolicy_ID] ,
				[ProfileType_ID])
			VALUES
			(	@System_ID,
				'1')
		END
		
		set @errorCode = @@ERROR

		IF @errorCode <> 0
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Errore durante l''inserimento della relaziona A nella tabella ARCHIVE_TransferPolicy_ProfileType' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END		
		
		IF @IsP>0
		BEGIN
			INSERT INTO [DOCSADM].[ARCHIVE_TransferPolicy_ProfileType] 
			(	[TransferPolicy_ID] ,
				[ProfileType_ID])
			VALUES
			(	@System_ID,
				'2')
		END
		
		set @errorCode = @@ERROR

		IF @errorCode <> 0
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Errore durante l''inserimento della relaziona P nella tabella ARCHIVE_TransferPolicy_ProfileType' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END	
		    
		IF @IsI>0
		BEGIN
			INSERT INTO [DOCSADM].[ARCHIVE_TransferPolicy_ProfileType] 
			(	[TransferPolicy_ID] ,
				[ProfileType_ID])
			VALUES
			(	@System_ID,
				'3')
		END
		
		set @errorCode = @@ERROR

		IF @errorCode <> 0
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Errore durante l''inserimento della relaziona I nella tabella ARCHIVE_TransferPolicy_ProfileType' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END	
		
		IF @IsNonProt>0
		BEGIN
			INSERT INTO [DOCSADM].[ARCHIVE_TransferPolicy_ProfileType] 
			(	[TransferPolicy_ID] ,
				[ProfileType_ID])
			VALUES
			(	@System_ID,
				'4')
		END
		
		set @errorCode = @@ERROR

		IF @errorCode <> 0
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Errore durante l''inserimento della relaziona NonProt nella tabella ARCHIVE_TransferPolicy_ProfileType' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END	
		
		IF @IsStRegProt>0
		BEGIN
			INSERT INTO [DOCSADM].[ARCHIVE_TransferPolicy_ProfileType] 
			(	[TransferPolicy_ID] ,
				[ProfileType_ID])
			VALUES
			(	@System_ID,
				'5')
		END
		
		set @errorCode = @@ERROR

		IF @errorCode <> 0
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Errore durante l''inserimento della relaziona StRegProt nella tabella ARCHIVE_TransferPolicy_ProfileType' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END	
				
		IF @IsStRep>0
		BEGIN
			INSERT INTO [DOCSADM].[ARCHIVE_TransferPolicy_ProfileType] 
			(	[TransferPolicy_ID] ,
				[ProfileType_ID])
			VALUES
			(	@System_ID,
				'6')
		END
		
		set @errorCode = @@ERROR

		IF @errorCode <> 0
		BEGIN
			-- Rollback the transaction
			ROLLBACK
			
			set @logType = 'ERROR'
			set @log = 'Errore durante l''inserimento della relaziona StRep nella tabella ARCHIVE_TransferPolicy_ProfileType' + ' - Codice errore: ' + CAST(@errorCode AS NVARCHAR(8))
			
			EXECUTE sp_ARCHIVE_BE_InsertLog @log, @logType, @logObject

			-- Raise an error and return
			RAISERROR (@log, 16, 1)
			RETURN
		END		  

	COMMIT TRANSACTION T1
	
END
GO
