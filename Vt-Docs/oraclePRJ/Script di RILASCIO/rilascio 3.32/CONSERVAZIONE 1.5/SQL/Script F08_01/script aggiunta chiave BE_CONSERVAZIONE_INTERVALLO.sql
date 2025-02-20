﻿/*
***                        ATTENZIONE                       ***
*** Script convertito da Oracle a SQL Server ma non testato ***
*** Testare prima di utilizzare                             ***
*/
BEGIN
  Utl_Insert_Chiave_Config
  (
  'BE_CONSERVAZIONE_INTERVALLO',	--CODICE
  'Intervallo in giorni tra due verifiche di integrità su istanze in Conservazione nel Centro Servizi ',  --DESCRIZIONE
  '180',	--VALORE
  'B', 		--TIPO CHIAVE
  '1', 		--VISIBILE
  '1', 		--MODIFICABILE
  '0', 		--GLOBALE
  'CS 1.5',   --myVersione_CD
  ,NULL, NULL, NULL);  --Codice_Old_Webconfig ,Forza_Update_Valore,RFU
END;
  
BEGIN  
	UPDATE dpa_chiavi_configurazione
	SET
	cha_conservazione='1'
	WHERE
	var_codice='BE_CONSERVAZIONE_INTERVALLO';
END;
