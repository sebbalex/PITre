CREATE TABLE DPA_LIBRO_FIRMA 
(
  ID_AREA NUMBER NOT NULL 
, RUOLO_TITOLARE NUMBER NOT NULL 
, UTENTE_TITOLARE NUMBER NOT NULL 
, PREFERENZE_CN VARCHAR2(50) 
, CONSTRAINT DPA_LIBRO_FIRMA_PK PRIMARY KEY 
  (
    ID_AREA 
  )
  ENABLE 
);

CREATE TABLE DPA_FIRMA_ELETTRONICA 
(
  ID_FIRMA NUMBER NOT NULL 
, ID_DOCUMENTO NUMBER NOT NULL 
, VERSION_ID NUMBER NOT NULL 
, DOC_ALL VARCHAR2(20) NOT NULL 
, NUM_ALL NUMBER 
, NUMERO_VERSIONE NUMBER NOT NULL 
, XML VARCHAR2(2000 CHAR) DEFAULT '<xml version="1.0" encoding="UTF-8"><FirmaElettronica><Documento id=""><Imponta></Imponta></Documento><Firmatario delega=""><Ruolo id=""></Ruolo><Utente id=""></Utente></Firmatario><DataCreazione></DataCreazione></FirmaElettronica></xml>'
, DATA_APPOSIZIONE DATE
, CONSTRAINT DPA_FIRMA_ELETTRONICA_PK PRIMARY KEY 
  (
    ID_FIRMA 
  )
  ENABLE 
);

CREATE TABLE DPA_ELEMENTO_IN_LIBRO_FIRMA 
(
  ID_ELEMENTO NUMBER NOT NULL 
, ID_RUOLO_TITOLARE NUMBER NOT NULL
, ID_UTENTE_TITOLARE NUMBER
, TIPO_FIRMA VARCHAR2(50) NOT NULL 
, STATO_FIRMA VARCHAR2(20) NOT NULL 
, NOTE VARCHAR2(256) 
, SCADENZA DATE 
, RUOLO_PROPONENTE VARCHAR2(255) 
, UTENTE_PROPONENTE VARCHAR2(255) 
, MODALITA VARCHAR2(20) NOT NULL 
, DATA_INSERIMENTO DATE NOT NULL 
, DOC_NUMBER NUMBER NOT NULL
, ID_DOC_PRINCIPALE NUMBER
, VERSION_ID NUMBER NOT NULL 
, NUM_ALL NUMBER 
, NUM_VERSIONE NUMBER NOT NULL
, ID_UTENTE_LOCKER NUMBER
, ISTANZA_PROCESSO NUMBER
, ID_ISTANZA_PASSO NUMBER
, ID_TRASM_SINGOLA NUMBER
, DTA_ACCETTAZIONE  DATE
, DTA_ESECUZIONE DATE
, CONSTRAINT DPA_ELEMENTO_IN_LIBRO_FIR_PK PRIMARY KEY 
  (
    ID_ELEMENTO 
  , ID_RUOLO_TITOLARE 
  )
  ENABLE 
);

CREATE TABLE DPA_SCHEMA_PROCESSO_FIRMA 
(
  ID_PROCESSO NUMBER NOT NULL 
, NOME VARCHAR2(256) NOT NULL 
, RUOLO_AUTORE NUMBER 
, UTENTE_AUTORE NUMBER 
, ELIMINATO NUMBER 
, CONSTRAINT DPA_SCHEMA_PROCESSO_FIRMA_PK PRIMARY KEY 
  (
    ID_PROCESSO 
  )
  ENABLE 
);

CREATE TABLE DPA_PASSO_DI_FIRMA 
(
  ID_PASSO NUMBER NOT NULL 
, ID_PROCESSO NUMBER NOT NULL 
, NUMERO_SEQUENZA NUMBER NOT NULL 
, TIPO_FIRMA VARCHAR2(50) 
, TIPO_EVENTO NUMBER NOT NULL 
, NOTE VARCHAR2(256) 
, ID_RUOLO_COINVOLTO NUMBER
, ID_UTENTE_COINVOLTO NUMBER 
, SCADENZA DATE 
, ELIMINATO NUMBER 
, CONSTRAINT DPA_PASSO_DI_FIRMA_PK PRIMARY KEY 
  (
    ID_PASSO 
  )
  ENABLE 
);

