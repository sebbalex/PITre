﻿using System;
using System.Collections;
using System.Configuration;
using System.Data;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using System.Web.UI.WebControls.WebParts;

namespace DocsPAWA.AdminTool.Gestione_Help
{
    public partial class Manuale : System.Web.UI.Page
    {
        protected string from;

        protected void Page_Load(object sender, EventArgs e)
        {
            this.from = this.Request.QueryString["from"];
        }
    }
}
