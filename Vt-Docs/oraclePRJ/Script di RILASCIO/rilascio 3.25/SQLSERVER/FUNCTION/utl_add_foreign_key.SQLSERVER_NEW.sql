
ALTER PROCEDURE [DOCSADM].[utl_add_foreign_key]
	
	@versioneCD			Nvarchar(200),
	@nome_utente		Nvarchar(200), 
	@nome_tabella		Nvarchar(200),
	@nome_colonna		Nvarchar(200),
	@nome_tabella_fk	Nvarchar(200),
	@nome_colonna_fk	Nvarchar(200),
	@condizione_add		Nvarchar(200),
    @RFU				Nvarchar(200)
    
AS
BEGIN	
		
	DECLARE @nome_foreign_key   Nvarchar(2000)
	DECLARE @tablePK			Nvarchar(2000)
	DECLARE @tableFK			Nvarchar(2000)
	DECLARE @colonnaFK			Nvarchar(2000)

	SET @tablePK = SUBSTRING(@nome_tabella, 1,10)
	SET @tableFK = SUBSTRING(@nome_tabella_fk, 1,10)
	SET @colonnaFK = SUBSTRING(@nome_colonna_fk, 1,8)
		   
	SET @nome_foreign_key = 'FK_'+@tableFK+'_'+@colonnaFK+'_'+@tablePK+''
		
		
	IF EXISTS(SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'['+@nome_utente+'].['+@nome_tabella_fk+']'))
	BEGIN
	
		IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_TYPE = 'FOREIGN KEY' AND TABLE_NAME = ''+@nome_tabella_fk+'' AND TABLE_SCHEMA =''+@nome_utente+''	AND CONSTRAINT_NAME = ''+@nome_foreign_key+'')
		BEGIN	
			PRINT 'NON ESISTE FK'
			
			DECLARE @istruzione			Nvarchar(2000)
			DECLARE @insert_log			Nvarchar(2000)
			DECLARE @data_eseguito		Nvarchar(2000)
			DECLARE @esito				Nvarchar(2000)
			DECLARE @comando_richiesto	Nvarchar(2000)
			DECLARE @ErrorVar			INT
			DECLARE @condizione			NVARCHAR(2000)
	
			IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_TYPE = 'PRIMARY KEY' AND TABLE_NAME = ''+@nome_tabella+'' AND TABLE_SCHEMA =''+@nome_utente+'' AND CONSTRAINT_NAME = 'PK_'+@nome_tabella+'')
			BEGIN
				PRINT 'ESISTE PK'
	   							
				SET @istruzione = N'ALTER TABLE ['+@nome_utente+'].' +@nome_tabella_fk + ' 
						  WITH CHECK ADD CONSTRAINT ' +@nome_foreign_key+ ' 
						  FOREIGN KEY (' +@nome_colonna_fk+') 
						  REFERENCES '+@nome_utente+'.' +@nome_tabella+ ' ('+@nome_colonna+')'

		
				BEGIN TRY
					EXECUTE sp_executesql @istruzione
					PRINT @istruzione
				END TRY
				BEGIN CATCH
					-- Salva il numero dell'errore
					SELECT @ErrorVar = @@ERROR
				END CATCH

				--Condizioni degli errori
				IF @ErrorVar <> 0
				BEGIN
					--IF @ErrorVar = 2715
					IF @ErrorVar = 2715
					BEGIN
						SET @esito = @istruzione
					END
					ELSE IF @ErrorVar = 547
					BEGIN
						SET @esito = 'Conflitto del PK e FK'
					END
					ELSE IF @ErrorVar = 1750
					BEGIN
						SET @esito = 'VERIFICARE CON "'+@istruzione
					END
					ELSE IF @ErrorVar = 1778
					BEGIN
						SET @esito = 'Uno delle due colonne non  valido'
					END
					ELSE
					BEGIN
						SET @esito = N'ERROR: error '+ RTRIM(CAST(@ErrorVar AS NVARCHAR(10))) + N' occurred.'
					END
				END
				ELSE	--se non ci sono nessun errore.
				BEGIN 
					SET @esito = 'Esito Positivo'
   
					SET @comando_richiesto = 'Added Foreign Key ' +@nome_foreign_key+' on '+@nome_tabella_fk+''
					
					EXECUTE [DOCSADM].utl_insert_log @nome_utente,getdate, @comando_richiesto, @versioneCD, @esito
				END
			END
			ELSE    
			BEGIN
				PRINT 'non esiste PK'
				
				SET @esito = 'Esito Negativo - Chiave primaria non esistente' 
    
				SET @comando_richiesto = 'Adding Foreign Key ' +@nome_foreign_key+' on '+@nome_tabella_fk+''
				
				EXECUTE [DOCSADM].utl_insert_log @nome_utente,getdate, @comando_richiesto, @versioneCD, @esito
			END
		END
		ELSE	-- SE  GIÀ ESISTENTE IL FK		
		BEGIN	
			PRINT 'ESISTE GIÀ FK'
			
			SET @esito = 'ESITO NEGATIVO - FOREIGN KEY GIÀ ESISTENTE O TABELLA NON ESISTENTE'
			
			SET @comando_richiesto = 'ADDING FOREIGN KEY ' +@nome_foreign_key+' ON '+@nome_tabella_fk+''
	       
			EXECUTE [DOCSADM].utl_insert_log @nome_utente,getdate, @comando_richiesto, @versioneCD, @esito

		END
	
		SET NOCOUNT ON;

		-- Insert statements for procedure here
		SELECT	@versioneCD, 
				@nome_utente, 
				@nome_tabella, 
				@nome_colonna, 
				@nome_tabella_fk,
				@nome_colonna_fk,
				@condizione_add, 
				@RFU
	END
END
              
---- utl_add_index.MSSQL.sql  marcatore per ricerca ----
-- es. invocazione:
-- exec utl_add_index('VERSIONE CD', --->es. 3.16.1
--					'NOME UTENTE', --->es. DOCSADM
--					'NOME TABELLA', --->es. TABELLA_A
--					'NOME INDICE', --->es. IDX_TABELLA
--					'IS_UNIQUE', --->es. 1 (UNIQUE), '' (NON UNIQUE)
--					'NOME COLONNA 1', --->es. COLONNA_A (OBBLIGATORIO 1 COLONNA)
--					'NOME COLONNA 2', --->es. COLONNA_B (PER LASCIARE VUOTO, SCRIVA NULL)
--					'NOME COLONNA 3', --->es. COLONNA_C (PER LASCIARE VUOTO, SCRIVA NULL)
--					'RFU' ---> per uso futuro")
-- =============================================
-- Author:		Gabriele Serpi
-- Create date: 25/07/2011
-- Description:	
-- =============================================

SET ANSI_NULLS ON