CREATE TABLE DPA_AUTORIZZ_RUOLI_PROCESSI 
(
  ID_PROCESSO NUMBER NOT NULL 
, ID_RUOLO NUMBER NOT NULL 
);

CREATE TABLE DPA_ISTANZA_PROCESSO_FIRMA 
(
  ID_ISTANZA NUMBER NOT NULL 
, ID_PROCESSO NUMBER NOT NULL 
, STATO VARCHAR2(50) 
, ATTIVATO_IL DATE 
, CONCLUSO_IL DATE 
, ID_RUOLO_PROPONENTE NUMBER NOT NULL 
, ID_UTENTE_PROPONENTE NUMBER NOT NULL 
, ID_DOCUMENTO NUMBER NOT NULL 
, VERSION_ID NUMBER NOT NULL 
, DOC_ALL VARCHAR2(20) NOT NULL 
, NUM_ALL NUMBER 
, NUM_VERSIONE NUMBER NOT NULL 
, MOTIVO_RESPINGIMENTO VARCHAR2(1000)
, NOTIFICA_INTERROTTO	CHAR(1)
, NOTIFICA_CONCLUSO	CHAR(1)
, DESCRIZIONE	VARCHAR2(256)
, NOTE	VARCHAR2(2000)
, CONSTRAINT DPA_ISTANZA_PROCESSO_FIRM_PK PRIMARY KEY 
  (
    ID_ISTANZA 
  )
  ENABLE 
);

CREATE TABLE DPA_ISTANZA_PASSO_FIRMA 
(
  ID_ISTANZA_PASSO NUMBER NOT NULL 
, ID_ISTANZA_PROCESSO NUMBER NOT NULL 
, ID_PASSO NUMBER NOT NULL 
, STATO_PASSO VARCHAR2(50) NOT NULL 
, ESEGUITO_IL DATE 
, MOTIVO_RESPINGIMENTO VARCHAR2(256)
, ID_RUOLO_COINVOLTO NUMBER
, ID_UTENTE_COINVOLTO NUMBER
, ID_UTENTE_LOCKER NUMBER
, DESC_UTENTE_LOCKER VARCHAR2(500)
, TIPO_FIRMA VARCHAR2(50) NOT NULL
, SCADENZA DATE
, TIPO_EVENTO NUMBER NOT NULL
, NUMERO_SEQUENZA NUMBER DEFAULT 1 NOT NULL
, ID_NOTIFICA_EFFETTUATA NUMBER
, NOTE VARCHAR2(1000)
, CONSTRAINT DPA_ISTANZA_PASSO_FIRMA_PK PRIMARY KEY 
  (
    ID_ISTANZA_PASSO 
  )
  ENABLE 
);

CREATE TABLE DPA_PASSO_DPA_EVENTO 
(
  ID_PASSO NUMBER
, ID_EVENTO NUMBER NOT NULL 
, ID_ISTANZA_PASSO  NUMBER
);

CREATE TABLE DPA_ANAGRAFICA_EVENTI
(
  ID_EVENTO NUMBER NOT NULL 
, VAR_COD_AZIONE VARCHAR2(256) NOT NULL 
, DESCRIZIONE VARCHAR2(256)
, CHA_TIPO_EVENTO CHAR(1) 
, GRUPPO VARCHAR2(256) NOT NULL 
, CONSTRAINT DPA_EVENTI_PK PRIMARY KEY 
  (
    ID_EVENTO 
  )
  ENABLE 
);

CREATE TABLE DPA_PROCESSO_FIRMA_VISIBILITA
      (
        ID_PROCESSO NUMBER NOT NULL,
        ID_GROUPS NUMBER NOT NULL
      );

