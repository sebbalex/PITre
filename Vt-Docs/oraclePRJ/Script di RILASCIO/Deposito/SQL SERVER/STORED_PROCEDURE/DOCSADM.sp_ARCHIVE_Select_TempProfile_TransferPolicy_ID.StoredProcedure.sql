USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Select_TempProfile_TransferPolicy_ID]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Select_TempProfile_TransferPolicy_ID]  ( @TransferPolicy_ID int  )
AS
BEGIN
SELECT [ARCHIVE_TempProfile].[TransferPolicy_ID] , 
		[ARCHIVE_TempProfile].[Profile_ID], 
		[ARCHIVE_TempProfile].[DataUltimoAccesso], 
		[ARCHIVE_TempProfile].[NumeroUtentiAccedutiUltimoAnno],
		[ARCHIVE_TempProfile].[NumeroAccessiUltimoAnno], 
		[ARCHIVE_TempProfile].[TipoTrasferimento_Policy],
		[ARCHIVE_TempProfile].[TipoTrasferimento_Versamento], 
		[ARCHIVE_TempProfile].[CopiaPerCatenaDoc_Policy], 
		[ARCHIVE_TempProfile].[CopiaPerConservazione_Policy], 
		[ARCHIVE_TempProfile].[CopiaPerFascicolo_Policy],
		[ARCHIVE_TempProfile].[CopiaPerCatenaDoc_Versamento], 
		[ARCHIVE_TempProfile].[CopiaPerConservazione_Versamento],
		[ARCHIVE_TempProfile].[CopiaPerFascicolo_Versamento],
		[ARCHIVE_TempProfile].[OggettoDocumento],
		[ARCHIVE_TempProfile].[TipoDocumento],
		[ARCHIVE_TempProfile].[Registro],
		[ARCHIVE_TempProfile].[UO],
		[ARCHIVE_TempProfile].[Tipologia],
		[ARCHIVE_TempProfile].[DataCreazione],
		[ARCHIVE_TempProfile].MantieniCopia
		
   FROM [DOCSADM].[ARCHIVE_TempProfile]
WHERE ( [TransferPolicy_ID] = @TransferPolicy_ID )
END
GO
