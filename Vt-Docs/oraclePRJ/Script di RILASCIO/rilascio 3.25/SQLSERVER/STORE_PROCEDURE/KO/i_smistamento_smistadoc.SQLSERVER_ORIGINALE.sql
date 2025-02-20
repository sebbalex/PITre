USE [GFD_SVIL]
GO
/****** Object:  StoredProcedure [DOCSADM].[I_SMISTAMENTO_SMISTADOC]    Script Date: 03/08/2013 11:22:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER  PROCEDURE [DOCSADM].[I_SMISTAMENTO_SMISTADOC]
@IDPeopleMittente int,
@IDCorrGlobaleRuoloMittente int,
@IDGruppoMittente int,
@IDAmministrazioneMittente int,
@IDPeopleDestinatario int,
@IDCorrGlobaleDestinatario int,
@IDDocumento int,
@IDTrasmissione int,
@IDTrasmissioneUtenteMittente int,
@TrasmissioneConWorkflow bit,
@NoteGeneraliDocumento varchar(250),
@NoteIndividuali varchar(250),
@DataScadenza datetime,
@TipoDiritto nchar(1),
@Rights int,
@OriginalRights int,
@IDRagioneTrasm int,
@idpeopledelegato int
AS

DECLARE @resultValue INT
DECLARE @resultValueOut int
DECLARE @ReturnValue int
DECLARE @Identity int
DECLARE @IdentityTrasm int
DECLARE @isAccettata nvarchar(1)
DECLARE @isAccettataDelegato nvarchar(1) 
DECLARE @isVista nvarchar(1) 
DECLARE @isVistaDelegato nvarchar(1) 

BEGIN

      set @isAccettata = '0'
      set @isAccettataDelegato = '0'
      set @isVista = '0'
      set @isVistaDelegato = '0'
      
      INSERT INTO DPA_TRASMISSIONE
      (
            ID_RUOLO_IN_UO,
            ID_PEOPLE,
            CHA_TIPO_OGGETTO,
            ID_PROFILE,
            ID_PROJECT,
            DTA_INVIO,
            VAR_NOTE_GENERALI 
      )
      VALUES
      (
            @IDCorrGlobaleRuoloMittente,
            @IDPeopleMittente,
            'D',
            @IDDocumento,
            NULL,
            GETDATE(),
            @NoteGeneraliDocumento
      )

      IF (@@ROWCOUNT = 0)
            BEGIN
                  SET @ReturnValue=-2 -- errore inserimento nella dpa_trasmissione
            END
      ELSE
            BEGIN
                  -- Inserimento in tabella DPA_TRASM_SINGOLA
                  SET @Identity=scope_identity()
                  set @IdentityTrasm = @Identity
                  
                  INSERT INTO DPA_TRASM_SINGOLA
                  (
                        ID_RAGIONE,
                        ID_TRASMISSIONE,
                        CHA_TIPO_DEST,
                        ID_CORR_GLOBALE,
                        VAR_NOTE_SING,
                        CHA_TIPO_TRASM,
                        DTA_SCADENZA,
                        ID_TRASM_UTENTE
                  )
                  VALUES
                  (
                        @IDRagioneTrasm,
                        @Identity,
                        'U',
                        @IDCorrGlobaleDestinatario,
                        @NoteIndividuali,
                        'S',
                        @DataScadenza,
                        NULL
                  )

                  IF (@@ROWCOUNT = 0)
                        BEGIN
                             SET @ReturnValue=-3  -- errore inserimento nella dpa_trasm_singola
                        END
                  ELSE
                        BEGIN
                             -- Inserimento in tabella DPA_TRASM_UTENTE
                             SET @Identity=scope_identity()

                             INSERT INTO DPA_TRASM_UTENTE
                             (
                                   ID_TRASM_SINGOLA,
                                   ID_PEOPLE,
                                   DTA_VISTA,
                                   DTA_ACCETTATA,
                                   DTA_RIFIUTATA,
                                   DTA_RISPOSTA,
                                   CHA_VISTA,
                                   CHA_ACCETTATA,
                                   CHA_RIFIUTATA,
                                   VAR_NOTE_ACC,
                                   VAR_NOTE_RIF,
                                   CHA_VALIDA,
                                   ID_TRASM_RISP_SING
                             )
                             VALUES
                             (
                                   @Identity,
                                   @IDPeopleDestinatario,
                                   NULL,
                                   NULL,
                                   NULL,
                                   NULL,
                                   '0',
                                   '0',
                                   '0',
                                   NULL,
                                   NULL,
                                   '1',
                                   NULL
                             )

                             IF (@@ROWCOUNT = 0)
                                   BEGIN
                                         SET @ReturnValue = - 4  -- errore inserimento nella dpa_trasm_utente
                                   END
                             ELSE
                                   BEGIN

                                         UPDATE DPA_TRASMISSIONE 
                                               SET DTA_INVIO = GETDATE() 
                                         WHERE SYSTEM_ID = @IdentityTrasm

                                         DECLARE @AccessRights int

                                         SET @AccessRights=
                                         (
                                               SELECT      MAX(ACCESSRIGHTS)
                                               FROM SECURITY
                                               WHERE       THING=@IDDocumento AND
                                               PERSONORGROUP=@IDPeopleDestinatario
                                         )

                                         IF (NOT @AccessRights IS NULL)
                                               BEGIN
                                                     IF (@AccessRights < @Rights)
                                                           UPDATE      SECURITY
                                                           SET   ACCESSRIGHTS=@Rights
                                                           WHERE       THING=@IDDocumento AND
                                                                 PERSONORGROUP=@IDPeopleDestinatario AND
                                                                 ACCESSRIGHTS=@AccessRights
                                               END
                                         ELSE        
                                               BEGIN
                                                     -- inserimento Rights
                                                     INSERT INTO SECURITY
                                                     (
                                                           THING,
                                                           PERSONORGROUP,
                                                           ACCESSRIGHTS,
                                                           ID_GRUPPO_TRASM,
                                                           CHA_TIPO_DIRITTO
                                                     )
                                                     VALUES
                                                     (
                                                           @IDDocumento,
                                                           @IDPeopleDestinatario,
                                                           @Rights,
                                                           @IDGruppoMittente,
                                                           @TipoDiritto
                                                     )
                                               END
                                         
                                         IF (@TrasmissioneConWorkflow='1')
                                               BEGIN
                                                     -- Verifica lo  stato di accettazione / visualizzazione della trasmissione utente
                                                     SET @isAccettata = 
                                                           (SELECT cha_accettata
                                                                 FROM dpa_trasm_utente 
                                                                 WHERE system_id = @idtrasmissioneutentemittente)
                                                       SET @isVista = 
                                                           (SELECT cha_vista
                                                                 FROM dpa_trasm_utente 
                                                                 WHERE system_id = @idtrasmissioneutentemittente)
                             
                                                     IF (@idPeopleDelegato > 0)
                                                           BEGIN
                                                                 -- Impostazione dei flag per la gestione del delegato
                                                                 SET @isVistaDelegato = '1'
                                                                     SET @isAccettataDelegato = '1'
                                                           END

                                                     IF (@isAccettata = '1')
                                                           BEGIN
                                                           -- caso in cui la trasmissione risulta gi accettata
                                                                 IF (@isVista = '0')
                                                                       BEGIN
                                                                                 -- l'oggetto trasmesso non risulta ancora visto,
                                                                                 -- pertanto vengono impostati i dati di visualizzazione
                                                                                 -- e viene rimossa la trasmissione dalla todolist
                                                                            UPDATE dpa_trasm_utente
                                                                            SET   dta_vista = (CASE WHEN dta_vista IS NULL THEN GETDATE() ELSE dta_vista END),
                                                                                  cha_vista = (case when dta_vista is null  then 1 else 0 end),
                                                                                               cha_vista_delegato = @isVistaDelegato,
                                                                                         cha_in_todolist = '0',
                                                                                               cha_valida = '0'
                                                                                      WHERE (   system_id = @idtrasmissioneutentemittente
                                                                                                OR system_id =
                                                                                                (SELECT tu.system_id
                                                                                                   FROM dpa_trasm_utente tu,
                                                                                                        dpa_trasmissione tx,
                                                                                                        dpa_trasm_singola ts
                                                                                                  WHERE tu.id_people = @idpeoplemittente
                                                                                                    AND tx.system_id = ts.id_trasmissione
                                                                                                    AND tx.system_id = @idtrasmissione
                                                                                                    AND ts.system_id = tu.id_trasm_singola
                                                                                                    AND ts.cha_tipo_dest = 'U')
                                                                                         )
                                                                       END
                                                                 ELSE
                                                                       BEGIN
                                                                            -- l'oggetto trasmesso visto,
                                                                                 -- pertanto la trasmissione viene solo rimossa dalla todolist

                                                                            UPDATE dpa_trasm_utente
                                                                                           SET cha_in_todolist = '0',
                                                                                               cha_valida = '0'
                                                                                       WHERE (   system_id = @idtrasmissioneutentemittente
                                                                                                OR system_id =
                                                                                                      (SELECT tu.system_id
                                                                                                         FROM dpa_trasm_utente tu,
                                                                                                              dpa_trasmissione tx,
                                                                                                              dpa_trasm_singola ts
                                                                                                        WHERE tu.id_people = @idpeoplemittente
                                                                                                          AND tx.system_id = ts.id_trasmissione
                                                                                                          AND tx.system_id = @idtrasmissione
                                                                                                          AND ts.system_id = tu.id_trasm_singola
                                                                                                          AND ts.cha_tipo_dest = 'U')
                                                                                               )
                             
                                                                       END
                                                           END
                                                     ELSE
                                                           BEGIN

                                                                     -- la trasmissione ancora non risulta accettata, pertanto:
                                                                     -- 1) viene accettata implicitamente, 
                                                                     -- 2) l'oggetto trasmesso impostato come visto,
                                                                     -- 3) la trasmissione rimossa la trasmissione da todolist
                                                                 UPDATE dpa_trasm_utente
                                                                         SET dta_vista = (CASE WHEN dta_vista IS NULL THEN GETDATE() ELSE dta_vista END),
                                                                       cha_vista = (case when dta_vista is null  then 1 else 0 end),
                                                                               cha_vista_delegato = @isVistaDelegato,
                                                                             dta_accettata = GETDATE(),
                                                                             cha_accettata = '1',
                                                                             cha_accettata_delegato = @isAccettataDelegato,
                                                                             var_note_acc = 'Documento accettato e smistato',                        
                                                                             cha_in_todolist = '0',
                                                                             cha_valida = '0'
                                                                       WHERE (   system_id = @idtrasmissioneutentemittente
                                                                              OR system_id =
                                                                                    (SELECT tu.system_id
                                                                                       FROM dpa_trasm_utente tu,
                                                                                            dpa_trasmissione tx,
                                                                                            dpa_trasm_singola ts
                                                                                      WHERE tu.id_people = @idpeoplemittente
                                                                                        AND tx.system_id = ts.id_trasmissione
                                                                                        AND tx.system_id = @idtrasmissione
                                                                                        AND ts.system_id = tu.id_trasm_singola
                                                                                        AND ts.cha_tipo_dest = 'U')
                                                                             ) 
                                                                             AND cha_valida = '1'
                                                           END

                                                     -- update security se diritti  trasmssione in accettazione =20
                                                       UPDATE security
                                                       SET     accessrights = @originalrights,
                                                               cha_tipo_diritto = 'T'
                                                       WHERE thing=@IDDocumento and   personorgroup IN (@idpeoplemittente, @idgruppomittente)
                                                               AND accessrights = 20

                                               END
                                         ELSE
                                               
                                               BEGIN
                                               
                                                     EXEC DOCSADM.SPsetDataVistaSmistamento @IDPeopleMittente, @IDDocumento, @IDGruppoMittente, 'D', @idTrasmissione, @idPeopleDelegato,  @resultValue out
                                                     
                                                     SET @resultValueOut= @resultValue
                                                     
                                                     IF(@resultValueOut=1)
                                                           BEGIN
                                                                 SET @ReturnValue = -4;
                                                                 RETURN
                                                           END
                                               END

                                         -- se la trasmissione era destinata a SINGOLO, 
                                         -- allora toglie la validit della trasmissione 
                                         -- a tutti gli altri utenti del ruolo (tranne a quella del mittente)
                                         IF ((SELECT top 1 A.CHA_TIPO_TRASM
                                               FROM DPA_TRASM_SINGOLA A, DPA_TRASM_UTENTE B
                                               WHERE A.SYSTEM_ID=B.ID_TRASM_SINGOLA
                                               AND B.SYSTEM_ID IN (SELECT TU.SYSTEM_ID FROM
                                               DPA_TRASM_UTENTE TU,DPA_TRASMISSIONE TX,DPA_TRASM_SINGOLA TS WHERE TU.ID_PEOPLE= @IDPeopleMittente AND
                                               TX.SYSTEM_ID=TS.ID_TRASMISSIONE AND TX.SYSTEM_ID=@IDTrasmissione AND TS.SYSTEM_ID=TU.ID_TRASM_SINGOLA
                                               and TS.SYSTEM_ID = (SELECT ID_TRASM_SINGOLA FROM DPA_TRASM_UTENTE WHERE SYSTEM_ID =@IDTrasmissioneUtenteMittente))
                                               ORDER BY CHA_TIPO_DEST
                                               )='S' AND @TrasmissioneConWorkflow='1')
                                                     -- se la trasmissione era destinata a SINGOLO, allora toglie la validit della trasmissione a tutti gli altri utenti del ruolo (tranne a quella del mittente)
                                                     UPDATE      DPA_TRASM_UTENTE
                                                     SET   CHA_VALIDA = '0', cha_in_todolist = '0'
                                                     WHERE       ID_TRASM_SINGOLA IN
                                                           (SELECT A.SYSTEM_ID
                                                           FROM DPA_TRASM_SINGOLA A, DPA_TRASM_UTENTE B
                                                           WHERE A.SYSTEM_ID=B.ID_TRASM_SINGOLA
                                                           AND B.SYSTEM_ID IN (SELECT TU.SYSTEM_ID FROM
                                                           DPA_TRASM_UTENTE TU,DPA_TRASMISSIONE TX,DPA_TRASM_SINGOLA TS WHERE TU.ID_PEOPLE=@IDPeopleMittente AND
                                                           TX.SYSTEM_ID=TS.ID_TRASMISSIONE AND TX.SYSTEM_ID=@IDTrasmissione AND TS.SYSTEM_ID=TU.ID_TRASM_SINGOLA
                                                           and TS.SYSTEM_ID = (SELECT ID_TRASM_SINGOLA FROM DPA_TRASM_UTENTE WHERE SYSTEM_ID =@IDTrasmissioneUtenteMittente)))
                                                           AND SYSTEM_ID NOT IN(@IDTrasmissioneUtenteMittente)

                                         SET @ReturnValue=0
                                   END
                             END
                        END
            END

RETURN @ReturnValue

