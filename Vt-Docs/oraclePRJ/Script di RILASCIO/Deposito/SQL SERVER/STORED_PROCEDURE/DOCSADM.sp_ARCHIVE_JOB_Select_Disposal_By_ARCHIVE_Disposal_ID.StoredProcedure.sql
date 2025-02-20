USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_JOB_Select_Disposal_By_ARCHIVE_Disposal_ID]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_JOB_Select_Disposal_By_ARCHIVE_Disposal_ID]  ( @Disposal_ID int  )
AS
BEGIN
SELECT [ARCHIVE_JOB_Disposal].[System_ID],
 [ARCHIVE_JOB_Disposal].[Disposal_ID], 
 [ARCHIVE_JOB_Disposal].[JobType_ID], 
 [ARCHIVE_JOB_Disposal].[InsertJobTimestamp] , 
 [ARCHIVE_JOB_Disposal].[StartJobTimestamp],
 [ARCHIVE_JOB_Disposal].[EndJobTimestamp],
 [ARCHIVE_JOB_Disposal].[Executed]
FROM [DOCSADM].[ARCHIVE_JOB_Disposal]
WHERE ( [Disposal_ID] = @Disposal_ID )
END
GO
