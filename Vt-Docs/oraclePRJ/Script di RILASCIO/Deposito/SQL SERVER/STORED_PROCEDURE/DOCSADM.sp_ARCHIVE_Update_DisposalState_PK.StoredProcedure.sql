USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Update_DisposalState_PK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Update_DisposalState_PK]  ( @Disposal_ID int , @DisposalStateType_ID int , @DateTime datetime , @System_ID int, @RowsAffected int out )
AS
BEGIN
UPDATE [DOCSADM].[ARCHIVE_DisposalState]
SET  [Disposal_ID] = @Disposal_ID,
[DisposalStateType_ID] = @DisposalStateType_ID,
[DateTime] = @DateTime 
WHERE ( [System_ID] = @System_ID )
set @RowsAffected= @@ROWCOUNT
END
GO
