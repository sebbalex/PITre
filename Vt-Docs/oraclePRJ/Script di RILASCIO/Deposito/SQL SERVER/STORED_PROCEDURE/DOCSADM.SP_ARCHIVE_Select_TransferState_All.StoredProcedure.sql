USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[SP_ARCHIVE_Select_TransferState_All]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[SP_ARCHIVE_Select_TransferState_All] 
AS
BEGIN
SELECT [ARCHIVE_TransferState].[System_ID], [ARCHIVE_TransferState].[Transfer_ID], [ARCHIVE_TransferState].[TransferStateType_ID], [ARCHIVE_TransferState].[DateTime] 
FROM [DOCSADM].[ARCHIVE_TransferState]
END
GO
