--------------------------------------------------------
--  Constraints for Table DPA_FASCICOLAZIONE_CARTACEA
--------------------------------------------------------

  ALTER TABLE "ITCOLL_6GIU12"."DPA_FASCICOLAZIONE_CARTACEA" ADD CONSTRAINT "INDX_FASC_CARTACEA_PK" PRIMARY KEY ("SYSTEM_ID") ENABLE;
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_FASCICOLAZIONE_CARTACEA" MODIFY ("SYSTEM_ID" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_FASCICOLAZIONE_CARTACEA" MODIFY ("PROJECT_ID" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_FASCICOLAZIONE_CARTACEA" MODIFY ("ID_DOCUMENT" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_FASCICOLAZIONE_CARTACEA" MODIFY ("VERSION_ID" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_FASCICOLAZIONE_CARTACEA" MODIFY ("DATA_ARCHIVIAZIONE" NOT NULL ENABLE);
