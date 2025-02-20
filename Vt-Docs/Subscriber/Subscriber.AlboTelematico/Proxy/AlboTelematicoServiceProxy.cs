﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.225
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

// 
// This source code was auto-generated by wsdl, Version=4.0.30319.1.
// 
namespace Subscriber.AlboTelematico.Proxy
{
    using System;
    using System.Web.Services;
    using System.Diagnostics;
    using System.Web.Services.Protocols;
    using System.ComponentModel;
    using System.Xml.Serialization;
    
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.1")]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Web.Services.WebServiceBindingAttribute(Name="AlboTelematicoServicesSoap", Namespace="http://valueteam.com/AlboTelematico")]
    public partial class AlboTelematicoServices : System.Web.Services.Protocols.SoapHttpClientProtocol {
        
        private System.Threading.SendOrPostCallback PubblicaConRevocaOperationCompleted;
        
        private System.Threading.SendOrPostCallback PubblicaSenzaRevocaOperationCompleted;
        
        private System.Threading.SendOrPostCallback AnnullaPubblicazioneOperationCompleted;
        
        private System.Threading.SendOrPostCallback RevocaPubblicazioneOperationCompleted;
        
        /// <remarks/>
        public AlboTelematicoServices() {
            this.Url = "http://localhost/AlboTelematico/AlboTelematicoServices.asmx";
        }
        
        /// <remarks/>
        public event PubblicaConRevocaCompletedEventHandler PubblicaConRevocaCompleted;
        
        /// <remarks/>
        public event PubblicaSenzaRevocaCompletedEventHandler PubblicaSenzaRevocaCompleted;
        
        /// <remarks/>
        public event AnnullaPubblicazioneCompletedEventHandler AnnullaPubblicazioneCompleted;
        
        /// <remarks/>
        public event RevocaPubblicazioneCompletedEventHandler RevocaPubblicazioneCompleted;
        
        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://valueteam.com/AlboTelematico/PubblicaConRevoca", RequestNamespace="http://valueteam.com/AlboTelematico", ResponseNamespace="http://valueteam.com/AlboTelematico", Use=System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle=System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public void PubblicaConRevoca(RichiestaPubblicazione datiRichiesta) {
            this.Invoke("PubblicaConRevoca", new object[] {
                        datiRichiesta});
        }
        
        /// <remarks/>
        public System.IAsyncResult BeginPubblicaConRevoca(RichiestaPubblicazione datiRichiesta, System.AsyncCallback callback, object asyncState) {
            return this.BeginInvoke("PubblicaConRevoca", new object[] {
                        datiRichiesta}, callback, asyncState);
        }
        
        /// <remarks/>
        public void EndPubblicaConRevoca(System.IAsyncResult asyncResult) {
            this.EndInvoke(asyncResult);
        }
        
        /// <remarks/>
        public void PubblicaConRevocaAsync(RichiestaPubblicazione datiRichiesta) {
            this.PubblicaConRevocaAsync(datiRichiesta, null);
        }
        
        /// <remarks/>
        public void PubblicaConRevocaAsync(RichiestaPubblicazione datiRichiesta, object userState) {
            if ((this.PubblicaConRevocaOperationCompleted == null)) {
                this.PubblicaConRevocaOperationCompleted = new System.Threading.SendOrPostCallback(this.OnPubblicaConRevocaOperationCompleted);
            }
            this.InvokeAsync("PubblicaConRevoca", new object[] {
                        datiRichiesta}, this.PubblicaConRevocaOperationCompleted, userState);
        }
        
