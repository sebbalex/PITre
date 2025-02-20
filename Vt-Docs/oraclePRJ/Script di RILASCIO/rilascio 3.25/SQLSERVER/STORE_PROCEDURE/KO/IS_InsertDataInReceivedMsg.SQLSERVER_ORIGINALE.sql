USE [GFD_SVIL]
GO
/****** Object:  StoredProcedure [DOCSADM].[IS_InsertDataInReceivedMsg]    Script Date: 03/08/2013 11:16:39 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [DOCSADM].[IS_InsertDataInReceivedMsg] @p_MessageId VARCHAR(4000),
@p_ReceivedPrivate INT,
@p_Subject VARCHAR(4000),
@p_SenderDescription VARCHAR(4000),
@p_SenderUrl VARCHAR(4000),
@p_SenderAdministrationCode VARCHAR(4000), 
@p_AOOCode VARCHAR(4000), 
@p_RecordNumber INT, 
@p_RecordDate DATETIME , 
@p_ReceiverCode VARCHAR(4000)
AS
Begin
-- Inserimento informazioni sul messaggio ricevuto
 Insert Into SimpInteropReceivedMessage(MessageId,
	ReceivedPrivate,
	ReceivedDate,
	Subject,
	SenderDescription,
	SenderUrl,
	SenderAdministrationCode,
	AOOCode,
	RecordNumber,
	RecordDate, 
	ReceiverCode)
VALUES(@p_MessageId,
	@p_ReceivedPrivate,
	GetDate(),
	@p_Subject,
	@p_SenderDescription,
	@p_SenderUrl,
	@p_SenderAdministrationCode,
	@p_AOOCode,
	@p_RecordNumber,
	@p_RecordDate,
	@p_ReceiverCode) 

End 
