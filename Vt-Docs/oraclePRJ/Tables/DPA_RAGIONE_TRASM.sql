--------------------------------------------------------
--  DDL for Table DPA_RAGIONE_TRASM
--------------------------------------------------------

  CREATE TABLE "ITCOLL_6GIU12"."DPA_RAGIONE_TRASM" 
   (	"SYSTEM_ID" NUMBER(10,0), 
	"VAR_DESC_RAGIONE" VARCHAR2(32 BYTE), 
	"CHA_TIPO_RAGIONE" VARCHAR2(1 BYTE), 
	"CHA_VIS" VARCHAR2(1 BYTE), 
	"CHA_TIPO_DIRITTI" VARCHAR2(1 BYTE), 
	"CHA_TIPO_DEST" VARCHAR2(1 BYTE), 
	"CHA_RISPOSTA" VARCHAR2(1 BYTE), 
	"VAR_NOTE" VARCHAR2(250 BYTE), 
	"CHA_EREDITA" VARCHAR2(1 BYTE), 
	"ID_AMM" NUMBER(10,0), 
	"CHA_TIPO_RISPOSTA" VARCHAR2(1 BYTE), 
	"VAR_NOTIFICA_TRASM" VARCHAR2(2 BYTE), 
	"VAR_TESTO_MSG_NOTIFICA_DOC" VARCHAR2(1024 BYTE), 
	"VAR_TESTO_MSG_NOTIFICA_FASC" VARCHAR2(1024 BYTE), 
	"CHA_CEDE_DIRITTI" CHAR(1 BYTE), 
	"CHA_RAG_SISTEMA" CHAR(1 CHAR) DEFAULT 0, 
	"CHA_MANTIENI_LETT" CHAR(1 BYTE), 
	"N_ORD" NUMBER(10,0)
   ) ;
