USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_AUTH_Select_AutorizedObject_PK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_AUTH_Select_AutorizedObject_PK] ( @System_ID int )
AS
BEGIN
SELECT 
ARCHIVE_AuthorizedObject.Authorization_ID, 
ARCHIVE_AuthorizedObject.Profile_ID, 
ARCHIVE_AuthorizedObject.Project_ID ,
ARCHIVE_AuthorizedObject.System_ID
FROM [DOCSADM].ARCHIVE_AuthorizedObject
WHERE ( Authorization_ID = @System_ID )
END
GO
