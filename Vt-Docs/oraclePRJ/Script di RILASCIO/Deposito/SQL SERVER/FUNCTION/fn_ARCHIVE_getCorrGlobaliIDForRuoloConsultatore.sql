USE [PCM_DEPOSITO_1]
GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==============================================================================================
-- Author:		Giovanni Olivari
-- Create date: 07/06/2013
-- Description:	Restituisce il System_ID della Tabella DPA_CORR_GLOBALI per il ruolo Consultatore
-- ==============================================================================================
CREATE FUNCTION [DOCSADM].[fn_ARCHIVE_getCorrGlobaliIDForRuoloConsultatore]
(
)
RETURNS INT
AS
BEGIN

	RETURN 1

END
