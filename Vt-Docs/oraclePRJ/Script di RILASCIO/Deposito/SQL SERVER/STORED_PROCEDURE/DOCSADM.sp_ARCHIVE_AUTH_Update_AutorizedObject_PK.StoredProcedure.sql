USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_AUTH_Update_AutorizedObject_PK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_AUTH_Update_AutorizedObject_PK]  
( @Authorization_ID int , @Project_ID int , @Profile_ID int , @System_ID int OUTPUT )

AS
BEGIN
UPDATE [DOCSADM].[ARCHIVE_AuthorizedObject]
SET  
[Authorization_ID] = @Authorization_ID,
[Project_ID] = @Project_ID ,
[Profile_ID] = @Profile_ID
WHERE ( [System_ID] = @System_ID )
SET @System_ID = SCOPE_IDENTITY()
END
GO
