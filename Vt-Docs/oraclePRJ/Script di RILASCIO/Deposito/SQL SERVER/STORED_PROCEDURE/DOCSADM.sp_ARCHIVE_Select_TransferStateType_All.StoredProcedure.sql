USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Select_TransferStateType_All]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Select_TransferStateType_All] 
AS
BEGIN
SELECT [ARCHIVE_TransferStateType].[System_ID], [ARCHIVE_TransferStateType].[Name] 
FROM [DOCSADM].[ARCHIVE_TransferStateType]
END
GO
