USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Insert_TransferState]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Insert_TransferState]  ( @Transfer_ID int , @TransferStateType_ID int , @System_ID int OUTPUT )
AS
BEGIN
INSERT INTO [DOCSADM].[ARCHIVE_TransferState] ( [Transfer_ID], [TransferStateType_ID], [DateTime] ) 
VALUES ( @Transfer_ID, @TransferStateType_ID, getdate() ) 
SET @System_ID = SCOPE_IDENTITY()
END
GO
