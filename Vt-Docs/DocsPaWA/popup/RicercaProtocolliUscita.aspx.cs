using System;
using System.Collections;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Web;
using System.Web.SessionState;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.UI.HtmlControls;
using System.Text.RegularExpressions;
using DocsPAWA.DocsPaWR;


namespace DocsPAWA.popup
{
	/// <summary>
	/// Summary description for RicercaProtocolliUscita.
	/// </summary>
	public class RicercaProtocolliUscita : DocsPAWA.CssPage
	{
		protected System.Web.UI.WebControls.Label lbl_message;
		protected System.Web.UI.WebControls.DataGrid DataGrid1;
		protected System.Web.UI.WebControls.Label lblNumeroProtocollo;
		protected System.Web.UI.WebControls.Label lblDataProtocollo;
		protected System.Web.UI.WebControls.Label lblEndDataProtocollo;
		protected System.Web.UI.HtmlControls.HtmlTable tblNumeroProtocollo;
		//protected DocsPaWebCtrlLibrary.DateMask txtEndDataProtocollo;
        protected DocsPAWA.UserControls.Calendar txtEndDataProtocollo;
		protected System.Web.UI.WebControls.Label lblInitNumProto;
		protected System.Web.UI.WebControls.TextBox txtInitNumProto;
		protected System.Web.UI.WebControls.Label lblEndNumProto;
		protected System.Web.UI.WebControls.TextBox txtEndNumProto;
		protected System.Web.UI.WebControls.DropDownList ddl_dtaProto;
		protected System.Web.UI.WebControls.Label lblInitDtaProto;
		//protected DocsPaWebCtrlLibrary.DateMask txtInitDtaProto;
        protected DocsPAWA.UserControls.Calendar txtInitDtaProto;
		protected System.Web.UI.WebControls.DropDownList ddl_numProto;
		protected System.Web.UI.WebControls.Button btn_find;
		protected System.Web.UI.WebControls.Button btn_chiudi;
		protected DocsPAWA.DocsPaWR.FiltroRicerca[][] qV;
		protected DocsPAWA.DocsPaWR.FiltroRicerca fV1;
		protected DocsPAWA.DocsPaWR.FiltroRicerca[] fVList;	
		protected static int currentPage;
		protected DocsPAWA.DocsPaWR.InfoDocumento[] infoDoc;
		protected ArrayList Dg_elem;
		protected DocsPAWA.DocsPaWR.FiltroRicerca[][] ListaFiltri;
		protected int numTotPage;
		protected System.Web.UI.WebControls.CheckBox chk_ADL;
		protected System.Web.UI.WebControls.Label lbl_annoProto;
		protected System.Web.UI.WebControls.TextBox txt_annoProto;
		protected System.Web.UI.WebControls.Label lbl_countRecord;
		protected System.Web.UI.WebControls.DataGrid dg_lista_corr;
		protected System.Web.UI.WebControls.ImageButton btn_chiudi_risultato;
		protected System.Web.UI.WebControls.Panel pnl_corr;
		protected System.Web.UI.WebControls.ImageButton btn_clearFlag;
		protected int nRec;
		protected DataSet ds;
		protected System.Web.UI.WebControls.Button btn_ok;
		protected DataTable dt;
		protected System.Web.UI.HtmlControls.HtmlInputHidden hd_returnValueModal;
		protected Hashtable ht_destinatariTO_CC;
		protected string str_indexSel;
		protected DocsPAWA.DocsPaWR.SchedaDocumento schedaDocIngresso;
		protected DocsPAWA.DocsPaWR.InfoDocumento infoDocSel = null;
        protected DocsPAWA.UserControls.AppTitleProvider appTitleProvider;
        protected string tipoProto;

        protected System.Web.UI.WebControls.Panel pnl_catene_extra_aoo;
        protected System.Web.UI.WebControls.DropDownList ddl_reg;
        private DocsPAWA.DocsPaWR.Registro[] userRegistri;

		private void Page_Load(object sender, System.EventArgs e)
		{
			this.Response.Expires=-1;
		 	//DocsPAWA.Utils.DefaultButton(this,ref txtInitDtaProto,ref btn_find);
			//DocsPAWA.Utils.DefaultButton(this,ref txtEndDataProtocollo,ref btn_find);

			DocsPAWA.Utils.DefaultButton(this,ref this.GetCalendarControl("txtInitDtaProto").txt_Data,ref btn_find);
			DocsPAWA.Utils.DefaultButton(this,ref this.GetCalendarControl("txtEndDataProtocollo").txt_Data,ref btn_find);

         
         
			// Put user code to initialize the page here
			/// <summary>
			if (!IsPostBack)
			{
				RicercaProtocolliUscitaSessionMng.SetAsLoaded(this);

				// Associazione funzioni javascript agli eventi client dei controlli
				this.AddControlsClientAttribute();

                //GESTIONE CATENE EXTRA AOO
                if (UserManager.isFiltroAooEnabled(this))
                {
                    this.pnl_catene_extra_aoo.Visible = true;
                    CaricaComboRegistri(ddl_reg);
                }
			}
			else
			{
				// gestione del valore di ritorno della modal Dialog 
				if(this.hd_returnValueModal.Value != null && this.hd_returnValueModal.Value != string.Empty && this.hd_returnValueModal.Value != "undefined")
				{
					
//						//Gestione pulsante SI, CONTINUA
//
//						/* Alla pressione del pulsante CONTINUA l'utente vuole proseguire il collegamento nonostante
//						 * i dati dei due protocolli (oggetto e corrispondente) sono diversi */
//						schedaDocIngresso = DocumentManager.getDocumentoInLavorazione(this);
//						infoDocSel = DocumentManager.getInfoDocumento(this);
//						if(infoDocSel!=null)
//						{
//							schedaDocIngresso.protocollo.rispostaProtocollo = infoDocSel;
//						}
//						//metto in sessione la scheda documento con le informazioni del protocollo a cui risponde
//						DocumentManager.setDocumentoSelezionato(this,schedaDocIngresso);
//
//						Page.RegisterStartupScript("","<script>window.returnValue = 'Y'; window.close();</script>");
//						

						string retValue=this.GestioneAvvisoModale(hd_returnValueModal.Value);

						if (retValue!="C")
						{
							//rimuovo le cose appoggiate in sessione
							RicercaProtocolliUscitaSessionMng.ClearSessionData(this);
						}
				}
			}
		}

		#region Web Form Designer generated code
		override protected void OnInit(EventArgs e)
		{
			//
			// CODEGEN: This call is required by the ASP.NET Web Form Designer.
			//
			InitializeComponent();
			base.OnInit(e);
		}
		
		/// <summary>
		/// Required method for Designer support - do not modify
		/// the contents of this method with the code editor.
		/// </summary>
		private void InitializeComponent()
		{    
			this.chk_ADL.CheckedChanged += new System.EventHandler(this.chk_ADL_CheckedChanged);
			this.ddl_numProto.SelectedIndexChanged += new System.EventHandler(this.ddl_numProto_SelectedIndexChanged);
			this.ddl_dtaProto.SelectedIndexChanged += new System.EventHandler(this.ddl_dtaProto_SelectedIndexChanged);
			this.btn_find.Click += new System.EventHandler(this.btn_find_Click);
			this.DataGrid1.PageIndexChanged += new System.Web.UI.WebControls.DataGridPageChangedEventHandler(this.DataGrid1_PageIndexChange);
			this.DataGrid1.SelectedIndexChanged += new System.EventHandler(this.DataGrid1_SelectedIndexChanged);
			this.btn_chiudi_risultato.Click += new System.Web.UI.ImageClickEventHandler(this.btn_chiudi_risultato_Click);
			this.dg_lista_corr.PageIndexChanged += new System.Web.UI.WebControls.DataGridPageChangedEventHandler(this.dg_lista_corr_PageIndexChanged);
			this.btn_ok.Click += new System.EventHandler(this.btn_ok_Click);
			this.btn_chiudi.Click += new System.EventHandler(this.btn_chiudi_Click);
			this.Load += new System.EventHandler(this.Page_Load);

		}
		#endregion

