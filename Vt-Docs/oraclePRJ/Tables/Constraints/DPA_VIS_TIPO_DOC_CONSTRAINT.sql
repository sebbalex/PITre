--------------------------------------------------------
--  Constraints for Table DPA_VIS_TIPO_DOC
--------------------------------------------------------

  ALTER TABLE "ITCOLL_6GIU12"."DPA_VIS_TIPO_DOC" ADD CONSTRAINT "DPA_VIS_TIPO_DOC_U01" UNIQUE ("ID_TIPO_DOC", "ID_RUOLO") ENABLE;
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_VIS_TIPO_DOC" ADD CONSTRAINT "PK_DPA_VIS_TIPO_DOC" PRIMARY KEY ("SYSTEM_ID") ENABLE;
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_VIS_TIPO_DOC" MODIFY ("SYSTEM_ID" NOT NULL ENABLE);
