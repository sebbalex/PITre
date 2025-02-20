--------------------------------------------------------
--  DDL for Index INDX_PROJ_UNIQUE
--------------------------------------------------------

  CREATE UNIQUE INDEX "ITCOLL_6GIU12"."INDX_PROJ_UNIQUE" ON "ITCOLL_6GIU12"."PROJECT" ("VAR_CHIAVE_FASC") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 5242880 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "PITRE_INFOTN_DATA_COLL" ;