		private void ddl_numProto_SelectedIndexChanged(object sender, System.EventArgs e)
		{
			this.txtEndNumProto.Text="";
			
			if(this.ddl_numProto.SelectedIndex==0)
			{
				this.txtEndNumProto.Visible=false;
				this.lblEndNumProto.Visible=false;
				this.lblInitNumProto.Visible=false;
			}
			else
			{
				this.txtEndNumProto.Visible=true;
				this.lblEndNumProto.Visible=true;
				this.lblInitNumProto.Visible=true;
			}
		}

		#region Gestione javascript
		
		/// <summary>
		/// Associazione funzioni javascript agli eventi client dei controlli
		/// </summary>
		private void AddControlsClientAttribute()
		{
			//this.txtInitNumProto.Attributes.Add("onKeyPress","ValidateNumericKey();");			
			//this.txtEndNumProto.Attributes.Add("onKeyPress","ValidateNumericKey();");
			//this.btn_chiudi.Attributes.Add("onClick","CloseWindow(false);");
			//this.txt_annoProto.Attributes.Add("onKeyPress","ValidateNumericKey();");
		}
		#endregion

//		private void btn_find_Click(object sender, System.Web.UI.ImageClickEventArgs e)
//		{
//			try
//			{	
//				//impostazioni iniziali
//				this.pnl_corr.Visible=false;
//				this.DataGrid1.Visible = false;
//				this.lbl_countRecord.Visible = false;
//				//pulisce selezioni precedenti
//				resetOption();
//
//				RicercaProtocolliUscitaSessionMng.ClearSessionData(this);
//
//				//fine impostazioni
//
//					//INIZIO VALIDAZIONE DATI INPUT ALLA RICERCA				
//					if(txtInitNumProto.Text!="")
//					{
//						if(IsValidNumber(txtInitNumProto)==false)
//						{
//							Response.Write("<script>alert('Il numero di protocollo deve essere numerico!');</script>");
//							string s = "<SCRIPT language='javascript'>document.getElementById('" + txtInitNumProto.ID + "').focus();</SCRIPT>";
//							RegisterStartupScript("focus", s);
//							return;
//						}
//					}
//					if(txtEndNumProto.Text!="")
//					{
//						if(IsValidNumber(txtEndNumProto)==false)
//						{
//							Response.Write("<script>alert('Il numero di protocollo deve essere numerico!');</script>");
//							string s = "<SCRIPT language='javascript'>document.getElementById('" + txtEndNumProto.ID + "').focus();</SCRIPT>";
//							RegisterStartupScript("focus", s);
//							return;
//						}
//					}
//					//controllo validit� anno inserito
//					if(txt_annoProto.Text!="")
//					{
//						if(IsValidYear(txt_annoProto.Text)==false)
//						{
//							Response.Write("<script>alert('Formato anno non corretto !');</script>");
//							string s = "<SCRIPT language='javascript'>document.getElementById('" + txt_annoProto.ID + "').focus();</SCRIPT>";
//							RegisterStartupScript("focus", s);
//							return;
//						}
//					}
//					// FINE VALIDAZIONE
//
//					currentPage = 1 ;
//				
//					if (RicercaProtoUscita())
//					{		
//						DocumentManager.setFiltroRicDoc(this,qV);
//						LoadData(true);
//					}
//				
//
//				
//			}
//			catch(System.Exception ex)
//			{
//				ErrorManager.redirect(this,ex);
//			}
//		}

		#region METODI VALIDAZIONE DATI IN INPUT
		/// <summary>
		/// Validazione valore numerico
		/// </summary>
		/// <param name="numberText"></param>
		/// <returns></returns>
		private bool IsValidNumber(TextBox numberText)
		{
			bool retValue=true;
			
			try
			{
				int.Parse(numberText.Text);
			}
			catch 
			{
				retValue=false;
			}

			return retValue;
		}

		public bool IsValidYear(string strYear)
		{
			Regex onlyNumberPattern = new Regex(@"\d{4}");
			return onlyNumberPattern.IsMatch(strYear);
		}
		#endregion

