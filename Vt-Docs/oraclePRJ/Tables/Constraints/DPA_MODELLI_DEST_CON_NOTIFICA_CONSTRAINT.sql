--------------------------------------------------------
--  Constraints for Table DPA_MODELLI_DEST_CON_NOTIFICA
--------------------------------------------------------

  ALTER TABLE "ITCOLL_6GIU12"."DPA_MODELLI_DEST_CON_NOTIFICA" ADD CONSTRAINT "DPA_MODELLI_DEST_CON_NOTIFI_PK" PRIMARY KEY ("SYSTEM_ID") ENABLE;
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_MODELLI_DEST_CON_NOTIFICA" MODIFY ("ID_MODELLO_MITT_DEST" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_MODELLI_DEST_CON_NOTIFICA" MODIFY ("ID_PEOPLE" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_MODELLI_DEST_CON_NOTIFICA" MODIFY ("ID_MODELLO" NOT NULL ENABLE);