        private void OnPubblicaConRevocaOperationCompleted(object arg) {
            if ((this.PubblicaConRevocaCompleted != null)) {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.PubblicaConRevocaCompleted(this, new System.ComponentModel.AsyncCompletedEventArgs(invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }
        
        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://valueteam.com/AlboTelematico/PubblicaSenzaRevoca", RequestNamespace="http://valueteam.com/AlboTelematico", ResponseNamespace="http://valueteam.com/AlboTelematico", Use=System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle=System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public void PubblicaSenzaRevoca(RichiestaPubblicazione datiRichiesta) {
            this.Invoke("PubblicaSenzaRevoca", new object[] {
                        datiRichiesta});
        }
        
        /// <remarks/>
        public System.IAsyncResult BeginPubblicaSenzaRevoca(RichiestaPubblicazione datiRichiesta, System.AsyncCallback callback, object asyncState) {
            return this.BeginInvoke("PubblicaSenzaRevoca", new object[] {
                        datiRichiesta}, callback, asyncState);
        }
        
        /// <remarks/>
        public void EndPubblicaSenzaRevoca(System.IAsyncResult asyncResult) {
            this.EndInvoke(asyncResult);
        }
        
        /// <remarks/>
        public void PubblicaSenzaRevocaAsync(RichiestaPubblicazione datiRichiesta) {
            this.PubblicaSenzaRevocaAsync(datiRichiesta, null);
        }
        
        /// <remarks/>
        public void PubblicaSenzaRevocaAsync(RichiestaPubblicazione datiRichiesta, object userState) {
            if ((this.PubblicaSenzaRevocaOperationCompleted == null)) {
                this.PubblicaSenzaRevocaOperationCompleted = new System.Threading.SendOrPostCallback(this.OnPubblicaSenzaRevocaOperationCompleted);
            }
            this.InvokeAsync("PubblicaSenzaRevoca", new object[] {
                        datiRichiesta}, this.PubblicaSenzaRevocaOperationCompleted, userState);
        }
        
        private void OnPubblicaSenzaRevocaOperationCompleted(object arg) {
            if ((this.PubblicaSenzaRevocaCompleted != null)) {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.PubblicaSenzaRevocaCompleted(this, new System.ComponentModel.AsyncCompletedEventArgs(invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }
        
        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://valueteam.com/AlboTelematico/AnnullaPubblicazione", RequestNamespace="http://valueteam.com/AlboTelematico", ResponseNamespace="http://valueteam.com/AlboTelematico", Use=System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle=System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public void AnnullaPubblicazione(RichiestaPubblicazione datiRichiesta) {
            this.Invoke("AnnullaPubblicazione", new object[] {
                        datiRichiesta});
        }
        
        /// <remarks/>
        public System.IAsyncResult BeginAnnullaPubblicazione(RichiestaPubblicazione datiRichiesta, System.AsyncCallback callback, object asyncState) {
            return this.BeginInvoke("AnnullaPubblicazione", new object[] {
                        datiRichiesta}, callback, asyncState);
        }
        
        /// <remarks/>
        public void EndAnnullaPubblicazione(System.IAsyncResult asyncResult) {
            this.EndInvoke(asyncResult);
        }
        
        /// <remarks/>
        public void AnnullaPubblicazioneAsync(RichiestaPubblicazione datiRichiesta) {
            this.AnnullaPubblicazioneAsync(datiRichiesta, null);
        }
        
        /// <remarks/>
        public void AnnullaPubblicazioneAsync(RichiestaPubblicazione datiRichiesta, object userState) {
            if ((this.AnnullaPubblicazioneOperationCompleted == null)) {
                this.AnnullaPubblicazioneOperationCompleted = new System.Threading.SendOrPostCallback(this.OnAnnullaPubblicazioneOperationCompleted);
            }
            this.InvokeAsync("AnnullaPubblicazione", new object[] {
                        datiRichiesta}, this.AnnullaPubblicazioneOperationCompleted, userState);
        }
        
        private void OnAnnullaPubblicazioneOperationCompleted(object arg) {
            if ((this.AnnullaPubblicazioneCompleted != null)) {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.AnnullaPubblicazioneCompleted(this, new System.ComponentModel.AsyncCompletedEventArgs(invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }
        
        /// <remarks/>
        [System.Web.Services.Protocols.SoapDocumentMethodAttribute("http://valueteam.com/AlboTelematico/RevocaPubblicazione", RequestNamespace="http://valueteam.com/AlboTelematico", ResponseNamespace="http://valueteam.com/AlboTelematico", Use=System.Web.Services.Description.SoapBindingUse.Literal, ParameterStyle=System.Web.Services.Protocols.SoapParameterStyle.Wrapped)]
        public void RevocaPubblicazione(RichiestaPubblicazione datiRichiesta) {
            this.Invoke("RevocaPubblicazione", new object[] {
                        datiRichiesta});
        }
        
        /// <remarks/>
        public System.IAsyncResult BeginRevocaPubblicazione(RichiestaPubblicazione datiRichiesta, System.AsyncCallback callback, object asyncState) {
            return this.BeginInvoke("RevocaPubblicazione", new object[] {
                        datiRichiesta}, callback, asyncState);
        }
        
        /// <remarks/>
        public void EndRevocaPubblicazione(System.IAsyncResult asyncResult) {
            this.EndInvoke(asyncResult);
        }
        
        /// <remarks/>
        public void RevocaPubblicazioneAsync(RichiestaPubblicazione datiRichiesta) {
            this.RevocaPubblicazioneAsync(datiRichiesta, null);
        }
        
        /// <remarks/>
        public void RevocaPubblicazioneAsync(RichiestaPubblicazione datiRichiesta, object userState) {
            if ((this.RevocaPubblicazioneOperationCompleted == null)) {
                this.RevocaPubblicazioneOperationCompleted = new System.Threading.SendOrPostCallback(this.OnRevocaPubblicazioneOperationCompleted);
            }
            this.InvokeAsync("RevocaPubblicazione", new object[] {
                        datiRichiesta}, this.RevocaPubblicazioneOperationCompleted, userState);
        }
        
        private void OnRevocaPubblicazioneOperationCompleted(object arg) {
            if ((this.RevocaPubblicazioneCompleted != null)) {
                System.Web.Services.Protocols.InvokeCompletedEventArgs invokeArgs = ((System.Web.Services.Protocols.InvokeCompletedEventArgs)(arg));
                this.RevocaPubblicazioneCompleted(this, new System.ComponentModel.AsyncCompletedEventArgs(invokeArgs.Error, invokeArgs.Cancelled, invokeArgs.UserState));
            }
        }
        
        /// <remarks/>
        public new void CancelAsync(object userState) {
            base.CancelAsync(userState);
        }
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(Namespace="http://valueteam.com/AlboTelematico")]
    public partial class RichiestaPubblicazione {
        
        private string userIDField;
        
        private string passwordField;
        
        private DocumentoDaPubblicare documentoField;
        
        /// <remarks/>
        public string UserID {
            get {
                return this.userIDField;
            }
            set {
                this.userIDField = value;
            }
        }
        
        /// <remarks/>
        public string Password {
            get {
                return this.passwordField;
            }
            set {
                this.passwordField = value;
            }
        }
        
        /// <remarks/>
        public DocumentoDaPubblicare Documento {
            get {
                return this.documentoField;
            }
            set {
                this.documentoField = value;
            }
        }
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(Namespace="http://valueteam.com/AlboTelematico")]
    public partial class DocumentoDaPubblicare {
        
        private string idDocumentoField;
        
        private string statoDocumentoField;
        
        private AttributoProfilo[] attributiProfiloField;
        
        private FileDaPubblicare documentoPrincipaleField;
        
        private FileDaPubblicare[] allegatiField;
        
        /// <remarks/>
        public string IdDocumento {
            get {
                return this.idDocumentoField;
            }
            set {
                this.idDocumentoField = value;
            }
        }
        
        /// <remarks/>
        public string StatoDocumento {
            get {
                return this.statoDocumentoField;
            }
            set {
                this.statoDocumentoField = value;
            }
        }
        
        /// <remarks/>
        public AttributoProfilo[] AttributiProfilo {
            get {
                return this.attributiProfiloField;
            }
            set {
                this.attributiProfiloField = value;
            }
        }
        
        /// <remarks/>
        public FileDaPubblicare DocumentoPrincipale {
            get {
                return this.documentoPrincipaleField;
            }
            set {
                this.documentoPrincipaleField = value;
            }
        }
        
        /// <remarks/>
        public FileDaPubblicare[] Allegati {
            get {
                return this.allegatiField;
            }
            set {
                this.allegatiField = value;
            }
        }
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(Namespace="http://valueteam.com/AlboTelematico")]
    public partial class AttributoProfilo {
        
        private string nomeField;
        
        private string valoreField;
        
        /// <remarks/>
        public string Nome {
            get {
                return this.nomeField;
            }
            set {
                this.nomeField = value;
            }
        }
        
        /// <remarks/>
        public string Valore {
            get {
                return this.valoreField;
            }
            set {
                this.valoreField = value;
            }
        }
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.1")]
    [System.SerializableAttribute()]
    [System.Diagnostics.DebuggerStepThroughAttribute()]
    [System.ComponentModel.DesignerCategoryAttribute("code")]
    [System.Xml.Serialization.XmlTypeAttribute(Namespace="http://valueteam.com/AlboTelematico")]
    public partial class FileDaPubblicare {
        
        private string nomeFileField;
        
        private byte[] contenutoField;
        
        /// <remarks/>
        public string NomeFile {
            get {
                return this.nomeFileField;
            }
            set {
                this.nomeFileField = value;
            }
        }
        
        /// <remarks/>
        [System.Xml.Serialization.XmlElementAttribute(DataType="base64Binary")]
        public byte[] Contenuto {
            get {
                return this.contenutoField;
            }
            set {
                this.contenutoField = value;
            }
        }
    }
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.1")]
    public delegate void PubblicaConRevocaCompletedEventHandler(object sender, System.ComponentModel.AsyncCompletedEventArgs e);
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.1")]
    public delegate void PubblicaSenzaRevocaCompletedEventHandler(object sender, System.ComponentModel.AsyncCompletedEventArgs e);
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.1")]
    public delegate void AnnullaPubblicazioneCompletedEventHandler(object sender, System.ComponentModel.AsyncCompletedEventArgs e);
    
    /// <remarks/>
    [System.CodeDom.Compiler.GeneratedCodeAttribute("wsdl", "4.0.30319.1")]
    public delegate void RevocaPubblicazioneCompletedEventHandler(object sender, System.ComponentModel.AsyncCompletedEventArgs e);
}
