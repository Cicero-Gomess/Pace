namespace sistemaadmin
{
    partial class FormComentarios
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
            this.pnlFiltro = new System.Windows.Forms.Panel();
            this.lblPostId = new System.Windows.Forms.Label();
            this.txtPostId = new System.Windows.Forms.TextBox();
            this.btnCarregar = new System.Windows.Forms.Button();
            this.pnlCentro = new System.Windows.Forms.Panel();
            this.dgvComentarios = new System.Windows.Forms.DataGridView();
            this.pnlEdicao = new System.Windows.Forms.Panel();
            this.lblComentario = new System.Windows.Forms.Label();
            this.txtComentario = new System.Windows.Forms.TextBox();
            this.pnlRodape = new System.Windows.Forms.Panel();
            this.btnAdicionar = new System.Windows.Forms.Button();
            this.btnAtualizar = new System.Windows.Forms.Button();
            this.btnDeletar = new System.Windows.Forms.Button();
            this.btnLimpar = new System.Windows.Forms.Button();

            this.pnlTopo.SuspendLayout();
            this.pnlFiltro.SuspendLayout();
            this.pnlCentro.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvComentarios)).BeginInit();
            this.pnlEdicao.SuspendLayout();
            this.pnlRodape.SuspendLayout();
            this.SuspendLayout();

            // pnlTopo
            this.pnlTopo.BackColor = System.Drawing.Color.FromArgb(41, 128, 185);
            this.pnlTopo.Controls.Add(this.lblTitulo);
            this.pnlTopo.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlTopo.Padding = new System.Windows.Forms.Padding(20, 15, 20, 15);
            this.pnlTopo.Name = "pnlTopo";
            this.pnlTopo.Size = new System.Drawing.Size(1100, 60);
            this.pnlTopo.TabIndex = 0;

            // lblTitulo
            this.lblTitulo.AutoSize = false;
            this.lblTitulo.Font = new System.Drawing.Font("Microsoft Sans Serif", 18F, System.Drawing.FontStyle.Bold);
            this.lblTitulo.ForeColor = System.Drawing.Color.White;
            this.lblTitulo.Location = new System.Drawing.Point(20, 15);
            this.lblTitulo.Name = "lblTitulo";
            this.lblTitulo.Size = new System.Drawing.Size(450, 30);
            this.lblTitulo.TabIndex = 0;
            this.lblTitulo.Text = "Gerenciamento de Comentários";

            // pnlFiltro
            this.pnlFiltro.BackColor = System.Drawing.Color.FromArgb(236, 240, 241);
            this.pnlFiltro.Controls.Add(this.lblPostId);
            this.pnlFiltro.Controls.Add(this.txtPostId);
            this.pnlFiltro.Controls.Add(this.btnCarregar);
            this.pnlFiltro.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlFiltro.Name = "pnlFiltro";
            this.pnlFiltro.Padding = new System.Windows.Forms.Padding(15);
            this.pnlFiltro.Size = new System.Drawing.Size(1100, 60);
            this.pnlFiltro.TabIndex = 1;

            // lblPostId
            this.lblPostId.AutoSize = true;
            this.lblPostId.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.lblPostId.ForeColor = System.Drawing.Color.FromArgb(44, 62, 80);
            this.lblPostId.Location = new System.Drawing.Point(15, 17);
            this.lblPostId.Name = "lblPostId";
            this.lblPostId.Size = new System.Drawing.Size(100, 17);
            this.lblPostId.TabIndex = 0;
            this.lblPostId.Text = "ID do Post:";

            // txtPostId
            this.txtPostId.BackColor = System.Drawing.Color.White;
            this.txtPostId.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtPostId.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F);
            this.txtPostId.Location = new System.Drawing.Point(125, 15);
            this.txtPostId.Name = "txtPostId";
            this.txtPostId.Size = new System.Drawing.Size(80, 23);
            this.txtPostId.TabIndex = 1;

            // btnCarregar
            this.btnCarregar.BackColor = System.Drawing.Color.FromArgb(52, 152, 219);
            this.btnCarregar.FlatAppearance.BorderSize = 0;
            this.btnCarregar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnCarregar.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnCarregar.ForeColor = System.Drawing.Color.White;
            this.btnCarregar.Location = new System.Drawing.Point(215, 15);
            this.btnCarregar.Name = "btnCarregar";
            this.btnCarregar.Size = new System.Drawing.Size(150, 30);
            this.btnCarregar.TabIndex = 2;
            this.btnCarregar.Text = "Carregar Comentários";
            this.btnCarregar.UseVisualStyleBackColor = false;
            this.btnCarregar.Click += new System.EventHandler(this.btnCarregar_Click);

            // pnlCentro
            this.pnlCentro.Controls.Add(this.dgvComentarios);
            this.pnlCentro.Dock = System.Windows.Forms.DockStyle.Fill;
            this.pnlCentro.Name = "pnlCentro";
            this.pnlCentro.Padding = new System.Windows.Forms.Padding(15);
            this.pnlCentro.Size = new System.Drawing.Size(1100, 400);
            this.pnlCentro.TabIndex = 2;

            // dgvComentarios
            this.dgvComentarios.BackgroundColor = System.Drawing.Color.White;
            this.dgvComentarios.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.dgvComentarios.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvComentarios.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvComentarios.Location = new System.Drawing.Point(15, 15);
            this.dgvComentarios.Name = "dgvComentarios";
            this.dgvComentarios.ReadOnly = true;
            this.dgvComentarios.RowHeadersVisible = false;
            this.dgvComentarios.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect;
            this.dgvComentarios.Size = new System.Drawing.Size(1070, 370);
            this.dgvComentarios.TabIndex = 0;
            this.dgvComentarios.SelectionChanged += new System.EventHandler(this.dgvComentarios_SelectionChanged);

            // pnlEdicao
            this.pnlEdicao.BackColor = System.Drawing.Color.FromArgb(236, 240, 241);
            this.pnlEdicao.Controls.Add(this.lblComentario);
            this.pnlEdicao.Controls.Add(this.txtComentario);
            this.pnlEdicao.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.pnlEdicao.Name = "pnlEdicao";
            this.pnlEdicao.Padding = new System.Windows.Forms.Padding(15);
            this.pnlEdicao.Size = new System.Drawing.Size(1100, 140);
            this.pnlEdicao.TabIndex = 3;

            // lblComentario
            this.lblComentario.AutoSize = true;
            this.lblComentario.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.lblComentario.ForeColor = System.Drawing.Color.FromArgb(44, 62, 80);
            this.lblComentario.Location = new System.Drawing.Point(15, 15);
            this.lblComentario.Name = "lblComentario";
            this.lblComentario.Size = new System.Drawing.Size(150, 17);
            this.lblComentario.TabIndex = 0;
            this.lblComentario.Text = "Conteúdo do Comentário:";

            // txtComentario
            this.txtComentario.BackColor = System.Drawing.Color.White;
            this.txtComentario.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtComentario.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.txtComentario.Location = new System.Drawing.Point(15, 35);
            this.txtComentario.Multiline = true;
            this.txtComentario.Name = "txtComentario";
            this.txtComentario.ScrollBars = System.Windows.Forms.ScrollBars.Vertical;
            this.txtComentario.Size = new System.Drawing.Size(1070, 90);
            this.txtComentario.TabIndex = 1;

            // pnlRodape
            this.pnlRodape.BackColor = System.Drawing.Color.White;
            this.pnlRodape.Controls.Add(this.btnAdicionar);
            this.pnlRodape.Controls.Add(this.btnAtualizar);
            this.pnlRodape.Controls.Add(this.btnDeletar);
            this.pnlRodape.Controls.Add(this.btnLimpar);
            this.pnlRodape.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.pnlRodape.Name = "pnlRodape";
            this.pnlRodape.Padding = new System.Windows.Forms.Padding(15);
            this.pnlRodape.Size = new System.Drawing.Size(1100, 60);
            this.pnlRodape.TabIndex = 4;

            // btnAdicionar (Verde)
            this.btnAdicionar.BackColor = System.Drawing.Color.FromArgb(46, 204, 113);
            this.btnAdicionar.FlatAppearance.BorderSize = 0;
            this.btnAdicionar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnAdicionar.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnAdicionar.ForeColor = System.Drawing.Color.White;
            this.btnAdicionar.Location = new System.Drawing.Point(15, 15);
            this.btnAdicionar.Name = "btnAdicionar";
            this.btnAdicionar.Size = new System.Drawing.Size(110, 35);
            this.btnAdicionar.TabIndex = 0;
            this.btnAdicionar.Text = "Adicionar";
            this.btnAdicionar.UseVisualStyleBackColor = false;
            this.btnAdicionar.Click += new System.EventHandler(this.btnAdicionar_Click);

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

            // btnLimpar (Cinza)
            this.btnLimpar.BackColor = System.Drawing.Color.FromArgb(149, 165, 166);
            this.btnLimpar.FlatAppearance.BorderSize = 0;
            this.btnLimpar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnLimpar.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnLimpar.ForeColor = System.Drawing.Color.White;
            this.btnLimpar.Location = new System.Drawing.Point(375, 15);
            this.btnLimpar.Name = "btnLimpar";
            this.btnLimpar.Size = new System.Drawing.Size(110, 35);
            this.btnLimpar.TabIndex = 3;
            this.btnLimpar.Text = "Limpar";
            this.btnLimpar.UseVisualStyleBackColor = false;
            this.btnLimpar.Click += new System.EventHandler(this.btnLimpar_Click);

            // FormComentarios
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(1100, 660);
            this.Controls.Add(this.pnlCentro);
            this.Controls.Add(this.pnlEdicao);
            this.Controls.Add(this.pnlRodape);
            this.Controls.Add(this.pnlFiltro);
            this.Controls.Add(this.pnlTopo);
            this.Name = "FormComentarios";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Gerenciamento de Comentários";
            this.Load += new System.EventHandler(this.FormComentarios_Load);

            this.pnlTopo.ResumeLayout(false);
            this.pnlFiltro.ResumeLayout(false);
            this.pnlFiltro.PerformLayout();
            this.pnlCentro.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvComentarios)).EndInit();
            this.pnlEdicao.ResumeLayout(false);
            this.pnlEdicao.PerformLayout();
            this.pnlRodape.ResumeLayout(false);
            this.ResumeLayout(false);
        }

        #endregion

        private System.Windows.Forms.Panel pnlTopo;
        private System.Windows.Forms.Label lblTitulo;
        private System.Windows.Forms.Panel pnlFiltro;
        private System.Windows.Forms.Label lblPostId;
        private System.Windows.Forms.TextBox txtPostId;
        private System.Windows.Forms.Button btnCarregar;
        private System.Windows.Forms.Panel pnlCentro;
        private System.Windows.Forms.DataGridView dgvComentarios;
        private System.Windows.Forms.Panel pnlEdicao;
        private System.Windows.Forms.Label lblComentario;
        private System.Windows.Forms.TextBox txtComentario;
        private System.Windows.Forms.Panel pnlRodape;
        private System.Windows.Forms.Button btnAdicionar;
        private System.Windows.Forms.Button btnAtualizar;
        private System.Windows.Forms.Button btnDeletar;
        private System.Windows.Forms.Button btnLimpar;
    }
}
