namespace sistemaadmin
{
    partial class FormPerfil
    {
        /// <summary>
        /// Variável de designer necessária.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Limpar os recursos que estão sendo usados.
        /// </summary>
        /// <param name="disposing">true se for necessário descartar os recursos gerenciados; caso contrário, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Código gerado pelo Windows Form Designer

        /// <summary>
        /// Método necessário para suporte ao Designer - não modifique 
        /// o conteúdo deste método com o editor de código.
        /// </summary>
        private void InitializeComponent()
        {
            this.pnlTopo = new System.Windows.Forms.Panel();
            this.lblTitulo = new System.Windows.Forms.Label();
            this.pnlCard = new System.Windows.Forms.Panel();
            this.picFoto = new System.Windows.Forms.PictureBox();
            this.lblUsername = new System.Windows.Forms.Label();
            this.lblUsernameValor = new System.Windows.Forms.Label();
            this.lblEmail = new System.Windows.Forms.Label();
            this.lblEmailValor = new System.Windows.Forms.Label();
            this.lblNovaFoto = new System.Windows.Forms.Label();
            this.txtNovaFotoUrl = new System.Windows.Forms.TextBox();
            this.btnAtualizarFoto = new System.Windows.Forms.Button();
            this.btnRecarregarPerfil = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.picFoto)).BeginInit();
            this.pnlTopo.SuspendLayout();
            this.pnlCard.SuspendLayout();
            this.SuspendLayout();

