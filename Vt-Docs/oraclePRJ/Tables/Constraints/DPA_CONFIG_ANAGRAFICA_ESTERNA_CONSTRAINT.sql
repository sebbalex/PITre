--------------------------------------------------------
--  Constraints for Table DPA_CONFIG_ANAGRAFICA_ESTERNA
--------------------------------------------------------

  ALTER TABLE "ITCOLL_6GIU12"."DPA_CONFIG_ANAGRAFICA_ESTERNA" MODIFY ("NOME_ANAGRAFICA_ESTERNA" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_CONFIG_ANAGRAFICA_ESTERNA" MODIFY ("WSURL_ANAGRAFICA_ESTERNA" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_CONFIG_ANAGRAFICA_ESTERNA" MODIFY ("INTEGRATION_ADAPTER_ID" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_CONFIG_ANAGRAFICA_ESTERNA" MODIFY ("INTEGRATION_ADAPTER_VERSION" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_CONFIG_ANAGRAFICA_ESTERNA" MODIFY ("ENABLED" NOT NULL ENABLE);
 
  ALTER TABLE "ITCOLL_6GIU12"."DPA_CONFIG_ANAGRAFICA_ESTERNA" ADD PRIMARY KEY ("SYSTEM_ID") ENABLE;
