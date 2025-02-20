﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.239
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System.Xml.Serialization;
using DocsPaConservazione.Metadata.Common;

// 
// This source code was auto-generated by xsd, Version=4.0.30319.1.
// 

namespace DocsPaConservazione.Metadata.Fascicolo
{
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("xsd", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
    public partial class Fascicolo
    {

        private SoggettoProduttore soggettoProduttoreField;
        private Tipologia tipologiaField;
        private Contenuto contenutoField;
        private string codiceField;
        private string descrizioneField;
        private string numeroField;
        private string classificazioneField;
        private string titolarioDiRiferimentoField;
        private string dataCreazioneField;
        private string dataChiusuraField;
        private string estremoCronologicoInferioreField;
        private string estremoCronologicoSuperioreField;
        private string livelloRiservatezzaField;

        /// <remarks/>
        public SoggettoProduttore SoggettoProduttore
        {
            get
            {
                return this.soggettoProduttoreField;
            }
            set
            {
                this.soggettoProduttoreField = value;
            }
        }

        /// <remarks/>
        public Tipologia Tipologia
        {
            get
            {
                return this.tipologiaField;
            }
            set
            {
                this.tipologiaField = value;
            }
        }

        /// <remarks/>
        public Contenuto Contenuto
        {
            get
            {
                return this.contenutoField;
            }
            set
            {
                this.contenutoField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string Codice
        {
            get
            {
                return this.codiceField;
            }
            set
            {
                this.codiceField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string Descrizione
        {
            get
            {
                return this.descrizioneField;
            }
            set
            {
                this.descrizioneField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string Numero
        {
            get
            {
                return this.numeroField;
            }
            set
            {
                this.numeroField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string Classificazione
        {
            get
            {
                return this.classificazioneField;
            }
            set
            {
                this.classificazioneField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string TitolarioDiRiferimento
        {
            get
            {
                return this.titolarioDiRiferimentoField;
            }
            set
            {
                this.titolarioDiRiferimentoField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string DataCreazione
        {
            get
            {
                return this.dataCreazioneField;
            }
            set
            {
                this.dataCreazioneField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string DataChiusura
        {
            get
            {
                return this.dataChiusuraField;
            }
            set
            {
                this.dataChiusuraField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string EstremoCronologicoInferiore
        {
            get
            {
                return this.estremoCronologicoInferioreField;
            }
            set
            {
                this.estremoCronologicoInferioreField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string EstremoCronologicoSuperiore
        {
            get
            {
                return this.estremoCronologicoSuperioreField;
            }
            set
            {
                this.estremoCronologicoSuperioreField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string LivelloRiservatezza
        {
            get
            {
                return this.livelloRiservatezzaField;
            }
            set
            {
                this.livelloRiservatezzaField = value;
            }
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("xsd", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
    public partial class SoggettoProduttore
    {

        private Amministrazione amministrazioneField;
        private GerarchiaUO gerarchiaUOField;
        private Creatore creatoreField;

        /// <remarks/>
        public Amministrazione Amministrazione
        {
            get
            {
                return this.amministrazioneField;
            }
            set
            {
                this.amministrazioneField = value;
            }
        }

        /// <remarks/>
        public GerarchiaUO GerarchiaUO
        {
            get
            {
                return this.gerarchiaUOField;
            }
            set
            {
                this.gerarchiaUOField = value;
            }
        }

        /// <remarks/>
        public Creatore Creatore
        {
            get
            {
                return this.creatoreField;
            }
            set
            {
                this.creatoreField = value;
            }
        }
    }


    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("xsd", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
    public partial class GerarchiaUO
    {
        private UnitaOrganizzativa[] unitaOrganizzativaField;
        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("UnitaOrganizzativa")]
        public UnitaOrganizzativa[] UnitaOrganizzativa
        {
            get
            {
                return this.unitaOrganizzativaField;
            }
            set
            {
                this.unitaOrganizzativaField = value;
            }
        }
    }


 

  

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("xsd", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
    public partial class Contenuto
    {

        private object[] itemsField;
        private string consistenzaSottofascicoliField;
        private string consistenzaDocumentiField;

        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("Documento", typeof(Documento))]
        [System.Xml.Serialization.XmlElementAttribute("Sottofascicolo", typeof(Sottofascicolo))]
        public object[] Items
        {
            get
            {
                return this.itemsField;
            }
            set
            {
                this.itemsField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string ConsistenzaSottofascicoli
        {
            get
            {
                return this.consistenzaSottofascicoliField;
            }
            set
            {
                this.consistenzaSottofascicoliField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string ConsistenzaDocumenti
        {
            get
            {
                return this.consistenzaDocumentiField;
            }
            set
            {
                this.consistenzaDocumentiField = value;
            }
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("xsd", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
    public partial class Documento
    {
        private string iDdocumentoField;
        private string dataCreazioneField;
        private string oggettoField;
        private string livelloRiservatezzaField;

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string IDdocumento
        {
            get
            {
                return this.iDdocumentoField;
            }
            set
            {
                this.iDdocumentoField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string DataCreazione
        {
            get
            {
                return this.dataCreazioneField;
            }
            set
            {
                this.dataCreazioneField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string Oggetto
        {
            get
            {
                return this.oggettoField;
            }
            set
            {
                this.oggettoField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string LivelloRiservatezza
        {
            get
            {
                return this.livelloRiservatezzaField;
            }
            set
            {
                this.livelloRiservatezzaField = value;
            }
        }
    }

    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("xsd", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlRootAttribute(Namespace = "", IsNullable = false)]
    public partial class Sottofascicolo
    {

        private object[] itemsField;
        private string codiceField;
        private string descrizioneField;

        [XmlIgnoreAttribute]
        public string parent; //Mi serve internamente per la gerarchia


        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute("Documento", typeof(Documento))]
        [System.Xml.Serialization.XmlElementAttribute("Sottofascicolo", typeof(Sottofascicolo))]
        public object[] Items
        {
            get
            {
                return this.itemsField;
            }
            set
            {
                this.itemsField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string Codice
        {
            get
            {
                return this.codiceField;
            }
            set
            {
                this.codiceField = value;
            }
        }

        /// <remarks/>
        [System.Xml.Serialization.XmlAttributeAttribute()]
        public string Descrizione
        {
            get
            {
                return this.descrizioneField;
            }
            set
            {
                this.descrizioneField = value;
            }
        }
    }

}