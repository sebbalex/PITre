


ALTER  PROCEDURE [DOCSADM].[utl_insert_log]
	-- Add the parameters for the stored procedure here
		@nome_utente		Nvarchar(200), 
		@data_eseguito		Nvarchar(200), 
		@comando_eseguito	Nvarchar (200),
		@versione_CD		Nvarchar(200),
		@esito				Nvarchar(200)	
		

AS
BEGIN

	DECLARE @istruzione    Nvarchar(2000)
	--DECLARE @data_eseguito Nvarchar (200)
	
	--SET IDENTITY_INSERT [DOCSADM].DPA_LOG_INSTALL ON
	set @data_eseguito = (select convert (varchar, getdate(), 120))
	
	SET @istruzione = N'INSERT INTO '+@nome_utente +'.DPA_LOG_INSTALL VALUES (
		'''+ISNULL(@data_eseguito,GETDATE())+''',
        '''+@comando_eseguito+''',
        '''+@versione_CD+''',
        '''+@esito+''')'
        
        execute sp_executesql @istruzione
        print @istruzione

END            
