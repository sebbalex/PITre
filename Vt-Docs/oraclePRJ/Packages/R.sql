--------------------------------------------------------
--  DDL for Package R
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE "ITCOLL_6GIU12"."R" AS

  TYPE T_CURSOR IS REF CURSOR; 
  
    -- Procedure per la gestione degli utenti
  PROCEDURE GetUserCredentials(pNomeUtente NVARCHAR2, pPassword NVARCHAR2, cur_OUT OUT T_CURSOR);
  
  PROCEDURE GetUsers(cur_OUT OUT T_CURSOR, pFiltro NVARCHAR2, pOrdinamento NVARCHAR2, pPagina INT, pOggettiPagina INT, pTotaleOggetti OUT INT);
  
  PROCEDURE GetUser(pId INTEGER, cur_OUT OUT T_CURSOR);

  PROCEDURE DeleteUser(pId INTEGER, pDataUltimaModifica DATE);
  
  PROCEDURE InsertUser(pNomeUtente NVARCHAR2, pPassword NVARCHAR2, pAmministratore CHAR, pDataCreazione DATE, pDataUltimaModifica DATE, pId OUT INTEGER);
  
  PROCEDURE UpdateUser(pId INTEGER, pAmministratore CHAR,pDataUltimaModifica DATE, pOldDataUltimaModifica DATE);
    
  PROCEDURE ChangeUserPassword(pNomeUtente NVARCHAR2, pPassword NVARCHAR2, pNewPassword NVARCHAR2);
 
  PROCEDURE ContainsUser(pNomeUtente NVARCHAR2, pRet OUT INTEGER);

 -- Procedure per la gestione degli elementi rubrica
  PROCEDURE GetElementiRubrica(cur_OUT OUT T_CURSOR, pFiltro NVARCHAR2, pOrdinamento NVARCHAR2, pPagina INT, pOggettiPagina INT, pTotaleOggetti OUT INT);

  PROCEDURE InsertElementoRubrica(pCodice NVARCHAR2, pDescrizione NVARCHAR2, 
                                    pIndirizzo NVARCHAR2, pCitta NVARCHAR2, pCap NVARCHAR2, 
                                    pProvincia NVARCHAR2, pNazione NVARCHAR2, 
                                  pTelefono NVARCHAR2, pFax NVARCHAR2, 
                                  pAOO NVARCHAR2,
                                  pDataCreazione DATE, pDataUltimaModifica DATE, 
                                  pUtenteCreatore NVARCHAR2, 
                                  pTipoCorrispondente NVarChar2, 
                                  pAmministrazione Nvarchar2,
                                  pUrl Nvarchar2,
                                  pChaPubblica Nvarchar2,
                                  pId OUT INTEGER);

 PROCEDURE UpdateElementoRubrica(pId INTEGER, pDescrizione NVARCHAR2, 
                                    pIndirizzo NVARCHAR2, 
                                     pCitta NVARCHAR2, pCap NVARCHAR2, pProvincia NVARCHAR2,
                                    pNazione NVARCHAR2, pTelefono NVARCHAR2, pFax NVARCHAR2, 
                                  pAOO NVARCHAR2,
                                  pDataUltimaModifica DATE, pOldDataUltimaModifica DATE, 
                                  pTipoCorrispondente NVARCHAR2, pAmministrazione Nvarchar2,
                                  pUrl Nvarchar2,
                                  pChaPubblica Nvarchar2);
  
  PROCEDURE DeleteElementoRubrica(pId INTEGER, pDataUltimaModifica DATE); 
   
  PROCEDURE GetElementoRubrica(cur_OUT OUT T_CURSOR, pId IN INTEGER);
  
  PROCEDURE ContainsElementoRubrica(pCodice NVARCHAR2, pRet OUT INTEGER);
  
  PROCEDURE InsertAmministrazione(pCodice NVARCHAR2, pUrl nvarchar2, pId OUT INTEGER);
  
  PROCEDURE UpdateAmministrazione(pCodice NVARCHAR2, pUrl nvarchar2, pIdAmministrazione INTEGER);
  
  PROCEDURE InsertEmail(pId Number, pEmail nvarchar2, pNote nvarchar2, pPreferita Number);
  
  PROCEDURE RemoveEmails(pId Number);
  
  PROCEDURE GetEmails(cur_OUT OUT T_CURSOR, pId IN INTEGER);

