﻿//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//     Runtime Version:4.0.30319.296
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace Subscriber.AlboTelematico {
    using System;
    
    
    /// <summary>
    ///   A strongly-typed resource class, for looking up localized strings, etc.
    /// </summary>
    // This class was auto-generated by the StronglyTypedResourceBuilder
    // class via a tool like ResGen or Visual Studio.
    // To add or remove a member, edit your .ResX file then rerun ResGen
    // with the /str option, or rebuild your VS project.
    [global::System.CodeDom.Compiler.GeneratedCodeAttribute("System.Resources.Tools.StronglyTypedResourceBuilder", "4.0.0.0")]
    [global::System.Diagnostics.DebuggerNonUserCodeAttribute()]
    [global::System.Runtime.CompilerServices.CompilerGeneratedAttribute()]
    internal class ErrorDescriptions {
        
        private static global::System.Resources.ResourceManager resourceMan;
        
        private static global::System.Globalization.CultureInfo resourceCulture;
        
        [global::System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("Microsoft.Performance", "CA1811:AvoidUncalledPrivateCode")]
        internal ErrorDescriptions() {
        }
        
        /// <summary>
        ///   Returns the cached ResourceManager instance used by this class.
        /// </summary>
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
        internal static global::System.Resources.ResourceManager ResourceManager {
            get {
                if (object.ReferenceEquals(resourceMan, null)) {
                    global::System.Resources.ResourceManager temp = new global::System.Resources.ResourceManager("Subscriber.AlboTelematico.ErrorDescriptions", typeof(ErrorDescriptions).Assembly);
                    resourceMan = temp;
                }
                return resourceMan;
            }
        }
        
        /// <summary>
        ///   Overrides the current thread's CurrentUICulture property for all
        ///   resource lookups using this strongly typed resource class.
        /// </summary>
        [global::System.ComponentModel.EditorBrowsableAttribute(global::System.ComponentModel.EditorBrowsableState.Advanced)]
        internal static global::System.Globalization.CultureInfo Culture {
            get {
                return resourceCulture;
            }
            set {
                resourceCulture = value;
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to Si è verificato un errore nell&apos; invocazione del servizio di ALT per notificare la presenza di un documento da PUBBLICARE/ANNULLARE/REVOCARE.
        /// </summary>
        internal static string ALBO_TELEMATICO_SERVICES_ERROR {
            get {
                return ResourceManager.GetString("ALBO_TELEMATICO_SERVICES_ERROR", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to L&apos;estensione del file deve essere di tipo PDF.
        /// </summary>
        internal static string EXTENSION_FILE_ERROR {
            get {
                return ResourceManager.GetString("EXTENSION_FILE_ERROR", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to I campi Durata e Numero Atto devono essere di tipo numerico.
        /// </summary>
        internal static string FORMAT_NUMBER_ERROR {
            get {
                return ResourceManager.GetString("FORMAT_NUMBER_ERROR", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to .
        /// </summary>
        internal static string REVOCATION_DOCUMENT_ERROR {
            get {
                return ResourceManager.GetString("REVOCATION_DOCUMENT_ERROR", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to Il documento non si trova in uno stato che genera notifica ad ALT (PUBBLICARE/ANNULLARE/REVOCARE).
        /// </summary>
        internal static string STATE_DISCARDS_ERROR {
            get {
                return ResourceManager.GetString("STATE_DISCARDS_ERROR", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to Il documento non può essere annullato perchè pubblicato da più di 5 giorni.
        /// </summary>
        internal static string VOID_DOCUMENT_ERROR {
            get {
                return ResourceManager.GetString("VOID_DOCUMENT_ERROR", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to Si è verificato un errore nel reperimento del token di autenticazione tramite i nuovi WS lato PITRE.
        /// </summary>
        internal static string WS_GET_AUTHENTICATION_TOKEN_ERROR {
            get {
                return ResourceManager.GetString("WS_GET_AUTHENTICATION_TOKEN_ERROR", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to Si è verificato un errore nell&apos; invocazione del servizio PITRE GetDocument.
        /// </summary>
        internal static string WS_GETDOCUMENT_ERROR {
            get {
                return ResourceManager.GetString("WS_GETDOCUMENT_ERROR", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to Si è verificato un errore nella modifica del diagramma di stato tramite i nuovi WS lato PITRE.
        /// </summary>
        internal static string WS_MODIFY_DIAGRAM_STATE_ERROR {
            get {
                return ResourceManager.GetString("WS_MODIFY_DIAGRAM_STATE_ERROR", resourceCulture);
            }
        }
        
        /// <summary>
        ///   Looks up a localized string similar to Si è verificato un errore nella modifica della tipologia atto tramite i nuovi WS lato PITRE.
        /// </summary>
        internal static string WS_MODIFY_TEMPLATE_ERROR {
            get {
                return ResourceManager.GetString("WS_MODIFY_TEMPLATE_ERROR", resourceCulture);
            }
        }
    }
}
