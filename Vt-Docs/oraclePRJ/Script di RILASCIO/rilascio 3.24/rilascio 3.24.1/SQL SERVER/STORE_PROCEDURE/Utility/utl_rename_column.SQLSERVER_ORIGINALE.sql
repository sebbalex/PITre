

ALTER PROCEDURE [DOCSADM].[utl_rename_column]
	-- Add the parameters for the stored procedure here
		@versioneCD				Nvarchar(200),
		@nome_utente			Nvarchar(200), 
		@nome_tabella			Nvarchar(200),
		@nome_colonna			Nvarchar(200),
		@nome_colonna_nuova		Nvarchar(200),
		@RFU					Nvarchar(200)
AS
BEGIN
	if exists(select * from syscolumns where name=@nome_colonna and id in(select id from sysobjects where name=@nome_tabella and xtype='U'))
	BEGIN
		if not exists(select * from syscolumns where name=@nome_colonna_nuova and id in(select id from sysobjects where name=@nome_tabella and xtype='U'))
		BEGIN
	
			DECLARE @istruzione Nvarchar(2000)
			DECLARE @insert_log Nvarchar(2000)
			DECLARE @data_eseguito Nvarchar(2000)
			DECLARE @esito Nvarchar(2000)
			DECLARE @comando_richiesto Nvarchar(2000)
	   	   	
	   		SET @istruzione = N'EXEC SP_RENAME ''' + @nome_utente + '.' + @nome_tabella + '.'+ @nome_colonna +''', ''' + @nome_colonna_nuova + ''', ''COLUMN'';'
		
			PRINT @istruzione

			execute sp_executesql @istruzione
       
			set @esito = 'Esito positivo'
			set @comando_richiesto = 'Renamed column ' +@nome_colonna+' to '+@nome_colonna_nuova+' on '+@nome_tabella+''

			execute [DOCSADM].utl_insert_log @nome_utente,getdate, @comando_richiesto, @versioneCD, @esito
       
		END
		ELSE
		BEGIN	
	   
		   set @esito = 'Esito negativo - Colonna nuova gi esistente'
		   set @comando_richiesto = 'Renaming column ' +@nome_colonna+' to '+@nome_colonna_nuova+' on '+@nome_tabella+''

		   execute [DOCSADM].utl_insert_log @nome_utente,getdate, @comando_richiesto, @versioneCD, @esito
		END   
	END
	ELSE
	BEGIN	
	   
		set @esito = 'Esito negativo - Colonna vecchia non esistente'
		set @comando_richiesto = 'Renaming column ' +@nome_colonna+' to '+@nome_colonna_nuova+' on '+@nome_tabella+''

		execute [DOCSADM].utl_insert_log @nome_utente,getdate, @comando_richiesto, @versioneCD, @esito
	END
	
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT	@versioneCD, 
			@nome_utente, 
			@nome_tabella, 
			@nome_colonna, 
			@nome_colonna_nuova,
			@RFU
END
