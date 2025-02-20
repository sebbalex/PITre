USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Update_TransferState]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Update_TransferState]  ( @Transfer_ID int , @Transfer_ID_Original int , @TransferStateType_ID int , @TransferStateType_ID_Original int , @DateTime datetime , @DateTime_Original datetime , @System_ID int , @RowsAffected int out )
AS
BEGIN
UPDATE [DOCSADM].[ARCHIVE_TransferState]
SET  [Transfer_ID] = @Transfer_ID,
[TransferStateType_ID] = @TransferStateType_ID,
[DateTime] = @DateTime 
WHERE
   (
    (([Transfer_ID] IS NOT NULL AND @Transfer_ID_Original IS NOT NULL AND [Transfer_ID] = @Transfer_ID_Original) OR ([Transfer_ID] IS NULL AND @Transfer_ID_Original IS NULL)) AND
    (([TransferStateType_ID] IS NOT NULL AND @TransferStateType_ID_Original IS NOT NULL AND [TransferStateType_ID] = @TransferStateType_ID_Original) OR ([TransferStateType_ID] IS NULL AND @TransferStateType_ID_Original IS NULL)) AND
    (([DateTime] IS NOT NULL AND @DateTime_Original IS NOT NULL AND [DateTime] = @DateTime_Original) OR ([DateTime] IS NULL AND @DateTime_Original IS NULL)) AND
    ( [System_ID] = @System_ID )
   )
set @RowsAffected= @@ROWCOUNT
END
GO
