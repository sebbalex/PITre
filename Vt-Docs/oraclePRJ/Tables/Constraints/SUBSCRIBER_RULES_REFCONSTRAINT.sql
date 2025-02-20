--------------------------------------------------------
--  Ref Constraints for Table SUBSCRIBER_RULES
--------------------------------------------------------

  ALTER TABLE "ITCOLL_6GIU12"."SUBSCRIBER_RULES" ADD CONSTRAINT "FK_PUBLISH_INSTANCEID" FOREIGN KEY ("INSTANCEID")
	  REFERENCES "ITCOLL_6GIU12"."SUBSCRIBER_INSTANCES" ("ID") ON DELETE CASCADE ENABLE NOVALIDATE;
 
  ALTER TABLE "ITCOLL_6GIU12"."SUBSCRIBER_RULES" ADD CONSTRAINT "FK_RULE_SUBRULES" FOREIGN KEY ("PARENTRULEID")
	  REFERENCES "ITCOLL_6GIU12"."SUBSCRIBER_RULES" ("ID") ON DELETE CASCADE ENABLE NOVALIDATE;
