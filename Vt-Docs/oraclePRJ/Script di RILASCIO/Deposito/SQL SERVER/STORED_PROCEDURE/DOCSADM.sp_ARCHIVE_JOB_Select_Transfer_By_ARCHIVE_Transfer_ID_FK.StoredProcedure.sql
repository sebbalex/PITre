USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_JOB_Select_Transfer_By_ARCHIVE_Transfer_ID_FK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC   [DOCSADM].[sp_ARCHIVE_JOB_Select_Transfer_By_ARCHIVE_Transfer_ID_FK]  ( @Transfer_ID int  )
AS
BEGIN
SELECT [ARCHIVE_JOB_Transfer].[System_ID], [ARCHIVE_JOB_Transfer].[Transfer_ID], [ARCHIVE_JOB_Transfer].[JobType_ID], [ARCHIVE_JOB_Transfer].[InsertJobTimestamp] , [ARCHIVE_JOB_Transfer].[StartJobTimestamp],[ARCHIVE_JOB_Transfer].[EndJobTimestamp],[ARCHIVE_JOB_Transfer].[Executed]
FROM [DOCSADM].[ARCHIVE_JOB_Transfer]
WHERE ( [Transfer_ID] = @Transfer_ID )
END
GO
