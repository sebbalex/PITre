ALTER TABLE DPA_SCHEMA_PROCESSO_FIRMA
ADD (CHA_MODELLO CHAR(1) DEFAULT '0' );

ALTER TABLE DPA_SCHEMA_PROCESSO_FIRMA
ADD (ID_AMM NUMBER);

ALTER TABLE DPA_ISTANZA_PROCESSO_FIRMA
ADD (ID_PEOPLE_INTERRUZIONE NUMBER);

ALTER TABLE DPA_ISTANZA_PROCESSO_FIRMA
ADD (ID_PEOPLE_DELEGATO_INTER NUMBER);

ALTER TABLE DOCUMENTTYPES
ADD (LABEL VARCHAR(200) DEFAULT NULL);

UPDATE DOCUMENTTYPES SET LABEL= 'PITRE' where type_id = 'SIMPLIFIEDINTEROPERABILITY';

UPDATE DPA_SCHEMA_PROCESSO_FIRMA SET ID_AMM  = GETIDAMM(UTENTE_AUTORE)
WHERE ID_AMM IS NULL;
/
COMMIT;