END R;

/

--------------------------------------------------------
--  DDL for Package Body R
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY "ITCOLL_6GIU12"."R" AS

  
 PROCEDURE GetUserCredentials(pNomeUtente NVARCHAR2, pPassword NVARCHAR2, cur_OUT OUT T_CURSOR)
  IS
  BEGIN
        OPEN cur_OUT FOR
           SELECT Id, Nome, Amministratore, DataCreazione, DataUltimaModifica 
           FROM      Utenti
           WHERE  UPPER(Nome) = UPPER(pNomeUtente) AND Password = pPassword;       
  
  END GetUserCredentials;
  
  PROCEDURE GetUsers(cur_OUT OUT T_CURSOR, pFiltro NVARCHAR2, pOrdinamento NVARCHAR2, pPagina INT, pOggettiPagina INT, pTotaleOggetti OUT INT)
  IS
         sqlInnerText VARCHAR2(2000) := NULL;
         selectStatement NVARCHAR2(2000) := NULL;
         fromClausole NVARCHAR2(2000) := NULL;
         whereClausole NVARCHAR2(2000) := NULL;
         orderByStatement NVARCHAR2(2000) := 'Nome ASC';
         startRow INT := 0;
         endRow INT := 0;
  
  BEGIN
        IF (pPagina != 0 AND pOggettiPagina != 0) THEN
            startRow := ((pPagina * pOggettiPagina) - pOggettiPagina) + 1;
            endRow := (startRow - 1) + pOggettiPagina;
        END IF;
        
        selectStatement := 'ROWNUM RN, ' ||
                            'Id, ' ||
                            'Nome, ' ||
                            'Amministratore, ' ||
                            'DataCreazione, ' ||
                            'DataUltimaModifica';

        fromClausole := 'Utenti';
             
        whereClausole := 'UPPER(Nome) != UPPER(''SA'')';                        

        if (pFiltro is not null) then
            whereClausole := ' AND ' || pFiltro;
        end if;
        
        if (pOrdinamento is not null) then
            orderByStatement := pOrdinamento;
        end if;
                
        sqlInnerText :=  'SELECT ' || selectStatement ||
                         ' FROM ' || fromClausole ||
                         ' WHERE ' || whereClausole ||
                         ' ORDER BY ' || orderByStatement;
        
        IF (pPagina != 0 AND pOggettiPagina != 0) THEN
            EXECUTE IMMEDIATE  'SELECT COUNT(*) FROM (' || sqlInnerText || ')' INTO pTotaleOggetti;
        
            OPEN cur_OUT FOR 'SELECT * FROM (' || sqlInnerText || ') ER WHERE ER.RN >= ' || startRow || ' AND ER.RN <= ' || endRow;
        ELSE
            OPEN cur_OUT FOR sqlInnerText;
        END IF;        

  END GetUsers;
  
  PROCEDURE GetUser(pId INTEGER, cur_OUT OUT T_CURSOR)
    IS
  BEGIN
       OPEN cur_OUT FOR
       SELECT Id, Nome, Amministratore, DataCreazione, DataUltimaModifica 
       FROM      Utenti
       WHERE Id = pId AND
                    UPPER(Nome) != UPPER('SA');
       
  END GetUser;
  
  PROCEDURE DeleteUser(pId INTEGER, pDataUltimaModifica DATE)
  IS
  BEGIN
         DELETE FROM Utenti WHERE Id = pId AND UPPER(Nome) != UPPER('SA') AND DataUltimaModifica = pDataUltimaModifica;
  
  END DeleteUser;
  
  PROCEDURE InsertUser(pNomeUtente NVARCHAR2, pPassword NVARCHAR2, pAmministratore CHAR, pDataCreazione DATE, pDataUltimaModifica DATE, pId OUT INTEGER)
  IS
  BEGIN
      SELECT SEQ_UT.NEXTVAL INTO pId FROM dual;

    INSERT INTO Utenti
    (
     Id,
     Nome,
     Password,
     Amministratore,
     DataCreazione,
     DataUltimaModifica
    )
    VALUES
    (
     pId,
     pNomeUtente,
     pPassword,
     pAmministratore,
     pDataCreazione,
     pDataUltimaModifica
    );
  
  END InsertUser;
  
  PROCEDURE UpdateUser(pId INTEGER, pAmministratore CHAR, pDataUltimaModifica DATE, pOldDataUltimaModifica DATE)
  IS
  BEGIN
         UPDATE Utenti
       SET      Amministratore = pAmministratore,
                DataUltimaModifica = pDataUltimaModifica
       WHERE  Id = pId AND UPPER(Nome) != UPPER('SA') AND DataUltimaModifica = pOldDataUltimaModifica;
  
  END UpdateUser;
  
  PROCEDURE ChangeUserPassword(pNomeUtente NVARCHAR2, pPassword NVARCHAR2, pNewPassword NVARCHAR2)
  IS
  BEGIN
         UPDATE Utenti 
       SET       Password = pNewPassword
       WHERE  Nome = pNomeUtente AND Password = pPassword; 
       
  END ChangeUserPassword;

    PROCEDURE ContainsUser(pNomeUtente NVARCHAR2, pRet OUT INTEGER)
    IS
    BEGIN
        SELECT COUNT(Id) INTO pRet
        FROM Utenti
        WHERE UPPER(Nome) = UPPER(pNomeUtente);
        
    END ContainsUser;

  PROCEDURE GetElementiRubrica(cur_OUT OUT T_CURSOR, pFiltro NVARCHAR2, pOrdinamento NVARCHAR2, pPagina INT, pOggettiPagina INT, pTotaleOggetti OUT INT)
  IS 
         sqlInnerText VARCHAR2(2000) := NULL;
		 selectStatement NVARCHAR2(2000) := NULL;
		 fromClausole NVARCHAR2(2000) := NULL;
         whereClausole NVARCHAR2(2000) := NULL;
         orderByStatement NVARCHAR2(2000) := 'Codice ASC';
         startRow INT := 0;
         endRow INT := 0;
         
    BEGIN
        IF (pPagina != 0 AND pOggettiPagina != 0) THEN
            startRow := ((pPagina * pOggettiPagina) - pOggettiPagina) + 1;
            endRow := (startRow - 1) + pOggettiPagina;
        END IF;
  
        selectStatement := 'ER.Id, ' ||
                           'ER.Codice, ' ||
                           'ER.Descrizione, ' ||
                           'ER.Indirizzo, ' ||
                           'ER.Citta, ' ||
                           'ER.Cap, ' ||
                           'ER.Provincia, ' ||
                           'ER.Nazione, ' ||        
                           'ER.Telefono, ' ||
                           'ER.Fax, ' ||
                           'ER.AOO, ' ||
                           'ER.DataCreazione, ' ||
                           'ER.DataUltimaModifica, ' ||
                           'U.Nome AS UtenteCreatore,' ||
                           'ER.TipoCorrispondente,' ||
                           'Amm.Amministrazione,' ||
                           'AMM.Url,' ||
                           'ER.CHA_PUBBLICATO'; 
        
        fromClausole := 'ElementiRubrica ER LEFT JOIN EMAILS E ON ER.ID = E.IDELEMENTORUBRICA 
        INNER JOIN Utenti U ON ER.IdUtenteCreatore = U.Id 
        LEFT OUTER JOIN Amministrazioni AMM ON ER.IdAmministrazione = AMM.Id';
        
        if (pFiltro is not null) then
            whereClausole := ' WHERE ' || pFiltro;
        end if;

        if (pOrdinamento is not null) then
            orderByStatement := pOrdinamento;
        end if;
                          
        sqlInnerText := 'SELECT distinct ' || selectStatement ||
                        ' FROM ' || fromClausole ||
                                whereClausole ||
                        ' ORDER BY ' || orderByStatement;
                    
        
        IF (pPagina != 0 AND pOggettiPagina != 0) THEN
            EXECUTE IMMEDIATE  'SELECT COUNT(*) FROM (' || sqlInnerText || ')' INTO pTotaleOggetti;

            OPEN cur_OUT FOR 'SELECT * FROM (SELECT ROWNUM RN, ER1.* FROM (' || sqlInnerText || ') ER1) ER2 WHERE ER2.RN BETWEEN ' || startRow || ' AND ' || endRow;
        ELSE
            OPEN cur_OUT FOR sqlInnerText;
        END IF;
        
    END GetElementiRubrica;
  
  PROCEDURE InsertElementoRubrica(pCodice NVARCHAR2, pDescrizione NVARCHAR2, 
                                    pIndirizzo NVARCHAR2, pCitta NVARCHAR2, pCap NVARCHAR2, 
                                    pProvincia NVARCHAR2, pNazione NVARCHAR2, 
                                  pTelefono NVARCHAR2, pFax NVARCHAR2, 
                                  pAOO NVARCHAR2,
                                  pDataCreazione DATE, pDataUltimaModifica DATE, 
                                  pUtenteCreatore NVARCHAR2, 
                                  pTipoCorrispondente NVarChar2, 
                                  pAmministrazione Nvarchar2,
                                  pUrl Nvarchar2,
                                  pChaPubblica Nvarchar2,
                                  pId OUT INTEGER)
    IS
      ammId Number := 0;
    BEGIN
    
    -- Inserimento dell'amministrazione (o recupero di quella gia presente)
    If pAmministrazione is not null
      Then
        InsertAmministrazione(pAmministrazione, pUrl, ammId);
    End If; 
    -- Inserimento corrispondente
    SELECT SEQ_ER.NEXTVAL INTO pId FROM dual;

    INSERT INTO ElementiRubrica
    (
      Id,
      Codice,
      Descrizione,
      Indirizzo,
      Citta,
      Cap,
      Provincia,
      Nazione,
      Telefono,
      Fax,
      AOO,
      DataCreazione,
      DataUltimaModifica,
      IdUtenteCreatore,
      IdAmministrazione,
      TipoCorrispondente,
      cha_pubblicato
    )
    VALUES
    (
      pId,
      pCodice,
      pDescrizione,
      pIndirizzo,
      pCitta,
      pCap,
      pProvincia,
      pNazione,
      pTelefono,
      pFax,
      pAOO,
      pDataCreazione,
      pDataUltimaModifica,
      (SELECT Id FROM Utenti WHERE UPPER(Nome) = UPPER(pUtenteCreatore)),
      ammId,
      pTipoCorrispondente,
      pChaPubblica
    );        
                                
    END InsertElementoRubrica;

  PROCEDURE UpdateElementoRubrica(pId INTEGER, pDescrizione NVARCHAR2, 
                                    pIndirizzo NVARCHAR2, 
                                     pCitta NVARCHAR2, pCap NVARCHAR2, pProvincia NVARCHAR2,
                                    pNazione NVARCHAR2, pTelefono NVARCHAR2, pFax NVARCHAR2, 
                                  pAOO NVARCHAR2,
                                  pDataUltimaModifica DATE, pOldDataUltimaModifica DATE, 
                                  pTipoCorrispondente NVARCHAR2, pAmministrazione Nvarchar2,
                                  pUrl Nvarchar2,
                                  pChaPubblica Nvarchar2)
    IS 
      ammId Number := 0;
       BEGIN
       
       -- Selezione dell'id dell'amministrazione per lo specifico corrispondente
       Select IdAmministrazione Into ammId From ElementiRubrica Where Id = pId;
       
       -- Se l'id amministrazione e nullo, ne viene aggiunta una
       --If(ammId is null Or ammId = 0) 
        --Then
          --InsertAmministrazione(pAmministrazione, pUrl, ammId);
       --Else
         -- Aggiornamento dell'amministrazione
         --UpdateAmministrazione(pAmministrazione, pUrl, ammId);
        --End If;   
       If pAmministrazione is not null Then
          InsertAmministrazione(pAmministrazione, pUrl, ammId);
       End If;   
          
      
       UPDATE ElementiRubrica
       SET    Descrizione = pDescrizione,
              Indirizzo = pIndirizzo,
              Citta = pCitta,
              Cap = pCap,
              Provincia = pProvincia,
              Nazione = pNazione,
              Telefono = pTelefono,
              Fax = pFax,
              IdAmministrazione = ammId,
              AOO = pAOO,
              DataUltimaModifica = pDataUltimaModifica,
              TipoCorrispondente = pTipoCorrispondente,
              cha_pubblicato = pChaPubblica
       WHERE  Id = pId AND DataUltimaModifica = pOldDataUltimaModifica;
                                                        
       END UpdateElementoRubrica;
  
  PROCEDURE DeleteElementoRubrica(pId INTEGER, pDataUltimaModifica DATE)
    IS
    
      BEGIN
           -- Rimozione record elemento rubrica
             DELETE FROM ElementiRubrica WHERE Id = pId AND DataUltimaModifica = pDataUltimaModifica;

      END DeleteElementoRubrica;
  
   
  PROCEDURE GetElementoRubrica(cur_OUT OUT T_CURSOR, pId IN INTEGER)
  IS 

    BEGIN 
        OPEN cur_OUT FOR 
        SELECT ER.Id,
               ER.Codice,
               ER.Descrizione,
               ER.Indirizzo,
               ER.Citta,
               ER.Cap,
               ER.Provincia,
               ER.Nazione,
               ER.Telefono,
               ER.Fax,
               ER.AOO,
               ER.DataCreazione,
               ER.DataUltimaModifica,
               U.Nome AS UtenteCreatore,
               ER.TipoCorrispondente,
               Amm.Amministrazione,
               Amm.Url,
               ER.CHA_PUBBLICATO
             FROM ElementiRubrica ER              
                  INNER JOIN Utenti U ON ER.IdUtenteCreatore = U.Id
                  LEFT OUTER JOIN Amministrazioni Amm ON ER.IdAmministrazione = Amm.Id
             WHERE ER.Id = pId;
             
    END GetElementoRubrica;
    
    PROCEDURE ContainsElementoRubrica(pCodice NVARCHAR2, pRet OUT INTEGER)
    IS
    BEGIN
        SELECT COUNT(Id) INTO pRet
        FROM ElementiRubrica 
        WHERE UPPER(Codice) = UPPER(pCodice);
    
    END ContainsElementoRubrica;
    
    -- Inserimento nuovo elemento nell'anagrafica delle amministrazioni
    -- Restituisce l'id della nuova amministrazione
    PROCEDURE InsertAmministrazione(pCodice NVARCHAR2, pUrl nvarchar2, pId OUT INTEGER)
    IS
      numAmm Number := 0;
    BEGIN
        -- Se c'e gia un'amministrazione con il codice pCodice, viene selezionato
        -- e restituito l'id di tale amministrazione altrimenti viene inserita
        -- una nuova amministrazione
        Select count(*) Into numAmm From amministrazioni Where Amministrazione = pCodice;
        If numAmm = 0 Then
          Begin
            Select SEQ_AMMINISRAZIONI.nextval Into pId From dual;
            
            INSERT INTO Amministrazioni
            (ID, 
            Amministrazione, 
            URL
            ) VALUES
            (pId,
            pCodice,
            pUrl);
            
          End;
        Else
          Begin
            Select Id into pId From Amministrazioni Where Amministrazione = pCodice;
            Update Amministrazioni
            Set Amministrazione = pCodice,
                Url = pUrl
            Where Id = pId;
          End;
        End If;  

    END InsertAmministrazione;
  
    -- Aggiornamento elemento nell'anagrafica delle amministrazioni
    PROCEDURE UpdateAmministrazione(pCodice NVARCHAR2, pUrl nvarchar2, pIdAmministrazione INTEGER)
    IS
    BEGIN
        Update Amministrazioni
        Set Amministrazione = pCodice,
            Url = pUrl
        Where Id = pIdAmministrazione;
    END UpdateAmministrazione;
    
    -- Inserimento di una nuova mail
    PROCEDURE InsertEmail(pId Number, pEmail nvarchar2, pNote nvarchar2, pPreferita Number)
    IS
    BEGIN
        Insert Into Emails(IdElementoRubrica, Email, Note, Preferita)
        Values (pId, pEmail, pNote, pPreferita);
    END InsertEmail;
    
    -- Rimozione di tutte le mail associate ad un corrispondente
    PROCEDURE RemoveEmails(pId Number)
    IS
    BEGIN
        Delete From Emails
        Where IdElementoRubrica = pId;
    END RemoveEmails;
    
    -- Reperimento emails associate al corrispondente
    PROCEDURE GetEmails(cur_OUT OUT T_CURSOR, pId IN INTEGER)
    IS 
  
      BEGIN 
          OPEN cur_OUT FOR 
          SELECT  e.EMail,
                  e.Note,
                  e.Preferita
          FROM Emails e
          WHERE e.IdElementoRubrica = pId;
               
      END GetEmails;
    
END R;

/
