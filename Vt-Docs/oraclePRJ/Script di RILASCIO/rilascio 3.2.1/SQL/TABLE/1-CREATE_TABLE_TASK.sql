DROP TABLE DPA_TASK;
CREATE TABLE DPA_TASK
(
  SYSTEM_ID           INT     primary key IDENTITY(1,1)               NOT NULL,
  ID_RUOLO_MITT       INT                    DEFAULT 0                     NOT NULL,
  ID_PEOPLE_MITT      INT                    DEFAULT 0                     NOT NULL,
  ID_RUOLO_RECEIVER   INT                    DEFAULT 0                     NOT NULL,
  ID_PEOPLE_RECEIVER  INT                    DEFAULT 0                     NOT NULL,
  ID_PROFILE          INT,
  ID_PROJECT          INT,
  ID_PROFILE_REVIEW   INT,
  ID_TRASMISSIONE     INT,
  ID_TRASM_SINGOLA    INT,
  ID_RAGIONE_TRASM    INT,
  ID_TIPO_ATTO 	INT,
  CHA_CONTRIBUTO    CHAR(1)
)GO


CREATE TABLE DPA_STATO_TASK
(
  SYSTEM_ID         INT    primary key IDENTITY(1,1)                NOT NULL,
  ID_TASK      		INT    DEFAULT 0       NOT NULL,
  DTA_APERTURA		DATETIME,
  DTA_SCADENZA		DATETIME,
  DTA_LAVORAZIONE   DATETIME,
  DTA_CHIUSURA		DATETIME,
  DTA_ANNULLAMENTO  DATETIME,
  CHA_STATO 		CHAR(1),
  NOTE_LAVORAZIONE  VARCHAR(2000),
  NOTE_RIAPERTURA 	VARCHAR(2000)
)GO

CREATE TABLE DPA_TIPO_RAGIONE
(
   ID_RAGIONE_TRASM			INT,
   CHA_TIPO_TASK			CHAR(1),
   ID_TIPO_ATTO				INT,
   CHA_CONTRIBUTO_OBBLIGATORIO 	CHAR(1) DEFAULT '0' 
)GO

