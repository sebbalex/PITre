BEGIN
	 --INSERIMENTO NUOVA RAGIONE DI TRASMISSIONE ASSEGNA_ATTIVITA
	INSERT INTO DPA_RAGIONE_TRASM (SYSTEM_ID, VAR_DESC_RAGIONE, CHA_TIPO_RAGIONE, CHA_VIS, CHA_TIPO_DIRITTI, CHA_TIPO_DEST, CHA_RISPOSTA, VAR_NOTE, CHA_EREDITA, CHA_TIPO_RISPOSTA, ID_AMM, VAR_NOTIFICA_TRASM, CHA_CEDE_DIRITTI, CHA_MANTIENI_LETT, CHA_MANTIENI_SCRITT, CHA_RAG_SISTEMA, CHA_PROC_RES, CHA_TIPO_TASK )
	(SELECT SEQ.NEXTVAL, 'ASSEGNA_ATTIVITA', 'W', '1','W', 'T',	'0', 'Ragione di trasmissione per avvio attività', '0', 'C',	a.system_id, 'NN',	'N', 0,	0,	0, null, '1'
	  FROM dpa_amministra a
	);
	
	--RAGIONE PER ACQUISIZIONE DIRITTI
	INSERT INTO DPA_RAGIONE_TRASM (SYSTEM_ID, VAR_DESC_RAGIONE, CHA_TIPO_RAGIONE, CHA_VIS, CHA_TIPO_DIRITTI, CHA_TIPO_DEST, CHA_RISPOSTA, VAR_NOTE, CHA_EREDITA, CHA_TIPO_RISPOSTA, ID_AMM, VAR_NOTIFICA_TRASM, CHA_CEDE_DIRITTI, CHA_MANTIENI_LETT, CHA_MANTIENI_SCRITT, CHA_RAG_SISTEMA, CHA_PROC_RES, CHA_TIPO_TASK )
	(SELECT SEQ.NEXTVAL, 'ASSEGNA_DIRITTI', 'D', '0','W', 'T',	'0', 'Ragione di trasmissione per assegnare diritti di visibilità', '0', 'C',	a.system_id, 'NN',	'N', 0,	0,	1, null, '0'
	  FROM dpa_amministra a
	);
END;
/
COMMIT;