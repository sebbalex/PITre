--------------------------------------------------------
--  DDL for Table DPA_OGGETTI_CUSTOM
--------------------------------------------------------

  CREATE TABLE "ITCOLL_6GIU12"."DPA_OGGETTI_CUSTOM" 
   (	"SYSTEM_ID" NUMBER, 
	"DESCRIZIONE" VARCHAR2(255 BYTE), 
	"ORIZZONTALE_VERTICALE" VARCHAR2(255 BYTE), 
	"CAMPO_OBBLIGATORIO" VARCHAR2(255 BYTE), 
	"MULTILINEA" VARCHAR2(255 BYTE), 
	"NUMERO_DI_LINEE" VARCHAR2(255 BYTE), 
	"NUMERO_DI_CARATTERI" VARCHAR2(255 BYTE), 
	"CAMPO_DI_RICERCA" VARCHAR2(255 BYTE), 
	"ID_TIPO_OGGETTO" NUMBER, 
	"RESET_ANNO" VARCHAR2(2 BYTE), 
	"FORMATO_CONTATORE" VARCHAR2(100 BYTE), 
	"ID_R_DEFAULT" VARCHAR2(50 BYTE), 
	"RICERCA_CORR" VARCHAR2(50 BYTE), 
	"CHA_TIPO_TAR" VARCHAR2(2 BYTE), 
	"CONTA_DOPO" NUMBER, 
	"REPERTORIO" NUMBER, 
	"CAMPO_COMUNE" NUMBER, 
	"DA_VISUALIZZARE_RICERCA" NUMBER, 
	"FORMATO_ORA" VARCHAR2(10 BYTE), 
	"TIPO_LINK" VARCHAR2(50 BYTE), 
	"TIPO_OBJ_LINK" VARCHAR2(50 BYTE), 
	"CONFIG_OBJ_EST" CLOB, 
	"MODULO_SOTTOCONTATORE" NUMBER
   ) ;
