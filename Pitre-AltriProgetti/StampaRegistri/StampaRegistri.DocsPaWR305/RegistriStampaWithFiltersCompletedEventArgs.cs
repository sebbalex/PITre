using System;
using System.CodeDom.Compiler;
using System.ComponentModel;
using System.Diagnostics;

namespace StampaRegistri.DocsPaWR305
{
	[GeneratedCode("System.Web.Services", "2.0.50727.42"), DesignerCategory("code"), DebuggerStepThrough]
	public class RegistriStampaWithFiltersCompletedEventArgs : AsyncCompletedEventArgs
	{
		private object[] results;

		public StampaRegistroResult Result
		{
			get
			{
				base.RaiseExceptionIfNecessary();
				return (StampaRegistroResult)this.results[0];
			}
		}

		public FileDocumento fileDoc
		{
			get
			{
				base.RaiseExceptionIfNecessary();
				return (FileDocumento)this.results[1];
			}
		}

		internal RegistriStampaWithFiltersCompletedEventArgs(object[] results, Exception exception, bool cancelled, object userState) : base(exception, cancelled, userState)
		{
			this.results = results;
		}
	}
}
