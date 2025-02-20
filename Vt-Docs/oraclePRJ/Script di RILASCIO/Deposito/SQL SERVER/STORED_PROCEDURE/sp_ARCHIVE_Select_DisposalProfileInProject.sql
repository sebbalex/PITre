SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ============================================================================
-- Author:		Limiti Stefano
-- Create date: 21/10/2013
-- Description:	Data la lista dei documenti e dei fascicoli contenuti in uno
-- scarto, torna le relazioni tra loro ossia per ogni fascicolo, 
-- della lista di fascicoli, quali documenti contiene dell'altra lista 				
-- ============================================================================
CREATE PROCEDURE [DOCSADM].[sp_ARCHIVE_Select_DisposalProfileInProject]
	@ProjectsList VARCHAR(MAX),
	@ProfileList VARCHAR(MAX)
	
	AS
	BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

		DECLARE @sql_string nvarchar(MAX)
		
		SET @sql_string = CAST(N'
			SELECT  p.ID_FASCICOLO,  pc.link as DOC_NUMBER FROM PROJECT_COMPONENTS pc, PROJECT p
			WHERE pc.link IN (' AS NVARCHAR(MAX)) + CAST(@ProfileList AS NVARCHAR(MAX)) + CAST(N')' AS NVARCHAR(MAX))+
			CAST('AND p.SYSTEM_ID = pc.Project_ID AND Project_ID IN (SELECT P.SYSTEM_ID FROM PROJECT P WHERE P.ID_FASCICOLO IN ('AS NVARCHAR(MAX)) 
			+ CAST(@ProjectsList AS NVARCHAR(MAX)) + CAST(N'))' AS NVARCHAR(MAX))
			
		PRINT @sql_string;

		EXECUTE sp_executesql @sql_string;
END