		protected bool RicercaProtoUscita()
		{
			try
			{	
				//array contenitore degli array filtro di ricerca
				qV = new DocsPAWA.DocsPaWR.FiltroRicerca[1][];
				qV[0]= new DocsPAWA.DocsPaWR.FiltroRicerca[1];
				fVList= new DocsPAWA.DocsPaWR.FiltroRicerca[0];
					
				#region Filtro per REGISTRO (si ricercano i protocolli in uscita sul registro di quello in ingresso)
                if (!UserManager.isFiltroAooEnabled(this))
                {
                    fV1 = new DocsPAWA.DocsPaWR.FiltroRicerca();
                    fV1.argomento = DocsPaWR.FiltriDocumento.REGISTRO.ToString();
                    fV1.valore = UserManager.getRegistroSelezionato(this).systemId;
                    fVList = Utils.addToArrayFiltroRicerca(fVList, fV1);
                }
                else
                {
                    fV1 = new DocsPAWA.DocsPaWR.FiltroRicerca();
                    fV1.argomento = DocsPaWR.FiltriDocumento.REGISTRO.ToString();
                    if (ddl_reg.Items.Count <= 1)
                    {
                        fV1.valore = UserManager.getRegistroSelezionato(this).systemId;
                    }
                    else
                    {
                        fV1.valore = this.ddl_reg.SelectedItem.Value;
                    } 
                    fVList = Utils.addToArrayFiltroRicerca(fVList, fV1);
                }
                #endregion

				#region filtro NUMERO DI PROTOCOLLO
				if (this.ddl_numProto.SelectedIndex == 0)
				{

					if (this.txtInitNumProto.Text!=null && !this.txtInitNumProto.Text.Equals(""))
					{
						fV1= new DocsPAWA.DocsPaWR.FiltroRicerca();
						fV1.argomento=DocsPaWR.FiltriDocumento.NUM_PROTOCOLLO.ToString();
						fV1.valore=this.txtInitNumProto.Text;
						fVList=Utils.addToArrayFiltroRicerca(fVList,fV1);
					}
				}
				else
				{//valore singolo carico NUM_PROTOCOLLO_DAL - NUM_PROTOCOLLO_AL
					if (!this.txtInitNumProto.Text.Equals(""))
					{
						fV1= new DocsPAWA.DocsPaWR.FiltroRicerca();
						fV1.argomento=DocsPaWR.FiltriDocumento.NUM_PROTOCOLLO_DAL.ToString();
						fV1.valore=this.txtInitNumProto.Text;
						fVList=Utils.addToArrayFiltroRicerca(fVList,fV1);
					}
					if (!this.txtEndNumProto.Text.Equals(""))
					{
						fV1= new DocsPAWA.DocsPaWR.FiltroRicerca();
						fV1.argomento=DocsPaWR.FiltriDocumento.NUM_PROTOCOLLO_AL.ToString();
						fV1.valore=this.txtEndNumProto.Text;
						fVList=Utils.addToArrayFiltroRicerca(fVList,fV1);
					}
				}
				#endregion 

				#region filtro ANNO DI PROTOCOLLO
				
				fV1= new DocsPAWA.DocsPaWR.FiltroRicerca();
				fV1.argomento=DocsPaWR.FiltriDocumento.ANNO_PROTOCOLLO.ToString();
				fV1.valore=this.txt_annoProto.Text;
				fVList=Utils.addToArrayFiltroRicerca(fVList,fV1);
				#endregion

				#region filtro DATA PROTOCOLLO
				if (this.ddl_dtaProto.SelectedIndex == 0)
				{//valore singolo specificato per DATA_PROTOCOLLO
					if (!this.GetCalendarControl("txtInitDtaProto").txt_Data.Text.Equals(""))
					{
						if(!Utils.isDate(this.GetCalendarControl("txtInitDtaProto").txt_Data.Text))
						{
							Response.Write("<script>alert('Il formato della data non � valido. \\nIl formato richiesto � gg/mm/aaaa');</script>");
							string s = "<SCRIPT language='javascript'>document.getElementById('" + this.GetCalendarControl("txtInitDtaProto").txt_Data.ID + "').focus();</SCRIPT>";
							RegisterStartupScript("focus", s);
							return false;
						}
						fV1= new DocsPAWA.DocsPaWR.FiltroRicerca();
						fV1.argomento=DocsPaWR.FiltriDocumento.DATA_PROT_IL.ToString();
						fV1.valore=this.GetCalendarControl("txtInitDtaProto").txt_Data.Text;
						fVList=Utils.addToArrayFiltroRicerca(fVList,fV1);
					}
				}
				else
				{//valore singolo carico DATA_PROTOCOLLO_DAL - DATA_PROTOCOLLO_AL
					if (!this.GetCalendarControl("txtInitDtaProto").txt_Data.Text.Equals(""))
					{
						if(!Utils.isDate(this.GetCalendarControl("txtInitDtaProto").txt_Data.Text))
						{
							Response.Write("<script>alert('Il formato della data non � valido. \\nIl formato richiesto � gg/mm/aaaa');</script>");
							string s = "<SCRIPT language='javascript'>document.getElementById('" + this.GetCalendarControl("txtInitDtaProto").txt_Data.ID + "').focus();</SCRIPT>";
							RegisterStartupScript("focus", s);
							return false;
						}
						fV1= new DocsPAWA.DocsPaWR.FiltroRicerca();
						fV1.argomento=DocsPaWR.FiltriDocumento.DATA_PROT_SUCCESSIVA_AL.ToString();
						fV1.valore=this.GetCalendarControl("txtInitDtaProto").txt_Data.Text;
						fVList=Utils.addToArrayFiltroRicerca(fVList,fV1);
					}
					if (!this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Text.Equals(""))
					{
						if(!Utils.isDate(this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Text))
						{
							Response.Write("<script>alert('Il formato della data non � valido. \\nIl formato richiesto � gg/mm/aaaa');</script>");
							string s = "<SCRIPT language='javascript'>document.getElementById('" + this.GetCalendarControl("txtEndDataProtocollo").txt_Data.ID + "').focus();</SCRIPT>";
							RegisterStartupScript("focus", s);
							return false;
						}
						fV1= new DocsPAWA.DocsPaWR.FiltroRicerca();
						fV1.argomento=DocsPaWR.FiltriDocumento.DATA_PROT_PRECEDENTE_IL.ToString();
						fV1.valore=this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Text;
						fVList=Utils.addToArrayFiltroRicerca(fVList,fV1);
					}
				}
				#endregion 

				#region filtro per ricerca protocollo in partenza
                //fV1= new DocsPAWA.DocsPaWR.FiltroRicerca();
                //fV1.argomento=DocsPaWR.FiltriDocumento.DA_PROTOCOLLARE.ToString();
                //fV1.valore= "0";  //corrisponde a 'false'
                //fVList=Utils.addToArrayFiltroRicerca(fVList,fV1);

                // 12/12/2008 si � scelto di levare la possibilit� di cercare anche i predisposti
                // ricerca solo i protocolli in uscita
                // nel caso si volesse ripristinare la ricerca anche per i predisposti, si deve modificare
                // la query che li tira fuori
                //fV1 = new DocsPAWA.DocsPaWR.FiltroRicerca();
                //fV1.argomento = DocsPaWR.FiltriDocumento.PREDISPOSTO.ToString();
                //fV1.valore = "true";
                //fVList = Utils.addToArrayFiltroRicerca(fVList, fV1);

				fV1= new DocsPAWA.DocsPaWR.FiltroRicerca();
				fV1.argomento=DocsPaWR.FiltriDocumento.TIPO.ToString();
				fV1.valore= "T";
				fVList=Utils.addToArrayFiltroRicerca(fVList,fV1);
                   
            fV1 = new DocsPAWA.DocsPaWR.FiltroRicerca();
            fV1.argomento = DocsPaWR.FiltriDocumento.PROT_PARTENZA.ToString();
            fV1.valore = "true";
            fVList = Utils.addToArrayFiltroRicerca(fVList, fV1);
              
            
             #endregion


            qV[0]=fVList;
				return true;

			}
			catch(System.Exception ex)
			{
				ErrorManager.redirect(this,ex);
				return false;
			}
		}

		private void LoadData(bool updateGrid)
		{
            SearchResultInfo[] idProfileList;
			DocsPaWR.InfoUtente infoUt= new DocsPAWA.DocsPaWR.InfoUtente();
			infoUt = UserManager.getInfoUtente(this);
			ListaFiltri = DocumentManager.getFiltroRicDoc(this);
			if(!this.chk_ADL.Checked==true)
			{
                infoDoc = DocumentManager.getQueryInfoDocumentoPaging(infoUt.idGruppo, infoUt.idPeople, this, this.ListaFiltri, currentPage, out numTotPage, out nRec, true, false, true, false, out idProfileList);	
			}
			else
			{
				DocsPaWR.AreaLavoro areaLavoro = DocumentManager.getListaAreaLavoro(this,"P","0",currentPage,out numTotPage,out nRec,UserManager.getRegistroSelezionato(this).systemId);
				
				infoDoc=new DocsPAWA.DocsPaWR.InfoDocumento[areaLavoro.lista.Length];

				for (int i=0;i<areaLavoro.lista.Length;i++)
					infoDoc[i]=(DocsPAWA.DocsPaWR.InfoDocumento) areaLavoro.lista[i];
			}

			
			this.lbl_countRecord.Visible = true;
			this.lbl_countRecord.Text = "Documenti tot:  " + nRec;

			this.DataGrid1.VirtualItemCount = nRec ;
			this.DataGrid1.CurrentPageIndex = currentPage-1;

			//appoggio il risultato in sessione
			//Session["RicercaProtocolliUscita.ListaInfoDoc"] =infoDoc;
			RicercaProtocolliUscitaSessionMng.SetListaInfoDocumenti(this,infoDoc);

			if (infoDoc != null && infoDoc.Length > 0)
			{
				this.BindGrid(infoDoc);
			}

		}

		public void BindGrid(DocsPAWA.DocsPaWR.InfoDocumento[] infos)
		{
			DocsPaWR.InfoDocumento currentDoc;

			if (infos != null  && infos.Length > 0)
			{
				//Costruisco il datagrid
				Dg_elem = new ArrayList();
				string descrDoc=string.Empty;
				int numProt=new Int32();

				for(int i= 0; i< infos.Length ; i++)
				{					
					currentDoc = ((DocsPAWA.DocsPaWR.InfoDocumento) infos[i]);
	
					string dataApertura = "";
					if (currentDoc.dataApertura != null && currentDoc.dataApertura .Length > 0)
						dataApertura = currentDoc.dataApertura.Substring(0,10);


                    if (currentDoc.numProt != null && !currentDoc.numProt.Equals(""))
                    {
                        numProt = Int32.Parse(currentDoc.numProt);
                        descrDoc = numProt.ToString();
                    }
                    else
                    {
                        descrDoc = currentDoc.docNumber;
                    }
                    //numProt=Int32.Parse(currentDoc.numProt);
                    //descrDoc=numProt.ToString();
					
					descrDoc = descrDoc + "\n" + dataApertura;
					string MittDest="";

					if(currentDoc.mittDest!= null && currentDoc.mittDest.Length>0)
					{
						for(int g=0;g<currentDoc.mittDest.Length;g++)
							MittDest+=currentDoc.mittDest[g]+" - ";
						if(currentDoc.mittDest.Length>0)
							MittDest = MittDest.Substring(0,MittDest.Length -3);
					}		

					Dg_elem.Add(new ProtocolloUscitaDataGridItem(descrDoc, currentDoc.oggetto,MittDest, currentDoc.codRegistro, i));
				}
				
				this.DataGrid1.SelectedIndex=-1;
				this.DataGrid1.DataSource = Dg_elem;
				this.DataGrid1.DataBind();
				this.DataGrid1.Visible = true;
			}
			else
			{
				this.DataGrid1.Visible = false;
				this.lbl_message.Visible = true;
			}
		}

