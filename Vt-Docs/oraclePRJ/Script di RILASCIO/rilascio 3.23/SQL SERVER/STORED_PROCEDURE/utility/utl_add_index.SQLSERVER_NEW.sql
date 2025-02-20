


ALTER PROCEDURE [DOCSADM].[utl_add_index]
-- Add the parameters for the stored procedure here
	@versioneCD					Nvarchar(200),
	@nome_utente				Nvarchar(200), 
	@nome_tabella				Nvarchar(200),
	@nome_index					Nvarchar(200),  
	@is_index_unique			Nvarchar(200),		-- supply '1' for unique
	@nome_colonna1				Nvarchar(200),
	@nome_colonna2				Nvarchar(200),
	@nome_colonna3				Nvarchar(200),
	@nome_colonna4				Nvarchar(200),
	@Index_Type					Nvarchar(200),		-- supply CLUSTERED or NORMAL for NONCLUSTERED 
	@Ityp_Name					Nvarchar(200),		-- n.a. valid only for Oracle 
	@Optional_Ityp_Parameters	Nvarchar(200),		-- n.a. valid only for Oracle 
	@RFU						Nvarchar(200)
		
AS
BEGIN
	
	--DECLARE @nome_indice	Nvarchar(2000)
	--DECLARE @tableI			Nvarchar(2000)
	--DECLARE @colonnaI		Nvarchar(2000)
		
	--SET @tableI = SUBSTRING(@nome_tabella, 1,10)
	--SET @colonnaI = SUBSTRING(@nome_colonna1, 1,10)
	   
--	   set @nome_indice = 'IDX_'+@tableI+'_'+@colonnaI+''
	
	
	IF NOT EXISTS (SELECT name FROM sys.indexes WHERE name = @nome_index)
		
	BEGIN
		DECLARE @istruzione				Nvarchar(2000)
		DECLARE @insert_log				Nvarchar(2000)
		DECLARE @data_eseguito			Nvarchar(2000)
		DECLARE @esito					Nvarchar(2000)
		DECLARE @unique					Nvarchar(2000)
		DECLARE @ErrorVar				INT
		DECLARE @colonne				NVARCHAR(2000)
		DECLARE @comando_richiesto		NVARCHAR(2000)  
		DECLARE @tipoindice				NVARCHAR(2000)  
	  
	  
		----------------SE LA QUARTA COLONNA VIENE INSERITA
		IF @NOME_COLONNA4 IS NOT NULL
		BEGIN
			SET @COLONNE =   @NOME_COLONNA1+','+ @NOME_COLONNA2+','+  @NOME_COLONNA3+','+  @NOME_COLONNA4
		END
		ELSE
		----------------SE LA TERZA COLONNA VIENE INSERITA
		IF @NOME_COLONNA3 IS NOT NULL
		BEGIN
			SET @COLONNE =   @NOME_COLONNA1+','+  @NOME_COLONNA2+','+  @NOME_COLONNA3
		END
		ELSE
		----------------SE LA SECONDA COLONNA VIENE INSERITA
		IF @NOME_COLONNA2 IS NOT NULL
		BEGIN
  			SET @COLONNE =   @NOME_COLONNA1+','+ @NOME_COLONNA2
		END
		ELSE
		BEGIN
		----------------SE SOLO LA PRIMA COLONNA VIENE INSERITA	  
			SET @COLONNE = @NOME_COLONNA1
		END				

	
		-- se nella condizione "is_index_unique" viene impostato 1	
		IF @is_index_unique = '1'
			SET @unique = 'UNIQUE'
		ELSE
			SET @unique = ''
	  
		set @data_eseguito = (select convert (varchar, getdate(), 120))
	   	
	   	set @tipoindice = case @Index_Type when 'NORMAL' then 'NONCLUSTERED' else @Index_Type end
	   	
	   	SET @istruzione = N'CREATE '+@unique+' '+ @tipoindice  
			+ ' INDEX ['+@nome_index+'] ON [' + @nome_utente + '].[' + @nome_tabella 
			+ '] ( '		+@COLONNE+ ' )'


		begin try
			execute sp_executesql @istruzione
			print @istruzione
		end try
		begin catch
		-- Salva il numero dell'errore
			SELECT @ErrorVar = @@ERROR
		end catch

		--Condizioni degli errori
		IF @ErrorVar <> 0
		BEGIN
			IF @ErrorVar = 515
            BEGIN
                SET @esito = N'ESITO NEGATIVO - Non  possibile di modificare la colonna NON PIENA'
            END
			ELSE IF @ErrorVar = 156
            BEGIN
                SET @esito = @istruzione
            END
			ELSE
            BEGIN
                SET @esito = N'ERROR: error '
                    + RTRIM(CAST(@ErrorVar AS NVARCHAR(10)))
                    + N' occurred.';
            END
        END
		-- SE NON CI SONO NESSUN ERRORE.
		ELSE
		BEGIN 
			SET @ESITO = 'ESITO POSITIVO'
		END

	    SET @COMANDO_RICHIESTO = 'ADDED INDEX ' +@NOME_INDEX+' ON '+@NOME_TABELLA+''
       
		EXECUTE DOCSADM.UTL_INSERT_LOG @NOME_UTENTE  , NULL, @COMANDO_RICHIESTO, @VERSIONECD, @ESITO
	
	END
	ELSE
	--SE  GIA' ESISTENTE L'INDICE		
	BEGIN	
		SET @COMANDO_RICHIESTO = 'ADDING INDEX ' +@nome_index+' ON '+@NOME_TABELLA+''
		SET @ESITO = 'ESITO NEGATIVO - INDICE GIA ESISTENTE'
		EXECUTE DOCSADM.UTL_INSERT_LOG @NOME_UTENTE  , NULL, @COMANDO_RICHIESTO, @VERSIONECD, @ESITO
	END
END
