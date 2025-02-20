DECLARE
  CODICE VARCHAR2(200);
  DESCRIZIONE VARCHAR2(200);
  VALORE VARCHAR2(200);
  TIPO_CHIAVE VARCHAR2(200);
  VISIBILE VARCHAR2(200);
  MODIFICABILE VARCHAR2(200);
  GLOBALE VARCHAR2(200);
  MYVERSIONE_CD VARCHAR2(200);
  CODICE_OLD_WEBCONFIG VARCHAR2(200);
  FORZA_UPDATE VARCHAR2(200);
  RFU VARCHAR2(200);
  

BEGIN
  CODICE := 'BE_ENABLE_REPORT_POLICY_PARER';
  DESCRIZIONE := 'Abilita l''invio del report di esecuzione delle policy per l''amministrazione';
  VALORE := '1';
  TIPO_CHIAVE := 'B';
  VISIBILE := '1';
  MODIFICABILE := '1';
  GLOBALE := '0';
  MYVERSIONE_CD := '3.2.7';
  CODICE_OLD_WEBCONFIG := NULL;
  FORZA_UPDATE := '1';
  RFU := NULL;
 
  UTL_INSERT_CHIAVE_CONFIG ( CODICE, DESCRIZIONE, VALORE, TIPO_CHIAVE, VISIBILE, MODIFICABILE, GLOBALE, MYVERSIONE_CD, CODICE_OLD_WEBCONFIG, FORZA_UPDATE, RFU );
  COMMIT;
END;