CREATE TABLE DPA_ISTANZA_PASSO_FIRMA
   (	
	ID_ISTANZA_PASSO NUMBER NOT NULL
	,ID_ISTANZA_PROCESSO NUMBER NOT NULL
	,ID_PASSO NUMBER NOT NULL
	,STATO_PASSO VARCHAR2(50) DEFAULT NULL NOT NULL
	,ESEGUITO_IL DATE
	,MOTIVO_RESPINGIMENTO VARCHAR2(256)
	,ID_RUOLO_COINVOLTO NUMBER
	,ID_UTENTE_COINVOLTO NUMBER
	,TIPO_FIRMA VARCHAR2(50) NOT NULL
	,SCADENZA DATE
	,TIPO_EVENTO NUMBER NOT NULL
	,NUMERO_SEQUENZA NUMBER DEFAULT 1 NOT NULL
	,ID_NOTIFICA_EFFETTUATA NUMBER
	,NOTE VARCHAR2(1000)
	,CONSTRAINT DPA_ISTANZA_PASSO_FIRMA_PK PRIMARY KEY 
	(
		ID_ISTANZA_PASSO
	) ENABLE
);

  CREATE TABLE 
      DPA_ELEMENTO_IN_LF_STOR  (
    ID_ELEMENTO       NUMBER NOT NULL ENABLE,
    ID_RUOLO_TITOLARE NUMBER NOT NULL ENABLE,
    TIPO_FIRMA       VARCHAR2(50 BYTE) NOT NULL ENABLE,
    STATO_FIRMA      VARCHAR2(20 BYTE) NOT NULL ENABLE,
    NOTE              VARCHAR2(256 BYTE),
    SCADENZA DATE,
    RUOLO_PROPONENTE  VARCHAR2(255 BYTE),
    UTENTE_PROPONENTE VARCHAR2(255 BYTE),
    MODALITA          VARCHAR2(20 BYTE) NOT NULL ENABLE,
    DATA_INSERIMENTO DATE NOT NULL ENABLE,
    DOC_NUMBER         NUMBER NOT NULL ENABLE,
    VERSION_ID         NUMBER NOT NULL ENABLE,
    NUM_ALL            NUMBER,
    NUM_VERSIONE       NUMBER NOT NULL ENABLE,
    ID_UTENTE_TITOLARE NUMBER,
    ID_UTENTE_LOCKER   NUMBER,
    ISTANZA_PROCESSO   NUMBER,
    ID_TRASM_SINGOLA   NUMBER,
    ID_DOC_PRINCIPALE  NUMBER,
    ID_ISTANZA_PASSO   NUMBER,
    DTA_ACCETTAZIONE DATE
  );

CREATE TABLE DPA_STATO_PASSO
(
ID_STATO NUMBER NOT NULL
,CODICE VARCHAR2(50) NOT NULL
,DESCRIZIONE VARCHAR2(256)
,CONSTRAINT DPA_STATO_PASSO_PK PRIMARY KEY 
	(ID_STATO, CODICE)
	ENABLE
);


CREATE TABLE DPA_EVENT_MONITOR 
(
  ID_DOCUMENTO NUMBER NOT NULL 
, ID_LOG NUMBER NOT NULL 
, ID_EVENTO NUMBER NOT NULL
, ID_GROUP NUMBER NOT NULL 
, ID_PEOPLE_AZIONE NUMBER NOT NULL
, ID_DELEGANTE NUMBER
, ID_PEOPLE NUMBER
, DATA_INSERIMENTO DATE
);

ALTER TABLE DPA_RAGIONE_TRASM 
ADD (CHA_PROC_RES VARCHAR2(50) DEFAULT NULL );

ALTER TABLE DPA_ANAGRAFICA_LOG
ADD (FOLLOW_CONFIG CHAR(1) DEFAULT '0' );

ALTER TABLE DPA_ANAGRAFICA_LOG
ADD (FOLLOW CHAR(1) DEFAULT '0' );

ALTER TABLE DPA_PASSO_DI_FIRMA
ADD (TICK CHAR(1) DEFAULT '0' );

ALTER TABLE DPA_SCHEMA_PROCESSO_FIRMA
ADD (TICK CHAR(1) DEFAULT '0' );

CREATE SEQUENCE SEQ_DPA_SCHEMA_PROCESSO_FIRMA INCREMENT BY 1 MAXVALUE 999999999999999999999999999 MINVALUE 1 CACHE 20;
	  
CREATE SEQUENCE SEQ_DPA_PASSO_DI_FIRMA INCREMENT BY 1 MAXVALUE 999999999999999999999999999 MINVALUE 1 CACHE 20;
	  
CREATE SEQUENCE SEQ_DPA_ELEMENTO_LIBRO_FIRMA INCREMENT BY 1 MAXVALUE 999999999999999999999999999 MINVALUE 1 CACHE 20;
	  
CREATE SEQUENCE SEQ_DPA_ISTANZA_PROCESSO_FIRMA INCREMENT BY 1 MAXVALUE 999999999999999999999999999 MINVALUE 1 CACHE 20;
	  
CREATE SEQUENCE SEQ_DPA_ISTANZA_PASSO_FIRMA INCREMENT BY 1 MAXVALUE 999999999999999999999999999 MINVALUE 1 CACHE 20;

