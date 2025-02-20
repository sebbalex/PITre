USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_AUTH_Update_Autorization_PK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_AUTH_Update_Autorization_PK]  
( @People_ID int , @StartDate datetime , @EndDate datetime ,
@Note Varchar(2000), @System_ID int OUTPUT )
AS
BEGIN
UPDATE [DOCSADM].ARCHIVE_Authorization
SET  
[People_ID] = @People_ID,
[StartDate] = @StartDate ,
[EndDate] = @EndDate ,
[Note]=@Note
WHERE ( [System_ID] = @System_ID )
SET @System_ID = SCOPE_IDENTITY()
END
GO
