using System;
using System.Windows.Forms;

namespace sistemaadmin
{
    public partial class FormPrincipal : Form
    {
        private string _token;
        private Form _currentForm;

        public FormPrincipal(string token)
        {
            InitializeComponent();
            _token = token;
        }

        private void FormPrincipal_Load(object sender, EventArgs e)
        {
            try
            {
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

