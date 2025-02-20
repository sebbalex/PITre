USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Update_TempProfile_MantieniCopia]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Update_TempProfile_MantieniCopia]  ( @ProfileListID VARCHAR(MAX), @TransferID int   )
AS
BEGIN
	SET NOCOUNT ON;
	-- update dei profile da mantenere in copia
	DECLARE @sql_stringCopia nvarchar(MAX)
	-- update dei profile che non sono da mantenere come copia
	DECLARE @sql_stringNotCopia nvarchar(MAX)
	
	
	SET @sql_stringCopia = CAST(N'
			UPDATE [DOCSADM].[ARCHIVE_TempProfile]
			SET [MantieniCopia]=1
			WHERE [Profile_ID] IN (' + CAST(@ProfileListID AS NVARCHAR(MAX)) + CAST(N')' AS NVARCHAR(MAX))+'
			AND [TransferPolicy_ID] IN 
				(select System_ID 
				from [DOCSADM].[ARCHIVE_TransferPolicy] 
				where Transfer_ID = '+ CAST(@TransferID AS NVARCHAR(MAX)) + CAST(N')' AS NVARCHAR(MAX)) AS NVARCHAR(MAX))
			
	SET @sql_stringNotCopia = CAST(N'
			UPDATE [DOCSADM].[ARCHIVE_TempProfile]
			SET [MantieniCopia]=0
			WHERE [Profile_ID] NOT IN (' + CAST(@ProfileListID AS NVARCHAR(MAX)) + CAST(N')' AS NVARCHAR(MAX))+'
			AND [TransferPolicy_ID] IN 
				(select System_ID 
				from [DOCSADM].[ARCHIVE_TransferPolicy] 
				where Transfer_ID = '+ CAST(@TransferID AS NVARCHAR(MAX)) + CAST(N')' AS NVARCHAR(MAX)) AS NVARCHAR(MAX))
				
	
	PRINT @sql_stringCopia;
	PRINT @sql_stringNotCopia;


	EXECUTE sp_executesql @sql_stringCopia;
	EXECUTE sp_executesql @sql_stringNotCopia;
END
GO
