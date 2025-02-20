USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Update_TempProjectDisposal]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================================================
-- Author:		Giordano Iacozzilli
-- Create date: 10/07/2013
-- Description:	Update record tabella  TempProjectDisposal
-- ============================================================================
CREATE PROCEDURE [DOCSADM].[sp_ARCHIVE_Update_TempProjectDisposal]
	@Disposal_ID int,
	@ProjectsList VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @sql_string nvarchar(MAX)

	-- Create temp table
	--
	IF OBJECT_ID('tempdb..#ProjectsListTable') IS NOT NULL DROP TABLE #ProjectsListTable
	CREATE TABLE #ProjectsListTable
	(
		ID int
	)

	SET @sql_string = CAST(N'
		INSERT INTO #ProjectsListTable (ID)
		SELECT Project_ID FROM ARCHIVE_TempProjectDisposal
		WHERE Project_ID IN (' AS NVARCHAR(MAX)) + CAST(@ProjectsList AS NVARCHAR(MAX)) + CAST(N')' AS NVARCHAR(MAX))
		
	PRINT @sql_string;

	EXECUTE sp_executesql @sql_string;

		Update ARCHIVE_TempProjectDisposal 
		set ARCHIVE_TempProjectDisposal.DaScartare = 0 
		where ARCHIVE_TempProjectDisposal.Disposal_ID = @Disposal_ID
		AND ARCHIVE_TempProjectDisposal.Project_ID in (select ID from  #ProjectsListTable);

		Update ARCHIVE_TempProjectDisposal 
		set ARCHIVE_TempProjectDisposal.DaScartare = 1
		where ARCHIVE_TempProjectDisposal.Disposal_ID = @Disposal_ID
		AND ARCHIVE_TempProjectDisposal.Project_ID not in (select ID from  #ProjectsListTable);


END
GO
