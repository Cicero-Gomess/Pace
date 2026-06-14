namespace sistemaadmin
{
    partial class FormPosts
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
            this.pnlConteudo = new System.Windows.Forms.Panel();
            this.pnlCentro = new System.Windows.Forms.Panel();
            this.dgvPosts = new System.Windows.Forms.DataGridView();
            this.pnlEditar = new System.Windows.Forms.Panel();
            this.lblConteudo = new System.Windows.Forms.Label();
            this.txtConteudo = new System.Windows.Forms.TextBox();
            this.lblImagem = new System.Windows.Forms.Label();
            this.txtImagem = new System.Windows.Forms.TextBox();
            this.pnlRodape = new System.Windows.Forms.Panel();
            this.btnCriar = new System.Windows.Forms.Button();
            this.btnAtualizar = new System.Windows.Forms.Button();
            this.btnDeletar = new System.Windows.Forms.Button();
            this.btnRecarregar = new System.Windows.Forms.Button();
            this.btnCurtir = new System.Windows.Forms.Button();
            this.btnDescurtir = new System.Windows.Forms.Button();

            this.pnlTopo.SuspendLayout();
            this.pnlConteudo.SuspendLayout();
            this.pnlCentro.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvPosts)).BeginInit();
            this.pnlEditar.SuspendLayout();
            this.pnlRodape.SuspendLayout();
            this.SuspendLayout();

            // pnlTopo
            this.pnlTopo.BackColor = System.Drawing.Color.FromArgb(41, 128, 185);
            this.pnlTopo.Controls.Add(this.lblTitulo);
            this.pnlTopo.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlTopo.Padding = new System.Windows.Forms.Padding(20, 15, 20, 15);
            this.pnlTopo.Name = "pnlTopo";
            this.pnlTopo.Size = new System.Drawing.Size(1000, 60);
            this.pnlTopo.TabIndex = 0;

            // lblTitulo
            this.lblTitulo.AutoSize = false;
            this.lblTitulo.Font = new System.Drawing.Font("Microsoft Sans Serif", 18F, System.Drawing.FontStyle.Bold);
            this.lblTitulo.ForeColor = System.Drawing.Color.White;
            this.lblTitulo.Location = new System.Drawing.Point(20, 15);
            this.lblTitulo.Name = "lblTitulo";
            this.lblTitulo.Size = new System.Drawing.Size(400, 30);
            this.lblTitulo.TabIndex = 0;
            this.lblTitulo.Text = "Gerenciamento de Posts";

            // pnlConteudo
            this.pnlConteudo.Controls.Add(this.pnlCentro);
            this.pnlConteudo.Controls.Add(this.pnlEditar);
            this.pnlConteudo.Dock = System.Windows.Forms.DockStyle.Fill;
            this.pnlConteudo.Name = "pnlConteudo";
            this.pnlConteudo.Padding = new System.Windows.Forms.Padding(15);
            this.pnlConteudo.Size = new System.Drawing.Size(1000, 540);
            this.pnlConteudo.TabIndex = 1;

            // pnlCentro
            this.pnlCentro.Controls.Add(this.dgvPosts);
            this.pnlCentro.Dock = System.Windows.Forms.DockStyle.Fill;
            this.pnlCentro.Name = "pnlCentro";
            this.pnlCentro.Size = new System.Drawing.Size(600, 510);
            this.pnlCentro.TabIndex = 0;

            // dgvPosts
            this.dgvPosts.BackgroundColor = System.Drawing.Color.White;
            this.dgvPosts.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.dgvPosts.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvPosts.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvPosts.Location = new System.Drawing.Point(0, 0);
            this.dgvPosts.Name = "dgvPosts";
            this.dgvPosts.ReadOnly = true;
            this.dgvPosts.RowHeadersVisible = false;
            this.dgvPosts.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect;
            this.dgvPosts.Size = new System.Drawing.Size(600, 510);
            this.dgvPosts.TabIndex = 0;
            this.dgvPosts.SelectionChanged += new System.EventHandler(this.dgvPosts_SelectionChanged);

            // pnlEditar
            this.pnlEditar.BackColor = System.Drawing.Color.FromArgb(236, 240, 241);
            this.pnlEditar.Controls.Add(this.lblConteudo);
            this.pnlEditar.Controls.Add(this.txtConteudo);
            this.pnlEditar.Controls.Add(this.lblImagem);
            this.pnlEditar.Controls.Add(this.txtImagem);
            this.pnlEditar.Dock = System.Windows.Forms.DockStyle.Right;
            this.pnlEditar.Name = "pnlEditar";
            this.pnlEditar.Padding = new System.Windows.Forms.Padding(15);
            this.pnlEditar.Size = new System.Drawing.Size(370, 510);
            this.pnlEditar.TabIndex = 1;

            // lblConteudo
            this.lblConteudo.AutoSize = true;
            this.lblConteudo.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.lblConteudo.ForeColor = System.Drawing.Color.FromArgb(44, 62, 80);
            this.lblConteudo.Location = new System.Drawing.Point(15, 15);
            this.lblConteudo.Name = "lblConteudo";
            this.lblConteudo.Size = new System.Drawing.Size(100, 17);
            this.lblConteudo.TabIndex = 0;
            this.lblConteudo.Text = "Conteúdo:";

            // txtConteudo
            this.txtConteudo.BackColor = System.Drawing.Color.White;
            this.txtConteudo.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtConteudo.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.txtConteudo.Location = new System.Drawing.Point(15, 35);
            this.txtConteudo.Multiline = true;
            this.txtConteudo.Name = "txtConteudo";
            this.txtConteudo.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.txtConteudo.Size = new System.Drawing.Size(340, 180);
            this.txtConteudo.TabIndex = 1;

            // lblImagem
            this.lblImagem.AutoSize = true;
            this.lblImagem.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.lblImagem.ForeColor = System.Drawing.Color.FromArgb(44, 62, 80);
            this.lblImagem.Location = new System.Drawing.Point(15, 225);
            this.lblImagem.Name = "lblImagem";
            this.lblImagem.Size = new System.Drawing.Size(120, 17);
            this.lblImagem.TabIndex = 2;
            this.lblImagem.Text = "URL da Imagem:";

            // txtImagem
            this.txtImagem.BackColor = System.Drawing.Color.White;
            this.txtImagem.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtImagem.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.txtImagem.Location = new System.Drawing.Point(15, 245);
            this.txtImagem.Multiline = true;
            this.txtImagem.Name = "txtImagem";
            this.txtImagem.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.txtImagem.Size = new System.Drawing.Size(340, 60);
            this.txtImagem.TabIndex = 3;

            // pnlRodape
            this.pnlRodape.BackColor = System.Drawing.Color.White;
            this.pnlRodape.Controls.Add(this.btnCriar);
            this.pnlRodape.Controls.Add(this.btnAtualizar);
            this.pnlRodape.Controls.Add(this.btnDeletar);
            this.pnlRodape.Controls.Add(this.btnRecarregar);
            this.pnlRodape.Controls.Add(this.btnCurtir);
            this.pnlRodape.Controls.Add(this.btnDescurtir);
            this.pnlRodape.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.pnlRodape.Name = "pnlRodape";
            this.pnlRodape.Padding = new System.Windows.Forms.Padding(15);
            this.pnlRodape.Size = new System.Drawing.Size(1000, 60);
            this.pnlRodape.TabIndex = 2;

            // btnCriar (Verde)
            this.btnCriar.BackColor = System.Drawing.Color.FromArgb(46, 204, 113);
            this.btnCriar.FlatAppearance.BorderSize = 0;
            this.btnCriar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnCriar.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnCriar.ForeColor = System.Drawing.Color.White;
            this.btnCriar.Location = new System.Drawing.Point(15, 15);
            this.btnCriar.Name = "btnCriar";
            this.btnCriar.Size = new System.Drawing.Size(110, 35);
            this.btnCriar.TabIndex = 0;
            this.btnCriar.Text = "Criar";
            this.btnCriar.UseVisualStyleBackColor = false;
            this.btnCriar.Click += new System.EventHandler(this.btnCriar_Click);

            // btnAtualizar (Amarelo)
            this.btnAtualizar.BackColor = System.Drawing.Color.FromArgb(241, 196, 15);
            this.btnAtualizar.FlatAppearance.BorderSize = 0;
            this.btnAtualizar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnAtualizar.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnAtualizar.ForeColor = System.Drawing.Color.White;
            this.btnAtualizar.Location = new System.Drawing.Point(135, 15);
            this.btnAtualizar.Name = "btnAtualizar";
            this.btnAtualizar.Size = new System.Drawing.Size(110, 35);
            this.btnAtualizar.TabIndex = 1;
            this.btnAtualizar.Text = "Atualizar";
            this.btnAtualizar.UseVisualStyleBackColor = false;
            this.btnAtualizar.Click += new System.EventHandler(this.btnAtualizar_Click);

            // btnDeletar (Vermelho)
            this.btnDeletar.BackColor = System.Drawing.Color.FromArgb(231, 76, 60);
            this.btnDeletar.FlatAppearance.BorderSize = 0;
            this.btnDeletar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnDeletar.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnDeletar.ForeColor = System.Drawing.Color.White;
            this.btnDeletar.Location = new System.Drawing.Point(255, 15);
            this.btnDeletar.Name = "btnDeletar";
            this.btnDeletar.Size = new System.Drawing.Size(110, 35);
            this.btnDeletar.TabIndex = 2;
            this.btnDeletar.Text = "Deletar";
            this.btnDeletar.UseVisualStyleBackColor = false;
            this.btnDeletar.Click += new System.EventHandler(this.btnDeletar_Click);

            // btnRecarregar (Neutro)
            this.btnRecarregar.BackColor = System.Drawing.Color.FromArgb(52, 73, 94);
            this.btnRecarregar.FlatAppearance.BorderSize = 0;
            this.btnRecarregar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnRecarregar.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnRecarregar.ForeColor = System.Drawing.Color.White;
            this.btnRecarregar.Location = new System.Drawing.Point(375, 15);
            this.btnRecarregar.Name = "btnRecarregar";
            this.btnRecarregar.Size = new System.Drawing.Size(110, 35);
            this.btnRecarregar.TabIndex = 3;
            this.btnRecarregar.Text = "Recarregar";
            this.btnRecarregar.UseVisualStyleBackColor = false;
            this.btnRecarregar.Click += new System.EventHandler(this.btnRecarregar_Click);

            // btnCurtir (Coração Vermelho)
            this.btnCurtir.BackColor = System.Drawing.Color.FromArgb(231, 76, 60);
            this.btnCurtir.FlatAppearance.BorderSize = 0;
            this.btnCurtir.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnCurtir.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnCurtir.ForeColor = System.Drawing.Color.White;
            this.btnCurtir.Location = new System.Drawing.Point(495, 15);
            this.btnCurtir.Name = "btnCurtir";
            this.btnCurtir.Size = new System.Drawing.Size(110, 35);
            this.btnCurtir.TabIndex = 4;
            this.btnCurtir.Text = "❤️ Curtir";
            this.btnCurtir.UseVisualStyleBackColor = false;
            this.btnCurtir.Click += new System.EventHandler(this.btnCurtir_Click);

            // btnDescurtir (Coração Cinza)
            this.btnDescurtir.BackColor = System.Drawing.Color.FromArgb(149, 165, 166);
            this.btnDescurtir.FlatAppearance.BorderSize = 0;
            this.btnDescurtir.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnDescurtir.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnDescurtir.ForeColor = System.Drawing.Color.White;
            this.btnDescurtir.Location = new System.Drawing.Point(615, 15);
            this.btnDescurtir.Name = "btnDescurtir";
            this.btnDescurtir.Size = new System.Drawing.Size(110, 35);
            this.btnDescurtir.TabIndex = 5;
            this.btnDescurtir.Text = "💔 Descurtir";
            this.btnDescurtir.UseVisualStyleBackColor = false;
            this.btnDescurtir.Click += new System.EventHandler(this.btnDescurtir_Click);

            // FormPosts
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(1000, 660);
            this.Controls.Add(this.pnlConteudo);
            this.Controls.Add(this.pnlRodape);
            this.Controls.Add(this.pnlTopo);
            this.Name = "FormPosts";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Gerenciamento de Posts";
            this.Load += new System.EventHandler(this.FormPosts_Load);

            this.pnlTopo.ResumeLayout(false);
            this.pnlConteudo.ResumeLayout(false);
            this.pnlCentro.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvPosts)).EndInit();
            this.pnlEditar.ResumeLayout(false);
            this.pnlEditar.PerformLayout();
            this.pnlRodape.ResumeLayout(false);
            this.ResumeLayout(false);
        }

        #endregion

        private System.Windows.Forms.Panel pnlTopo;
        private System.Windows.Forms.Label lblTitulo;
        private System.Windows.Forms.Panel pnlConteudo;
        private System.Windows.Forms.Panel pnlCentro;
        private System.Windows.Forms.DataGridView dgvPosts;
        private System.Windows.Forms.Panel pnlEditar;
        private System.Windows.Forms.Label lblConteudo;
        private System.Windows.Forms.TextBox txtConteudo;
        private System.Windows.Forms.Label lblImagem;
        private System.Windows.Forms.TextBox txtImagem;
        private System.Windows.Forms.Panel pnlRodape;
        private System.Windows.Forms.Button btnCriar;
        private System.Windows.Forms.Button btnAtualizar;
        private System.Windows.Forms.Button btnDeletar;
        private System.Windows.Forms.Button btnRecarregar;
        private System.Windows.Forms.Button btnCurtir;
        private System.Windows.Forms.Button btnDescurtir;
    }
}
