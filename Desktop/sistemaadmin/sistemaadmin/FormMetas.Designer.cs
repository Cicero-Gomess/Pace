namespace sistemaadmin
{
    partial class FormMetas
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
            this.lblStatusFiltro = new System.Windows.Forms.Label();
            this.cmbStatusFiltro = new System.Windows.Forms.ComboBox();
            this.btnCarregarMetas = new System.Windows.Forms.Button();
            this.pnlCentro = new System.Windows.Forms.Panel();
            this.dgvMetas = new System.Windows.Forms.DataGridView();
            this.pnlEdicao = new System.Windows.Forms.Panel();
            this.btnLimpar = new System.Windows.Forms.Button();
            this.btnDeletar = new System.Windows.Forms.Button();
            this.btnAtualizar = new System.Windows.Forms.Button();
            this.btnAdicionar = new System.Windows.Forms.Button();
            this.lblStatus = new System.Windows.Forms.Label();
            this.cmbStatus = new System.Windows.Forms.ComboBox();
            this.lblCategoria = new System.Windows.Forms.Label();
            this.cmbCategoria = new System.Windows.Forms.ComboBox();
            this.lblPrazo = new System.Windows.Forms.Label();
            this.dtpPrazo = new System.Windows.Forms.DateTimePicker();
            this.lblDescricao = new System.Windows.Forms.Label();
            this.txtDescricao = new System.Windows.Forms.TextBox();
            this.lblTitulo2 = new System.Windows.Forms.Label();
            this.txtTitulo = new System.Windows.Forms.TextBox();

            this.pnlTopo.SuspendLayout();
            this.pnlFiltro.SuspendLayout();
            this.pnlCentro.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvMetas)).BeginInit();
            this.pnlEdicao.SuspendLayout();
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
            this.lblTitulo.Text = "Gerenciamento de Metas";

            // pnlFiltro
            this.pnlFiltro.BackColor = System.Drawing.Color.FromArgb(236, 240, 241);
            this.pnlFiltro.Controls.Add(this.lblStatusFiltro);
            this.pnlFiltro.Controls.Add(this.cmbStatusFiltro);
            this.pnlFiltro.Controls.Add(this.btnCarregarMetas);
            this.pnlFiltro.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlFiltro.Name = "pnlFiltro";
            this.pnlFiltro.Padding = new System.Windows.Forms.Padding(15);
            this.pnlFiltro.Size = new System.Drawing.Size(1100, 60);
            this.pnlFiltro.TabIndex = 1;

            // lblStatusFiltro
            this.lblStatusFiltro.AutoSize = true;
            this.lblStatusFiltro.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.lblStatusFiltro.ForeColor = System.Drawing.Color.FromArgb(44, 62, 80);
            this.lblStatusFiltro.Location = new System.Drawing.Point(15, 17);
            this.lblStatusFiltro.Name = "lblStatusFiltro";
            this.lblStatusFiltro.Size = new System.Drawing.Size(100, 17);
            this.lblStatusFiltro.TabIndex = 0;
            this.lblStatusFiltro.Text = "Filtrar por Status:";

            // cmbStatusFiltro
            this.cmbStatusFiltro.BackColor = System.Drawing.Color.White;
            this.cmbStatusFiltro.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cmbStatusFiltro.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F);
            this.cmbStatusFiltro.Items.AddRange(new object[] { "Todos", "em andamento", "concluida" });
            this.cmbStatusFiltro.Location = new System.Drawing.Point(125, 15);
            this.cmbStatusFiltro.Name = "cmbStatusFiltro";
            this.cmbStatusFiltro.Size = new System.Drawing.Size(120, 25);
            this.cmbStatusFiltro.TabIndex = 1;
            this.cmbStatusFiltro.SelectedIndex = 0;

            // btnCarregarMetas
            this.btnCarregarMetas.BackColor = System.Drawing.Color.FromArgb(52, 152, 219);
            this.btnCarregarMetas.FlatAppearance.BorderSize = 0;
            this.btnCarregarMetas.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnCarregarMetas.Font = new System.Drawing.Font("Microsoft Sans Serif", 10F, System.Drawing.FontStyle.Bold);
            this.btnCarregarMetas.ForeColor = System.Drawing.Color.White;
            this.btnCarregarMetas.Location = new System.Drawing.Point(255, 15);
            this.btnCarregarMetas.Name = "btnCarregarMetas";
            this.btnCarregarMetas.Size = new System.Drawing.Size(150, 30);
            this.btnCarregarMetas.TabIndex = 2;
            this.btnCarregarMetas.Text = "Carregar Metas";
            this.btnCarregarMetas.UseVisualStyleBackColor = false;
            this.btnCarregarMetas.Click += new System.EventHandler(this.btnCarregarMetas_Click);

            // pnlCentro
            this.pnlCentro.Controls.Add(this.dgvMetas);
            this.pnlCentro.Dock = System.Windows.Forms.DockStyle.Fill;
            this.pnlCentro.Name = "pnlCentro";
            this.pnlCentro.Padding = new System.Windows.Forms.Padding(15);
            this.pnlCentro.Size = new System.Drawing.Size(1100, 350);
            this.pnlCentro.TabIndex = 2;

            // dgvMetas
            this.dgvMetas.BackgroundColor = System.Drawing.Color.White;
            this.dgvMetas.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.dgvMetas.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvMetas.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvMetas.Location = new System.Drawing.Point(15, 15);
            this.dgvMetas.Name = "dgvMetas";
            this.dgvMetas.ReadOnly = true;
            this.dgvMetas.RowHeadersVisible = false;
            this.dgvMetas.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect;
            this.dgvMetas.Size = new System.Drawing.Size(1070, 320);
            this.dgvMetas.TabIndex = 0;
            this.dgvMetas.SelectionChanged += new System.EventHandler(this.dgvMetas_SelectionChanged);

            // pnlEdicao
            this.pnlEdicao.BackColor = System.Drawing.Color.FromArgb(236, 240, 241);
            this.pnlEdicao.Controls.Add(this.btnLimpar);
            this.pnlEdicao.Controls.Add(this.btnDeletar);
            this.pnlEdicao.Controls.Add(this.btnAtualizar);
            this.pnlEdicao.Controls.Add(this.btnAdicionar);
            this.pnlEdicao.Controls.Add(this.lblStatus);
            this.pnlEdicao.Controls.Add(this.cmbStatus);
            this.pnlEdicao.Controls.Add(this.lblCategoria);
            this.pnlEdicao.Controls.Add(this.cmbCategoria);
            this.pnlEdicao.Controls.Add(this.lblPrazo);
            this.pnlEdicao.Controls.Add(this.dtpPrazo);
            this.pnlEdicao.Controls.Add(this.lblDescricao);
            this.pnlEdicao.Controls.Add(this.txtDescricao);
            this.pnlEdicao.Controls.Add(this.lblTitulo2);
            this.pnlEdicao.Controls.Add(this.txtTitulo);
            this.pnlEdicao.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.pnlEdicao.Name = "pnlEdicao";
            this.pnlEdicao.Padding = new System.Windows.Forms.Padding(15);
            this.pnlEdicao.Size = new System.Drawing.Size(1100, 230);
            this.pnlEdicao.TabIndex = 3;

            // lblTitulo2
            this.lblTitulo2.AutoSize = true;
            this.lblTitulo2.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold);
            this.lblTitulo2.Location = new System.Drawing.Point(15, 15);
            this.lblTitulo2.Name = "lblTitulo2";
            this.lblTitulo2.Size = new System.Drawing.Size(50, 15);
            this.lblTitulo2.TabIndex = 0;
            this.lblTitulo2.Text = "Título:";

            // txtTitulo
            this.txtTitulo.BackColor = System.Drawing.Color.White;
            this.txtTitulo.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtTitulo.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.txtTitulo.Location = new System.Drawing.Point(70, 12);
            this.txtTitulo.Name = "txtTitulo";
            this.txtTitulo.Size = new System.Drawing.Size(200, 21);
            this.txtTitulo.TabIndex = 1;

            // lblDescricao
            this.lblDescricao.AutoSize = true;
            this.lblDescricao.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold);
            this.lblDescricao.Location = new System.Drawing.Point(280, 15);
            this.lblDescricao.Name = "lblDescricao";
            this.lblDescricao.Size = new System.Drawing.Size(70, 15);
            this.lblDescricao.TabIndex = 2;
            this.lblDescricao.Text = "Descrição:";

            // txtDescricao
            this.txtDescricao.BackColor = System.Drawing.Color.White;
            this.txtDescricao.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtDescricao.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.txtDescricao.Location = new System.Drawing.Point(360, 12);
            this.txtDescricao.Name = "txtDescricao";
            this.txtDescricao.Size = new System.Drawing.Size(200, 21);
            this.txtDescricao.TabIndex = 3;

            // lblCategoria
            this.lblCategoria.AutoSize = true;
            this.lblCategoria.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold);
            this.lblCategoria.Location = new System.Drawing.Point(570, 15);
            this.lblCategoria.Name = "lblCategoria";
            this.lblCategoria.Size = new System.Drawing.Size(70, 15);
            this.lblCategoria.TabIndex = 4;
            this.lblCategoria.Text = "Categoria:";

            // cmbCategoria
            this.cmbCategoria.BackColor = System.Drawing.Color.White;
            this.cmbCategoria.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cmbCategoria.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.cmbCategoria.Items.AddRange(new object[] { "Pessoal", "Estudos", "Trabalho", "Saúde", "Projeto", "Outro" });
            this.cmbCategoria.Location = new System.Drawing.Point(650, 12);
            this.cmbCategoria.Name = "cmbCategoria";
            this.cmbCategoria.Size = new System.Drawing.Size(100, 23);
            this.cmbCategoria.TabIndex = 5;

            // lblPrazo
            this.lblPrazo.AutoSize = true;
            this.lblPrazo.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold);
            this.lblPrazo.Location = new System.Drawing.Point(758, 15);
            this.lblPrazo.Name = "lblPrazo";
            this.lblPrazo.Size = new System.Drawing.Size(50, 15);
            this.lblPrazo.TabIndex = 6;
            this.lblPrazo.Text = "Prazo:";

            // dtpPrazo
            this.dtpPrazo.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.dtpPrazo.Location = new System.Drawing.Point(815, 12);
            this.dtpPrazo.Name = "dtpPrazo";
            this.dtpPrazo.Size = new System.Drawing.Size(120, 21);
            this.dtpPrazo.TabIndex = 7;

            // lblStatus
            this.lblStatus.AutoSize = true;
            this.lblStatus.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold);
            this.lblStatus.Location = new System.Drawing.Point(940, 15);
            this.lblStatus.Name = "lblStatus";
            this.lblStatus.Size = new System.Drawing.Size(50, 15);
            this.lblStatus.TabIndex = 8;
            this.lblStatus.Text = "Status:";

            // cmbStatus
            this.cmbStatus.BackColor = System.Drawing.Color.White;
            this.cmbStatus.DropDownStyle = System.Windows.Forms.ComboBoxStyle.DropDownList;
            this.cmbStatus.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F);
            this.cmbStatus.Items.AddRange(new object[] { "em andamento", "concluida" });
            this.cmbStatus.Location = new System.Drawing.Point(1000, 12);
            this.cmbStatus.Name = "cmbStatus";
            this.cmbStatus.Size = new System.Drawing.Size(85, 23);
            this.cmbStatus.TabIndex = 9;

            // btnAdicionar
            this.btnAdicionar.BackColor = System.Drawing.Color.FromArgb(46, 204, 113);
            this.btnAdicionar.FlatAppearance.BorderSize = 0;
            this.btnAdicionar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnAdicionar.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold);
            this.btnAdicionar.ForeColor = System.Drawing.Color.White;
            this.btnAdicionar.Location = new System.Drawing.Point(70, 45);
            this.btnAdicionar.Name = "btnAdicionar";
            this.btnAdicionar.Size = new System.Drawing.Size(100, 30);
            this.btnAdicionar.TabIndex = 10;
            this.btnAdicionar.Text = "Adicionar";
            this.btnAdicionar.UseVisualStyleBackColor = false;
            this.btnAdicionar.Click += new System.EventHandler(this.btnAdicionar_Click);

            // btnAtualizar
            this.btnAtualizar.BackColor = System.Drawing.Color.FromArgb(52, 152, 219);
            this.btnAtualizar.FlatAppearance.BorderSize = 0;
            this.btnAtualizar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnAtualizar.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold);
            this.btnAtualizar.ForeColor = System.Drawing.Color.White;
            this.btnAtualizar.Location = new System.Drawing.Point(180, 45);
            this.btnAtualizar.Name = "btnAtualizar";
            this.btnAtualizar.Size = new System.Drawing.Size(100, 30);
            this.btnAtualizar.TabIndex = 11;
            this.btnAtualizar.Text = "Atualizar";
            this.btnAtualizar.UseVisualStyleBackColor = false;
            this.btnAtualizar.Click += new System.EventHandler(this.btnAtualizar_Click);

            // btnDeletar
            this.btnDeletar.BackColor = System.Drawing.Color.FromArgb(231, 76, 60);
            this.btnDeletar.FlatAppearance.BorderSize = 0;
            this.btnDeletar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnDeletar.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold);
            this.btnDeletar.ForeColor = System.Drawing.Color.White;
            this.btnDeletar.Location = new System.Drawing.Point(290, 45);
            this.btnDeletar.Name = "btnDeletar";
            this.btnDeletar.Size = new System.Drawing.Size(100, 30);
            this.btnDeletar.TabIndex = 12;
            this.btnDeletar.Text = "Deletar";
            this.btnDeletar.UseVisualStyleBackColor = false;
            this.btnDeletar.Click += new System.EventHandler(this.btnDeletar_Click);

            // btnLimpar
            this.btnLimpar.BackColor = System.Drawing.Color.FromArgb(149, 165, 166);
            this.btnLimpar.FlatAppearance.BorderSize = 0;
            this.btnLimpar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnLimpar.Font = new System.Drawing.Font("Microsoft Sans Serif", 9F, System.Drawing.FontStyle.Bold);
            this.btnLimpar.ForeColor = System.Drawing.Color.White;
            this.btnLimpar.Location = new System.Drawing.Point(400, 45);
            this.btnLimpar.Name = "btnLimpar";
            this.btnLimpar.Size = new System.Drawing.Size(100, 30);
            this.btnLimpar.TabIndex = 13;
            this.btnLimpar.Text = "Limpar";
            this.btnLimpar.UseVisualStyleBackColor = false;
            this.btnLimpar.Click += new System.EventHandler(this.btnLimpar_Click);

            // FormMetas
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1100, 700);
            this.Controls.Add(this.pnlEdicao);
            this.Controls.Add(this.pnlCentro);
            this.Controls.Add(this.pnlFiltro);
            this.Controls.Add(this.pnlTopo);
            this.Name = "FormMetas";
            this.Text = "Gerenciamento de Metas";
            this.Load += new System.EventHandler(this.FormMetas_Load);

            this.pnlTopo.ResumeLayout(false);
            this.pnlFiltro.ResumeLayout(false);
            this.pnlFiltro.PerformLayout();
            this.pnlCentro.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvMetas)).EndInit();
            this.pnlEdicao.ResumeLayout(false);
            this.pnlEdicao.PerformLayout();
            this.ResumeLayout(false);
        }

        #endregion

        private System.Windows.Forms.Panel pnlTopo;
        private System.Windows.Forms.Label lblTitulo;
        private System.Windows.Forms.Panel pnlFiltro;
        private System.Windows.Forms.Label lblStatusFiltro;
        private System.Windows.Forms.ComboBox cmbStatusFiltro;
        private System.Windows.Forms.Button btnCarregarMetas;
        private System.Windows.Forms.Panel pnlCentro;
        private System.Windows.Forms.DataGridView dgvMetas;
        private System.Windows.Forms.Panel pnlEdicao;
        private System.Windows.Forms.Button btnLimpar;
        private System.Windows.Forms.Button btnDeletar;
        private System.Windows.Forms.Button btnAtualizar;
        private System.Windows.Forms.Button btnAdicionar;
        private System.Windows.Forms.Label lblStatus;
        private System.Windows.Forms.ComboBox cmbStatus;
        private System.Windows.Forms.Label lblCategoria;
        private System.Windows.Forms.ComboBox cmbCategoria;
        private System.Windows.Forms.Label lblPrazo;
        private System.Windows.Forms.DateTimePicker dtpPrazo;
        private System.Windows.Forms.Label lblDescricao;
        private System.Windows.Forms.TextBox txtDescricao;
        private System.Windows.Forms.Label lblTitulo2;
        private System.Windows.Forms.TextBox txtTitulo;
    }
}