		public class ProtocolloUscitaDataGridItem 
		{		
			private string data;
			private string oggetto;
			private string mittDest;
			private string registro;
			private int chiave;

			public ProtocolloUscitaDataGridItem(string data, string oggetto,string mittDest, string registro, int chiave)
			{
				this.data = data;
				this.oggetto = oggetto;
				this.registro=registro;
				this.mittDest = mittDest;
				this.chiave = chiave;
			}
					
			public string Data{get{return data;}}
			public string Oggetto{get{return oggetto;}}
			public string Registro{get{return registro;}}
			public string MittDest{get{return mittDest;}}
			public int    Chiave{get{return chiave;}}
		}

        /// 
        /// </summary>
        /// <param name="controlId"></param>
        /// <returns></returns>
        private DocsPAWA.UserControls.Calendar GetCalendarControl(string controlId)
        {
            return (DocsPAWA.UserControls.Calendar)this.FindControl(controlId);
        }

		private void ddl_dtaProto_SelectedIndexChanged(object sender, System.EventArgs e)
		{
			this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Text="";
			if(this.ddl_dtaProto.SelectedIndex==0)
			{
				this.GetCalendarControl("txtEndDataProtocollo").Visible=false;
                this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Visible = false;
                this.GetCalendarControl("txtEndDataProtocollo").btn_Cal.Visible = false;
				this.lblEndDataProtocollo.Visible=false;
				this.lblInitDtaProto.Visible=false;
					
			}
			else
			{
				this.GetCalendarControl("txtEndDataProtocollo").Visible=true;
                this.GetCalendarControl("txtEndDataProtocollo").btn_Cal.Visible = true;
                this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Visible = true;
				this.lblEndDataProtocollo.Visible=true;
				this.lblInitDtaProto.Visible=true;
			}
		}

		private void DataGrid1_PageIndexChange(object source, System.Web.UI.WebControls.DataGridPageChangedEventArgs e)
		{
			DataGrid1.CurrentPageIndex = e.NewPageIndex;
			currentPage = e.NewPageIndex + 1;
			pnl_corr.Visible=false;
			// Cricamento del DataGrid
			this.LoadData(true);
		}



		private void DataGrid1_SelectedIndexChanged(object sender, System.EventArgs e)
		{
			
			DocsPaWR.Corrispondente[] listaCorrTo = null;
			DocsPaWR.Corrispondente[] listaCorrCC = null;
		
			if(this.DataGrid1.SelectedIndex >=0)
			{
				str_indexSel = ((Label) this.DataGrid1.Items[this.DataGrid1.SelectedIndex].Cells[5].Controls[1]).Text;
				int indexSel = Int32.Parse(str_indexSel);
				//this.infoDoc = (DocsPAWA.DocsPaWR.InfoDocumento[]) Session["RicercaProtocolliUscita.ListaInfoDoc"];
				this.infoDoc = RicercaProtocolliUscitaSessionMng.GetListaInfoDocumenti(this);
			
				if (indexSel > -1) 
					infoDocSel = (DocsPAWA.DocsPaWR.InfoDocumento) this.infoDoc[indexSel];

				if(infoDocSel!=null)
				{
					//prendo il dettaglio del documento e estraggo i destinatari del protocollo
					DocsPaWR.SchedaDocumento schedaDocUscita = new DocsPAWA.DocsPaWR.SchedaDocumento();
					schedaDocUscita = DocumentManager.getDettaglioDocumento(this,infoDocSel.idProfile,infoDocSel.docNumber);
                    //prendo i destinatari in To
                    listaCorrTo = ((DocsPAWA.DocsPaWR.ProtocolloUscita)schedaDocUscita.protocollo).destinatari;
                    //prendo i destinatari in CC
                    listaCorrCC = ((DocsPAWA.DocsPaWR.ProtocolloUscita)schedaDocUscita.protocollo).destinatariConoscenza;
                   					
					FillDataGrid(listaCorrTo,listaCorrCC);
					DocumentManager.setInfoDocumento(this, infoDocSel);
				}

			}
		}

		private void AppendDataRow(DataTable dt,string tipoCorr,string systemId,string descCorr)
		{
			DataRow row=dt.NewRow();
			row["SYSTEM_ID"]=systemId;
			row["TIPO_CORR"]=tipoCorr;
			row["DESC_CORR"]=descCorr;
			dt.Rows.Add(row);
			row=null;
		}

		/// <summary>
		/// Caricamento griglia destinatari del protocollo in uscita selezionato
		/// </summary>
		/// <param name="uoApp"></param>
		private void FillDataGrid(DocsPAWA.DocsPaWR.Corrispondente[] listaCorrTo, DocsPAWA.DocsPaWR.Corrispondente[] listaCorrCC)
		{
			ds=this.CreateGridDataSetDestinatari();
			this.CaricaGridDataSetDestinatari(ds, listaCorrTo, listaCorrCC);
			this.dg_lista_corr.DataSource=ds;
			DocumentManager.setDataGridProtocolliUscita(this,dt);
			this.dg_lista_corr.DataBind();

			// Impostazione corrispondente predefinito
			this.SelectDefaultCorrispondente();
		}

		private DataSet CreateGridDataSetDestinatari()
		{
			DataSet retValue=new DataSet();

			dt=new DataTable("GRID_TABLE_DESTINATARI");
			dt.Columns.Add("SYSTEM_ID",typeof(string));
			dt.Columns.Add("TIPO_CORR",typeof(string));
			dt.Columns.Add("DESC_CORR",typeof(string));
			retValue.Tables.Add(dt);

			return retValue;
		}
		/// <summary>
		/// Caricamento dataset utilizzato per le griglie
		/// </summary>
		/// <param name="ds"></param>
		/// <param name="uo"></param>
		private void CaricaGridDataSetDestinatari(DataSet ds, DocsPAWA.DocsPaWR.Corrispondente[] listaCorrTo, DocsPAWA.DocsPaWR.Corrispondente[] listaCorrCC)
		{
			DataTable dt=ds.Tables["GRID_TABLE_DESTINATARI"];
			ht_destinatariTO_CC = new Hashtable();
			string tipoURP = "";

			if(listaCorrTo!=null && listaCorrTo.Length>0)
			{
				for(int i=0;i<listaCorrTo.Length;i++)
				{	
					if(listaCorrTo[i].tipoCorrispondente!=null && listaCorrTo[i].tipoCorrispondente.Equals("O"))
					{
						this.AppendDataRow(dt,listaCorrTo[i].tipoCorrispondente,listaCorrTo[i].systemId, "&nbsp;"+listaCorrTo[i].descrizione);	
					}
					else
					{
						if(listaCorrTo[i].GetType().Equals(typeof(DocsPAWA.DocsPaWR.UnitaOrganizzativa)))
						{
							tipoURP = "U";
						}
						if(listaCorrTo[i].GetType().Equals(typeof(DocsPAWA.DocsPaWR.Ruolo)))
						{
							tipoURP = "R";
						}
						if(listaCorrTo[i].GetType().Equals(typeof(DocsPAWA.DocsPaWR.Utente)))
						{
							tipoURP = "P";
						}
						this.AppendDataRow(dt,listaCorrTo[i].tipoIE,listaCorrTo[i].systemId,GetImage(tipoURP) +" - "+listaCorrTo[i].descrizione);
					}
					ht_destinatariTO_CC.Add(listaCorrTo[i].systemId,listaCorrTo[i]);
				}
			}
			if(listaCorrCC!=null && listaCorrCC.Length>0)
			{
				for(int i=0;i<listaCorrCC.Length;i++)
				{	
					if(listaCorrCC[i].tipoCorrispondente!=null && listaCorrCC[i].tipoCorrispondente.Equals("O"))
					{
						this.AppendDataRow(dt,listaCorrCC[i].tipoCorrispondente,listaCorrCC[i].systemId,"&nbsp;"+listaCorrCC[i].descrizione + " (CC)");
					}
					else
					{
						if(listaCorrCC[i].GetType().Equals(typeof(DocsPAWA.DocsPaWR.UnitaOrganizzativa)))
						{
							tipoURP = "U";
						}
						if(listaCorrCC[i].GetType().Equals(typeof(DocsPAWA.DocsPaWR.Ruolo)))
						{
							tipoURP = "R";
						}
						if(listaCorrCC[i].GetType().Equals(typeof(DocsPAWA.DocsPaWR.Utente)))
						{
							tipoURP = "P";
						}
						this.AppendDataRow(dt,listaCorrCC[i].tipoIE,listaCorrCC[i].systemId,GetImage(tipoURP) +" - "+listaCorrCC[i].descrizione + " (CC)");
					}
					ht_destinatariTO_CC.Add(listaCorrCC[i].systemId,listaCorrCC[i]);
				}
			}
			if ((listaCorrTo!=null && listaCorrTo.Length>0) || (listaCorrCC!=null && listaCorrCC.Length>0))
			{
				this.pnl_corr.Visible=true;
			}
			DocumentManager.setHash(this,ht_destinatariTO_CC);
			
		}

