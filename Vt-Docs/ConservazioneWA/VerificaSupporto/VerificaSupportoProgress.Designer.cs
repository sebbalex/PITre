﻿namespace VerificaSupporto
{
    partial class VerificaSupportoProgress
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.btnAnnulla = new System.Windows.Forms.Button();
            this.prgElaborazione = new System.Windows.Forms.ProgressBar();
            this.lblElaborazione = new System.Windows.Forms.Label();
            this.SuspendLayout();
            // 
            // btnAnnulla
            // 
            this.btnAnnulla.DialogResult = System.Windows.Forms.DialogResult.Cancel;
            this.btnAnnulla.FlatStyle = System.Windows.Forms.FlatStyle.Popup;
            this.btnAnnulla.Location = new System.Drawing.Point(403, 63);
            this.btnAnnulla.Name = "btnAnnulla";
            this.btnAnnulla.Size = new System.Drawing.Size(75, 23);
            this.btnAnnulla.TabIndex = 0;
            this.btnAnnulla.Text = "&Annulla";
            this.btnAnnulla.UseVisualStyleBackColor = true;
            this.btnAnnulla.Click += new System.EventHandler(this.btnAnnulla_Click);
            // 
            // prgElaborazione
            // 
            this.prgElaborazione.Location = new System.Drawing.Point(11, 9);
            this.prgElaborazione.Name = "prgElaborazione";
            this.prgElaborazione.Size = new System.Drawing.Size(467, 23);
            this.prgElaborazione.Style = System.Windows.Forms.ProgressBarStyle.Continuous;
            this.prgElaborazione.TabIndex = 1;
            // 
            // lblElaborazione
            // 
            this.lblElaborazione.AutoSize = true;
            this.lblElaborazione.Location = new System.Drawing.Point(8, 44);
            this.lblElaborazione.Name = "lblElaborazione";
            this.lblElaborazione.Size = new System.Drawing.Size(0, 13);
            this.lblElaborazione.TabIndex = 2;
            // 
            // VerificaSupportoProgress
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.CancelButton = this.btnAnnulla;
            this.ClientSize = new System.Drawing.Size(490, 98);
            this.Controls.Add(this.lblElaborazione);
            this.Controls.Add(this.prgElaborazione);
            this.Controls.Add(this.btnAnnulla);
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "VerificaSupportoProgress";
            this.ShowIcon = false;
            this.ShowInTaskbar = false;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Verifica supporto";
            this.Shown += new System.EventHandler(this.VerificaSupportoProgress_Shown);
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnAnnulla;
        private System.Windows.Forms.ProgressBar prgElaborazione;
        private System.Windows.Forms.Label lblElaborazione;
    }
}