USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_JOB_Insert_Disposal]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_JOB_Insert_Disposal]  
( @Disposal_ID int , @JobType_ID int , @System_ID int OUTPUT )
AS
BEGIN
INSERT INTO [DOCSADM].[ARCHIVE_JOB_Disposal] (Disposal_ID , [JobType_ID], [InsertJobTimestamp], [Executed])
VALUES ( @Disposal_ID, @JobType_ID, GETDATE(), 0) 
SET @System_ID = SCOPE_IDENTITY()
END
GO
