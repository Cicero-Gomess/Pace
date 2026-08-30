using System;
using System.Windows.Forms;
using sistemaadmin.Services;

namespace sistemaadmin
{
    public partial class FormPrincipal : Form
    {
        private string _token;
        private Form _currentForm;
        private bool _isAdmin;

        public FormPrincipal(string token)
        {
            InitializeComponent();
            _token = token;
            // Verificar se o Backend realmente fornece dados de permissão
            // Se não fornece, IsAdmin() retornará false e btnMetas será escondido
            // NOTA: O contrato atual da API não inclui campos de permissão no JWT
            _isAdmin = PermissionHelper.IsPermissionDataAvailable(token) && PermissionHelper.IsAdmin(token);
        }

        private void FormPrincipal_Load(object sender, EventArgs e)
        {
            try
            {
                // IMPORTANTE: Funcionalidades administrativas
                // 
                // NOTA SOBRE PERMISSÕES (30/08/2026):
                // O Backend atualmente NÃO retorna informações de permissão no JWT.
                // Por isso, o controle de acesso é feito inteiramente no servidor API.
                // As telas de Metas e Comentários são acessíveis, mas a API é responsável
                // por autorizar cada operação (criar, editar, deletar) com base nas permissões reais.
                //
                // Isso segue o padrão de "segurança em camadas":
                // - Desktop: Permite acesso às telas
                // - Backend/API: Valida permissões para cada operação
                // 
                // Quando o Backend for atualizado para incluir permissões no JWT ou em /profile/me,
                // este código será automaticamente compatível.

                // Nota: btnMetas está sempre visível. A segurança é garantida pelo Backend.
                // Se o usuário não tiver permissão, as operações na API retornarão 403.

                AbrirFormDashboard();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao carregar dashboard:\n{ex.Message}", "Erro ao Inicializar",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                // Mostrar painel vazio em vez de quebrar
            }
        }

        private void BtnDashboard_Click(object sender, EventArgs e)
        {
            AbrirFormDashboard();
        }

        private void BtnPosts_Click(object sender, EventArgs e)
        {
            AbrirFormPosts();
        }

        private void BtnComentarios_Click(object sender, EventArgs e)
        {
            AbrirFormComentarios();
        }

        private void BtnMetas_Click(object sender, EventArgs e)
        {
            AbrirFormMetas();
        }

        private void BtnPerfil_Click(object sender, EventArgs e)
        {
            AbrirFormPerfil();
        }

        private void BtnLogout_Click(object sender, EventArgs e)
        {
            RealizarLogout();
        }

        private void AbrirFormDashboard()
        {
            AbrirForm(new FormDashboard(_token));
        }

        private void AbrirFormPosts()
        {
            AbrirForm(new FormPosts(_token));
        }

        private void AbrirFormComentarios()
        {
            AbrirForm(new FormComentarios(_token));
        }

        private void AbrirFormMetas()
        {
            AbrirForm(new FormMetas(_token));
        }

        private void AbrirFormPerfil()
        {
            AbrirForm(new FormPerfil(_token));
        }

        private void AbrirForm(Form form)
        {
            try
            {
                FecharFormAtual();

                form.TopLevel = false;
                form.FormBorderStyle = FormBorderStyle.None;
                form.Dock = DockStyle.Fill;

                pnlContainer.Controls.Clear();
                pnlContainer.Controls.Add(form);
                form.Show();

                _currentForm = form;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao abrir formulário:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                form?.Dispose();
            }
        }

        private void FecharFormAtual()
        {
            if (_currentForm != null && !_currentForm.IsDisposed)
            {
                _currentForm.Dispose();
                _currentForm = null;
            }
        }

        private void RealizarLogout()
        {
            if (MessageBox.Show("Deseja sair?", "Confirmação", MessageBoxButtons.YesNo) == DialogResult.Yes)
            {
                FecharFormAtual();
                // Fechar FormPrincipal e voltar para FormLogin
                this.Close();
            }
        }
    }
}

