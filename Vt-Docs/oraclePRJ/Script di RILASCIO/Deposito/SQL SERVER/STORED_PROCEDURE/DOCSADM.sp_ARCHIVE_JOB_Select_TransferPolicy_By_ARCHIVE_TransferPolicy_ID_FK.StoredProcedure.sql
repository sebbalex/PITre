USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_JOB_Select_TransferPolicy_By_ARCHIVE_TransferPolicy_ID_FK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC   [DOCSADM].[sp_ARCHIVE_JOB_Select_TransferPolicy_By_ARCHIVE_TransferPolicy_ID_FK]  ( @TransferPolicy_ID int  )
AS
BEGIN
SELECT [ARCHIVE_JOB_TransferPolicy].[System_ID], [ARCHIVE_JOB_TransferPolicy].[TransferPolicy_ID], [ARCHIVE_JOB_TransferPolicy].[JobType_ID], [ARCHIVE_JOB_TransferPolicy].[InsertJobTimestamp] , [ARCHIVE_JOB_TransferPolicy].[StartJobTimestamp],[ARCHIVE_JOB_TransferPolicy].[EndJobTimestamp],[ARCHIVE_JOB_TransferPolicy].[Executed]
FROM [DOCSADM].[ARCHIVE_JOB_TransferPolicy]
WHERE ( [TransferPolicy_ID] = @TransferPolicy_ID )
END
GO