            // pnlTopo
            this.pnlTopo.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(41)))), ((int)(((byte)(128)))), ((int)(((byte)(185)))));
            this.pnlTopo.Controls.Add(this.lblTitulo);
            this.pnlTopo.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlTopo.Height = 70;
            this.pnlTopo.Name = "pnlTopo";
            this.pnlTopo.Padding = new System.Windows.Forms.Padding(20);
            this.pnlTopo.Size = new System.Drawing.Size(700, 70);
            this.pnlTopo.TabIndex = 0;

            // lblTitulo
            this.lblTitulo.AutoSize = false;
            this.lblTitulo.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            this.lblTitulo.Dock = System.Windows.Forms.DockStyle.Fill;
            this.lblTitulo.Font = new System.Drawing.Font("Segoe UI", 24F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblTitulo.ForeColor = System.Drawing.Color.White;
            this.lblTitulo.Location = new System.Drawing.Point(20, 20);
            this.lblTitulo.Name = "lblTitulo";
            this.lblTitulo.Size = new System.Drawing.Size(660, 30);
            this.lblTitulo.TabIndex = 0;
            this.lblTitulo.Text = "Perfil do Usuário";

            // pnlCard
            this.pnlCard.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(236)))), ((int)(((byte)(240)))), ((int)(((byte)(241)))));
            this.pnlCard.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.pnlCard.Controls.Add(this.picFoto);
            this.pnlCard.Controls.Add(this.lblUsername);
            this.pnlCard.Controls.Add(this.lblUsernameValor);
            this.pnlCard.Controls.Add(this.lblEmail);
            this.pnlCard.Controls.Add(this.lblEmailValor);
            this.pnlCard.Controls.Add(this.lblNovaFoto);
            this.pnlCard.Controls.Add(this.txtNovaFotoUrl);
            this.pnlCard.Controls.Add(this.btnAtualizarFoto);
            this.pnlCard.Controls.Add(this.btnRecarregarPerfil);
            this.pnlCard.Location = new System.Drawing.Point(50, 90);
            this.pnlCard.Name = "pnlCard";
            this.pnlCard.Size = new System.Drawing.Size(600, 580);
            this.pnlCard.TabIndex = 1;

            // picFoto
            this.picFoto.BackColor = System.Drawing.Color.White;
            this.picFoto.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.picFoto.Location = new System.Drawing.Point(175, 20);
            this.picFoto.Name = "picFoto";
            this.picFoto.Size = new System.Drawing.Size(250, 250);
            this.picFoto.SizeMode = System.Windows.Forms.PictureBoxSizeMode.StretchImage;
            this.picFoto.TabIndex = 0;
            this.picFoto.TabStop = false;

            // lblUsername
            this.lblUsername.AutoSize = true;
            this.lblUsername.Font = new System.Drawing.Font("Segoe UI", 11F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblUsername.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(52)))), ((int)(((byte)(73)))), ((int)(((byte)(94)))));
            this.lblUsername.Location = new System.Drawing.Point(30, 290);
            this.lblUsername.Name = "lblUsername";
            this.lblUsername.Size = new System.Drawing.Size(100, 20);
            this.lblUsername.TabIndex = 1;
            this.lblUsername.Text = "Username:";

            // lblUsernameValor
            this.lblUsernameValor.AutoSize = true;
            this.lblUsernameValor.Font = new System.Drawing.Font("Segoe UI", 11F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblUsernameValor.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(52)))), ((int)(((byte)(73)))), ((int)(((byte)(94)))));
            this.lblUsernameValor.Location = new System.Drawing.Point(140, 290);
            this.lblUsernameValor.Name = "lblUsernameValor";
            this.lblUsernameValor.Size = new System.Drawing.Size(30, 20);
            this.lblUsernameValor.TabIndex = 2;
            this.lblUsernameValor.Text = "---";

            // lblEmail
            this.lblEmail.AutoSize = true;
            this.lblEmail.Font = new System.Drawing.Font("Segoe UI", 11F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblEmail.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(52)))), ((int)(((byte)(73)))), ((int)(((byte)(94)))));
            this.lblEmail.Location = new System.Drawing.Point(30, 330);
            this.lblEmail.Name = "lblEmail";
            this.lblEmail.Size = new System.Drawing.Size(55, 20);
            this.lblEmail.TabIndex = 3;
            this.lblEmail.Text = "Email:";

            // lblEmailValor
            this.lblEmailValor.AutoSize = true;
            this.lblEmailValor.Font = new System.Drawing.Font("Segoe UI", 11F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblEmailValor.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(52)))), ((int)(((byte)(73)))), ((int)(((byte)(94)))));
            this.lblEmailValor.Location = new System.Drawing.Point(140, 330);
            this.lblEmailValor.Name = "lblEmailValor";
            this.lblEmailValor.Size = new System.Drawing.Size(30, 20);
            this.lblEmailValor.TabIndex = 4;
            this.lblEmailValor.Text = "---";

            // lblNovaFoto
            this.lblNovaFoto.AutoSize = true;
            this.lblNovaFoto.Font = new System.Drawing.Font("Segoe UI", 11F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lblNovaFoto.ForeColor = System.Drawing.Color.FromArgb(((int)(((byte)(52)))), ((int)(((byte)(73)))), ((int)(((byte)(94)))));
            this.lblNovaFoto.Location = new System.Drawing.Point(30, 385);
            this.lblNovaFoto.Name = "lblNovaFoto";
            this.lblNovaFoto.Size = new System.Drawing.Size(130, 20);
            this.lblNovaFoto.TabIndex = 5;
            this.lblNovaFoto.Text = "Nova Foto (URL):";

            // txtNovaFotoUrl
            this.txtNovaFotoUrl.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtNovaFotoUrl.Font = new System.Drawing.Font("Segoe UI", 10F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.txtNovaFotoUrl.Location = new System.Drawing.Point(30, 415);
            this.txtNovaFotoUrl.Multiline = true;
            this.txtNovaFotoUrl.Name = "txtNovaFotoUrl";
            this.txtNovaFotoUrl.Size = new System.Drawing.Size(540, 35);
            this.txtNovaFotoUrl.TabIndex = 6;

            // btnAtualizarFoto
            this.btnAtualizarFoto.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(46)))), ((int)(((byte)(204)))), ((int)(((byte)(113)))));
            this.btnAtualizarFoto.Cursor = System.Windows.Forms.Cursors.Hand;
            this.btnAtualizarFoto.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnAtualizarFoto.Font = new System.Drawing.Font("Segoe UI", 11F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnAtualizarFoto.ForeColor = System.Drawing.Color.White;
            this.btnAtualizarFoto.Location = new System.Drawing.Point(30, 470);
            this.btnAtualizarFoto.Name = "btnAtualizarFoto";
            this.btnAtualizarFoto.Size = new System.Drawing.Size(260, 45);
            this.btnAtualizarFoto.TabIndex = 7;
            this.btnAtualizarFoto.Text = "✓ Atualizar Foto";
            this.btnAtualizarFoto.UseVisualStyleBackColor = false;
            this.btnAtualizarFoto.Click += new System.EventHandler(this.BtnAtualizarFoto_Click);

            // btnRecarregarPerfil
            this.btnRecarregarPerfil.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(52)))), ((int)(((byte)(152)))), ((int)(((byte)(219)))));
            this.btnRecarregarPerfil.Cursor = System.Windows.Forms.Cursors.Hand;
            this.btnRecarregarPerfil.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnRecarregarPerfil.Font = new System.Drawing.Font("Segoe UI", 11F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.btnRecarregarPerfil.ForeColor = System.Drawing.Color.White;
            this.btnRecarregarPerfil.Location = new System.Drawing.Point(310, 470);
            this.btnRecarregarPerfil.Name = "btnRecarregarPerfil";
            this.btnRecarregarPerfil.Size = new System.Drawing.Size(260, 45);
            this.btnRecarregarPerfil.TabIndex = 8;
            this.btnRecarregarPerfil.Text = "🔄 Recarregar Perfil";
            this.btnRecarregarPerfil.UseVisualStyleBackColor = false;
            this.btnRecarregarPerfil.Click += new System.EventHandler(this.BtnRecarregarPerfil_Click);

            // FormPerfil
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(700, 800);
            this.Controls.Add(this.pnlCard);
            this.Controls.Add(this.pnlTopo);
            this.Name = "FormPerfil";
            this.Text = "Perfil do Usuário";
            this.Load += new System.EventHandler(this.FormPerfil_Load);
            ((System.ComponentModel.ISupportInitialize)(this.picFoto)).EndInit();
            this.pnlTopo.ResumeLayout(false);
            this.pnlCard.ResumeLayout(false);
            this.pnlCard.PerformLayout();
            this.ResumeLayout(false);
        }

        #endregion

        private System.Windows.Forms.Panel pnlTopo;
        private System.Windows.Forms.Label lblTitulo;
        private System.Windows.Forms.Panel pnlCard;
        private System.Windows.Forms.PictureBox picFoto;
        private System.Windows.Forms.Label lblUsername;
        private System.Windows.Forms.Label lblUsernameValor;
        private System.Windows.Forms.Label lblEmail;
        private System.Windows.Forms.Label lblEmailValor;
        private System.Windows.Forms.Label lblNovaFoto;
        private System.Windows.Forms.TextBox txtNovaFotoUrl;
        private System.Windows.Forms.Button btnAtualizarFoto;
        private System.Windows.Forms.Button btnRecarregarPerfil;
    }
}
