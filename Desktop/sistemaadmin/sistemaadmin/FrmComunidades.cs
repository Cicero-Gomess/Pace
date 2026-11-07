using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;
using sistemaadmin.Services;

namespace sistemaadmin
{
    public partial class FrmComunidades : Form
    {
        private readonly string _token;
        private ComunidadeService _comunidadeService;
        private List<ComunidadeItem> _comunidades;
        private ComunidadeItem _comunidadeSelecionada;

        public FrmComunidades(string token)
        {
            InitializeComponent();
            _token = token;
            _comunidades = new List<ComunidadeItem>();
        }

        private void FrmComunidades_Load(object sender, EventArgs e)
        {
            _comunidadeService = new ComunidadeService(_token);
            this.Text = "Sistema Administrativo - Gerenciamento de Comunidades";
            this.CenterToScreen();

            // Carregar comunidades de forma assíncrona (não-bloqueante)
            _ = CarregarComunidadesAsync();
        }

        private async Task CarregarComunidadesAsync()
        {
            try
            {
                btnRecarregar.Enabled = false;
                btnRecarregar.Text = "Carregando...";

                var json = await _comunidadeService.GetAllAsync().ConfigureAwait(false);
                _comunidades = ParsearComunidades(json);

                // ✅ CORREÇÃO: Atualizar UI na thread principal
                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        dgvComunidades.DataSource = null;
                        dgvComunidades.DataSource = _comunidades;
                        AjustarColunas();
                        LimparDetalhes();
                    }));
                }
                else
                {
                    dgvComunidades.DataSource = null;
                    dgvComunidades.DataSource = _comunidades;
                    AjustarColunas();
                    LimparDetalhes();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao carregar comunidades:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                // ✅ CORREÇÃO: Atualizar UI via Invoke
                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        btnRecarregar.Enabled = true;
                        btnRecarregar.Text = "Recarregar";
                    }));
                }
                else
                {
                    btnRecarregar.Enabled = true;
                    btnRecarregar.Text = "Recarregar";
                }
            }
        }

        private List<ComunidadeItem> ParsearComunidades(string json)
        {
            var comunidades = new List<ComunidadeItem>();

            try
            {
                // Parse simples do JSON array
                if (string.IsNullOrEmpty(json) || json == "[]")
                    return comunidades;

                json = json.Trim();
                if (json.StartsWith("[") && json.EndsWith("]"))
                {
                    json = json.Substring(1, json.Length - 2);
                }

                string[] items = json.Split(new string[] { "},{" }, StringSplitOptions.None);

                foreach (var item in items)
                {
                    string cleanItem = item.Replace("{", "").Replace("}", "").Trim();

                    if (string.IsNullOrEmpty(cleanItem))
                        continue;

                    var comunidade = new ComunidadeItem();

                    // Extrai ID
                    var idMatch = Regex.Match(cleanItem, @"""id""\s*:\s*(\d+)");
                    if (idMatch.Success)
                        comunidade.id = int.Parse(idMatch.Groups[1].Value);

                    // Extrai nome
                    var nomeMatch = Regex.Match(cleanItem, @"""nome""\s*:\s*""([^""]*)""");
                    if (nomeMatch.Success)
                        comunidade.nome = UnescapeJson(nomeMatch.Groups[1].Value);

                    // Extrai descrição
                    var descricaoMatch = Regex.Match(cleanItem, @"""descricao""\s*:\s*""([^""]*)""");
                    if (descricaoMatch.Success)
                        comunidade.descricao = UnescapeJson(descricaoMatch.Groups[1].Value);

                    // Extrai privacidade
                    var privacidadeMatch = Regex.Match(cleanItem, @"""privacidade""\s*:\s*""([^""]*)""");
                    if (privacidadeMatch.Success)
                        comunidade.privacidade = UnescapeJson(privacidadeMatch.Groups[1].Value);

                    // Extrai criador_id
                    var criadorMatch = Regex.Match(cleanItem, @"""criador_id""\s*:\s*(\d+)");
                    if (criadorMatch.Success)
                        comunidade.criador_id = int.Parse(criadorMatch.Groups[1].Value);

                    // Extrai data_criacao
                    var dataMatch = Regex.Match(cleanItem, @"""data_criacao""\s*:\s*""([^""]*)""");
                    if (dataMatch.Success)
                        comunidade.data_criacao = UnescapeJson(dataMatch.Groups[1].Value);

                    // Extrai membros_count
                    var membrosMatch = Regex.Match(cleanItem, @"""membros_count""\s*:\s*(\d+)");
                    if (membrosMatch.Success)
                        comunidade.membros_count = int.Parse(membrosMatch.Groups[1].Value);

                    // Extrai sou_membro
                    var souMembroMatch = Regex.Match(cleanItem, @"""sou_membro""\s*:\s*(true|false)");
                    if (souMembroMatch.Success)
                        comunidade.sou_membro = souMembroMatch.Groups[1].Value == "true";

                    // Extrai sou_criador
                    var souCriadorMatch = Regex.Match(cleanItem, @"""sou_criador""\s*:\s*(true|false)");
                    if (souCriadorMatch.Success)
                        comunidade.sou_criador = souCriadorMatch.Groups[1].Value == "true";

                    // Extrai topicos como string JSON array
                    var topicosMatch = Regex.Match(cleanItem, @"""topicos""\s*:\s*(\[[^\]]*\])");
                    if (topicosMatch.Success)
                        comunidade.topicos = topicosMatch.Groups[1].Value;
                    else
                        comunidade.topicos = "[]";

                    comunidades.Add(comunidade);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Erro ao parsear comunidades: {ex.Message}");
            }

            return comunidades;
        }

        private string UnescapeJson(string text)
        {
            if (string.IsNullOrEmpty(text))
                return string.Empty;

            return text
                .Replace("\\n", "\n")
                .Replace("\\r", "\r")
                .Replace("\\t", "\t")
                .Replace("\\\"", "\"")
                .Replace("\\\\", "\\");
        }

        private void AjustarColunas()
        {
            if (dgvComunidades.Columns.Count == 0)
                return;

            dgvComunidades.Columns["id"].Width = 50;
            dgvComunidades.Columns["nome"].Width = 150;
            dgvComunidades.Columns["descricao"].Width = 200;
            dgvComunidades.Columns["privacidade"].Width = 80;
            dgvComunidades.Columns["membros_count"].Width = 80;
            dgvComunidades.Columns["data_criacao"].Width = 120;

            // Ocultar colunas não necessárias
            dgvComunidades.Columns["topicos"].Visible = false;
            dgvComunidades.Columns["criador_id"].Visible = false;
            dgvComunidades.Columns["sou_membro"].Visible = false;
            dgvComunidades.Columns["sou_criador"].Visible = false;
        }

        private void LimparDetalhes()
        {
            txtNome.Text = "";
            txtDescricao.Text = "";
            txtPrivacidade.Text = "";
            txtMembros.Text = "";
            txtCriador.Text = "";
            txtCriacao.Text = "";
            txtTopicos.Text = "";

            btnAtualizar.Enabled = false;
            btnExcluir.Enabled = false;
            btnMembros.Enabled = false;

            _comunidadeSelecionada = null;
        }

        private void dgvComunidades_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvComunidades.SelectedRows.Count == 0)
            {
                LimparDetalhes();
                return;
            }

            _comunidadeSelecionada = (ComunidadeItem)dgvComunidades.SelectedRows[0].DataBoundItem;

            if (_comunidadeSelecionada != null)
            {
                PopularDetalhes(_comunidadeSelecionada);
                btnAtualizar.Enabled = _comunidadeSelecionada.sou_criador;
                btnExcluir.Enabled = _comunidadeSelecionada.sou_criador;
                btnMembros.Enabled = _comunidadeSelecionada.sou_criador;
            }
        }

        private void PopularDetalhes(ComunidadeItem comunidade)
        {
            txtNome.Text = comunidade.nome ?? "";
            txtDescricao.Text = comunidade.descricao ?? "";
            txtPrivacidade.Text = comunidade.privacidade ?? "";
            txtMembros.Text = $"{comunidade.membros_count}";
            txtCriador.Text = $"{comunidade.criador_id}";
            txtCriacao.Text = comunidade.data_criacao ?? "";
            txtTopicos.Text = comunidade.topicos ?? "";
        }

        private async void btnPesquisar_Click(object sender, EventArgs e)
        {
            string termo = txtPesquisa.Text.Trim().ToLower();

            if (string.IsNullOrEmpty(termo))
            {
                MessageBox.Show("Digite um termo para pesquisar.", "Aviso",
                    MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                var resultado = _comunidades
                    .Where(c => c.nome.ToLower().Contains(termo) || c.descricao.ToLower().Contains(termo))
                    .ToList();

                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        dgvComunidades.DataSource = null;
                        dgvComunidades.DataSource = resultado;
                        AjustarColunas();
                        LimparDetalhes();
                    }));
                }
                else
                {
                    dgvComunidades.DataSource = null;
                    dgvComunidades.DataSource = resultado;
                    AjustarColunas();
                    LimparDetalhes();
                }

                MessageBox.Show($"Encontradas {resultado.Count} comunidade(s).", "Resultado",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao pesquisar:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private async void btnLimparFiltro_Click(object sender, EventArgs e)
        {
            txtPesquisa.Text = "";
            await CarregarComunidadesAsync();
        }

        private async void btnRecarregar_Click(object sender, EventArgs e)
        {
            await CarregarComunidadesAsync();
        }

        private async void btnAtualizar_Click(object sender, EventArgs e)
        {
            try
            {
                if (_comunidadeSelecionada == null)
                {
                    MessageBox.Show("Selecione uma comunidade para atualizar.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                string nome = txtNome.Text.Trim();
                string descricao = txtDescricao.Text.Trim();

                if (string.IsNullOrEmpty(nome))
                {
                    MessageBox.Show("O nome da comunidade não pode estar vazio.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                btnAtualizar.Enabled = false;
                btnAtualizar.Text = "Atualizando...";

                // Preparar topicos como array JSON
                string topicos = _comunidadeSelecionada.topicos;
                if (string.IsNullOrEmpty(topicos) || topicos == "[]")
                {
                    topicos = "[]";
                }

                await _comunidadeService.UpdateAsync(
                    _comunidadeSelecionada.id,
                    nome,
                    descricao,
                    topicos,
                    txtPrivacidade.Text.Trim()
                );

                MessageBox.Show("Comunidade atualizada com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparDetalhes();
                await CarregarComunidadesAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao atualizar comunidade:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnAtualizar.Enabled = true;
                btnAtualizar.Text = "Atualizar";
            }
        }

        private async void btnExcluir_Click(object sender, EventArgs e)
        {
            try
            {
                if (_comunidadeSelecionada == null)
                {
                    MessageBox.Show("Selecione uma comunidade para excluir.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                DialogResult resultado = MessageBox.Show(
                    $"Tem certeza que deseja excluir a comunidade?\n\n\"{_comunidadeSelecionada.nome}\"",
                    "Confirmação", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

                if (resultado != DialogResult.Yes)
                    return;

                btnExcluir.Enabled = false;
                btnExcluir.Text = "Excluindo...";

                await _comunidadeService.DeleteAsync(_comunidadeSelecionada.id);

                MessageBox.Show("Comunidade excluída com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparDetalhes();
                await CarregarComunidadesAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao excluir comunidade:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnExcluir.Enabled = _comunidadeSelecionada != null && _comunidadeSelecionada.sou_criador;
                btnExcluir.Text = "Excluir";
            }
        }

        private async void btnMembros_Click(object sender, EventArgs e)
        {
            try
            {
                if (_comunidadeSelecionada == null)
                {
                    MessageBox.Show("Selecione uma comunidade para gerenciar membros.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                if (!_comunidadeSelecionada.sou_criador)
                {
                    MessageBox.Show("Você não tem permissão para gerenciar membros desta comunidade.", "Erro",
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }

                btnMembros.Enabled = false;
                btnMembros.Text = "Carregando...";

                var json = await _comunidadeService.GetMembersAsync(_comunidadeSelecionada.id).ConfigureAwait(false);

                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        ExibirFormularioMembros(json);
                    }));
                }
                else
                {
                    ExibirFormularioMembros(json);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao obter membros:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnMembros.Enabled = _comunidadeSelecionada != null && _comunidadeSelecionada.sou_criador;
                btnMembros.Text = "Gerenciar Membros";
            }
        }

        private void ExibirFormularioMembros(string jsonMembros)
        {
            try
            {
                var membros = new List<MembroItem>();

                if (!string.IsNullOrEmpty(jsonMembros) && jsonMembros.Trim() != "[]")
                {
                    jsonMembros = jsonMembros.Trim();
                    if (jsonMembros.StartsWith("[") && jsonMembros.EndsWith("]"))
                    {
                        jsonMembros = jsonMembros.Substring(1, jsonMembros.Length - 2);
                    }

                    string[] items = jsonMembros.Split(new string[] { "},{" }, StringSplitOptions.None);

                    foreach (var item in items)
                    {
                        string cleanItem = item.Replace("{", "").Replace("}", "").Trim();

                        if (string.IsNullOrEmpty(cleanItem))
                            continue;

                        var membro = new MembroItem();

                        // Extrai usuario_id
                        var usuarioIdMatch = Regex.Match(cleanItem, @"""usuario_id""\s*:\s*(\d+)");
                        if (usuarioIdMatch.Success)
                            membro.usuario_id = int.Parse(usuarioIdMatch.Groups[1].Value);

                        // Extrai username
                        var usernameMatch = Regex.Match(cleanItem, @"""username""\s*:\s*""([^""]*)""");
                        if (usernameMatch.Success)
                            membro.username = UnescapeJson(usernameMatch.Groups[1].Value);

                        // Extrai cargo
                        var cargoMatch = Regex.Match(cleanItem, @"""cargo""\s*:\s*""([^""]*)""");
                        if (cargoMatch.Success)
                            membro.cargo = UnescapeJson(cargoMatch.Groups[1].Value);

                        // Extrai data_entrada
                        var dataMatch = Regex.Match(cleanItem, @"""data_entrada""\s*:\s*""([^""]*)""");
                        if (dataMatch.Success)
                            membro.data_entrada = UnescapeJson(dataMatch.Groups[1].Value);

                        membros.Add(membro);
                    }
                }

                string mensagem = $"Comunidade: {_comunidadeSelecionada.nome}\n\nMembros ({membros.Count}):\n\n";

                foreach (var membro in membros)
                {
                    mensagem += $"- {membro.username} ({membro.cargo}) - Entrada: {membro.data_entrada}\n";
                }

                MessageBox.Show(mensagem, "Membros da Comunidade",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao exibir membros:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }

    // Classes auxiliares para representação de dados
    public class ComunidadeItem
    {
        public int id { get; set; }
        public string nome { get; set; }
        public string descricao { get; set; }
        public string topicos { get; set; }
        public string privacidade { get; set; }
        public int criador_id { get; set; }
        public string data_criacao { get; set; }
        public int membros_count { get; set; }
        public bool sou_membro { get; set; }
        public bool sou_criador { get; set; }
    }

    public class MembroItem
    {
        public int usuario_id { get; set; }
        public string username { get; set; }
        public string cargo { get; set; }
        public string data_entrada { get; set; }
    }
}
