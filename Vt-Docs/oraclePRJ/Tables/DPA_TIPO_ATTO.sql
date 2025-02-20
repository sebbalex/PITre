--------------------------------------------------------
--  DDL for Table DPA_TIPO_ATTO
--------------------------------------------------------

  CREATE TABLE "ITCOLL_6GIU12"."DPA_TIPO_ATTO" 
   (	"SYSTEM_ID" NUMBER(10,0), 
	"VAR_DESC_ATTO" VARCHAR2(64 BYTE), 
	"ID_AMM" NUMBER, 
	"GG_SCADENZA" NUMBER(*,0), 
	"GG_PRE_SCADENZA" NUMBER(*,0), 
	"CHA_PRIVATO" VARCHAR2(1 BYTE), 
	"IPERDOCUMENTO" NUMBER, 
	"PATH_ALL_1" VARCHAR2(255 BYTE), 
	"EXT_ALL_1" CHAR(10 BYTE), 
	"ABILITATO_SI_NO" NUMBER, 
	"EXT_MOD_1" CHAR(10 BYTE), 
	"EXT_MOD_2" CHAR(10 BYTE), 
	"IN_ESERCIZIO" VARCHAR2(255 BYTE), 
	"PATH_MOD_1" VARCHAR2(255 BYTE), 
	"PATH_MOD_2" VARCHAR2(255 BYTE), 
	"COD_MOD_TRASM" VARCHAR2(128 BYTE), 
	"COD_CLASS" VARCHAR2(128 BYTE), 
	"PATH_MOD_EXC" VARCHAR2(255 BYTE), 
	"PATH_MOD_SU" VARCHAR2(255 BYTE)
   ) ;
