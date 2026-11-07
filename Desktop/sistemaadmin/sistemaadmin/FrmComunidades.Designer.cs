namespace sistemaadmin
{
    partial class FrmComunidades
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
            this.pnlPesquisa = new System.Windows.Forms.Panel();
            this.btnLimparFiltro = new System.Windows.Forms.Button();
            this.btnPesquisar = new System.Windows.Forms.Button();
            this.txtPesquisa = new System.Windows.Forms.TextBox();
            this.lblPesquisa = new System.Windows.Forms.Label();
            this.pnlListagem = new System.Windows.Forms.Panel();
            this.dgvComunidades = new System.Windows.Forms.DataGridView();
            this.pnlDetalhes = new System.Windows.Forms.Panel();
            this.grpDetalhes = new System.Windows.Forms.GroupBox();
            this.lblNome = new System.Windows.Forms.Label();
            this.txtNome = new System.Windows.Forms.TextBox();
            this.lblDescricao = new System.Windows.Forms.Label();
            this.txtDescricao = new System.Windows.Forms.TextBox();
            this.lblPrivacidade = new System.Windows.Forms.Label();
            this.txtPrivacidade = new System.Windows.Forms.TextBox();
            this.lblMembros = new System.Windows.Forms.Label();
            this.txtMembros = new System.Windows.Forms.TextBox();
            this.lblCriador = new System.Windows.Forms.Label();
            this.txtCriador = new System.Windows.Forms.TextBox();
            this.lblCriacao = new System.Windows.Forms.Label();
            this.txtCriacao = new System.Windows.Forms.TextBox();
            this.lblTopicos = new System.Windows.Forms.Label();
            this.txtTopicos = new System.Windows.Forms.TextBox();
            this.pnlBotoes = new System.Windows.Forms.Panel();
            this.btnRecarregar = new System.Windows.Forms.Button();
            this.btnMembros = new System.Windows.Forms.Button();
            this.btnExcluir = new System.Windows.Forms.Button();
            this.btnAtualizar = new System.Windows.Forms.Button();
            this.pnlPesquisa.SuspendLayout();
            this.pnlListagem.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvComunidades)).BeginInit();
            this.pnlDetalhes.SuspendLayout();
            this.grpDetalhes.SuspendLayout();
            this.pnlBotoes.SuspendLayout();
            this.SuspendLayout();
            // 
            // pnlPesquisa
            // 
            this.pnlPesquisa.BackColor = System.Drawing.Color.White;
            this.pnlPesquisa.Controls.Add(this.btnLimparFiltro);
            this.pnlPesquisa.Controls.Add(this.btnPesquisar);
            this.pnlPesquisa.Controls.Add(this.txtPesquisa);
            this.pnlPesquisa.Controls.Add(this.lblPesquisa);
            this.pnlPesquisa.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlPesquisa.Location = new System.Drawing.Point(0, 0);
            this.pnlPesquisa.Name = "pnlPesquisa";
            this.pnlPesquisa.Padding = new System.Windows.Forms.Padding(10);
            this.pnlPesquisa.Size = new System.Drawing.Size(800, 60);
            this.pnlPesquisa.TabIndex = 0;
            // 
            // btnLimparFiltro
            // 
            this.btnLimparFiltro.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(149)))), ((int)(((byte)(165)))), ((int)(((byte)(166)))));
            this.btnLimparFiltro.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnLimparFiltro.Font = new System.Drawing.Font("Segoe UI", 9F);
            this.btnLimparFiltro.ForeColor = System.Drawing.Color.White;
            this.btnLimparFiltro.Location = new System.Drawing.Point(380, 18);
            this.btnLimparFiltro.Name = "btnLimparFiltro";
            this.btnLimparFiltro.Size = new System.Drawing.Size(90, 30);
            this.btnLimparFiltro.TabIndex = 3;
            this.btnLimparFiltro.Text = "Limpar";
            this.btnLimparFiltro.UseVisualStyleBackColor = false;
            this.btnLimparFiltro.Click += new System.EventHandler(this.btnLimparFiltro_Click);
            // 
            // btnPesquisar
            // 
            this.btnPesquisar.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(52)))), ((int)(((byte)(152)))), ((int)(((byte)(219)))));
            this.btnPesquisar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnPesquisar.Font = new System.Drawing.Font("Segoe UI", 9F);
            this.btnPesquisar.ForeColor = System.Drawing.Color.White;
            this.btnPesquisar.Location = new System.Drawing.Point(290, 18);
            this.btnPesquisar.Name = "btnPesquisar";
            this.btnPesquisar.Size = new System.Drawing.Size(80, 30);
            this.btnPesquisar.TabIndex = 2;
            this.btnPesquisar.Text = "Pesquisar";
            this.btnPesquisar.UseVisualStyleBackColor = false;
            this.btnPesquisar.Click += new System.EventHandler(this.btnPesquisar_Click);
            // 
            // txtPesquisa
            // 
            this.txtPesquisa.Font = new System.Drawing.Font("Segoe UI", 9F);
            this.txtPesquisa.Location = new System.Drawing.Point(80, 22);
            this.txtPesquisa.Name = "txtPesquisa";
            this.txtPesquisa.Size = new System.Drawing.Size(200, 23);
            this.txtPesquisa.TabIndex = 1;
            // 
            // lblPesquisa
            // 
            this.lblPesquisa.AutoSize = true;
            this.lblPesquisa.Font = new System.Drawing.Font("Segoe UI", 9F);
            this.lblPesquisa.ForeColor = System.Drawing.Color.Black;
            this.lblPesquisa.Location = new System.Drawing.Point(10, 25);
            this.lblPesquisa.Name = "lblPesquisa";
            this.lblPesquisa.Size = new System.Drawing.Size(64, 15);
            this.lblPesquisa.TabIndex = 0;
            this.lblPesquisa.Text = "Pesquisar:";
            // 
            // pnlListagem
            // 
            this.pnlListagem.Controls.Add(this.dgvComunidades);
            this.pnlListagem.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlListagem.Location = new System.Drawing.Point(0, 60);
            this.pnlListagem.Name = "pnlListagem";
            this.pnlListagem.Padding = new System.Windows.Forms.Padding(10);
            this.pnlListagem.Size = new System.Drawing.Size(800, 200);
            this.pnlListagem.TabIndex = 1;
            // 
            // dgvComunidades
            // 
            this.dgvComunidades.AllowUserToAddRows = false;
            this.dgvComunidades.AllowUserToDeleteRows = false;
            this.dgvComunidades.BackgroundColor = System.Drawing.Color.White;
            this.dgvComunidades.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvComunidades.AutoSizeColumnsMode = System.Windows.Forms.DataGridViewAutoSizeColumnsMode.Fill;
            this.dgvComunidades.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvComunidades.Location = new System.Drawing.Point(10, 10);
            this.dgvComunidades.MultiSelect = false;
            this.dgvComunidades.Name = "dgvComunidades";
            this.dgvComunidades.ReadOnly = true;
            this.dgvComunidades.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect;
            this.dgvComunidades.Size = new System.Drawing.Size(780, 180);
            this.dgvComunidades.TabIndex = 0;
            this.dgvComunidades.SelectionChanged += new System.EventHandler(this.dgvComunidades_SelectionChanged);
            // 
            // pnlDetalhes
            // 
            this.pnlDetalhes.Controls.Add(this.grpDetalhes);
            this.pnlDetalhes.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlDetalhes.Location = new System.Drawing.Point(0, 260);
            this.pnlDetalhes.Name = "pnlDetalhes";
            this.pnlDetalhes.Padding = new System.Windows.Forms.Padding(10);
            this.pnlDetalhes.Size = new System.Drawing.Size(800, 250);
            this.pnlDetalhes.TabIndex = 2;
            // 
            // grpDetalhes
            // 
            this.grpDetalhes.Controls.Add(this.lblNome);
            this.grpDetalhes.Controls.Add(this.txtNome);
            this.grpDetalhes.Controls.Add(this.lblDescricao);
            this.grpDetalhes.Controls.Add(this.txtDescricao);
            this.grpDetalhes.Controls.Add(this.lblPrivacidade);
            this.grpDetalhes.Controls.Add(this.txtPrivacidade);
            this.grpDetalhes.Controls.Add(this.lblMembros);
            this.grpDetalhes.Controls.Add(this.txtMembros);
            this.grpDetalhes.Controls.Add(this.lblCriador);
            this.grpDetalhes.Controls.Add(this.txtCriador);
            this.grpDetalhes.Controls.Add(this.lblCriacao);
            this.grpDetalhes.Controls.Add(this.txtCriacao);
            this.grpDetalhes.Controls.Add(this.lblTopicos);
            this.grpDetalhes.Controls.Add(this.txtTopicos);
            this.grpDetalhes.Dock = System.Windows.Forms.DockStyle.Fill;
            this.grpDetalhes.Font = new System.Drawing.Font("Segoe UI", 9F);
            this.grpDetalhes.Location = new System.Drawing.Point(10, 10);
            this.grpDetalhes.Name = "grpDetalhes";
            this.grpDetalhes.Padding = new System.Windows.Forms.Padding(10);
            this.grpDetalhes.Size = new System.Drawing.Size(780, 220);
            this.grpDetalhes.TabIndex = 0;
            this.grpDetalhes.TabStop = false;
            this.grpDetalhes.Text = "Detalhes da Comunidade";
            // 
            // lblNome
            // 
            this.lblNome.AutoSize = true;
            this.lblNome.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.lblNome.Location = new System.Drawing.Point(10, 25);
            this.lblNome.Name = "lblNome";
            this.lblNome.Size = new System.Drawing.Size(38, 13);
            this.lblNome.TabIndex = 0;
            this.lblNome.Text = "Nome:";
            // 
            // txtNome
            // 
            this.txtNome.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtNome.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.txtNome.Location = new System.Drawing.Point(75, 22);
            this.txtNome.Name = "txtNome";
            this.txtNome.Size = new System.Drawing.Size(335, 22);
            this.txtNome.TabIndex = 1;
            // 
            // lblDescricao
            // 
            this.lblDescricao.AutoSize = true;
            this.lblDescricao.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.lblDescricao.Location = new System.Drawing.Point(10, 50);
            this.lblDescricao.Name = "lblDescricao";
            this.lblDescricao.Size = new System.Drawing.Size(57, 13);
            this.lblDescricao.TabIndex = 2;
            this.lblDescricao.Text = "Descrição:";
            // 
            // txtDescricao
            // 
            this.txtDescricao.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtDescricao.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.txtDescricao.Location = new System.Drawing.Point(75, 47);
            this.txtDescricao.Multiline = true;
            this.txtDescricao.Name = "txtDescricao";
            this.txtDescricao.Size = new System.Drawing.Size(335, 50);
            this.txtDescricao.TabIndex = 3;
            // 
            // lblPrivacidade
            // 
            this.lblPrivacidade.AutoSize = true;
            this.lblPrivacidade.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.lblPrivacidade.Location = new System.Drawing.Point(420, 25);
            this.lblPrivacidade.Name = "lblPrivacidade";
            this.lblPrivacidade.Size = new System.Drawing.Size(61, 13);
            this.lblPrivacidade.TabIndex = 4;
            this.lblPrivacidade.Text = "Privacidade:";
            // 
            // txtPrivacidade
            // 
            this.txtPrivacidade.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtPrivacidade.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.txtPrivacidade.Location = new System.Drawing.Point(485, 22);
            this.txtPrivacidade.Name = "txtPrivacidade";
            this.txtPrivacidade.ReadOnly = true;
            this.txtPrivacidade.Size = new System.Drawing.Size(285, 22);
            this.txtPrivacidade.TabIndex = 5;
            // 
            // lblMembros
            // 
            this.lblMembros.AutoSize = true;
            this.lblMembros.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.lblMembros.Location = new System.Drawing.Point(420, 50);
            this.lblMembros.Name = "lblMembros";
            this.lblMembros.Size = new System.Drawing.Size(57, 13);
            this.lblMembros.TabIndex = 6;
            this.lblMembros.Text = "Membros:";
            // 
            // txtMembros
            // 
            this.txtMembros.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtMembros.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.txtMembros.Location = new System.Drawing.Point(485, 47);
            this.txtMembros.Name = "txtMembros";
            this.txtMembros.ReadOnly = true;
            this.txtMembros.Size = new System.Drawing.Size(285, 22);
            this.txtMembros.TabIndex = 7;
            // 
            // lblCriador
            // 
            this.lblCriador.AutoSize = true;
            this.lblCriador.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.lblCriador.Location = new System.Drawing.Point(10, 100);
            this.lblCriador.Name = "lblCriador";
            this.lblCriador.Size = new System.Drawing.Size(48, 13);
            this.lblCriador.TabIndex = 8;
            this.lblCriador.Text = "Criador:";
            // 
            // txtCriador
            // 
            this.txtCriador.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtCriador.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.txtCriador.Location = new System.Drawing.Point(75, 97);
            this.txtCriador.Name = "txtCriador";
            this.txtCriador.ReadOnly = true;
            this.txtCriador.Size = new System.Drawing.Size(335, 22);
            this.txtCriador.TabIndex = 9;
            // 
            // lblCriacao
            // 
            this.lblCriacao.AutoSize = true;
            this.lblCriacao.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.lblCriacao.Location = new System.Drawing.Point(420, 100);
            this.lblCriacao.Name = "lblCriacao";
            this.lblCriacao.Size = new System.Drawing.Size(51, 13);
            this.lblCriacao.TabIndex = 10;
            this.lblCriacao.Text = "Criação:";
            // 
            // txtCriacao
            // 
            this.txtCriacao.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtCriacao.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.txtCriacao.Location = new System.Drawing.Point(485, 97);
            this.txtCriacao.Name = "txtCriacao";
            this.txtCriacao.ReadOnly = true;
            this.txtCriacao.Size = new System.Drawing.Size(285, 22);
            this.txtCriacao.TabIndex = 11;
            // 
            // lblTopicos
            // 
            this.lblTopicos.AutoSize = true;
            this.lblTopicos.Font = new System.Drawing.Font("Segoe UI", 8F);
            this.lblTopicos.Location = new System.Drawing.Point(10, 125);
            this.lblTopicos.Name = "lblTopicos";
            this.lblTopicos.Size = new System.Drawing.Size(50, 13);
            this.lblTopicos.TabIndex = 12;
            this.lblTopicos.Text = "Tópicos:";
            // 
            // txtTopicos
            // 
            this.txtTopicos.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.txtTopicos.Font = new System.Drawing.Font("Segoe UI", 7F);
            this.txtTopicos.Location = new System.Drawing.Point(75, 122);
            this.txtTopicos.Multiline = true;
            this.txtTopicos.Name = "txtTopicos";
            this.txtTopicos.ReadOnly = true;
            this.txtTopicos.Size = new System.Drawing.Size(695, 50);
            this.txtTopicos.TabIndex = 13;
            // 
            // pnlBotoes
            // 
            this.pnlBotoes.BackColor = System.Drawing.Color.White;
            this.pnlBotoes.Controls.Add(this.btnRecarregar);
            this.pnlBotoes.Controls.Add(this.btnMembros);
            this.pnlBotoes.Controls.Add(this.btnExcluir);
            this.pnlBotoes.Controls.Add(this.btnAtualizar);
            this.pnlBotoes.Dock = System.Windows.Forms.DockStyle.Top;
            this.pnlBotoes.Location = new System.Drawing.Point(0, 460);
            this.pnlBotoes.Name = "pnlBotoes";
            this.pnlBotoes.Padding = new System.Windows.Forms.Padding(10);
            this.pnlBotoes.Size = new System.Drawing.Size(800, 60);
            this.pnlBotoes.TabIndex = 3;
            // 
            // btnRecarregar
            // 
            this.btnRecarregar.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(46)))), ((int)(((byte)(204)))), ((int)(((byte)(113)))));
            this.btnRecarregar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnRecarregar.Font = new System.Drawing.Font("Segoe UI", 9F);
            this.btnRecarregar.ForeColor = System.Drawing.Color.White;
            this.btnRecarregar.Location = new System.Drawing.Point(690, 15);
            this.btnRecarregar.Name = "btnRecarregar";
            this.btnRecarregar.Size = new System.Drawing.Size(90, 30);
            this.btnRecarregar.TabIndex = 3;
            this.btnRecarregar.Text = "Recarregar";
            this.btnRecarregar.UseVisualStyleBackColor = false;
            this.btnRecarregar.Click += new System.EventHandler(this.btnRecarregar_Click);
            // 
            // btnMembros
            // 
            this.btnMembros.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(52)))), ((int)(((byte)(152)))), ((int)(((byte)(219)))));
            this.btnMembros.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnMembros.Font = new System.Drawing.Font("Segoe UI", 9F);
            this.btnMembros.ForeColor = System.Drawing.Color.White;
            this.btnMembros.Location = new System.Drawing.Point(481, 15);
            this.btnMembros.Name = "btnMembros";
            this.btnMembros.Size = new System.Drawing.Size(199, 30);
            this.btnMembros.TabIndex = 2;
            this.btnMembros.Text = "Gerenciar Membros";
            this.btnMembros.UseVisualStyleBackColor = false;
            this.btnMembros.Click += new System.EventHandler(this.btnMembros_Click);
            // 
            // btnExcluir
            // 
            this.btnExcluir.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(231)))), ((int)(((byte)(76)))), ((int)(((byte)(60)))));
            this.btnExcluir.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnExcluir.Font = new System.Drawing.Font("Segoe UI", 9F);
            this.btnExcluir.ForeColor = System.Drawing.Color.White;
            this.btnExcluir.Location = new System.Drawing.Point(261, 15);
            this.btnExcluir.Name = "btnExcluir";
            this.btnExcluir.Size = new System.Drawing.Size(210, 30);
            this.btnExcluir.TabIndex = 1;
            this.btnExcluir.Text = "Excluir";
            this.btnExcluir.UseVisualStyleBackColor = false;
            this.btnExcluir.Click += new System.EventHandler(this.btnExcluir_Click);
            // 
            // btnAtualizar
            // 
            this.btnAtualizar.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(52)))), ((int)(((byte)(152)))), ((int)(((byte)(219)))));
            this.btnAtualizar.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnAtualizar.Font = new System.Drawing.Font("Segoe UI", 9F);
            this.btnAtualizar.ForeColor = System.Drawing.Color.White;
            this.btnAtualizar.Location = new System.Drawing.Point(10, 15);
            this.btnAtualizar.Name = "btnAtualizar";
            this.btnAtualizar.Size = new System.Drawing.Size(241, 30);
            this.btnAtualizar.TabIndex = 0;
            this.btnAtualizar.Text = "Atualizar";
            this.btnAtualizar.UseVisualStyleBackColor = false;
            this.btnAtualizar.Click += new System.EventHandler(this.btnAtualizar_Click);
            // 
            // FrmComunidades
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackColor = System.Drawing.Color.White;
            this.ClientSize = new System.Drawing.Size(800, 600);
            this.Controls.Add(this.pnlBotoes);
            this.Controls.Add(this.pnlDetalhes);
            this.Controls.Add(this.pnlListagem);
            this.Controls.Add(this.pnlPesquisa);
            this.Name = "FrmComunidades";
            this.Text = "Gerenciamento de Comunidades";
            this.Load += new System.EventHandler(this.FrmComunidades_Load);
            this.pnlPesquisa.ResumeLayout(false);
            this.pnlPesquisa.PerformLayout();
            this.pnlListagem.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvComunidades)).EndInit();
            this.pnlDetalhes.ResumeLayout(false);
            this.grpDetalhes.ResumeLayout(false);
            this.grpDetalhes.PerformLayout();
            this.pnlBotoes.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Panel pnlPesquisa;
        private System.Windows.Forms.Label lblPesquisa;
        private System.Windows.Forms.TextBox txtPesquisa;
        private System.Windows.Forms.Button btnPesquisar;
        private System.Windows.Forms.Button btnLimparFiltro;
        private System.Windows.Forms.Panel pnlListagem;
        private System.Windows.Forms.DataGridView dgvComunidades;
        private System.Windows.Forms.Panel pnlDetalhes;
        private System.Windows.Forms.GroupBox grpDetalhes;
        private System.Windows.Forms.Label lblNome;
        private System.Windows.Forms.TextBox txtNome;
        private System.Windows.Forms.Label lblDescricao;
        private System.Windows.Forms.TextBox txtDescricao;
        private System.Windows.Forms.Label lblPrivacidade;
        private System.Windows.Forms.TextBox txtPrivacidade;
        private System.Windows.Forms.Label lblMembros;
        private System.Windows.Forms.TextBox txtMembros;
        private System.Windows.Forms.Label lblCriador;
        private System.Windows.Forms.TextBox txtCriador;
        private System.Windows.Forms.Label lblCriacao;
        private System.Windows.Forms.TextBox txtCriacao;
        private System.Windows.Forms.Label lblTopicos;
        private System.Windows.Forms.TextBox txtTopicos;
        private System.Windows.Forms.Panel pnlBotoes;
        private System.Windows.Forms.Button btnAtualizar;
        private System.Windows.Forms.Button btnExcluir;
        private System.Windows.Forms.Button btnMembros;
        private System.Windows.Forms.Button btnRecarregar;
    }
}
