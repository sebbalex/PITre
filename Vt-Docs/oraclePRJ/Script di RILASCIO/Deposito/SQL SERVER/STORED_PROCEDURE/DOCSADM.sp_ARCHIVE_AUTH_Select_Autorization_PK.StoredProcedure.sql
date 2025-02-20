USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_AUTH_Select_Autorization_PK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_AUTH_Select_Autorization_PK] ( @System_ID int  )
AS
BEGIN
SELECT 
ARCHIVE_Authorization.[System_ID], 
ARCHIVE_Authorization.People_ID, 
ARCHIVE_Authorization.StartDate ,
ARCHIVE_Authorization.EndDate,
ARCHIVE_Authorization.Note
FROM [DOCSADM].ARCHIVE_Authorization
WHERE ( [System_ID] = @System_ID )
END
GO
