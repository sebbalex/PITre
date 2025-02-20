USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Update_DisposalState]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Update_DisposalState]  ( @Disposal_ID int , @Disposal_ID_Original int , @DisposalStateType_ID int , @DisposalStateType_ID_Original int , @DateTime datetime , @DateTime_Original datetime , @System_ID int , @RowsAffected int out )
AS
BEGIN
UPDATE [DOCSADM].[ARCHIVE_DisposalState]
SET  [Disposal_ID] = @Disposal_ID,
[DisposalStateType_ID] = @DisposalStateType_ID,
[DateTime] = @DateTime 
WHERE
   (
    (([Disposal_ID] IS NOT NULL AND @Disposal_ID_Original IS NOT NULL AND [Disposal_ID] = @Disposal_ID_Original) OR ([Disposal_ID] IS NULL AND @Disposal_ID_Original IS NULL)) AND
    (([DisposalStateType_ID] IS NOT NULL AND @DisposalStateType_ID_Original IS NOT NULL AND [DisposalStateType_ID] = @DisposalStateType_ID_Original) OR ([DisposalStateType_ID] IS NULL AND @DisposalStateType_ID_Original IS NULL)) AND
    (([DateTime] IS NOT NULL AND @DateTime_Original IS NOT NULL AND [DateTime] = @DateTime_Original) OR ([DateTime] IS NULL AND @DateTime_Original IS NULL)) AND
    ( [System_ID] = @System_ID )
   )
set @RowsAffected= @@ROWCOUNT
END
GO
