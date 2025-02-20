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

namespace SAAdminTool.UserControls
{
	/// <summary>
	/// Summary description for DialogCalendario.
	/// </summary>
    public class DialogCalendar : SAAdminTool.CssPage
	{
		protected System.Web.UI.HtmlControls.HtmlInputHidden txtSelectedDate;
		protected System.Web.UI.WebControls.Calendar ctlCalendario;
	
		private void Page_Load(object sender, System.EventArgs e)
		{
            Response.Expires = -1;
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
			this.ctlCalendario.SelectionChanged += new System.EventHandler(this.ctlCalendario_SelectionChanged);
			this.Load += new System.EventHandler(this.Page_Load);

		}
		#endregion

		private void ctlCalendario_SelectionChanged(object sender, System.EventArgs e)
		{
			this.SetSelectedDate();
			this.RegisterClientScript("CloseWindow","CloseWindow();");
		}

		/// <summary>
		/// Impostazione data selezionata in un campo nascosto
		/// </summary>
		private void SetSelectedDate()
		{
			this.txtSelectedDate.Value=this.ctlCalendario.SelectedDate.ToShortDateString();            
		}

		#region Gestione javascript

		/// <summary>
		/// Registrazione script client
		/// </summary>
		/// <param name="scriptKey"></param>
		/// <param name="scriptValue"></param>
		private void RegisterClientScript(string scriptKey,string scriptValue)
		{
			if(!this.Page.IsStartupScriptRegistered(scriptKey))
			{
				string scriptString = "<SCRIPT>" + scriptValue + "</SCRIPT>";
				this.Page.RegisterStartupScript(scriptKey, scriptString);
			}
		}

		#endregion
	}
}
