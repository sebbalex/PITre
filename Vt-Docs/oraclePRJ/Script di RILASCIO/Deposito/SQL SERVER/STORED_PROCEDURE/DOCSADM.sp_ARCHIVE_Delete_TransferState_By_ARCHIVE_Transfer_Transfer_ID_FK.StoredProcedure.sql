USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Delete_TransferState_By_ARCHIVE_Transfer_Transfer_ID_FK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Delete_TransferState_By_ARCHIVE_Transfer_Transfer_ID_FK]  ( @Transfer_ID int, @RowsAffected int out  )
AS
BEGIN
DELETE [DOCSADM].[ARCHIVE_TransferState]
WHERE ( [Transfer_ID] = @Transfer_ID )
set @RowsAffected = @@ROWCOUNT
END
GO
