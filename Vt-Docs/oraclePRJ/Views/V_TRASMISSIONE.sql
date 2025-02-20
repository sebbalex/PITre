--------------------------------------------------------
--  DDL for View V_TRASMISSIONE
--------------------------------------------------------

  CREATE OR REPLACE FORCE VIEW "ITCOLL_6GIU12"."V_TRASMISSIONE" ("SYSTEM_ID_TX", "ID_RUOLO_IN_UO_MITT", "ID_PEOPLE_MITT", "CHA_TIPO_OGGETTO", "ID_PROFILE", "ID_PROJECT", "DTA_INVIO", "VAR_NOTE_GENERALI", "CHA_CESSIONE", "CHA_SALVATA_CON_CESSIONE", "SYSTEM_ID_TS", "ID_RAGIONE", "ID_TRASMISSIONE", "CHA_TIPO_DEST", "ID_CORR_GLOBALE_DEST", "VAR_NOTE_SING", "CHA_TIPO_TRASM", "DTA_SCADENZA", "ID_TRASM_UTENTE", "SYSTEM_ID_TU", "ID_TRASM_SINGOLA", "ID_PEOPLE_DEST", "DTA_VISTA", "DTA_ACCETTATA", "DTA_RIFIUTATA", "DTA_RISPOSTA", "CHA_VISTA", "CHA_ACCETTATA", "CHA_RIFIUTATA", "VAR_NOTE_ACC", "VAR_NOTE_RIF", "CHA_VALIDA", "ID_TRASM_RISP_SING", "CHA_IN_TODOLIST", "DTA_RIMOZIONE_TODOLIST", "SYSTEM_ID_TR", "VAR_DESC_RAGIONE", "CHA_TIPO_RAGIONE", "CHA_VIS", "CHA_TIPO_DIRITTI", "CHA_TIPO_DEST_TR", "CHA_RISPOSTA", "VAR_NOTE", "CHA_EREDITA", "ID_AMM", "CHA_TIPO_RISPOSTA", "VAR_NOTIFICA_TRASM", "VAR_TESTO_MSG_NOTIFICA_DOC", "VAR_TESTO_MSG_NOTIFICA_FASC", "CHA_CEDE_DIRITTI", "CHA_RAG_SISTEMA") AS 
  SELECT tx."SYSTEM_ID", tx."ID_RUOLO_IN_UO", tx."ID_PEOPLE",
          tx."CHA_TIPO_OGGETTO", tx."ID_PROFILE", tx."ID_PROJECT",
          tx."DTA_INVIO", tx."VAR_NOTE_GENERALI", tx."CHA_CESSIONE",
          tx."CHA_SALVATA_CON_CESSIONE", ts."SYSTEM_ID", ts."ID_RAGIONE",
          ts."ID_TRASMISSIONE", ts."CHA_TIPO_DEST", ts."ID_CORR_GLOBALE",
          ts."VAR_NOTE_SING", ts."CHA_TIPO_TRASM", ts."DTA_SCADENZA",
          ts."ID_TRASM_UTENTE", tu."SYSTEM_ID", tu."ID_TRASM_SINGOLA",
          tu."ID_PEOPLE", tu."DTA_VISTA", tu."DTA_ACCETTATA",
          tu."DTA_RIFIUTATA", tu."DTA_RISPOSTA", tu."CHA_VISTA",
          tu."CHA_ACCETTATA", tu."CHA_RIFIUTATA", tu."VAR_NOTE_ACC",
          tu."VAR_NOTE_RIF", tu."CHA_VALIDA", tu."ID_TRASM_RISP_SING",
          tu."CHA_IN_TODOLIST", tu."DTA_RIMOZIONE_TODOLIST", tr."SYSTEM_ID",
          tr."VAR_DESC_RAGIONE", tr."CHA_TIPO_RAGIONE", tr."CHA_VIS",
          tr."CHA_TIPO_DIRITTI", tr."CHA_TIPO_DEST", tr."CHA_RISPOSTA",
          tr."VAR_NOTE", tr."CHA_EREDITA", tr."ID_AMM",
          tr."CHA_TIPO_RISPOSTA", tr."VAR_NOTIFICA_TRASM",
          tr."VAR_TESTO_MSG_NOTIFICA_DOC", tr."VAR_TESTO_MSG_NOTIFICA_FASC",
          tr."CHA_CEDE_DIRITTI", tr."CHA_RAG_SISTEMA"
     FROM dpa_trasmissione tx,
          dpa_trasm_singola ts,
          dpa_trasm_utente tu,
          dpa_ragione_trasm tr
    WHERE tx.system_id = ts.id_trasmissione
      AND ts.system_id = tu.id_trasm_singola
      AND ts.id_ragione = tr.system_id ;
