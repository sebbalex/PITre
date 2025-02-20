SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--///////////////////////////////////////////////////////	
--///	Stefano Limiti								/////	
--///	12/09/2013									/////
--///////////////////////////////////////////////////////

CREATE PROC   [DOCSADM].[sp_ARCHIVE_Update_TransferFileInfo_PK]  ( @System_ID int,
																   @Processed int , 
																   @ProcessResult int, 
																   @ProcessError varchar (2000) , 
																   @RowsAffected int out )
AS
BEGIN

	UPDATE [DOCSADM].[ARCHIVE_TempTransferFile]
	SET    [Processed] = @Processed,
		   [ProcessResult] = @ProcessResult ,
		   [ProcessError] = @ProcessError 
	
	WHERE ( [System_ID] = @System_ID )

	set @RowsAffected = @@ROWCOUNT
	
END
