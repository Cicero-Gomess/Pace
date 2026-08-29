using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Windows.Forms;
using sistemaadmin.Models;
using sistemaadmin.Services;

namespace sistemaadmin
{
    public partial class FormMetas : Form
    {
        private readonly string _token;
        private MetaService _metaService;
        private List<MetaDTO> _metas;
        private MetaDTO _metaSelecionada;

        public FormMetas(string token)
        {
            InitializeComponent();
            _token = token;
            _metas = new List<MetaDTO>();
        }

        private void FormMetas_Load(object sender, EventArgs e)
        {
            try
            {
                _metaService = new MetaService(_token);
                this.Text = "Sistema Administrativo - Gerenciamento de Metas";
                this.CenterToScreen();
                ConfigurarDataGridView();
                ConfigurarDateTimePicker();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao inicializar FormMetas:\n{ex.Message}", "Erro ao Inicializar",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void ConfigurarDataGridView()
        {
            dgvMetas.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            dgvMetas.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dgvMetas.MultiSelect = false;
            dgvMetas.AllowUserToAddRows = false;
            dgvMetas.AllowUserToDeleteRows = false;
        }

        private void ConfigurarDateTimePicker()
        {
            dtpPrazo.Value = DateTime.Now.AddMonths(1);
        }

        private async void btnCarregarMetas_Click(object sender, EventArgs e)
        {
            try
            {
                btnCarregarMetas.Enabled = false;
                btnCarregarMetas.Text = "Carregando...";

                var json = await _metaService.ListarMetasAsync();
                _metas = ParsearMetas(json);

                // Aplicar filtro se selecionado
                List<MetaDTO> metasFiltradas = _metas;
                if (cmbStatusFiltro.SelectedIndex > 0)
                {
                    string statusFiltro = cmbStatusFiltro.SelectedItem.ToString();
                    metasFiltradas = new List<MetaDTO>();
                    foreach (var meta in _metas)
                    {
                        if (meta.Status == statusFiltro)
                            metasFiltradas.Add(meta);
                    }
                }

                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        dgvMetas.DataSource = null;
                        dgvMetas.DataSource = metasFiltradas;
                        LimparCampos();

                        if (metasFiltradas.Count == 0)
                        {
                            MessageBox.Show("Nenhuma meta encontrada.", "Informação",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }));
                }
                else
                {
                    dgvMetas.DataSource = null;
                    dgvMetas.DataSource = metasFiltradas;
                    LimparCampos();

                    if (metasFiltradas.Count == 0)
                    {
                        MessageBox.Show("Nenhuma meta encontrada.", "Informação",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao carregar metas:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnCarregarMetas.Enabled = true;
                btnCarregarMetas.Text = "Carregar Metas";
            }
        }

        private void dgvMetas_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvMetas.SelectedRows.Count > 0)
            {
                _metaSelecionada = (MetaDTO)dgvMetas.SelectedRows[0].DataBoundItem;
                PreencherCamposEdicao(_metaSelecionada);
            }
        }

        private void PreencherCamposEdicao(MetaDTO meta)
        {
            txtTitulo.Text = meta.Titulo ?? "";
            txtDescricao.Text = meta.Descricao ?? "";

            // Selecionar categoria
            if (!string.IsNullOrEmpty(meta.Categoria))
            {
                int idx = cmbCategoria.Items.IndexOf(meta.Categoria);
                if (idx >= 0)
                    cmbCategoria.SelectedIndex = idx;
            }

            // Selecionar status
            if (!string.IsNullOrEmpty(meta.Status))
            {
                int idx = cmbStatus.Items.IndexOf(meta.Status);
                if (idx >= 0)
                    cmbStatus.SelectedIndex = idx;
            }

            // Definir data do prazo
            if (meta.Prazo.HasValue)
                dtpPrazo.Value = meta.Prazo.Value;
            else
                dtpPrazo.Value = DateTime.Now.AddMonths(1);
        }

        private async void btnAdicionar_Click(object sender, EventArgs e)
        {
            try
            {
                string titulo = txtTitulo.Text.Trim();
                string categoria = cmbCategoria.SelectedItem?.ToString() ?? "";
                string descricao = txtDescricao.Text.Trim();
                DateTime prazo = dtpPrazo.Value;

                if (string.IsNullOrEmpty(titulo))
                {
                    MessageBox.Show("Por favor, insira o título da meta.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                if (string.IsNullOrEmpty(categoria))
                {
                    MessageBox.Show("Por favor, selecione uma categoria.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                btnAdicionar.Enabled = false;
                btnAdicionar.Text = "Adicionando...";

                await _metaService.CriarMetaAsync(titulo, categoria, descricao, prazo);

                MessageBox.Show("Meta adicionada com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparCampos();
                await RecarregarMetas();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao adicionar meta:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnAdicionar.Enabled = true;
                btnAdicionar.Text = "Adicionar";
            }
        }

        private async void btnAtualizar_Click(object sender, EventArgs e)
        {
            try
            {
                if (_metaSelecionada == null)
                {
                    MessageBox.Show("Por favor, selecione uma meta para atualizar.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                string titulo = txtTitulo.Text.Trim();
                string categoria = cmbCategoria.SelectedItem?.ToString() ?? "";
                string descricao = txtDescricao.Text.Trim();
                string status = cmbStatus.SelectedItem?.ToString() ?? "";
                DateTime prazo = dtpPrazo.Value;

                if (string.IsNullOrEmpty(titulo))
                {
                    MessageBox.Show("Por favor, insira o título da meta.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                btnAtualizar.Enabled = false;
                btnAtualizar.Text = "Atualizando...";

                await _metaService.AtualizarMetaAsync(
                    _metaSelecionada.Id,
                    titulo: titulo,
                    categoria: categoria,
                    descricao: descricao,
                    prazo: prazo,
                    status: status
                );

                MessageBox.Show("Meta atualizada com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparCampos();
                await RecarregarMetas();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao atualizar meta:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnAtualizar.Enabled = true;
                btnAtualizar.Text = "Atualizar";
            }
        }

        private async void btnDeletar_Click(object sender, EventArgs e)
        {
            try
            {
                if (_metaSelecionada == null)
                {
                    MessageBox.Show("Por favor, selecione uma meta para deletar.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                if (MessageBox.Show($"Deseja deletar a meta '{_metaSelecionada.Titulo}'?", "Confirmação",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question) != DialogResult.Yes)
                {
                    return;
                }

                btnDeletar.Enabled = false;
                btnDeletar.Text = "Deletando...";

                await _metaService.DeletarMetaAsync(_metaSelecionada.Id);

                MessageBox.Show("Meta deletada com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparCampos();
                await RecarregarMetas();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao deletar meta:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnDeletar.Enabled = true;
                btnDeletar.Text = "Deletar";
            }
        }

        private void btnLimpar_Click(object sender, EventArgs e)
        {
            LimparCampos();
        }

        private void LimparCampos()
        {
            txtTitulo.Clear();
            txtDescricao.Clear();
            cmbCategoria.SelectedIndex = 0;
            cmbStatus.SelectedIndex = 0;
            dtpPrazo.Value = DateTime.Now.AddMonths(1);
            _metaSelecionada = null;
        }

        private async Task RecarregarMetas()
        {
            try
            {
                var json = await _metaService.ListarMetasAsync();
                _metas = ParsearMetas(json);

                List<MetaDTO> metasFiltradas = _metas;
                if (cmbStatusFiltro.SelectedIndex > 0)
                {
                    string statusFiltro = cmbStatusFiltro.SelectedItem.ToString();
                    metasFiltradas = new List<MetaDTO>();
                    foreach (var meta in _metas)
                    {
                        if (meta.Status == statusFiltro)
                            metasFiltradas.Add(meta);
                    }
                }

                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        dgvMetas.DataSource = null;
                        dgvMetas.DataSource = metasFiltradas;
                    }));
                }
                else
                {
                    dgvMetas.DataSource = null;
                    dgvMetas.DataSource = metasFiltradas;
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Erro ao recarregar metas: {ex.Message}");
            }
        }

        /// <summary>
        /// Parseia JSON de metas retornado pela API
        /// </summary>
        private List<MetaDTO> ParsearMetas(string json)
        {
            var metas = new List<MetaDTO>();

            try
            {
                // Remover [ e ] se existirem
                json = json.Trim();
                if (json.StartsWith("["))
                    json = json.Substring(1);
                if (json.EndsWith("]"))
                    json = json.Substring(0, json.Length - 1);

                // Split por objetos JSON
                var objetos = SepararObjetos(json);

                foreach (var obj in objetos)
                {
                    var meta = new MetaDTO();
                    meta.Id = ExtrairInteiro(obj, "id");
                    meta.IdUsuario = ExtrairInteiro(obj, "id_usuario");
                    meta.Titulo = ExtrairString(obj, "titulo");
                    meta.Descricao = ExtrairString(obj, "descricao");
                    meta.Categoria = ExtrairString(obj, "categoria");
                    meta.Status = ExtrairString(obj, "status");

                    // Parsear data
                    string dataStr = ExtrairString(obj, "prazo");
                    if (!string.IsNullOrEmpty(dataStr) && DateTime.TryParse(dataStr, out DateTime data))
                        meta.Prazo = data;

                    if (!string.IsNullOrEmpty(meta.Titulo))
                        metas.Add(meta);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Erro ao parsear metas: {ex.Message}");
            }

            return metas;
        }

        private List<string> SepararObjetos(string json)
        {
            var objetos = new List<string>();
            int nivelChaves = 0;
            int inicio = -1;

            for (int i = 0; i < json.Length; i++)
            {
                if (json[i] == '{')
                {
                    if (nivelChaves == 0)
                        inicio = i;
                    nivelChaves++;
                }
                else if (json[i] == '}')
                {
                    nivelChaves--;
                    if (nivelChaves == 0 && inicio >= 0)
                    {
                        objetos.Add(json.Substring(inicio, i - inicio + 1));
                        inicio = -1;
                    }
                }
            }

            return objetos;
        }

        private int ExtrairInteiro(string json, string campo)
        {
            int idx = json.IndexOf($"\"{campo}\"");
            if (idx < 0)
                return 0;

            idx = json.IndexOf(":", idx);
            if (idx < 0)
                return 0;

            int fimIdx = json.IndexOf(",", idx);
            if (fimIdx < 0)
                fimIdx = json.IndexOf("}", idx);

            string valor = json.Substring(idx + 1, fimIdx - idx - 1).Trim();
            if (int.TryParse(valor, out int resultado))
                return resultado;

            return 0;
        }

        private string ExtrairString(string json, string campo)
        {
            int idx = json.IndexOf($"\"{campo}\"");
            if (idx < 0)
                return null;

            idx = json.IndexOf(":", idx);
            if (idx < 0)
                return null;

            idx = json.IndexOf("\"", idx);
            if (idx < 0)
                return null;

            int fimIdx = json.IndexOf("\"", idx + 1);
            if (fimIdx < 0)
                return null;

            string valor = json.Substring(idx + 1, fimIdx - idx - 1);
            return valor;
        }
    }
}
