USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_JOB_Select_TransferPolicyByTransferID]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC   [DOCSADM].[sp_ARCHIVE_JOB_Select_TransferPolicyByTransferID]  ( @Transfer_ID int  )
AS
BEGIN
SELECT [jb].[System_ID], [jb].[TransferPolicy_ID], [jb].[JobType_ID], [jb].[InsertJobTimestamp], [jb].[StartJobTimestamp], jb.EndJobTimestamp,jb.Executed 
FROM [DOCSADM].[ARCHIVE_JOB_TransferPolicy] jb , [DOCSADM].[ARCHIVE_TransferPolicy] p
WHERE ( p.Transfer_ID = @Transfer_ID 
		and p.System_ID = jb.TransferPolicy_ID )
END
GO
