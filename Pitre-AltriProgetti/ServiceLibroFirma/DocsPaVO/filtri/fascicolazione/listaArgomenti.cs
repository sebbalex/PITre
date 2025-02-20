using System;
using System.Xml.Serialization;

namespace DocsPaVO.filtri.fascicolazione 
{
	/// <summary>
	/// </summary>
	[XmlType("FiltriFascicolazione")]
	public enum listaArgomenti 
	{
		APERTURA_IL,
		APERTURA_SUCCESSIVA_AL,
		APERTURA_PRECEDENTE_IL,
		CHIUSURA_IL,
		CHIUSURA_SUCCESSIVA_AL,
		CHIUSURA_PRECEDENTE_IL,
		STATO,
		TITOLO,
		TIPO_FASCICOLO,
		NUMERO_FASCICOLO,
		ANNO_FASCICOLO,
		CREAZIONE_IL,
		CREAZIONE_SUCCESSIVA_AL,
		CREAZIONE_PRECEDENTE_IL,
		IN_CHILD_RIC_ESTESA,
		DATA_LF_IL,
		DATA_LF_SUCCESSIVA_AL,
		DATA_LF_PRECEDENTE_IL,
		ID_UO_LF,
		ID_UO_REF,
		DESC_UO_REF,
		VAR_NOTE,
        INCLUDI_FASCICOLI_FIGLI,
        CODICE_CLASSIFICA,
        TIPOLOGIA_FASCICOLO,
        PROFILAZIONE_DINAMICA,
        ID_TITOLARIO,
        ID_REGISTRO, 
        DOC_IN_FASC_ADL,
        SOTTOFASCICOLO,
        SCADENZA_IL,
        SCADENZA_SUCCESSIVA_AL,
        SCADENZA_PRECEDENTE_IL,
		DIAGRAMMA_STATO_FASC,
        CONSERVAZIONE,
        ID_PEOPLE_CREATORE,
        DESC_PEOPLE_CREATORE,
        ID_UO_CREATORE,
        DESC_UO_CREATORE,
        ID_RUOLO_CREATORE,
        DESC_RUOLO_CREATORE,
        DEPOSITO,
        CODICE_FASCICOLO,
        APERTURA_SC,
        APERTURA_MC,
        APERTURA_TODAY,
        CHIUSURA_SC,
        CHIUSURA_MC,
        CHIUSURA_TODAY,
        CREAZIONE_SC,
        CREAZIONE_MC,
        CREAZIONE_TODAY,
        DATA_LF_SC,
        DATA_LF_MC,
        DATA_LF_TODAY,
        SCADENZA_SC,
        SCADENZA_MC,
        SCADENZA_TODAY,
        FILE_EXCEL,
        ATTRIBUTO_EXCEL,
        UO_SOTTOPOSTE,
        ORACLE_FIELD_FOR_ORDER,
        SQL_FIELD_FOR_ORDER,
        PROFILATION_FIELD_FOR_ORDER,
        ORDER_DIRECTION,
        REG_NO_SECURITY,
        VISIBILITA_T_A,
        IN_CONSERVAZIONE,
        COD_EXT_APP
	}
}
