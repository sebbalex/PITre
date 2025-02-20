using System;
using System.Xml;
using System.Collections;
using System.Collections.Generic;
using SAAdminTool.utils;
using SAAdminTool.DocsPaWR;

namespace AmmUtils
{
    /// <summary>
    /// Summary description for WebServiceLink.
    /// </summary>
    public class WebServiceLink
    {
        public WebServiceLink()
        {
        }

        #region Login

        private SAAdminTool.DocsPaWR.DocsPaWebService _WS = null;

        protected SAAdminTool.DocsPaWR.DocsPaWebService WS
        {
            get
            {
                if (this._WS == null)
                {
                    this._WS = new SAAdminTool.DocsPaWR.DocsPaWebService();
                    this._WS.Timeout = System.Threading.Timeout.Infinite;
                }

                return this._WS;
            }
        }

        //public SAAdminTool.DocsPaWR.EsitoOperazione Login(string userid, string password)
        //{
        //    SAAdminTool.DocsPaWR.EsitoOperazione esito = new SAAdminTool.DocsPaWR.EsitoOperazione();
        //    return this.WS.LoginAmministratore(userid, password, string.Empty);
        //}

        public SAAdminTool.DocsPaWR.EsitoOperazione Login(SAAdminTool.DocsPaWR.UserLogin userLogin, bool forceLogin, out SAAdminTool.DocsPaWR.InfoUtenteAmministratore infoUtente)
        {
            SAAdminTool.DocsPaWR.EsitoOperazione esito = new SAAdminTool.DocsPaWR.EsitoOperazione();
            return this.WS.LoginAmministratoreProfilato(userLogin, forceLogin, out infoUtente);
        }

        //public SAAdminTool.DocsPaWR.EsitoOperazione UpdateLoginAmministrazione(string userid, string sessionID)
        //{
        //    SAAdminTool.DocsPaWR.EsitoOperazione esito = new SAAdminTool.DocsPaWR.EsitoOperazione();
        //    return this.WS.UpdateLoginAmministrazione(userid, sessionID);
        //}

        public SAAdminTool.DocsPaWR.InfoAmministrazione GetInfoAmmAppartenenzaUtente(string userid, string pwd)
        {
            return this.WS.GetInfoAmmAppartenenzaUtente(userid, pwd);
        }

        public void Logout(SAAdminTool.DocsPaWR.InfoUtenteAmministratore adminUser)
        {
            this.WS.LogoutAmministratore(adminUser);
        }

        public bool CheckLogin(string user)
        {
            bool result = false;
            //
            //result=this.WS.CheckAdministrator(user);
            return result;
        }

        public bool CheckSession(string sessionID)
        {
            bool result = false;
            result = this.WS.AmmCheckSessionID(sessionID);
            return result;
        }

        #endregion

        #region Cambia password

        /// <summary>
        /// Cambia la password dell'amministratore corrente
        /// </summary>
        /// <param name="userId">Userid</param>
        /// <param name="password">Nuova password</param>
        /// <returns></returns>
        public bool CambiaPwd(string userId, string password)
        {

            return this.WS.CambiaPwdAmministratore(userId, password);
        }

        /// <summary>
        /// Modifica della password per l'utente amministratore
        /// </summary>
        /// <param name="newPassword"></param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.ValidationResultInfo AdminChangePassword(string newPassword)
        {
            SAAdminTool.DocsPaWR.UserLogin userLogin = CreateUserLoginCurrentUser(newPassword);
            userLogin.Modulo = "Amministrazione";
            return this.WS.AdminChangePassword(userLogin, string.Empty);
        }

        /// <summary>
        /// Creazione oggetto "UserLogin" a partire dai metadati dalla sessione utente corrente
        /// </summary>
        /// <param name="password">La password deve essere fornita dall'utente, in quanto non � mantenuta nella sessione</param>
        /// <returns></returns>
        private SAAdminTool.DocsPaWR.UserLogin CreateUserLoginCurrentUser(string password)
        {
            SAAdminTool.DocsPaWR.UserLogin userLogin = null;

            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();

            SAAdminTool.DocsPaWR.InfoUtente infoUtente = sessionManager.getUserAmmSession();

            if (infoUtente != null)
            {
                userLogin = new SAAdminTool.DocsPaWR.UserLogin();
                userLogin.SystemID = infoUtente.idPeople;
                userLogin.UserName = infoUtente.userId;
                userLogin.Password = password;
                userLogin.IdAmministrazione = infoUtente.idAmministrazione;
                userLogin.DST = infoUtente.dst;
                userLogin.IPAddress = System.Web.HttpContext.Current.Request.UserHostAddress;
            }

            return userLogin;
        }

        #endregion

        #region Download dei file XML

        #region GADAMO: ipotesi di gestione diversa del file XML del titolario
        //		/// <summary>
        //		/// Download del file XML della Security
        //		/// </summary>
        //		/// <returns></returns>
        //		public XmlDocument DownloadSecurity()
        //		{
        //			XmlDocument doc = null;
        //
        //			DOCSPAWebService.DocsPaWebService ws=new DOCSPAWebService.DocsPaWebService();
        //			this.WS.Timeout = 3600000; //1 ora in ms
        //			string xml=this.WS.ExportSecurity();
        //			if(xml!=null)
        //			{
        //				doc=new XmlDocument();
        //				doc.LoadXml(xml);
        //			}
        //			return doc;
        //		}
        #endregion

        /// <summary>
        /// Download del file XML del Titolario
        /// </summary>
        /// <returns></returns>
        public XmlDocument DownloadTitolario()
        {
            XmlDocument doc = null;

            string xml = this.WS.ExportTitolario();
            if (xml != null)
            {
                doc = new XmlDocument();
                doc.LoadXml(xml);
            }
            return doc;
        }

        /// <summary>
        /// Download del file XML dell'Amministrazione
        /// </summary>
        /// <returns></returns>
        public XmlDocument DownloadAmministrazione()
        {
            XmlDocument doc = null;

            string xml = this.WS.ExportAmministrazioni();
            if (xml != null)
            {
                doc = new XmlDocument();
                doc.LoadXml(xml);
            }
            return doc;
        }

        #endregion

        #region Upload dei file XML
        /// <summary>
        /// Upload dei file XML
        /// </summary>
        /// <param name="doc">XmlDocument</param>
        /// <returns></returns>
        /*
		public void UploadData(XmlDocument docAmm, XmlDocument docTitolario)
		{
            
			//this.WS.BeginUpdateData(docAmm.OuterXml, docTitolario.OuterXml, null, null);
			this.WS.BeginUpdateData(docAmm.OuterXml, null, null, null);
			this.WS.Dispose();
		}
        */
        /// <summary>
        /// Ritorna lo stato dell'upload dei file XML
        /// </summary>
        /// <returns></returns>
        public string GetUploadStatus()
        {
            string result = this.WS.RefreshAmministrazione();

            return result;
        }
        #endregion

        #region gestione utenti

