USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Select_TransferPolicy_By_ARCHIVE_Transfer_Transfer_ID_FK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Select_TransferPolicy_By_ARCHIVE_Transfer_Transfer_ID_FK]  ( @Transfer_ID int  )
AS
BEGIN
SELECT 
[ARCHIVE_TransferPolicy].[System_ID], 
[ARCHIVE_TransferPolicy].[Description], 
[ARCHIVE_TransferPolicy].[Enabled], 
[ARCHIVE_TransferPolicy].[Transfer_ID], 
[ARCHIVE_TransferPolicy].[TransferPolicyType_ID], 
[ARCHIVE_TransferPolicy].[Registro_ID], 
[ARCHIVE_TransferPolicy].[TransferPolicyState_ID],
[ARCHIVE_TransferPolicy].[UO_ID], 
[ARCHIVE_TransferPolicy].[IncludiSottoalberoUO], 
[ARCHIVE_TransferPolicy].[Tipologia_ID], 
[ARCHIVE_TransferPolicy].[Titolario_ID], 
[ARCHIVE_TransferPolicy].[ClasseTitolario], 
[ARCHIVE_TransferPolicy].[IncludiSottoalberoClasseTit], 
[ARCHIVE_TransferPolicy].[AnnoCreazioneDa], 
[ARCHIVE_TransferPolicy].[AnnoCreazioneA], 
[ARCHIVE_TransferPolicy].[AnnoProtocollazioneDa], 
[ARCHIVE_TransferPolicy].[AnnoProtocollazioneA], 
[ARCHIVE_TransferPolicy].[AnnoChiusuraDa], 
[ARCHIVE_TransferPolicy].[AnnoChiusuraA] 
FROM [DOCSADM].[ARCHIVE_TransferPolicy] 
WHERE ( [Transfer_ID] = @Transfer_ID )
END
GO
