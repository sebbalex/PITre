USE [GFD_SVIL]
GO
/****** Object:  StoredProcedure [DOCSADM].[SPsetDataVistaSmistamento]    Script Date: 03/08/2013 14:16:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER  PROCEDURE [DOCSADM].[SPsetDataVistaSmistamento]
@idPeople INT,
@idOggetto INT,
@idGruppo INT,
@tipoOggetto CHAR(1),
@idTrasmissione INT,
@iddelegato  INT,
@resultValue int out
AS
DECLARE @sysTrasmSingola INT
DECLARE @chaTipoTrasm CHAR(1)
DECLARE @chaTipoRagione CHAR(1)
DECLARE @chaTipoDest CHAR(1)


BEGIN TRY

SET @resultValue = 0

DECLARE cursorTrasmSingolaDocumento CURSOR LOCAL FOR
SELECT B.system_id, b.cha_tipo_trasm, c.cha_tipo_ragione, b.cha_tipo_dest
FROM dpa_trasmissione a, dpa_trasm_singola b,  DPA_RAGIONE_TRASM c
WHERE a.system_id = @idTrasmissione and a.dta_invio is not null and a.system_id = b.id_trasmissione and (b.id_corr_globale =
(select system_id from dpa_corr_globali where id_gruppo = @idGruppo)
OR b.id_corr_globale =
(SELECT SYSTEM_ID FROM DPA_CORR_GLOBALI WHERE ID_people = @idPeople))
AND a.ID_PROFILE = @idOggetto and
b.ID_RAGIONE = c.SYSTEM_ID

IF(@tipoOggetto='D')
BEGIN
              
      OPEN cursorTrasmSingolaDocumento
      FETCH NEXT FROM cursorTrasmSingolaDocumento
      INTO @sysTrasmSingola, @chaTipoTrasm, @chaTipoRagione, @chaTipoDest
      BEGIN
            WHILE @@FETCH_STATUS = 0
                  BEGIN
                        IF (@chaTipoRagione = 'N' OR @chaTipoRagione = 'I')
                        -- SE Â¿ una trasmissione senza workFlow
                        BEGIN
                             IF (@iddelegato = 0)
                                   BEGIN
                                         -- nella trasmissione utente relativa all'utente che sta vedendo il documento setto la data di vista
                                         UPDATE DPA_TRASM_UTENTE
                                         SET DPA_TRASM_UTENTE.CHA_VISTA = '1',
                                         DPA_TRASM_UTENTE.DTA_VISTA = (CASE WHEN DTA_VISTA IS NULL THEN  GETDATE() ELSE DTA_VISTA END),
                                         DPA_TRASM_UTENTE.CHA_IN_TODOLIST = '0'
                                         WHERE
-- modifica del aprile 2011
--DPA_TRASM_UTENTE.DTA_VISTA IS NULL     AND
-- fine modifica del aprile 2011
                                         id_trasm_singola = @sysTrasmSingola
                                         and DPA_TRASM_UTENTE.ID_PEOPLE =@idPeople
                                         
                                         IF (@@ERROR <> 0)
                                         BEGIN
                                               SET @resultValue=1
                                               return @resultValue
                                         END
                                   END
                             ELSE
                                   BEGIN
                                         --in caso di delega
                                         UPDATE DPA_TRASM_UTENTE
                                          SET DPA_TRASM_UTENTE.CHA_VISTA = '1',
                                                  dpa_trasm_utente.cha_vista_delegato = '1',
                                                  dpa_trasm_utente.id_people_delegato = @iddelegato,
                                         DPA_TRASM_UTENTE.DTA_VISTA = (CASE WHEN DTA_VISTA IS NULL THEN  GETDATE() ELSE DTA_VISTA END),
                                         DPA_TRASM_UTENTE.CHA_IN_TODOLIST = '0'
                                         WHERE
-- modifica del aprile 2011
--DPA_TRASM_UTENTE.DTA_VISTA IS NULL     AND
-- fine modifica del aprile 2011 
                                         id_trasm_singola = @sysTrasmSingola
                                         and DPA_TRASM_UTENTE.ID_PEOPLE =@idPeople
                                         
                                         IF (@@ERROR <> 0)
                                         BEGIN
                                               SET @resultValue=1
                                               return @resultValue
                                         END
                                   END
                        
                        
                             -- Impostazione data vista nella trasmissione in todolist
                             update      dpa_todolist
                             set   DTA_VISTA = getdate()
                             where id_trasm_singola = @sysTrasmSingola and 
                                   ID_PEOPLE_DEST = @idPeople AND
                                   id_profile = @idoggetto;

                             IF (@@ERROR <> 0)
                                   BEGIN
                                         SET @resultValue=1
                                         return @resultValue
                                   END
                        
                             IF (@chaTipoTrasm = 'S' AND @chaTipoDest= 'R')
                                   BEGIN
                                         IF (@iddelegato = 0) 
                                               BEGIN
                                                     UPDATE DPA_TRASM_UTENTE SET
                                                     DPA_TRASM_UTENTE.CHA_VISTA = '1',
                                                     DPA_TRASM_UTENTE.CHA_IN_TODOLIST = '0'
                                                     WHERE
-- modifica del aprile 2011
--DPA_TRASM_UTENTE.DTA_VISTA IS NULL     AND
-- fine modifica del aprile 2011         
                                                     id_trasm_singola = @sysTrasmSingola
                                                     AND DPA_TRASM_UTENTE.ID_PEOPLE != @idPeople
                  
                                                     IF (@@ERROR <> 0)
                                                           BEGIN
                                                                 SET @resultValue=1
                                                                 return @resultValue
                                                           END

                                               END
                                         ELSE
                                               BEGIN
                                                     UPDATE DPA_TRASM_UTENTE SET
                                                     DPA_TRASM_UTENTE.CHA_VISTA = '1',
                                                     DPA_TRASM_UTENTE.CHA_VISTA_DELEGATO = '1',
                                                     DPA_TRASM_UTENTE.ID_PEOPLE_DELEGATO = @idDelegato,
                                                     DPA_TRASM_UTENTE.CHA_IN_TODOLIST = '0'
                                                     WHERE
-- modifica del aprile 2011
--DPA_TRASM_UTENTE.DTA_VISTA IS NULL     AND
-- fine modifica del aprile 2011                     
                                                     id_trasm_singola = @sysTrasmSingola
                                                     AND DPA_TRASM_UTENTE.ID_PEOPLE != @idPeople
                  
                                                     IF (@@ERROR <> 0)
                                                           BEGIN
                                                                 SET @resultValue=1
                                                                 return @resultValue
                                                           END
                                                     END
                                               END
                                   END

                        ELSE

                        -- la ragione di trasmissione prevede workflow
                        BEGIN
                             IF (@iddelegato = 0) 
                                   BEGIN
                                         UPDATE DPA_TRASM_UTENTE
                                         SET DPA_TRASM_UTENTE.CHA_VISTA = '1',
                                         DPA_TRASM_UTENTE.DTA_VISTA = (CASE WHEN DTA_VISTA IS NULL THEN  GETDATE() ELSE DTA_VISTA END),
                                         DTA_ACCETTATA = (CASE WHEN DTA_ACCETTATA IS NULL THEN  GETDATE() ELSE DTA_ACCETTATA END),
                                         CHA_ACCETTATA = '1',
                                         CHA_VALIDA = '0'
                                         WHERE 
-- modifica del aprile 2011
--DPA_TRASM_UTENTE.DTA_VISTA IS NULL     AND
-- fine modifica del aprile 2011 
                                         id_trasm_singola = @sysTrasmSingola
                                         and DPA_TRASM_UTENTE.ID_PEOPLE = @idPeople
                                   END
        -- Codice Remmato: abianchi/cferlito - 08/06/2011  -- ETT000000016597
        -- questo IF ((@@ERROR) genera problemi facendo entrare il cursore sia 
        -- nell IF di sopra sia nel ELSE di sotto (blocco delegato)
                                 
           --                        IF (@@ERROR <> 0)
           --                              BEGIN
                                                                 --SET @resultValue=1
                                                                 -- return @resultValue
                                                           --END
            -- Codice Remmato: abianchi/cferlito - 08/06/2011  -- ETT000000016597
                                        
                             ELSE
                                   BEGIN
                                         UPDATE DPA_TRASM_UTENTE
                                         SET DPA_TRASM_UTENTE.CHA_VISTA = '1',
                                         DPA_TRASM_UTENTE.CHA_VISTA_DELEGATO = '1',
                                         DPA_TRASM_UTENTE.ID_PEOPLE_DELEGATO = @iddelegato,
                                         DPA_TRASM_UTENTE.DTA_VISTA = (CASE WHEN DTA_VISTA IS NULL THEN  GETDATE() ELSE DTA_VISTA END),
                                         DTA_ACCETTATA = (CASE WHEN DTA_ACCETTATA IS NULL THEN  GETDATE() ELSE DTA_ACCETTATA END),
                                         CHA_ACCETTATA = '1',
                                         CHA_ACCETTATA_DELEGATO = '1',
                                         CHA_VALIDA = '0'
                                         WHERE 
-- modifica del aprile 2011
--DPA_TRASM_UTENTE.DTA_VISTA IS NULL     AND
-- fine modifica del aprile 2011
                                          id_trasm_singola = @sysTrasmSingola
                                         and DPA_TRASM_UTENTE.ID_PEOPLE = @idPeople
                                   END
                                   IF (@@ERROR <> 0)
                                         BEGIN
                                                                 SET @resultValue=1
                                                                 return @resultValue
                                                           END

                             -- Rimozione trasmissione da todolist solo se Ã¨ stata giÃ  accettata o rifiutata
                                     UPDATE     dpa_trasm_utente
                                     SET        cha_in_todolist = '0'
                                     WHERE      id_trasm_singola = @sysTrasmSingola 
                                            AND NOT  dpa_trasm_utente.dta_vista IS NULL
                                            AND (cha_accettata = '1' OR cha_rifiutata = '1');

                             IF (@@ERROR <> 0)
                                   BEGIN
                                         SET @resultValue=1
                                         return @resultValue
                                   END

                                     UPDATE dpa_todolist
                                        SET dta_vista = GETDATE()
                                      WHERE id_trasm_singola = @sysTrasmSingola
                                        AND id_people_dest = @idPeople
                                        AND id_profile = @idoggetto;

                             IF (@@ERROR <> 0)
                             BEGIN
                                   SET @resultValue=1
                                   return @resultValue
                             END

                             IF (@chaTipoTrasm = 'S' AND @chaTipoDest= 'R')
                             begin
                                   UPDATE DPA_TRASM_UTENTE SET
                                   DPA_TRASM_UTENTE.CHA_VALIDA= '0',
                                   DPA_TRASM_UTENTE.CHA_IN_TODOLIST = '0'
                                   WHERE
                                   id_trasm_singola = @sysTrasmSingola
                                   AND DPA_TRASM_UTENTE.ID_PEOPLE != @idPeople

                                   IF (@@ERROR <> 0)
                                         BEGIN
                                         SET @resultValue=1
                                         return @resultValue
                                   END
                             end
                        END

                        FETCH NEXT FROM cursorTrasmSingolaDocumento
                        INTO @sysTrasmSingola, @chaTipoTrasm, @chaTipoRagione, @chaTipoDest
                  END
                  CLOSE cursorTrasmSingolaDocumento
                  DEALLOCATE cursorTrasmSingolaDocumento
            END
END      
RETURN @resultValue
END TRY
BEGIN CATCH
    -- Execute error retrieval routine.
    EXECUTE docsadm.usp_GetErrorInfo;
END CATCH;


