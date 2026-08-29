using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Windows.Forms;
using sistemaadmin.Services;

namespace sistemaadmin
{
    public partial class FormComentarios : Form
    {
        private readonly string _token;
        private ComentarioService _comentarioService;
        private List<ComentarioItem> _comentarios;
        private int _postIdAtual = 0;

        public FormComentarios(string token)
        {
            InitializeComponent();
            _token = token;
            _comentarios = new List<ComentarioItem>();
        }

        private void FormComentarios_Load(object sender, EventArgs e)
        {
            _comentarioService = new ComentarioService(_token);
            this.Text = "Sistema Administrativo - Gerenciamento de Comentários";
            this.CenterToScreen();
            ConfigurarDataGridView();
        }

        private void ConfigurarDataGridView()
        {
            dgvComentarios.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            dgvComentarios.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dgvComentarios.MultiSelect = false;
            dgvComentarios.AllowUserToAddRows = false;
            dgvComentarios.AllowUserToDeleteRows = false;
        }

        private async void btnCarregar_Click(object sender, EventArgs e)
        {
            try
            {
                string searchInput = txtPostId.Text.Trim();

                if (string.IsNullOrEmpty(searchInput))
                {
                    MessageBox.Show("Por favor, insira um ID de post ou texto para buscar.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                btnCarregar.Enabled = false;
                btnCarregar.Text = "Carregando...";

                // Verificar se é um ID numérico
                if (int.TryParse(searchInput, out int postId))
                {
                    // Busca por ID
                    _postIdAtual = postId;
                    await CarregarComentariosporPostId(postId);
                }
                else
                {
                    // Busca por texto (conteúdo)
                    await CarregarComentariosPorTexto(searchInput);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro: {ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnCarregar.Enabled = true;
                btnCarregar.Text = "Carregar Comentários";
            }
        }

        private async Task CarregarComentariosporPostId(int postId)
        {
            try
            {
                btnCarregar.Enabled = false;
                btnCarregar.Text = "Carregando...";

                var json = await _comentarioService.ListarComentariosAsync(postId);
                _comentarios = ParsearComentarios(json);

                // ✅ CORREÇÃO: Atualizar UI na thread principal
                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        dgvComentarios.DataSource = null;
                        dgvComentarios.DataSource = _comentarios;
                        LimparCampos();

                        if (_comentarios.Count == 0)
                        {
                            MessageBox.Show("Nenhum comentário encontrado para este post.", "Informação",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }));
                }
                else
                {
                    dgvComentarios.DataSource = null;
                    dgvComentarios.DataSource = _comentarios;
                    LimparCampos();

                    if (_comentarios.Count == 0)
                    {
                        MessageBox.Show("Nenhum comentário encontrado para este post.", "Informação",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao carregar comentários:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnCarregar.Enabled = true;
                btnCarregar.Text = "Carregar Comentários";
            }
        }

        /// <summary>
        /// Busca comentários por texto (conteúdo de post)
        /// Usa API de busca de posts e depois carrega comentários de cada post encontrado
        /// </summary>
        private async Task CarregarComentariosPorTexto(string searchText)
        {
            try
            {
                btnCarregar.Enabled = false;
                btnCarregar.Text = "Buscando...";

                // Usar PostService para buscar posts por conteúdo
                var postService = new PostService(_comentarioService.Token ?? "");
                var postsJson = await postService.BuscarPostsPorConteudoAsync(searchText);

                // Parsear posts encontrados
                var postsEncontrados = ParsearPostsPorConteudo(postsJson);

                if (postsEncontrados.Count == 0)
                {
                    if (InvokeRequired)
                    {
                        Invoke(new Action(() =>
                        {
                            dgvComentarios.DataSource = null;
                            MessageBox.Show($"Nenhum post encontrado com '{searchText}'.", "Informação",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }));
                    }
                    else
                    {
                        dgvComentarios.DataSource = null;
                        MessageBox.Show($"Nenhum post encontrado com '{searchText}'.", "Informação",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    return;
                }

                // Carregar comentários de todos os posts encontrados
                var todosComentarios = new List<ComentarioItem>();
                foreach (var post in postsEncontrados)
                {
                    try
                    {
                        var comentariosJson = await _comentarioService.ListarComentariosAsync(post.Id);
                        var comentarios = ParsearComentarios(comentariosJson);
                        todosComentarios.AddRange(comentarios);
                    }
                    catch
                    {
                        // Ignorar erro em post individual, continuar com próximo
                    }
                }

                _comentarios = todosComentarios;

                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        dgvComentarios.DataSource = null;
                        dgvComentarios.DataSource = _comentarios;
                        LimparCampos();

                        if (_comentarios.Count == 0)
                        {
                            MessageBox.Show($"Nenhum comentário encontrado em posts com '{searchText}'.", "Informação",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                        else
                        {
                            MessageBox.Show($"Encontrados {_comentarios.Count} comentário(s) em {postsEncontrados.Count} post(s) com '{searchText}'.", "Sucesso",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }));
                }
                else
                {
                    dgvComentarios.DataSource = null;
                    dgvComentarios.DataSource = _comentarios;
                    LimparCampos();

                    if (_comentarios.Count == 0)
                    {
                        MessageBox.Show($"Nenhum comentário encontrado em posts com '{searchText}'.", "Informação",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    else
                    {
                        MessageBox.Show($"Encontrados {_comentarios.Count} comentário(s) em {postsEncontrados.Count} post(s) com '{searchText}'.", "Sucesso",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao buscar comentários por texto:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnCarregar.Enabled = true;
                btnCarregar.Text = "Carregar Comentários";
            }
        }

        private async Task CarregarComentarios(int postId)
        {
            try
            {
                btnCarregar.Enabled = false;
                btnCarregar.Text = "Carregando...";

                var json = await _comentarioService.ListarComentariosAsync(postId);
                _comentarios = ParsearComentarios(json);

                // ✅ CORREÇÃO: Atualizar UI na thread principal
                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        dgvComentarios.DataSource = null;
                        dgvComentarios.DataSource = _comentarios;
                        LimparCampos();

                        if (_comentarios.Count == 0)
                        {
                            MessageBox.Show("Nenhum comentário encontrado para este post.", "Informação",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }));
                }
                else
                {
                    dgvComentarios.DataSource = null;
                    dgvComentarios.DataSource = _comentarios;
                    LimparCampos();

                    if (_comentarios.Count == 0)
                    {
                        MessageBox.Show("Nenhum comentário encontrado para este post.", "Informação",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao carregar comentários:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnCarregar.Enabled = true;
                btnCarregar.Text = "Carregar Comentários";
            }
        }

        private void dgvComentarios_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvComentarios.SelectedRows.Count > 0)
            {
                ComentarioItem comentario = (ComentarioItem)dgvComentarios.SelectedRows[0].DataBoundItem;
                txtComentario.Text = comentario.comentario ?? "";
            }
        }

        private async void btnAdicionar_Click(object sender, EventArgs e)
        {
            try
            {
                if (_postIdAtual == 0)
                {
                    MessageBox.Show("Por favor, carregue os comentários de um post primeiro.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                string conteudo = txtComentario.Text.Trim();
                if (string.IsNullOrEmpty(conteudo))
                {
                    MessageBox.Show("Por favor, insira o conteúdo do comentário.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                btnAdicionar.Enabled = false;
                btnAdicionar.Text = "Adicionando...";

                await _comentarioService.AdicionarComentarioAsync(_postIdAtual, conteudo);

                MessageBox.Show("Comentário adicionado com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparCampos();
                await CarregarComentarios(_postIdAtual);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao adicionar comentário:\n{ex.Message}", "Erro",
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
                if (dgvComentarios.SelectedRows.Count == 0)
                {
                    MessageBox.Show("Por favor, selecione um comentário para atualizar.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                ComentarioItem comentario = (ComentarioItem)dgvComentarios.SelectedRows[0].DataBoundItem;
                string conteudo = txtComentario.Text.Trim();

                if (string.IsNullOrEmpty(conteudo))
                {
                    MessageBox.Show("Por favor, insira o conteúdo do comentário.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                btnAtualizar.Enabled = false;
                btnAtualizar.Text = "Atualizando...";

                await _comentarioService.AtualizarComentarioAsync(comentario.id, conteudo);

                MessageBox.Show("Comentário atualizado com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparCampos();
                await CarregarComentarios(_postIdAtual);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao atualizar comentário:\n{ex.Message}", "Erro",
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
                if (dgvComentarios.SelectedRows.Count == 0)
                {
                    MessageBox.Show("Por favor, selecione um comentário para deletar.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                ComentarioItem comentario = (ComentarioItem)dgvComentarios.SelectedRows[0].DataBoundItem;

                DialogResult resultado = MessageBox.Show(
                    $"Tem certeza que deseja deletar este comentário?\n\n\"{comentario.comentario}\"",
                    "Confirmação", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

                if (resultado != DialogResult.Yes)
                    return;

                btnDeletar.Enabled = false;
                btnDeletar.Text = "Deletando...";

                await _comentarioService.DeletarComentarioAsync(comentario.id);

                MessageBox.Show("Comentário deletado com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparCampos();
                await CarregarComentarios(_postIdAtual);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao deletar comentário:\n{ex.Message}", "Erro",
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
            txtComentario.Clear();
            dgvComentarios.ClearSelection();
        }

        private List<ComentarioItem> ParsearComentarios(string json)
        {
            var comentarios = new List<ComentarioItem>();

            try
            {
                if (string.IsNullOrEmpty(json) || json == "[]")
                    return comentarios;

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

                    var comentario = new ComentarioItem();

                    // Extrai ID
                    var idMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""id""\s*:\s*(\d+)");
                    if (idMatch.Success)
                        comentario.id = int.Parse(idMatch.Groups[1].Value);

                    // Extrai comentário
                    var comentarioMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""comentario""\s*:\s*""([^""]*)""");
                    if (comentarioMatch.Success)
                        comentario.comentario = _comentarioService.UnescapeJson(comentarioMatch.Groups[1].Value);

                    // Extrai data
                    var dataMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""data_comentario""\s*:\s*""([^""]*)""");
                    if (dataMatch.Success)
                        comentario.data_comentario = dataMatch.Groups[1].Value;

                    // Extrai username do objeto usuario
                    var usernameMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""usuario""[^}]*""username""\s*:\s*""([^""]*)""");
                    if (usernameMatch.Success)
                        comentario.username = usernameMatch.Groups[1].Value;

                    comentarios.Add(comentario);
                }
            }
            catch
            {
                // Retorna lista vazia se houver erro
            }

            return comentarios;
        }

        private class ComentarioItem
        {
            public int id { get; set; }
            public string comentario { get; set; }
            public string data_comentario { get; set; }
            public string username { get; set; }
        }

        private class PostSimplificado
        {
            public int Id { get; set; }
            public string Conteudo { get; set; }
        }

        /// <summary>
        /// Parseia JSON de posts retornado pela API (/post/buscar_post_conteudo)
        /// </summary>
        private List<PostSimplificado> ParsearPostsPorConteudo(string json)
        {
            var posts = new List<PostSimplificado>();

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
                    var post = new PostSimplificado();
                    post.Id = ExtrairInteiro(obj, "id");
                    post.Conteudo = ExtrairString(obj, "conteudo");

                    if (post.Id > 0 && !string.IsNullOrEmpty(post.Conteudo))
                        posts.Add(post);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Erro ao parsear posts: {ex.Message}");
            }

            return posts;
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
