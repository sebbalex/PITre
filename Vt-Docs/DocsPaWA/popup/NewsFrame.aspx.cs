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

namespace DocsPAWA.popup
{
	/// <summary>
	/// Summary description for NewsFrame.
	/// </summary>
    public class NewsFrame : DocsPAWA.CssPage
	{
        protected DocsPaWebCtrlLibrary.IFrameWebControl IF_News;

		private void Page_Load(object sender, System.EventArgs e)
		{
            string url = string.Empty;
            url = Request.QueryString["pagina"];
            if(string.IsNullOrEmpty(url))
                url = "../blank_page.htm";
            this.IF_News.NavigateTo = url;
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
			this.Load += new System.EventHandler(this.Page_Load);
		}
		#endregion
	}
}
