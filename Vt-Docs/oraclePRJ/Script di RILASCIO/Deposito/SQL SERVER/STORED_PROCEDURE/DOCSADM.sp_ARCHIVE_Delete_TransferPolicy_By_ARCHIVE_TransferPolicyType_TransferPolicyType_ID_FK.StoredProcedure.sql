USE [PCM_DEPOSITO_1]
GO
/****** Object:  StoredProcedure [DOCSADM].[sp_ARCHIVE_Delete_TransferPolicy_By_ARCHIVE_TransferPolicyType_TransferPolicyType_ID_FK]    Script Date: 08/14/2013 11:50:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC   [DOCSADM].[sp_ARCHIVE_Delete_TransferPolicy_By_ARCHIVE_TransferPolicyType_TransferPolicyType_ID_FK]  ( @TransferPolicyType_ID int  )
AS
BEGIN
DELETE [DOCSADM].[ARCHIVE_TransferPolicy]
WHERE ( [TransferPolicyType_ID] = @TransferPolicyType_ID )
END
GO