		/// <summary>
		/// In presenza di un solo corrispondente in griglia,
		/// lo seleziona per default
		/// </summary>
		private void SelectDefaultCorrispondente() 
		{	
			if (this.dg_lista_corr.Items.Count==1)
			{
				DataGridItem dgItem=this.dg_lista_corr.Items[0];
				
				RadioButton optCorr=dgItem.Cells[3].FindControl("optCorr") as RadioButton;
				if (optCorr!=null)
					optCorr.Checked=true;
			}
		}

		private void btn_chiudi_risultato_Click(object sender, System.Web.UI.ImageClickEventArgs e)
		{
			pnl_corr.Visible = false;
		}

		private void dg_lista_corr_PageIndexChanged(object source, System.Web.UI.WebControls.DataGridPageChangedEventArgs e)
		{
			this.dg_lista_corr.SelectedIndex=-1;
			this.dg_lista_corr.CurrentPageIndex=e.NewPageIndex;
			dg_lista_corr.DataSource = DocumentManager.getDataGridProtocolliUscita(this);
			dg_lista_corr.DataBind();
			
		}

		private void btn_ok_Click(object sender, System.EventArgs e)
		{
			DocsPaWR.Corrispondente destSelected = null;
	
			//itemIndex: indice item del datagrid che contiene radio selezionato
			int itemIndex; 

			/*	bool avanza:
			 *	- true: si pu� procedere perch� un corrispondente � stato selezionato;		
			 *  - false : non si procede e si avvisa l'utente che deve selezionarne uno */
			//bool avanza = verificaSelezione(out itemIndex);
			bool avanzaDoc = verificaSelezioneDocumento();
			
			
			if (avanzaDoc)
			{
				bool avanzaCor = verificaSelezione(out itemIndex);
				if(avanzaCor)
				{
					bool mittenteOK = false;
					bool oggettoOK = false;
					string oggettoProtoSel ="";
                    bool diventaOccasionale = true;

					//ricavo la system_id del corrispondente selezionato, contenuta nella prima colonna del datagrid
					string key = dg_lista_corr.Items[itemIndex].Cells[0].Text;
				
					//prendo la hashTable che contiene i corrisp dalla sesisone
					ht_destinatariTO_CC = DocumentManager.getHash(this);
				
					if (ht_destinatariTO_CC!= null)
					{
						if(ht_destinatariTO_CC.ContainsKey(key))
						{
							//prendo il corrispondente dalla hashTable secondo quanto � stato richiesto dall'utente
							destSelected = (DocsPAWA.DocsPaWR.Corrispondente)ht_destinatariTO_CC[key];

							#region CHIARIMENTO
							/*	CASI POSSIBILI PER RISPONDERE A UN PROTOCOLLO	
							*			----------------------------------------------------------------------------------
							*			caso 1 - il documento in ingresso (il protocollo di risposta) non � protocollato
							*						
							*					caso 1.1 - il campo mittente non � valorizzato, quindi posso
							*							   popolarlo con quello selezionato dall'utente
							*					
							*					caso 1.2 - il campo mittente � popolato, se sono diversi avviso l'utente
							*			
							*			Analogo il discorso per il campo oggetto, se sono diversi avviso l'utente e gli
							*			daremo la possibilit� di scegliere se proseguire o meno con l'operazione
							*			di collegamento	
							* 		   
							*			-----------------------------------------------------------------------------------
							*			caso 2 - il documento in ingresso � gi� protocollato, ha quindi un mittente
							*					
							*					caso 2.1 - mittente scelto � diverso da quello corrente, si avvisa l'utente
							*		     				   e si da la possibilit� si proseguire o meno con il collegamento
							* 
							*			Analogo il discorso per il campo oggetto
							*			-----------------------------------------------------------------------------------
							* */
							#endregion

							//prendo la scheda documento corrente in sessione
							schedaDocIngresso = DocumentManager.getDocumentoInLavorazione(this);

                            //Gestione corrispondenti nel caso di Corrispondenti extra AOO
                            if (UserManager.isFiltroAooEnabled(this))
                            {
                                
                                if (schedaDocIngresso != null)
                                {
                                    DocsPAWA.DocsPaWR.Registro tempRegUser = UserManager.getRegistroSelezionato(this);
                                    infoDocSel = DocumentManager.getInfoDocumento(this);
                                    if (tempRegUser.systemId != infoDocSel.idRegistro && !string.IsNullOrEmpty(destSelected.idRegistro))
                                    {
                                        DocsPAWA.DocsPaWR.Corrispondente tempDest = destSelected;
                                        tempDest.codiceRubrica = null;
                                        tempDest.idOld = "0";
                                        tempDest.systemId = null;
                                        tempDest.tipoCorrispondente = "O";
                                        tempDest.tipoIE = null;
                                        tempDest.idRegistro = tempRegUser.systemId;
                                        tempDest.idAmministrazione = UserManager.getUtente(this).idAmministrazione;
                                        diventaOccasionale = false;
                                        destSelected = tempDest;
                                    }
                                }
                            }


							if(schedaDocIngresso != null)
							{
								#region GESTIONE RISPOSTA AL PROTOCOLLO NON ANCORA PROTOCOLLATA
								//se non � protocollato
								if(schedaDocIngresso.protocollo != null && (schedaDocIngresso.protocollo.numero == null || schedaDocIngresso.protocollo.numero.Equals("")))
								{
									// il campo mittente della scheda documento relativa al protocollo di risposta non � popolato
                                    if (((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente == null)
                                    {
                                        mittenteOK = true;
                                        //popolo il campo mittente con il destinatario selezionato dal protocollo a cui ri risponde 
                                        //((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente = destSelected;
                                        RicercaProtocolliUscitaSessionMng.setCorrispondenteRisposta(this, destSelected);
                                    }
                                    else
                                    {
                                        //il campo mittente � stato popolato prima di selezionere il protocollo a cui rispondere,
                                        //quindi si verifica se i corrispondenti coincidono. In caso affermativo si procede con il collegamento,
                                        //in caso contrario avviso l'utente, dando la possibilit� di scegliere se proseguire con i nuovi dati o meno.

                                        //per i mittenti occasionali come si fa ?
                                        bool verificaUguaglianzaCorr = verificaUguaglianzacorrispondenti(destSelected, ((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente);
                                        if (verificaUguaglianzaCorr)
                                        {
                                            mittenteOK = true;
                                        }
                                        else
                                        {
                                            //setto il destinatario selezionato in sessione
                                            RicercaProtocolliUscitaSessionMng.setCorrispondenteRisposta(this, destSelected);
                                        }

                                        if (verificaUguaglianzaCorr == true && ((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente == null)
                                        {
                                            //setto il destinatario selezionato in sessione
                                            RicercaProtocolliUscitaSessionMng.setCorrispondenteRisposta(this, destSelected);
                                        }

                                    }
									if(this.DataGrid1.SelectedIndex >=0)
									{
										oggettoProtoSel = ((Label)DataGrid1.Items[this.DataGrid1.SelectedIndex].Cells[2].Controls[1]).Text;
									}
									//inizio verifica congruenza campo oggetto
									if(schedaDocIngresso.oggetto!=null && schedaDocIngresso.oggetto.descrizione!=null && schedaDocIngresso.oggetto.descrizione != String.Empty)
									{
										if(oggettoProtoSel!=null && oggettoProtoSel!= String.Empty)
										{
											if (schedaDocIngresso.oggetto.descrizione.ToUpper().Equals(oggettoProtoSel.ToUpper()))
											{
												oggettoOK = true;
											}
										}
									}
									else
									{
																	
										oggettoOK = true;
										if(oggettoProtoSel!=null && oggettoProtoSel!= String.Empty)
										{
											DocsPaWR.Oggetto ogg = new DocsPAWA.DocsPaWR.Oggetto();
											ogg.descrizione = oggettoProtoSel.ToString();
											schedaDocIngresso.oggetto = ogg;
										}
									}

                                    if (!mittenteOK || !oggettoOK || !diventaOccasionale)
									{
										//se i corrisp non coincidono si lancia un avviso	all'utente 
										if(!this.Page.IsStartupScriptRegistered("avvisoModale"))
										{
                                            string scriptString = "<SCRIPT>OpenAvvisoModale('" + mittenteOK + "' , '" + oggettoOK + "' , 'False' , '" + diventaOccasionale + "');</SCRIPT>";				
											this.Page.RegisterStartupScript("avvisoModale", scriptString);
										}	
									}
									else
									{
										infoDocSel = DocumentManager.getInfoDocumento(this);
										if(infoDocSel!=null)
										{
											schedaDocIngresso.rispostaDocumento = infoDocSel;
											schedaDocIngresso.modificaRispostaDocumento = true;
										}
										DocumentManager.setDocumentoSelezionato(this,schedaDocIngresso);
																	
										RicercaProtocolliUscitaSessionMng.SetDialogReturnValue(this,true);
										
										if(((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente == null)
										{
											if(RicercaProtocolliUscitaSessionMng.getCorrispondenteRisposta(this)!=null)
											{
												((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente = RicercaProtocolliUscitaSessionMng.getCorrispondenteRisposta(this);
											}
										}
										Page.RegisterStartupScript("","<script>window.close();</script>");
									}
								}
							}				
							
						
							#endregion

							    #region GESTIONE RISPOSTA AL PROTOCOLLO GIA' PRECEDENTEMENTE PROTOCOLLATA

							if(schedaDocIngresso.protocollo!=null && schedaDocIngresso.protocollo.numero!=null && schedaDocIngresso.protocollo.numero!=String.Empty)
							{
								bool verificaUguaglianzaCorr = verificaUguaglianzacorrispondenti(destSelected,((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente);
								if (verificaUguaglianzaCorr)
								{
									mittenteOK = true;	
								}
								if(this.DataGrid1.SelectedIndex >=0)
								{
									oggettoProtoSel = ((Label)DataGrid1.Items[this.DataGrid1.SelectedIndex].Cells[2].Controls[1]).Text;
								}
								//inizio verifica congruenza campo oggetto
								if(schedaDocIngresso.oggetto!=null && schedaDocIngresso.oggetto.descrizione!=null && schedaDocIngresso.oggetto.descrizione != String.Empty)
								{
									if(oggettoProtoSel!=null && oggettoProtoSel!= String.Empty)
									{
										if (schedaDocIngresso.oggetto.descrizione.ToUpper().Equals(oggettoProtoSel.ToUpper()))
										{
											oggettoOK = true;
										}
									}
								}
                                if (!mittenteOK || !oggettoOK || !diventaOccasionale)
								{
									//se i corrisp non coincidono si lancia un avviso	all'utente 
									if(!this.Page.IsStartupScriptRegistered("avvisoModale"))
									{
                                        string scriptString = "<SCRIPT>OpenAvvisoModale('" + mittenteOK + "' , '" + oggettoOK + "' , 'True' , '" + diventaOccasionale + "');</SCRIPT>";				
										this.Page.RegisterStartupScript("avvisoModale", scriptString);
									}	
								}
								else
								{
									infoDocSel = DocumentManager.getInfoDocumento(this);			
									if(infoDocSel!=null)
									{
										schedaDocIngresso.rispostaDocumento = infoDocSel;
										schedaDocIngresso.modificaRispostaDocumento = true;
									}

								
									DocumentManager.setDocumentoSelezionato(this,schedaDocIngresso);							
									Page.RegisterStartupScript("","<script>window.close();</script>");
								}
								#endregion		
							}
						}
						else
						{
							//se entro qui � perch� si � verificato errore
							throw new Exception("Errore nella gestione dei corrispondenti nella risposta al protocollo");
						}
					}
				}
				else
				{
					//avviso l'utente che non ha selezionato nessun corrispondente
					Page.RegisterStartupScript("alert","<SCRIPT>alert('ATTENZIONE: selezionare un corrispondente dalla lista');</SCRIPT>");
				}
			}
			else
			{
				//avviso l'utente che non ha selezionato nulla
				Page.RegisterStartupScript("alert","<SCRIPT>alert('ATTENZIONE: selezionare un documento');</SCRIPT>");
			}
		}

		private string GestioneAvvisoModale(string valore)
		{
			string retValue=string.Empty;

			try
			{
				//prendo il protocollo in ingresso in sessione
				schedaDocIngresso = DocumentManager.getDocumentoInLavorazione(this);

				//prendo il protocollo in uscita selezionato dal datagrid
				infoDocSel = DocumentManager.getInfoDocumento(this);

				retValue=valore;

				switch (valore)
				{
					case "Y": //Gestione pulsante SI, CONTINUA
						
						/* Alla pressione del pulsante CONTINUA l'utente vuole proseguire il 
						 * collegamento nonostante oggetto e corrispondente dei due protocolli siano diversi */
				
						if(schedaDocIngresso!=null && schedaDocIngresso.protocollo!=null)
						{
							if(infoDocSel!=null)
							{
								schedaDocIngresso.rispostaDocumento = infoDocSel;
								schedaDocIngresso.modificaRispostaDocumento = true;
							}
						
							this.hd_returnValueModal.Value = "";	
						
							if(((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente == null)
							{
								if(RicercaProtocolliUscitaSessionMng.getCorrispondenteRisposta(this)!=null)
								{
									((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente = RicercaProtocolliUscitaSessionMng.getCorrispondenteRisposta(this);
								}
							}
							DocumentManager.setDocumentoSelezionato(this,schedaDocIngresso);
							//metto in sessione la scheda documento con le informazioni del protocollo a cui risponde
							
							Page.RegisterStartupScript("","<script>window.close();</script>");
						}

						break;

					case "N":
						
						/* Alla pressione del pulsante NO, RESETTA l'utente vuole proseguire il collegamento 
						 * con i dati che ha digitato sulla pagina di protocollo */
						
						
						if(schedaDocIngresso!=null && schedaDocIngresso.protocollo!=null)
						{
							if(infoDocSel!=null)
							{
								schedaDocIngresso.rispostaDocumento = infoDocSel;
								schedaDocIngresso.modificaRispostaDocumento = true;
							}

							if(schedaDocIngresso.oggetto != null)
							{
								schedaDocIngresso.oggetto.descrizione = infoDocSel.oggetto.ToString();
							}
							else
							{
								DocsPaWR.Oggetto ogg = new DocsPAWA.DocsPaWR.Oggetto();
								ogg.descrizione = infoDocSel.oggetto.ToString();
								schedaDocIngresso.oggetto = ogg;
							}

							if(RicercaProtocolliUscitaSessionMng.getCorrispondenteRisposta(this)!=null)
							{
								((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente = RicercaProtocolliUscitaSessionMng.getCorrispondenteRisposta(this);
							}

							//	popolo il campo mittente con il destinatario selezionato dal protocollo a cui ri risponde 
							//((DocsPAWA.DocsPaWR.ProtocolloEntrata)schedaDocIngresso.protocollo).mittente = destSelected;

							//metto in sessione la scheda documento con le informazioni del protocollo a cui risponde
							DocumentManager.setDocumentoSelezionato(this,schedaDocIngresso);
							Page.RegisterStartupScript("","<script>window.close();</script>");
						
							this.hd_returnValueModal.Value = "";
						}

						break;

						case "S":
							//non posso modificare il mittente o oggetto, quindi il pulsante continua
							//si limiter� a popolare il campo risposta al protocollo con l'infoDoc corrente
							if(schedaDocIngresso!=null && schedaDocIngresso.protocollo!=null)
							{
								if(infoDocSel!=null)
								{
									schedaDocIngresso.rispostaDocumento = infoDocSel;
									schedaDocIngresso.modificaRispostaDocumento = true;
								}
							}
							DocumentManager.setDocumentoSelezionato(this,schedaDocIngresso);
							Page.RegisterStartupScript("","<script>window.close();</script>");

						break;
				}
			}
			catch
			{

			}

			return retValue;
		}

		private string GetImage(string rowType)
		{
			string retValue=string.Empty;
			string spaceIndent=string.Empty;

			switch (rowType)
			{
				case "U":
					retValue="uo_noexp";
					spaceIndent="&nbsp;";
					break;

				case "R":
					retValue="ruolo_noexp";
					spaceIndent="&nbsp;";
					break;

				case "P":
					retValue="utente_noexp";
					spaceIndent="&nbsp;";
					break;
			}

			retValue=spaceIndent + "<img src='../images/smistamento/" + retValue + ".gif' border='0'>";

			return retValue;
		}

		#region METODI DI VERIFICA

		//VERIFICA SE � STATO SELEZIONATO ALMENO UNA OPZIONE (CORRISPONDENTE) NEL PANNELLO pnl_corr
		private bool verificaSelezione(out int itemIndex)
		{
			bool verificaSelezione = false;
			itemIndex = -1;
			foreach (DataGridItem dgItem in this.dg_lista_corr.Items)
			{		
				RadioButton optCorr=dgItem.Cells[3].FindControl("optCorr") as RadioButton;
				if ((optCorr!=null) && optCorr.Checked == true)
				{
					itemIndex = dgItem.ItemIndex;
					verificaSelezione = true;
					break;
				}
			}
			return verificaSelezione;
		}

		//VERIFICA SE � STATO SELEZIONATO un documento
		private bool verificaSelezioneDocumento()
		{
			bool verificaSelezione = false;
			if(DataGrid1.SelectedIndex >= 0)
					verificaSelezione = true;
					
			
			return verificaSelezione;
		}
		//VERIFICA se il mittente del protocollo in ingresso coincide con il destinatario selezionato
		//del protocollo in uscita a cui si sta rispondendo
		private bool verificaUguaglianzacorrispondenti(DocsPAWA.DocsPaWR.Corrispondente destSelected, DocsPAWA.DocsPaWR.Corrispondente mittCorrente)
		{
			bool verificaUguaglianza = false;
			if(destSelected.systemId==mittCorrente.systemId)
			{
				verificaUguaglianza = true;
			}
			return verificaUguaglianza;
		}

		private void btn_chiudi_Click(object sender, System.EventArgs e)
		{			
			Response.Write("<SCRIPT>window.close();</SCRIPT>");
		}

		private void chk_ADL_CheckedChanged(object sender, System.EventArgs e)
		{
			CheckBox cb = (CheckBox) sender;
			if(cb.Checked)
			{
				//se il checkBox � spuntato disablito i filtri di ricerca
				this.ddl_numProto.SelectedIndex = 0;
				this.ddl_dtaProto.SelectedIndex = 0;
				this.ddl_numProto.Enabled=false;
				this.ddl_dtaProto.Enabled=false;

				this.lblInitDtaProto.Visible=false;
				this.lblInitNumProto.Visible=false;
				this.lblEndDataProtocollo.Visible=false;
				this.lblEndNumProto.Visible=false;

				this.GetCalendarControl("txtInitDtaProto").txt_Data.Enabled=false;
                this.GetCalendarControl("txtInitDtaProto").btn_Cal.Visible = false;
				this.GetCalendarControl("txtInitDtaProto").txt_Data.Text=String.Empty;
				
				this.GetCalendarControl("txtEndDataProtocollo").Visible=false;
                this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Visible = false;
                this.GetCalendarControl("txtEndDataProtocollo").btn_Cal.Visible = false;
				this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Text = String.Empty;

				this.txtInitNumProto.Enabled=false;
				this.txtInitNumProto.Text = String.Empty;

				this.txt_annoProto.Enabled=false;
				this.txt_annoProto.Text = String.Empty;

                this.txtEndNumProto.Text = String.Empty;
                this.txtEndNumProto.Visible = false;

                 //GESTIONE CATENE EXTRA AOO
                if (UserManager.isFiltroAooEnabled(this))
                {
                    this.ddl_reg.Enabled = false;
                    if (this.ddl_reg.Items.Count > 0)
                    {
                        this.ddl_reg.SelectedIndex = 0;
                    }
                }
			}
			else
			{
				//se il checkBox non � spuntato

				//riabilito i filtri di ricerca
				this.ddl_numProto.Enabled=true;
				this.ddl_dtaProto.Enabled=true;
				this.txt_annoProto.Enabled=true;
				this.GetCalendarControl("txtInitDtaProto").txt_Data.Enabled=true;
                this.GetCalendarControl("txtInitDtaProto").btn_Cal.Visible = true;
                this.GetCalendarControl("txtInitDtaProto").txt_Data.Text = String.Empty;
                this.txtInitNumProto.Enabled = true;

                //GESTIONE CATENE EXTRA AOO
                if (UserManager.isFiltroAooEnabled(this))
                {
                    this.ddl_reg.Enabled = true;
                }

				string s = "<SCRIPT language='javascript'>try{document.getElementById('" + txtInitNumProto.ID + "').focus();} catch(e){}</SCRIPT>";
				RegisterStartupScript("focus", s);

			}
		}

		private void resetOption()
		{
			foreach (DataGridItem dgItem in this.dg_lista_corr.Items)
			{
				RadioButton optCorr = dgItem.Cells[3].FindControl("optCorr") as RadioButton;
				optCorr.Checked = false;			
			}			
		}

		private void btn_find_Click(object sender, System.EventArgs e)
		{
			try
			{	
				//impostazioni iniziali
				this.pnl_corr.Visible=false;
				this.DataGrid1.Visible = false;
				this.lbl_countRecord.Visible = false;
				//pulisce selezioni precedenti
				resetOption();

				RicercaProtocolliUscitaSessionMng.ClearSessionData(this);

				//fine impostazioni

				//INIZIO VALIDAZIONE DATI INPUT ALLA RICERCA				
				if(txtInitNumProto.Text!="")
				{
					if(IsValidNumber(txtInitNumProto)==false)
					{
						Response.Write("<script>alert('Il numero di protocollo deve essere numerico!');</script>");
						string s = "<SCRIPT language='javascript'>document.getElementById('" + txtInitNumProto.ID + "').focus();</SCRIPT>";
						RegisterStartupScript("focus", s);
						return;
					}
				}
				if(txtEndNumProto.Text!="")
				{
					if(IsValidNumber(txtEndNumProto)==false)
					{
						Response.Write("<script>alert('Il numero di protocollo deve essere numerico!');</script>");
						string s = "<SCRIPT language='javascript'>document.getElementById('" + txtEndNumProto.ID + "').focus();</SCRIPT>";
						RegisterStartupScript("focus", s);
						return;
					}
				}
				//controllo validit� anno inserito
				if(txt_annoProto.Text!="")
				{
					if(IsValidYear(txt_annoProto.Text)==false)
					{
						Response.Write("<script>alert('Formato anno non corretto !');</script>");
						string s = "<SCRIPT language='javascript'>document.getElementById('" + txt_annoProto.ID + "').focus();</SCRIPT>";
						RegisterStartupScript("focus", s);
						return;
					}
				}

                if (this.ddl_dtaProto.SelectedIndex == 1)
                {
                    if (Utils.isDate(this.GetCalendarControl("txtInitDtaProto").txt_Data.Text) && Utils.isDate(this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Text) && Utils.verificaIntervalloDate(this.GetCalendarControl("txtInitDtaProto").txt_Data.Text, this.GetCalendarControl("txtEndDataProtocollo").txt_Data.Text))
                    {
                        Response.Write("<script>alert('Verificare intervallo date !');</script>");
                        string s = "<SCRIPT language='javascript'>document.getElementById('" + this.GetCalendarControl("txtInitDtaProto").txt_Data.ID + "').focus();</SCRIPT>";
                        Page.ClientScript.RegisterStartupScript(this.GetType(), "focus", s);
                       // Response.Write("<script>top.principale.document.iFrame_dx.location='../blank_page.htm';</script>");
                        return;
                    }
                }

                // FINE VALIDAZIONE

				currentPage = 1 ;
				
				if (RicercaProtoUscita())
				{		
					DocumentManager.setFiltroRicDoc(this,qV);
					LoadData(true);
				}
			}
			catch(System.Exception ex)
			{
				ErrorManager.redirect(this,ex);
			}
		
		}


		#region classe per la gestione della sessione
		/// <summary>
		/// Classe per la gestione dei dati in sessione relativamente
		/// alla dialog "RicercaProtocolliUscita"
		/// </summary>
		public sealed class RicercaProtocolliUscitaSessionMng
		{
			private RicercaProtocolliUscitaSessionMng()
			{
			}

			/// <summary>
			/// Gestione rimozione dati in sessione
			/// </summary>
			/// <param name="page"></param>
			public static void ClearSessionData(Page page)
			{
				DocumentManager.removeFiltroRicDoc(page);
				DocumentManager.removeDataGridProtocolliUscita(page);
				
				DocumentManager.removeInfoDocumento(page);
				DocumentManager.removeHash(page);

				RemoveListaInfoDocumenti(page);
				page.Session.Remove("RicercaProtocolliUscitaSessionMng.dialogReturnValue");
				removeCorrispondenteRisposta(page);
				
			}

			public static void SetListaInfoDocumenti(Page page,DocsPaWR.InfoDocumento[] listaDocumenti)
			{
				page.Session["RicercaProtocolliUscita.ListaInfoDoc"]=listaDocumenti;
			}

			public static DocsPAWA.DocsPaWR.InfoDocumento[] GetListaInfoDocumenti(Page page)
			{
				return page.Session["RicercaProtocolliUscita.ListaInfoDoc"] as DocsPAWA.DocsPaWR.InfoDocumento[];
			}

			public static void RemoveListaInfoDocumenti(Page page)
			{
				page.Session.Remove("RicercaProtocolliUscita.ListaInfoDoc");
			}

			/// <summary>
			/// Impostazione flag booleano, se true, la dialog � stata caricata almeno una volta
			/// </summary>
			/// <param name="page"></param>
			public static void SetAsLoaded(Page page)
			{
				page.Session["RicercaProtocolliUscitaSessionMng.isLoaded"]=true;
			}

			/// <summary>
			/// Impostazione flag relativo al caricamento della dialog
			/// </summary>
			/// <param name="page"></param>
			public static void SetAsNotLoaded(Page page)
			{
				page.Session.Remove("RicercaProtocolliUscitaSessionMng.isLoaded");
			}

			/// <summary>
			/// Verifica se la dialog � stata caricata almeno una volta
			/// </summary>
			/// <param name="page"></param>
			/// <returns></returns>
			public static bool IsLoaded(Page page)
			{
				return (page.Session["RicercaProtocolliUscitaSessionMng.isLoaded"]!=null);
			}

			/// <summary>
			/// Impostazione valore di ritorno
			/// </summary>
			/// <param name="page"></param>
			/// <param name="dialogReturnValue"></param>
			public static void SetDialogReturnValue(Page page,bool dialogReturnValue)
			{
				page.Session["RicercaProtocolliUscitaSessionMng.dialogReturnValue"]=dialogReturnValue;
			}

			/// <summary>
			/// Reperimento valore di ritorno
			/// </summary>
			/// <param name="page"></param>
			/// <returns></returns>
			public static bool GetDialogReturnValue(Page page)
			{
				bool retValue=false;

				if (IsLoaded(page))
					retValue=Convert.ToBoolean(page.Session["RicercaProtocolliUscitaSessionMng.dialogReturnValue"]);

				page.Session.Remove("RicercaProtocolliUscitaSessionMng.isLoaded");

				return retValue;
			}

			/// <summary>
			/// Metodo per il settaggio in sessione del corrispondente selezionato per il protocollo di risposta
			/// </summary>
			/// <param name="page"></param>
			/// <param name="corrispondente"></param>
			public static void setCorrispondenteRisposta(Page page, DocsPAWA.DocsPaWR.Corrispondente corrispondente) 
			{
				page.Session["RicercaProtocolliUscita.corrispondenteRisposta"] = corrispondente;
			}

			public static DocsPAWA.DocsPaWR.Corrispondente getCorrispondenteRisposta(Page page) 
			{
				return (DocsPAWA.DocsPaWR.Corrispondente)page.Session["RicercaProtocolliUscita.corrispondenteRisposta"];
			}

			public static void removeCorrispondenteRisposta(Page page) 
			{
				page.Session.Remove("RicercaProtocolliUscita.corrispondenteRisposta");
			}
			#endregion

            
		}

        public void CaricaComboRegistri(DropDownList ddl)
        {
            userRegistri = UserManager.getListaRegistri(this);
            string stato;
            string inCondition = "IN ( ";
            string inConditionSimple = "";
            int elemento = 0;
            if (userRegistri.Length > 1)
            {
                for (int i = 0; i < userRegistri.Length; i++)
                {
                    stato = UserManager.getStatoRegistro(userRegistri[i]);
                    {
                        DocsPAWA.DocsPaWR.Registro registro = UserManager.getRegistroBySistemId(this.Page, userRegistri[i].systemId);
                        if (!registro.Sospeso)
                        {
                            ddl.Items.Add(userRegistri[i].codRegistro);
                            ddl.Items[elemento].Value = userRegistri[i].systemId;
                            elemento++;
                        }
                    }
                    inCondition = inCondition + userRegistri[i].systemId;
                    inConditionSimple = inConditionSimple + userRegistri[i].systemId;
                    if (i < userRegistri.Length - 1)
                    {
                        inCondition = inCondition + " , ";
                        inConditionSimple = inConditionSimple + " , ";
                    }
                }
                inCondition = inCondition + " )";
            }
            else
            {
                //� presente un solo registro quindi non faccio visualizzare la combo
                this.pnl_catene_extra_aoo.Visible = false;
            }
        }

        private void ddl_registri_SelectedIndexChanged(object sender, System.EventArgs e)
        {
            //mette in sessione il registro selezionato
          /*  if (ddl_registri.SelectedIndex != -1)
            {
                if (userRegistri == null)
                    userRegistri = UserManager.getListaRegistri(this);
                setStatoReg(UserManager.getRegistroBySistemId(this, ddl_registri.SelectedValue));
                setRegistro(UserManager.getRegistroBySistemId(this, ddl_registri.SelectedValue));

                this.Session["RegistroSelezionato"] = ddl_registri.SelectedValue.Trim();
            }*/
        }


	}

	
        #endregion

	
	
		
}