CREATE SEQUENCE SEQ_DPA_FIRMA_ELETTRONICA INCREMENT BY 1 MAXVALUE 999999999999999999999999999 MINVALUE 1 CACHE 20;

CREATE INDEX INDX_ID_PROCESSO ON DPA_ISTANZA_PROCESSO_FIRMA
(ID_PROCESSO);

ALTER Table People Add (CHA_TIPO_FIRMA Varchar2(1));

ALTER Table DPA_LOG Add (ID_PEOPLE_DELEGANTE NUMBER);
ALTER Table DPA_LOG_STORICO Add (ID_PEOPLE_DELEGANTE NUMBER);

Insert Into DPA_ANAGRAFICA_EVENTI (Id_Evento, Var_Cod_Azione, Descrizione, CHA_TIPO_EVENTO, Gruppo) 
Values(1,'INSERIMENTO_DOCUMENTO_LF', 'Inserimento di un documento nel libro firma.','N', 'INSERIMENTO_DOCUMENTO_LF');

Insert Into DPA_ANAGRAFICA_EVENTI (Id_Evento, Var_Cod_Azione, Descrizione, CHA_TIPO_EVENTO, Gruppo) 
Values(2,'CONCLUSIONE_PROCESSO_LF_ALLEGATO', 'Conclusione del processo di firma.','N', 'CONCLUSIONE_PROCESSO_LF');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo)
VALUES (3, 'DOC_SIGNATURE', 'Cades','F', 'SIGN_D');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo)
VALUES (4, 'DOC_VERIFIED', 'Sottoscrizione','F', 'SIGN_E');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo)
VALUES (5, 'DOC_SIGNATURE_P', 'Pades','F', 'SIGN_D');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo) 
VALUES (6, 'DOC_STEP_OVER', 'Avanzamento iter', 'F', 'SIGN_E');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo) 
VALUES (7, 'INTERROTTO_PROCESSO_DOCUMENTO_DAL_PROPONENTE', 'Interruzione del processo di firma.', 'N', 'INTERROTTO_PROCESSO');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo) 
VALUES (8,'INTERROTTO_PROCESSO_ALLEGATO_DAL_PROPONENTE', 'Interruzione del processo di firma.', 'N', 'INTERROTTO_PROCESSO');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo) 
VALUES (9,'INTERROTTO_PROCESSO_DOCUMENTO_DAL_TITOLARE','Interruzione del processo di firma.','N','INTERROTTO_PROCESSO');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo) 
VALUES (10,'INTERROTTO_PROCESSO_ALLEGATO_DAL_TITOLARE','Interruzione del processo di firma.','N','INTERROTTO_PROCESSO');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo) 
VALUES (11,'CONCLUSIONE_PROCESSO_LF_DOCUMENTO','Conclusione del processo di firma.','N','CONCLUSIONE_PROCESSO_LF');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo) 
VALUES (12,'RECORD_PREDISPOSED','Protocollazione','E','EVENT');

INSERT INTO DPA_ANAGRAFICA_EVENTI (ID_EVENTO, VAR_COD_AZIONE, DESCRIZIONE, CHA_TIPO_EVENTO, Gruppo) 
VALUES (13,'DOC_ADD_INFASC','Classificazione/Fascicolazione','E','EVENT');

Insert Into Dpa_Anagrafica_Eventi (Id_Evento, Var_Cod_Azione, Descrizione, Cha_Tipo_Evento, Gruppo) 
Values (14,'WAITING','Attesa conclusione passi di firma','W','WAIT');

INSERT INTO DPA_STATO_PASSO  (ID_STATO, CODICE, DESCRIZIONE)
VALUES (0,'NEW','Non eseguito');

INSERT INTO DPA_STATO_PASSO  (ID_STATO, CODICE, DESCRIZIONE)
VALUES (1,'LOOK','In attesa');

INSERT INTO DPA_STATO_PASSO  (ID_STATO, CODICE, DESCRIZIONE)
VALUES (2,'CLOSE','Concluso');

INSERT INTO DPA_STATO_PASSO  (ID_STATO, CODICE, DESCRIZIONE)
VALUES (3,'STUCK','Interrotto');

INSERT INTO DPA_STATO_PASSO  (ID_STATO, CODICE, DESCRIZIONE)
VALUES (4,'CUT','Tagliato');
