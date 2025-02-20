
sET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE VIEW @db_user.RDE_Utente
AS
SELECT DISTINCT
A.USER_ID  AS IdUtente, A.SYSTEM_ID  AS IdUtenteRemoto, A.USER_PASSWORD AS Password,  B.ID_AMM  AS IdAmministrazioneRemoto,
B.VAR_COGNOME AS Cognome, B.VAR_NOME AS Nome
FROM   @db_user.DPA_CORR_GLOBALI B, @db_user.PEOPLEGROUPS C, @db_user.PEOPLE A
WHERE A.SYSTEM_ID = B.ID_PEOPLE
AND (B.CHA_TIPO_URP = 'P')  AND (B.CHA_TIPO_IE = 'I') AND (B.DTA_FINE IS NULL)
AND   (A.SYSTEM_ID = C.PEOPLE_SYSTEM_ID AND C.GROUPS_SYSTEM_ID
IN (SELECT N.ID_GRUPPO FROM @db_user.DPA_TIPO_F_RUOLO M, @db_user.DPA_CORR_GLOBALI N WHERE ID_TIPO_FUNZ IN (select id_tipo_funzione from @db_user.DPA_FUNZIONI where cod_funzione = 'PROTO_EME') AND M.ID_RUOLO_IN_UO = N.SYSTEM_ID))
GO


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO