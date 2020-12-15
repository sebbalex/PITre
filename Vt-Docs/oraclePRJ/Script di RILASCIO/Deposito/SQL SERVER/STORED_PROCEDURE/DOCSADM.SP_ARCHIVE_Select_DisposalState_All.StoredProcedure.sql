USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[SP_ARCHIVE_Select_DisposalState_All]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[SP_ARCHIVE_Select_DisposalState_All] 
AS
BEGIN
SELECT [ARCHIVE_DisposalState].[System_ID], [ARCHIVE_DisposalState].[Disposal_ID], [ARCHIVE_DisposalState].[DisposalStateType_ID], [ARCHIVE_DisposalState].[DateTime] 
FROM [DOCSADM].[ARCHIVE_DisposalState]
END
GO
