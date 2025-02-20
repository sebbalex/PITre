DECLARE
  CODICE VARCHAR2(200);
  DESCRIZIONE VARCHAR2(200);
  TIPO_CHIAVE VARCHAR2(200);
  DISABILITATA VARCHAR2(200);
  FORZA_DISABILITAZIONE VARCHAR2(200);
  MYVERSIONE_CD VARCHAR2(200);
  RFU VARCHAR2(200);
 
BEGIN
  CODICE := 'DO_REGISTRO_ACCESSI_EXPORT';
  DESCRIZIONE := 'Abilita il ruolo all''esportazione del report del registro degli accessi';
  TIPO_CHIAVE := '';
  DISABILITATA := 'N';
  FORZA_DISABILITAZIONE := 'N';
  MYVERSIONE_CD := '3.2.9';
  RFU := NULL;
 
  UTL_INSERT_CHIAVE_MICROFUNZ ( CODICE, DESCRIZIONE, TIPO_CHIAVE, DISABILITATA, FORZA_DISABILITAZIONE, MYVERSIONE_CD, RFU );
  COMMIT;
  
  CODICE := 'DO_REGISTRO_ACCESSI_PUBLISH';
  DESCRIZIONE := 'Abilita il ruolo alla pubblicazione del registro degli accessi';
  TIPO_CHIAVE := '';
  DISABILITATA := 'N';
  FORZA_DISABILITAZIONE := 'N';
  MYVERSIONE_CD := '3.2.9';
  RFU := NULL;
 
  UTL_INSERT_CHIAVE_MICROFUNZ ( CODICE, DESCRIZIONE, TIPO_CHIAVE, DISABILITATA, FORZA_DISABILITAZIONE, MYVERSIONE_CD, RFU );
  COMMIT;
END;