        /// <summary>
        /// 
        /// </summary>
        /// <param name="codiceAmm"></param>
        /// <returns></returns>
        public string ElencoUtentiConnessi(string codiceAmm)
        {
            string result = null;

            this.WS.Timeout = 3600000; //1 ora in ms
            result = this.WS.ElencoUtentiConnessi(codiceAmm);

            return result;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="codiceAmm"></param>
        /// <returns></returns>
        public int NumeroUtentiConnessi(string codiceAmm)
        {
            int result = 0;

            this.WS.Timeout = 3600000; //1 ora in ms
            result = this.WS.NumUtentiConnessi(codiceAmm);

            return result;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="codiceAmm"></param>
        /// <returns></returns>
        public int NumeroUtentiAttivi(string codiceAmm)
        {
            int result = 0;

            this.WS.Timeout = 3600000; //1 ora in ms
            result = this.WS.NumUtentiAttivi(codiceAmm);

            return result;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="codiceAmm"></param>
        /// <param name="userId"></param>
        /// <returns></returns>
        public bool DisconnettiUtente(string codiceAmm, string userId)
        {
            bool result = true;

            result = this.WS.DisconnettiUtente(userId, codiceAmm);

            return result;
        }

        #endregion

        #region gestione ruoli

        /// <summary>
        /// sposta un ruolo da una uo ad un'altra
        /// </summary>
        /// <param name="codRuolo">codice del ruolo da spostare</param>
        /// <param name="codAmm">codice Amm.ne</param>
        /// <param name="codNewUO">codice della nuova UO nella quale deve essere spostato il ruolo</param>
        /// <returns>bool</returns>
        public bool MoveRoleToNewUO(string codRuolo, string codAmm, string codNewUO, string descNewUO, string codTipoRuolo, string descTipoRuolo, string codNewRuolo, string descNewRuolo)
        {
            bool result = false;



            result = this.WS.MoveRoleToNewUO(codRuolo, codAmm, codNewUO, descNewUO, codTipoRuolo, descTipoRuolo, codNewRuolo, descNewRuolo);

            return result;
        }

        #endregion

        #region gestione log

        public string[] ListaFilesLog(string codAmm)
        {
            string[] files = null;

            this.WS.Timeout = 3600000; //1 ora in ms
            files = this.WS.GetFilesLog(codAmm);
            return files;
        }

        /// <summary>
        /// stampa pdf dei log
        /// </summary>
        /// <param name="codAmm"></param>
        /// <returns></returns>
        public bool stampaLog(string codAmm, string type)
        {
            bool result = false;

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            result = this.WS.StampaPDFLog(codAmm, type);
            return result;
        }

        /// <summary>
        /// conta quanti record di log ci sono sul db
        /// </summary>
        /// <returns></returns>
        public string ContaArchivio(string codAmm, string type)
        {

            string result = this.WS.ContaLog(codAmm, type);
            return result;
        }

        public string VerificaArchivioLogPath()
        {

            string result = this.WS.VerificaArchivioLogPath();
            return result;
        }

        public string VerificaArchivioLogPathAmm()
        {

            string result = this.WS.VerificaArchivioLogPathAmm();
            return result;
        }

        /// <summary>
        /// Prende il file XML dei log sul WS (per le abilitazioni)
        /// </summary>
        /// <returns>string stream</returns>
        public string GetXmlLog(string codAmm)
        {

            this.WS.Timeout = 3600000; //1 ora in ms
            string result = this.WS.GetXMLLog(codAmm);
            return result;
        }

        /// <summary>
        /// Prende il file XML dei log sul WS (per le abilitazioni)
        /// </summary>
        /// <returns>string stream</returns>
        public string GetXmlLogAmm(string codAmm)
        {

            this.WS.Timeout = 3600000; //1 ora in ms
            string result = this.WS.GetXMLLogAmm(codAmm);
            return result;
        }

        /// <summary>
        /// setta il file XML dei log sul WS (per le abilitazioni)
        /// </summary>
        /// <param name="streamXml">stream Xml</param>
        /// <returns>bool: true=esito positivo, false=esito negativo</returns>
        public bool SetXmlLog(string streamXml, string codAmm)
        {
            bool result = this.WS.SetXMLLog(streamXml, codAmm);

            return result;
        }

        /// <summary>
        /// setta il file XML dei log sul WS (per le abilitazioni) di amministrazione
        /// </summary>
        /// <param name="streamXml">stream Xml</param>
        /// <returns>bool: true=esito positivo, false=esito negativo</returns>
        public bool SetXmlLogAmm(string streamXml, string codAmm)
        {
            bool result = this.WS.SetXMLLogAmm(streamXml, codAmm);

            return result;
        }
        
        /// <summary>
        /// metodo per eseguire query sui log, dati alcuni filtri. Restituisce un file xml
        /// </summary>
        /// <param name="dataDa">data da:</param>
        /// <param name="dataA">data a:</param>
        /// <param name="user">userid operatore</param>
        /// <param name="oggetto">oggetto del log</param>
        /// <param name="azione">azione del log</param>
        /// <param name="codAmm">codice amm.ne</param>
        /// <returns>stream xml</returns>
        public string GetXmlLogFiltrato(string dataDa, string dataA, string user, string oggetto, string azione, string codAmm, string esito, string type, int table)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;
            string result = this.WS.GetXMLLogFiltrato(dataDa, dataA, user, oggetto, azione, codAmm, esito, type, table);

            return result;
        }

        #endregion

        #region gestione qualifiche

        public SAAdminTool.DocsPaWR.Qualifica[] GetQualifiche(int id_amm)
        {
            SAAdminTool.DocsPaWR.Qualifica[] qualifiche = this.WS.GetQualifiche(id_amm);
            return qualifiche;
        }

        public SAAdminTool.DocsPaWR.ValidationResultInfo InsertQual(SAAdminTool.DocsPaWR.Qualifica qual)
        {
            SAAdminTool.DocsPaWR.ValidationResultInfo retValue = this.WS.InsertQual(qual);
            return retValue;
        }

        public SAAdminTool.DocsPaWR.ValidationResultInfo UpdateQual(String idQualifica, String descrizione)
        {
            SAAdminTool.DocsPaWR.ValidationResultInfo retValue = this.WS.UpdateQual(idQualifica, descrizione);
            return retValue;
        }

        public SAAdminTool.DocsPaWR.ValidationResultInfo DeleteQual(String idQualifica, int idAmministrazione)
        {
            SAAdminTool.DocsPaWR.ValidationResultInfo retValue = this.WS.DeleteQual(idQualifica, idAmministrazione);
            return retValue;
        }

        public SAAdminTool.DocsPaWR.PeopleGroupsQualifiche[] GetPeopleGroupsQualifiche(String idAmm, String idUo, String idGruppo, String idPeople)
        {
            SAAdminTool.DocsPaWR.PeopleGroupsQualifiche[] pgqs = this.WS.GetPeopleGroupsQualifiche(idAmm, idUo, idGruppo, idPeople);
            return pgqs;
        }

        public SAAdminTool.DocsPaWR.ValidationResultInfo InsertPeopleGroupsQual(SAAdminTool.DocsPaWR.PeopleGroupsQualifiche pgq)
        {
            SAAdminTool.DocsPaWR.ValidationResultInfo retValue = this.WS.InsertPeopleGroupsQual(pgq);
            return retValue;
        }

        public SAAdminTool.DocsPaWR.ValidationResultInfo DeletePeopleGroups(String idPeopleGroups)
        {
            SAAdminTool.DocsPaWR.ValidationResultInfo retValue = this.WS.DeletePeopleGroups(idPeopleGroups);
            return retValue;
        }

        #endregion

        #region AMMINISTRAZIONI

        public string AmmGetIDAmm(string codAmm)
        {
            string result = this.WS.AmmGetIDAmm(codAmm);
            return result;
        }

        public ArrayList AmmGetListAmministrazioni()
        {
            SAAdminTool.DocsPaWR.InfoAmministrazione[] array = this.WS.AmmGetListAmministrazioni();

            ArrayList result = new ArrayList(array);

            return result;
        }

        public SAAdminTool.DocsPaWR.InfoAmministrazione GetInfoAmmCorrente(string idAmm)
        {
            SAAdminTool.DocsPaWR.InfoAmministrazione currAmm = this.WS.AmmGetInfoAmmCorrente(idAmm);
            return currAmm;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsertAmm(ref SAAdminTool.DocsPaWR.InfoAmministrazione info)
        {
            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();
            
            return this.WS.AmmInsertAmm(ref info, sessionManager.getUserAmmSession());
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmUpdateAmm(ref SAAdminTool.DocsPaWR.InfoAmministrazione info, bool modFascicolatura, bool modSegnatura, bool modTimbroPdf, bool modProtTit)
        {
            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();

            return this.WS.AmmUpdateAmm(ref info, sessionManager.getUserAmmSession(), modFascicolatura, modSegnatura, modTimbroPdf, modProtTit);
        }

        public bool IsEnabldRF(string idamm)
        {

            return this.WS.IsEnabledRF(idamm);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmDeleteAmm(ref SAAdminTool.DocsPaWR.InfoAmministrazione info)
        {
            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();

            return this.WS.AmmDeleteAmm(ref info, sessionManager.getUserAmmSession());
        }

        public string GetFormatoDominio(string idAmministrazione)
        {
            return this.WS.GetFormatoDominio(idAmministrazione);
        }


        #endregion

        #region TITOLARIO

        public string NodoTitolario(string codAmm, string idParent)
        {

            string result = this.WS.NodoTitolario(codAmm, idParent);
            return result;
        }
        public string RegistriInAmm(string codAmm)
        {

            string result = this.WS.RegistriInAmm(codAmm);
            return result;
        }

        public string RegistriInAmmRestricted(string sessionID)
        {

            string result = this.WS.RegistriInAmmRestricted(sessionID);
            return result;
        }

        public string Security_NodoRuoli(string idNodo, string codAmm)
        {

            string result = this.WS.SecurityNodoRuoli(idNodo, codAmm);
            return result;
        }

        public SAAdminTool.DocsPaWR.OrgNodoTitolario[] AmmGetNodiTitolario(string codiceAmministrazione, string idNodoTitolarioParent, string idRegistro)
        {

            return this.WS.AmmGetNodiTitolario(codiceAmministrazione, idNodoTitolarioParent, idRegistro);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmCanUpdateRuoloTitolario(string idTitolario, SAAdminTool.DocsPaWR.OrgRuoloTitolario ruoloTitolario)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            return this.WS.AmmCanUpdateRuoloTitolario(idTitolario, ruoloTitolario);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione[] AmmUpdateRuoliTitolario(string idTitolario, string idAmm, bool AllTitolario, SAAdminTool.DocsPaWR.OrgRuoloTitolario[] ruoliTitolario, SAAdminTool.DocsPaWR.OrgRuoloTitolario[] ruoliTitolarioDisattiva,string idRegistro)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;

            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();
            return this.WS.AmmUpdateRuoliTitolario(sessionManager.getUserAmmSession(), idTitolario, ruoliTitolario, ruoliTitolarioDisattiva, idAmm, AllTitolario, idRegistro);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmCanInsertTitolario(SAAdminTool.DocsPaWR.OrgNodoTitolario nodoTitolario)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            return this.WS.AmmCanInsertTitolario(nodoTitolario);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsertTitolario(ref SAAdminTool.DocsPaWR.OrgNodoTitolario nodoTitolario, string idAmm)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;

            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();
            return this.WS.AmmInsertTitolario(sessionManager.getUserAmmSession(), ref nodoTitolario, idAmm);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmCanUpdateTitolario(SAAdminTool.DocsPaWR.OrgNodoTitolario nodoTitolario)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            return this.WS.AmmCanUpdateTitolario(nodoTitolario);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmUpdateTitolario(SAAdminTool.DocsPaWR.OrgNodoTitolario nodoTitolario)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;

            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();
            return this.WS.AmmUpdateTitolario(sessionManager.getUserAmmSession(), nodoTitolario);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmCanDeleteTitolario(SAAdminTool.DocsPaWR.OrgNodoTitolario nodoTitolario)
        {

            return this.WS.AmmCanDeleteTitolario(nodoTitolario);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmDeleteTitolario(SAAdminTool.DocsPaWR.OrgNodoTitolario nodoTitolario)
        {
            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();
            return this.WS.AmmDeleteTitolario(sessionManager.getUserAmmSession(), nodoTitolario);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmExtendToChildNodes(string idNodoTitolario, SAAdminTool.DocsPaWR.OrgRuoloTitolario ruoloTitolario, string idAmm, string idRegistro, bool check)
        {
            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();

            return this.WS.AmmExtendToChildNodes(sessionManager.getUserAmmSession(), idNodoTitolario, ruoloTitolario, idAmm, idRegistro, check);
        }

        public string filtroRicerca(string codice, string descrizione, string codAmm, string idRegistro)
        {

            string result = this.WS.filtroRicercaTitAmm(codice, descrizione, codAmm, idRegistro);
            return result;
        }

        public string RicercaNodoRoot(string idrecord, string idparent, int livello)
        {

            string result = this.WS.findNodoRoot(idrecord, idparent, livello);
            return result;
        }

        public string AggiungeNewNodo(string padre, string codice, string descrizione, string idregistro, string livello, string codAmm, string codliv, string r_w)
        {

            string result = this.WS.AggNewNodo(padre, codice, descrizione, idregistro, livello, codAmm, codliv, r_w);
            return result;
        }

        public string CancellaNodo(string idrecord)
        {

            string result = this.WS.EliminaNodo(idrecord);
            return result;
        }

        public string PrendeCodLiv(string codliv, string livello, string codAmm, string idTitolario, string idRegistro)
        {

            string result = this.WS.GetCodLiv(codliv, livello, codAmm, idTitolario, idRegistro);
            return result;
        }

        public string spostaNodo(string currentCodLiv, string newCodLiv, string codAmm, string idRegistro)
        {

            string result = this.WS.SpostaNodoTitolario(currentCodLiv, newCodLiv, codAmm, idRegistro);
            return result;
        }

        public string GetDataFromProject(string field, string condition)
        {

            string result = this.WS.DataFromProject(field, condition);
            return result;
        }

        public string isEnableContatoreTitolario()
        {
            return WS.isEnableContatoreTitolario();
        }

        public string isEnableProtocolloTitolario()
        {
            return WS.isEnableProtocolloTitolario();
        }

        public bool isEnableRiferimentiMittente()
        {
            return WS.isEnableRiferimentiMittente();
        }

        #endregion

        #region ORGANIGRAMMA

        public SAAdminTool.DocsPaWR.OrgUO AmmGetDatiUOCorrente(string idUO)
        {

            SAAdminTool.DocsPaWR.OrgUO currentUO = this.WS.AmmGetDatiUOCorrente(idUO);

            return currentUO;
        }

        public ArrayList AmmGetListUO(string idParent, string livello, string idAmm)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgUO[] array = this.WS.AmmGetListUO(idParent, livello, idAmm);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListUOInReg(string idRegistro, string tipoRicerca, string ricerca)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgUO[] array = this.WS.AmmGetListUOInReg(idRegistro, tipoRicerca, ricerca);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListRuoliUO(string idUO)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgRuolo[] array = this.WS.AmmGetListRuoliUO(idUO);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListRuoliUORic(string idUO, bool ricorsivo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgRuolo[] array = this.WS.AmmGetListRuoliUORic(idUO, ricorsivo);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListaUoFiglie(SAAdminTool.DocsPaWR.OrgUO uo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            String[] array = this.WS.GetListaParentUo(uo.IDCorrGlobale, uo.Livello);
            ArrayList listaUoFiglie = new ArrayList(array);
            return listaUoFiglie;
        }

        public ArrayList AmmGetListUtentiRuolo(string idRuolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgUtente[] array = this.WS.AmmGetListUtentiRuolo(idRuolo);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListUtenti(string idAmm, string ricercaPer, string testoDaRicercare, string IDesclusi)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgUtente[] array = this.WS.AmmGetListUtenti(idAmm, ricercaPer, testoDaRicercare, IDesclusi);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListUtenti(string idAmm, string ricercaPer, string testoDaRicercare)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgUtente[] array = this.WS.AmmGetListUtentiInAmmRic(idAmm, ricercaPer, testoDaRicercare);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListUtenti(string idAmm)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgUtente[] array = this.WS.AmmGetListUtentiInAmm(idAmm);

            ArrayList result = new ArrayList(array);

            return result;
        }

        /// <summary>
        /// Ritorna la lista di Registri o RF, o entrambi a seconda del valore di chaRF
        /// </summary>
        /// <param name="idAmm"></param>
        /// <param name="idRuolo"></param>
        /// <param name="chaRF">0, sono registri, 1 solo RF, "" entrambi</param>
        /// <returns></returns>
        public ArrayList AmmGetListRegistriRF(string idAmm, string idRuolo, string chaRF)
        {

            SAAdminTool.DocsPaWR.OrgRegistro[] array = this.WS.AmmGetListRegistriRF(idAmm, idRuolo, chaRF);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListRegistriAssRuolo(string idAmm, string idRuolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgRegistro[] array = this.WS.AmmGetListRegistriAssRuolo(idAmm, idRuolo);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListFunzioni(string idAmm, string idRuolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgTipoFunzione[] array = this.WS.AmmGetListFunzioni(idAmm, idRuolo);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListTipiRuolo(string idAmm)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgTipoRuolo[] array = this.WS.AmmGetListTipiRuolo(idAmm);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListRuoliUtente(string idPeople)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgRuolo[] array = this.WS.AmmGetListRuoliUtente(idPeople);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmGetListRegistriUtente(string idCorrGlob, string idAmm)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgRegistro[] array = this.WS.AmmGetListRegistriUtente(idAmm, idCorrGlob);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsRegistriUtente(SAAdminTool.DocsPaWR.OrgRegistro[] listaRegistri, string idCorrGlob)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmInsRegistriUtenteAdmin(listaRegistri, idCorrGlob);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmEliminaRegistriUtente(string idCorrGlob)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmEliminaRegistriUtenteAdmin(idCorrGlob);

            return esito;
        }

        public bool AmmCheckRegAssUtente(string idCorrGlob)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            return this.WS.AmmCheckRegAssUtente(idCorrGlob);
        }

        public bool AmmIsUtenteRespAOO(string idpeople, string idGruppo)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;
            return this.WS.AmmCheckRespAOO(idpeople, idGruppo);
        }

        public string[] getUtenteRespAOO(string idpeople)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;
            return this.WS.getAmmRespAOO(idpeople);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmImpostaRuoloPreferito(string idPeople, string idGruppo)
        {
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmImpostaRuoloPreferito(this.CurrentInfoUtente, idPeople, idGruppo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.OrgUtente AmmGetDatiUtente(string idCorrGlob)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgUtente utente = this.WS.AmmGetDatiUtente(idCorrGlob);

            return utente;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsNuovaUO(SAAdminTool.DocsPaWR.OrgUO newUO)
        {
            SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmInsNuovaUO(sessionManager.getUserAmmSession(), newUO);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmModUO(SAAdminTool.DocsPaWR.OrgUO theUO, bool StoricizzUO)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmModUO(theUO, StoricizzUO);

            return esito;
        }

        public SAAdminTool.DocsPaWR.Amministrazione AmmModificaUoTIBCO(string oldCodiceUO, SAAdminTool.DocsPaWR.OrgUO theUO, out bool result)
        {

            return this.WS.AmmModificaUoTIBCO(oldCodiceUO, theUO, out result);                
        }

        public SAAdminTool.DocsPaWR.Amministrazione AmmEliminaUoTIBCO(SAAdminTool.DocsPaWR.OrgUO theUO, out bool result)
        {
            return this.WS.AmmEliminaUoTIBCO(theUO, out result);
        }

        public void inviaNotificaMail(SAAdminTool.DocsPaWR.OrgUO theUO, SAAdminTool.DocsPaWR.Amministrazione amm, string descrizioneAOO, string tipoOperazione, string oldCodiceUO)
        {
            this.WS.inviaNotificaMail(theUO, amm, descrizioneAOO, tipoOperazione, oldCodiceUO);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmEliminaUO(SAAdminTool.DocsPaWR.InfoUtente infoUtente, string idCorrGlob)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmEliminaUO(infoUtente, idCorrGlob);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsNuovoRuolo(SAAdminTool.DocsPaWR.OrgRuolo ruolo, bool computeAtipicita)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmInsNuovoRuolo(this.CurrentInfoUtente, ruolo, computeAtipicita);

            return esito;
        }

        //Undo Modifiche Lorusso 22-10-2012
        public SAAdminTool.DocsPaWR.ValidationResultInfo updateChiaveConfig(SAAdminTool.DocsPaWR.ChiaveConfigurazione chiaveConfig)
        {

            SAAdminTool.DocsPaWR.ValidationResultInfo esito = this.WS.updateChiaveConfig(this.CurrentInfoUtente, chiaveConfig);

            return esito;
        }
        //End Undo

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmModRuolo(SAAdminTool.DocsPaWR.OrgRuolo ruolo)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmModRuolo(this.CurrentInfoUtente, ruolo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmOnlyDisabledRole(SAAdminTool.DocsPaWR.OrgRuolo ruolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmOnlyDisabledRole(this.CurrentInfoUtente, ruolo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmEliminaRuolo(SAAdminTool.DocsPaWR.OrgRuolo ruolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmEliminaRuolo(this.CurrentInfoUtente, ruolo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsRegistri(SAAdminTool.DocsPaWR.OrgRegistro[] listaRegistri, string idUo, string idCorrGlobRuolo)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmInsRegistri(listaRegistri, idUo, idCorrGlobRuolo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsTipoFunzioni(SAAdminTool.DocsPaWR.OrgTipoFunzione[] listaFunzioni)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmInsTipoFunzioni(this.CurrentInfoUtente, listaFunzioni);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsUtenteInRuolo(string idPeople, string idGruppo, string idAmm, string type)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmInsUtenteInRuolo(this.CurrentInfoUtente, idPeople, idGruppo, idAmm, type);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsTrasmUtente(string idPeople, string idCorrGlobRuolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmInsTrasmUtente(idPeople, idCorrGlobRuolo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmEliminaUtenteInRuolo(string idPeople, string idGruppo, string idAmm)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmEliminaUtenteInRuolo(this.CurrentInfoUtente, idPeople, idGruppo, idAmm);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmEliminaADLUtente(string idPeople, string idCorrGlobGruppo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmEliminaADLUtente(idPeople, idCorrGlobGruppo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmVerificaUtenteLoggato(string userId, string idAmm)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmVerificaUtenteLoggato(userId, idAmm);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmVerificaUtenteRespStampeRep(string userId, string roleId, string idAmm)
        {
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmVerificaUtenteRespStampaRep(userId, roleId, idAmm);
            //DocsPAWA.DocsPaWR.EsitoOperazione esito = null;
            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmVerificaTrasmRuolo(string idCorrGlobRuolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmVerificaTrasmRuolo(idCorrGlobRuolo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmRifiutaTrasmConWF(string idCorrGlobRuolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmRifiutaTrasmConWF(idCorrGlobRuolo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmSostituzioneUtente(string idPeopleNewUT, string idCorrGlobRuolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmSostituzioneUtente(idPeopleNewUT, idCorrGlobRuolo);

            return esito;
        }

        public ArrayList AmmRicercaInOrg(string tipo, string codice, string descrizione, string idAmm, bool searchHistoricized, bool searchByCodeExact)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgRisultatoRicerca[] array = this.WS.AmmRicercaInOrg(tipo, codice, descrizione, idAmm, searchHistoricized, searchByCodeExact);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public ArrayList AmmListaIDParentRicerca(string IDPartenza, string tipo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            object[] retValue = this.WS.AmmListaIDParentRicerca(IDPartenza, tipo);

            return new ArrayList(retValue);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmModUtente(SAAdminTool.DocsPaWR.OrgUtente utente, string idAmministrazione)
        {
            // Prelevo le informazioni sull'amministratore
            SAAdminTool.DocsPaWR.InfoUtente infoUtente = this.CurrentInfoUtente;

            // Valorizzo il campo idAmministrazione ed il campo idGruppo
            infoUtente.idAmministrazione = idAmministrazione;
            infoUtente.idGruppo = "0";

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmModUtente(infoUtente, utente);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsUtente(SAAdminTool.DocsPaWR.OrgUtente utente, string idAmm)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;

            //string idAmm = AmmUtils.UtilsXml.GetAmmDataSession((string)Session["AMMDATASET"], "3");

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmInsUtente(this.CurrentInfoUtente, idAmm, utente);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmVerificaEliminazioneUtente(SAAdminTool.DocsPaWR.OrgUtente utente)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmVerificaEliminazioneUtente(utente);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmEliminaUtente(SAAdminTool.DocsPaWR.OrgUtente utente)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmEliminaUtente(this.CurrentInfoUtente, utente);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmDisabilitaUtente(string idPeople, string idAmm)
        {
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmDisabilitaUtente(this.CurrentInfoUtente,idPeople, idAmm);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmAbilitaUtente(string idPeople, string idAmm)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmAbilitaUtente(this.CurrentInfoUtente, idPeople, idAmm);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmEstendeVisibRuolo(string idRegistro, string idCorrGlobRuolo, string idGruppo, string idCorrGlobUO, string idAmm, string livelloRuolo, bool escludiAtipicita)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmEstendeVisibRuolo(this.CurrentInfoUtente, idRegistro, idCorrGlobRuolo, idGruppo, idCorrGlobUO, idAmm, livelloRuolo, escludiAtipicita);

            return esito;
        }

        public SAAdminTool.DocsPaWR.OrgDettagliGlobali AmmGetDatiUOStampaBuste(string idCorrGlob)
        {

            return this.WS.AmmGetDatiStampaBuste(idCorrGlob);
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmSpostaRuolo(SAAdminTool.DocsPaWR.OrgRuolo ruolo)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmSpostaRuolo(this.CurrentInfoUtente, ruolo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmSpostaUO(SAAdminTool.DocsPaWR.OrgUO uoDaSpostare, SAAdminTool.DocsPaWR.OrgUO uoPadre)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmSpostaUO(this.CurrentInfoUtente, uoDaSpostare, uoPadre);

            return esito;
        }

        public string GetXMLUOSmistamento(string idRegistro)
        {

            string result = this.WS.GetXMLUOSmistamento(idRegistro);
            return result;
        }

        public bool SetXMLUOSmistamento(string streamXml, string idRegistro)
        {

            bool result = this.WS.SetXMLUOSmistamento(streamXml, idRegistro);

            return result;
        }

        public SAAdminTool.DocsPaWR.FileDocumento AmmStampaOrganigramma(XmlDocument xmlDoc)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.FileDocumento filePdf = this.WS.StampaOrgInPdf(xmlDoc);
            return filePdf;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmOrdinamento(string idCorrGlobDaSpostare, string idPesoDaSpostare, string idCorrGlobSubisce, string idPesoSubisce)
        {
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmOrdinamento(idCorrGlobDaSpostare, idPesoDaSpostare, idCorrGlobSubisce, idPesoSubisce);
            return esito;
        }

        #endregion

        #region TIPI RUOLO

        public ArrayList AmmGetListTipoRuoloUtenti(string codTipoRuolo, string idAmm)
        {

            SAAdminTool.DocsPaWR.OrgRuolo[] array = this.WS.AmmGetListTipoRuoloUtenti(codTipoRuolo, idAmm);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public string GetLivelloTipoRuolo(string idCorrGlobRuolo)
        {

            return this.WS.GetLivelloTipoRuolo(idCorrGlobRuolo);
        }

        #endregion

        #region TIPI FUNZIONI e FUNZIONI

        /// <summary>
        /// Reperimento dei tipi funzione in amministrazione
        /// </summary>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.OrgTipoFunzione[] GetTipiFunzione(bool fillFunzioniElementari, string idAmm)
        {

            return this.WS.AmmGetTipiFunzione(fillFunzioniElementari, idAmm);
        }

        /// <summary>
        /// Reperimento di un tipo funzione in amministrazione
        /// </summary>
        /// <param name="idTipoFunzione"></param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.OrgTipoFunzione GetTipoFunzione(string idTipoFunzione, bool fillFunzioniElementari)
        {

            return this.WS.AmmGetTipoFunzione(idTipoFunzione, fillFunzioniElementari);
        }

        /// <summary>
        /// Inserimento di un nuovo tipo funzione
        /// </summary>
        /// <param name="tipoFunzione"></param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.ValidationResultInfo InsertTipoFunzione(ref SAAdminTool.DocsPaWR.OrgTipoFunzione tipoFunzione)
        {

            return this.WS.AmmInsertTipoFunzione(ref tipoFunzione);
        }

        /// <summary>
        /// Aggiornamento di un tipo funzione
        /// </summary>
        /// <param name="tipoRuolo"></param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.ValidationResultInfo UpdateTipoFunzione(ref SAAdminTool.DocsPaWR.OrgTipoFunzione tipoFunzione)
        {

            return this.WS.AmmUpdateTipoFunzione(ref tipoFunzione);
        }

        /// <summary>
        /// Cancellazione di un tipo funzione
        /// </summary>
        /// <param name="tipoRuolo"></param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.ValidationResultInfo DeleteTipoFunzione(SAAdminTool.DocsPaWR.OrgTipoFunzione tipoFunzione)
        {

            return this.WS.AmmDeleteTipoFunzione(tipoFunzione);
        }

        /// <summary>
        /// Reperimento funzioni in anagrafica
        /// </summary>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.OrgFunzioneAnagrafica[] GetFunzioniAnagrafica()
        {

            return this.WS.AmmGetFunzioniAnagrafica();
        }

        /// <summary>
        /// Reperimento funzioni in tipo funzione
        /// </summary>
        /// <param name="idTipoFunzione"></param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.OrgFunzione[] GetFunzioni(string idTipoFunzione)
        {

            return this.WS.AmmGetFunzioni(idTipoFunzione);
        }

        /// <summary>
        /// Generazione report
        /// </summary>
        /// <param name="tipo"></param>
        /// <param name="idFunzione"></param>
        /// <param name="idAmm"></param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.FileDocumento GetReportFunzioni(string tipo, string formato, string idFunzione, string idAmm)
        {
            return this.WS.AmmGetReportFunzioni(tipo, formato, idFunzione, idAmm);
        }

        /// <summary>
        /// Reperimento di un tipo funzione da codice in amministrazione
        /// </summary>
        /// <param name="codice">codice tipo funzione</param>
        /// <param name="fillFunzioniElementari"></param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.OrgTipoFunzione GetTipoFunzioneByCod(string codice, bool fillFunzioniElementari)
        {
            return this.WS.AmmGetTipoFunzioneByCod(codice, fillFunzioniElementari);
        }

        /// <summary>
        /// Reperimento di una funzione elementare da codice in amministrazione
        /// </summary>
        /// <param name="codice">codice funzione</param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.OrgFunzioneAnagrafica GetFunzioneAnagraficaReport(string codice)
        {
            return this.WS.AmmGetFunzioneAnagrafica(codice);
        }


        #endregion

        #region RAGIONI TRASMISSIONI

        public SAAdminTool.DocsPaWR.OrgRagioneTrasmissione GetRagioneTrasmissione(string idRagione)
        {

            return this.WS.AmmGetRagioneTrasmissione(idRagione);
        }

        public SAAdminTool.DocsPaWR.OrgRagioneTrasmissione[] GetInfoRagioniTrasmissione(string idAmministrazione)
        {

            return this.WS.AmmGetInfoRagioniTrasmissione(idAmministrazione);
        }

        public SAAdminTool.DocsPaWR.OrgRagioneTrasmissione[] GetRagioniTrasmissione(string idAmministrazione)
        {

            return this.WS.AmmGetRagioniTrasmissione(idAmministrazione);
        }

        public SAAdminTool.DocsPaWR.OrgRagioneTrasmissione[] GetRagioniTrasmissione()
        {

            return this.WS.AmmGetRagioniTrasmissioneAnagrafica();
        }

        public SAAdminTool.DocsPaWR.ValidationResultInfo InsertRagioneTrasmissione(ref SAAdminTool.DocsPaWR.OrgRagioneTrasmissione ragione, string idAmm)
        {

            return this.WS.AmmInsertRagioneTrasmissione(this.CurrentInfoUtente, ref ragione, idAmm);
        }

        public SAAdminTool.DocsPaWR.ValidationResultInfo UpdateRagioneTrasmissione(ref SAAdminTool.DocsPaWR.OrgRagioneTrasmissione ragione, string idAmm)
        {

            return this.WS.AmmUpdateRagioneTrasmissione(this.CurrentInfoUtente, ref ragione, idAmm);
        }

        //Federica 30/01/2008
        public SAAdminTool.DocsPaWR.ValidationResultInfo UpdateMessageNotificaRagioneTrasmissione(string codiceRagione, string idAmministrazione, string msgNotificaDocumenti, string msgNotificaFascioli, bool allRagioniDoc, bool allRagioniFasc)
        {

            return this.WS.AmmUpdateMessageNotificaRagioneTrasmissione(codiceRagione, idAmministrazione, msgNotificaDocumenti, msgNotificaFascioli, allRagioniDoc, allRagioniFasc);
        }

        public SAAdminTool.DocsPaWR.ValidationResultInfo DeleteRagioneTrasmissione(ref SAAdminTool.DocsPaWR.OrgRagioneTrasmissione ragione)
        {

            return this.WS.AmmDeleteRagioneTrasmissione(ref ragione);
        }

        #endregion

        #region EXPORT DATI RICERCHE
        public SAAdminTool.DocsPaWR.FileDocumento ExportDoc(SAAdminTool.DocsPaWR.InfoUtente userInfo, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtri, string exportType, string title, SAAdminTool.DocsPaWR.FullTextSearchContext context, ArrayList campiSelezionati, String[] documentsSystemId)
        {
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();


            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportRicercaDoc(userInfo, filtri, exportType, title, context, campiSelezionati.ToArray(), documentsSystemId, GridManager.SelectedGrid, !GridManager.IsRoleEnabledToUseGrids());
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportDocCustom(SAAdminTool.DocsPaWR.InfoUtente userInfo, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtri, string exportType, string title, SAAdminTool.DocsPaWR.FullTextSearchContext context, ArrayList campiSelezionati, String[] documentsSystemId, Field[] visibleFieldsTemplate)
        {
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();


            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportDocCustom(userInfo, filtri, exportType, title, context, campiSelezionati.ToArray(), documentsSystemId, GridManager.SelectedGrid, GridManager.IsRoleEnabledToUseGrids(), visibleFieldsTemplate);
            return file;
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="idGruppo"></param>
        /// <param name="idPeople"></param>
        /// <param name="folder"></param>
        /// <param name="codFascicolo"></param>
        /// <param name="exportType"></param>
        /// <param name="title"></param>
        /// <param name="filtriRicerca"></param>
        /// <param name="campiSelezionati"></param>
        /// <param name="userInfo"></param>
        /// <param name="selectedDocumentsId">Lista degli id dei documenti selezionati</param>
        /// <returns></returns>
        public SAAdminTool.DocsPaWR.FileDocumento ExportDocInFasc(string idGruppo, string idPeople, SAAdminTool.DocsPaWR.Folder folder, string codFascicolo, string exportType, string title, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtriRicerca, ArrayList campiSelezionati, SAAdminTool.DocsPaWR.InfoUtente userInfo, String[] selectedDocumentsId)
        {
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();


            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportRicercaDocInFasc(folder, codFascicolo, exportType, title, filtriRicerca, userInfo, campiSelezionati.ToArray(), GridManager.SelectedGrid, selectedDocumentsId, !GridManager.IsRoleEnabledToUseGrids());
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportDocInCest(SAAdminTool.DocsPaWR.InfoUtente userInfo, string exportType, string title, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtriRicerca, ArrayList campiSelezionati)
        {
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();
            
            
            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportRicercaDocInCest(userInfo, exportType, title, filtriRicerca, campiSelezionati.ToArray());
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportFasc(SAAdminTool.DocsPaWR.InfoUtente userInfo, SAAdminTool.DocsPaWR.Registro registro, bool enableUfficioRef, bool enableProfilazione, bool enableChilds, SAAdminTool.DocsPaWR.FascicolazioneClassificazione classificazione, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtri, string exportType, string title, ArrayList campiSelezionati, String[] objSystemId)
        {
            
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();

            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportRicercaFasc(userInfo, registro, enableUfficioRef, enableProfilazione, enableChilds, classificazione, filtri, exportType, title, campiSelezionati.ToArray(), objSystemId, GridManager.SelectedGrid, !GridManager.IsRoleEnabledToUseGrids());
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportLog(string codAmm, string type, string exportType, string title, string user, string data_a, string data_da, string oggetto, string azione, string esito, int tabelle)
        {

            
            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportLog(codAmm, type, exportType, title, user, data_a, data_da, oggetto, azione, esito, tabelle);
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportTrasm(SAAdminTool.DocsPaWR.TrasmissioneOggettoTrasm oggettoTrasmesso, string tipoRicerca, SAAdminTool.DocsPaWR.Utente utente, SAAdminTool.DocsPaWR.Ruolo ruolo, SAAdminTool.DocsPaWR.FiltroRicerca[] filtri, string exportType, string title, ArrayList campiSelezionati, SAAdminTool.DocsPaWR.InfoUtente userInfo)
        {
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();
            

            
            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportRicercaTrasm(oggettoTrasmesso, tipoRicerca, utente, ruolo, filtri, exportType, title, userInfo, campiSelezionati.ToArray());
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportToDoList(SAAdminTool.DocsPaWR.InfoUtente infoUtente, string docOrFasc, SAAdminTool.DocsPaWR.FiltroRicerca[] filtri, string registri, string exportType, string title, ArrayList campiSelezionati, String[] objectId)
        {
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();

            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportToDoList(infoUtente, docOrFasc, filtri, registri, exportType, title, campiSelezionati.ToArray(), objectId);
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportRubrica(SAAdminTool.DocsPaWR.InfoUtente infoUtente, bool store, string registri)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportRubrica(infoUtente, store, registri);
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportScarto(SAAdminTool.DocsPaWR.InfoUtente userInfo, SAAdminTool.DocsPaWR.InfoScarto infoScarto, string exportType, string title, SAAdminTool.DocsPaWR.FullTextSearchContext context, ArrayList campiSelezionati)
        {
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();

           
            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportScarto(userInfo, infoScarto, exportType, title, context, campiSelezionati.ToArray());
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportDocRicOrder(SAAdminTool.DocsPaWR.InfoUtente userInfo, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtri, string exportType, string title, SAAdminTool.DocsPaWR.FullTextSearchContext context, ArrayList campiSelezionati, String[] documentsSystemId)
        {
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();


            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportDocRicOrder(userInfo, filtri, exportType, title, context, campiSelezionati.ToArray(), documentsSystemId, GridManager.SelectedGrid, !GridManager.IsRoleEnabledToUseGrids());
            return file;
        }

        #endregion

        #region gestione voci menu
        //SABRINA GEST VOCI MENU UTENTE

        public ArrayList AmmGetListMenuUtente(string idCorrGlob, string idAmm)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.Menu[] array = this.WS.AmmGetListMenuUtente(idAmm, idCorrGlob);

            ArrayList result = new ArrayList(array);

            return result;
        }

        public SAAdminTool.DocsPaWR.Menu[] AmmGetListMenuUtenteObj(string idCorrGlob, string idAmm)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.Menu[] result = this.WS.AmmGetListMenuUtente(idAmm, idCorrGlob);

            return result;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmInsMenuUtente(SAAdminTool.DocsPaWR.Menu[] listaMenu, string idCorrGlob, string idAmm)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmInsMenuUtenteAdmin(listaMenu, idCorrGlob, idAmm);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmEliminaMenuUtente(string idCorrGlob)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmEliminaMenuUtenteAdmin(idCorrGlob);

            return esito;
        }

        public bool AmmCheckMenuAssUtente(string idCorrGlob)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            return this.WS.AmmCheckMenuAssUtente(idCorrGlob);
        }

        #endregion

        /// <summary>
        /// Reperimento credenziali utente corrente
        /// </summary>
        protected SAAdminTool.DocsPaWR.InfoUtente CurrentInfoUtente
        {
            get
            {
                SAAdminTool.AdminTool.Manager.SessionManager sessionManager = new SAAdminTool.AdminTool.Manager.SessionManager();
                return sessionManager.getUserAmmSession();
            }
        }

        #region Gestione rf

        public ArrayList AmmGetListRuoli(string idAmm, string ricercaPer, string testoDaRicercare, string idRegistro, string IDesclusi)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgRuolo[] array = this.WS.AmmGetListRuoli(idAmm, ricercaPer, testoDaRicercare, idRegistro, IDesclusi);

            ArrayList result = new ArrayList(array);

            return result;
        }


     /// <summary>
     /// Associazione di un RF a un Ruolo
     /// </summary>
     /// <param name="idRf">systemId dell'RF</param>
     /// <param name="idCorrGlobRuolo">systemId del ruolo (systemId della dpa_corr_globali)</param>
     /// <returns></returns>
        public SAAdminTool.DocsPaWR.EsitoOperazione AmmAssociazioneRFRuolo(string idRf, string idCorrGlobRuolo)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmAssociazioneRFRuolo(idRf, idCorrGlobRuolo);

            return esito;
        }

        public SAAdminTool.DocsPaWR.EsitoOperazione AmmDeleteAssociazioneRFRuolo(string idRf, string idCorrGlobRuolo)
        {

            SAAdminTool.DocsPaWR.EsitoOperazione esito = this.WS.AmmDeleteAssociazioneRFRuolo(idRf, idCorrGlobRuolo);

            return esito;
        }


        /// <summary>
        /// Ritorna una lista di Oggetti OrgRuolo, dove i ruoli sono tutti quelli associati al registro o al RF
        /// passato in ingresso al webServices
        /// </summary>
        /// <param name="idRegistro">SystemId del Registro o dell'RF</param>
        /// <returns>ArrayList di oggetti OrgRuolo</returns>
        public ArrayList AmmGetListaRuoliAOO(string idRegistro)
        {

            this.WS.Timeout = System.Threading.Timeout.Infinite;
            SAAdminTool.DocsPaWR.OrgRuolo[] array = this.WS.AmmGetListaRuoliAOO(idRegistro);

            ArrayList result = new ArrayList(array);

            return result;
        }


        #endregion      
  

        public SAAdminTool.DocsPaWR.OrgRegistro[] AmmGetRegistri(string idAmm, string isRf)
        {
            SAAdminTool.DocsPaWR.OrgRegistro[] result;

            result = this.WS.AmmGetRegistri(idAmm, isRf);

            return result;
        }

        public string AmmGetDispositivoStampaUtente(string idPeople)
        {
            string result;

            result = this.WS.GetDispositivoStampaUtente(idPeople);

            return result;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportFascRicOrder(SAAdminTool.DocsPaWR.InfoUtente userInfo, SAAdminTool.DocsPaWR.Registro registro, bool enableUfficioRef, bool enableProfilazione, bool enableChilds, SAAdminTool.DocsPaWR.FascicolazioneClassificazione classificazione, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtri, string exportType, string title, ArrayList campiSelezionati, String[] objSystemId)
        {

            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();

            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportRicercaFascRicOrder(userInfo, registro, enableUfficioRef, enableProfilazione, enableChilds, classificazione, filtri, exportType, title, campiSelezionati.ToArray(), objSystemId, GridManager.SelectedGrid, !GridManager.IsRoleEnabledToUseGrids());
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportFascCustom(SAAdminTool.DocsPaWR.InfoUtente userInfo, SAAdminTool.DocsPaWR.Registro registro, bool enableUfficioRef, bool enableProfilazione, bool enableChilds, SAAdminTool.DocsPaWR.FascicolazioneClassificazione classificazione, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtri, string exportType, string title, ArrayList campiSelezionati, String[] objSystemId, Field[] visibleFieldsTemplate, bool security)
        {

            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();

            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportRicercaFascCustom(userInfo, registro, enableUfficioRef, enableProfilazione, enableChilds, classificazione, filtri, exportType, title, campiSelezionati.ToArray(), objSystemId, GridManager.SelectedGrid, GridManager.IsRoleEnabledToUseGrids(), visibleFieldsTemplate,security);
            return file;
        }

        public SAAdminTool.DocsPaWR.FileDocumento ExportDocInFascCustom(
            SAAdminTool.DocsPaWR.InfoUtente userInfo, SAAdminTool.DocsPaWR.Folder folder, string codFascicolo, string exportType, string title, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtriRicerca, ArrayList campiSelezionati, String[] selectedDocumentsId, Field[] visibleFieldsTemplate, SAAdminTool.DocsPaWR.FiltroRicerca[][] filtriRicercaOrdinamento)
        {
            if (campiSelezionati == null)
                campiSelezionati = new ArrayList();


            SAAdminTool.DocsPaWR.FileDocumento file = this.WS.ExportRicercaDocInFascCustom(folder, codFascicolo, exportType, title, filtriRicerca, userInfo, campiSelezionati.ToArray(), selectedDocumentsId, GridManager.SelectedGrid, GridManager.IsRoleEnabledToUseGrids(), visibleFieldsTemplate, filtriRicercaOrdinamento);
            return file;
        }

        /// <summary>
        /// Metodo per lo spostamento di un ruolo da una uo ad un'altra
        /// </summary>
        /// <param name="request">Informazioni sul ruolo da spostare</param>
        /// <returns>Risultato dell'elaborazione</returns>
        public SAAdminTool.DocsPaWR.SaveChangesToRoleResponse SaveChangesToRole(SAAdminTool.DocsPaWR.SaveChangesToRoleRequest request)
        {
            request.UserInfo = this.CurrentInfoUtente;
            SAAdminTool.DocsPaWR.SaveChangesToRoleResponse esito = this.WS.SaveChangesToRole(request);

            return esito;

        }

        public EsitoOperazione CopyVisibility(InfoUtente infoUtente, CopyVisibility copyVisibility)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;
            return this.WS.CopyVisibility(infoUtente, copyVisibility);
        }

        public OrgRuolo GetRole(String idCorrGlobale)
        {
            return this.WS.GetRole(idCorrGlobale);
        }

        public bool AmmVerificaGestioneChiavi(string idPeople)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;
            return this.WS.AmmVerificaGestioneChiavi(idPeople);
        }

        #region Autenticazione Sistemi Esterni
        public SistemaEsterno[] getSistemiEsterni(string idAmm)
        {
            return this.WS.AmmGetSistemiEsterni(idAmm);
        }

        public MetodoPIS[] getPISMethods()
        {
            return this.WS.AmmGetPISMethods();
        }

        public bool ModificaMetodiPermessiSistemaEsterno(string metodi, string idSysExt)
        {
            return this.WS.AmmModAllowedPISforExtSys(metodi, idSysExt);
        }

        public bool ModificaDescTknPerSysExt(string desc, string tknTime, string idSysExt)
        {
            return this.WS.AmmModDescTknTimeForExtSys(desc, tknTime, idSysExt);
        }

        public TipoRuolo getTipoRuoloByCode(string idAmm, string codice)
        {
            return this.WS.AmmGetTipoRuoloByCode(idAmm, codice);
        }

        public bool InsSysExtAfterAssoc(string idAmm, string codUtente, string codRuolo, string descrizione)
        {
            return this.WS.AmmInsSysExtAfterAssoc(this.CurrentInfoUtente, idAmm, codUtente, codRuolo, descrizione);
        }

        public UnitaOrganizzativa GetHubSistemiEsterni(string codice, string idAmm)
        {
            return this.WS.GetHubSistemiEsterni(codice,idAmm);
        }

        public string ctrlInserimentoSistemaEsterno(string idAmm, string codUtente, string codRuolo)
        {
            return this.WS.ctrlInserimentoSistemaEsterno(idAmm, codUtente, codRuolo);
        }

        public bool setVisibilityHubSysExt(string idHub)
        {
            return this.WS.setVisibilityHubSysExt(idHub);
        }

        public bool delExtSys(SAAdminTool.DocsPaWR.SistemaEsterno sysExt, SAAdminTool.DocsPaWR.InfoUtente infoUt)
        {
            return this.WS.DeleteExternalSystem(sysExt, infoUt);
        }
        #endregion

        #region Conservazione - MEV CS 1.5

        /// <summary>
        /// Svuota l'hashtable delle chiavi config per l'amministrazione
        /// </summary>
        /// <param name="idAmm"></param>
        public void Clear(string idAmm)
        {
            this.WS.Timeout = System.Threading.Timeout.Infinite;
            WS.clearHashTableChiaviConfig(idAmm);
            InitConfigurationKeys.remove(idAmm);
        }

        #endregion
    }
}
