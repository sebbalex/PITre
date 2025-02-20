USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Select_TransferState_PK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Select_TransferState_PK]  ( @System_ID int  )
AS
BEGIN
SELECT [ARCHIVE_TransferState].[System_ID], [ARCHIVE_TransferState].[Transfer_ID], [ARCHIVE_TransferState].[TransferStateType_ID], [ARCHIVE_TransferState].[DateTime] 
FROM [DOCSADM].[ARCHIVE_TransferState]
WHERE ( [System_ID] = @System_ID )
END
GO
