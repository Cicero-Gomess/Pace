using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Windows.Forms;
using sistemaadmin.Services;

namespace sistemaadmin
{
    public partial class FormPosts : Form
    {
        private readonly string _token;
        private PostService _postService;
        private List<PostItem> _posts;

        // Variáveis para carregamento incremental
        private int _currentOffset = 0;
        private bool _isLoadingMore = false;
        private bool _allPostsLoaded = false;
        private HashSet<int> _loadedPostIds = new HashSet<int>();

        public FormPosts(string token)
        {
            InitializeComponent();
            _token = token;
            _posts = new List<PostItem>();
        }

        private void FormPosts_Load(object sender, EventArgs e)
        {
            _postService = new PostService(_token);
            this.Text = "Sistema Administrativo - Gerenciamento de Posts";
            this.CenterToScreen();

            // Carregar posts de forma assíncrona (não-bloqueante)
            _ = CarregarPostsAsync();
        }

        private async Task CarregarPostsAsync()
        {
            try
            {
                // Resetar estado inicial
                _currentOffset = 0;
                _isLoadingMore = false;
                _allPostsLoaded = false;
                _loadedPostIds.Clear();

                btnRecarregar.Enabled = false;
                btnRecarregar.Text = "Carregando...";

                var json = await _postService.GetFeedAsync().ConfigureAwait(false);
                _posts = ParsearPosts(json);

                // Armazenar IDs dos posts carregados
                foreach (var post in _posts)
                {
                    _loadedPostIds.Add(post.id);
                }

                // Se retornou menos de 4 posts, chegou ao fim da lista
                if (_posts.Count < 4)
                {
                    _allPostsLoaded = true;
                }
                else
                {
                    _currentOffset = 4;
                }

                // ✅ CORREÇÃO: Atualizar UI na thread principal
                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        dgvPosts.DataSource = null;
                        dgvPosts.DataSource = _posts;
                        AjustarColunas();
                        LimparCampos();

                        // Atualizar estado do botão de carregar posts
                        if (btnCarregarPosts != null)
                        {
                            btnCarregarPosts.Enabled = !_allPostsLoaded;
                            btnCarregarPosts.Text = _allPostsLoaded ? "Todos carregados" : "Carregar Posts";
                        }
                    }));
                }
                else
                {
                    dgvPosts.DataSource = null;
                    dgvPosts.DataSource = _posts;
                    AjustarColunas();
                    LimparCampos();

                    // Atualizar estado do botão de carregar posts
                    if (btnCarregarPosts != null)
                    {
                        btnCarregarPosts.Enabled = !_allPostsLoaded;
                        btnCarregarPosts.Text = _allPostsLoaded ? "Todos carregados" : "Carregar Posts";
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao carregar posts:\n{ex.Message}", "Erro", 
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

        private async void btnCriar_Click(object sender, EventArgs e)
        {
            try
            {
                string conteudo = txtConteudo.Text.Trim();
                string imagem = txtImagem.Text.Trim();

                if (string.IsNullOrEmpty(conteudo))
                {
                    MessageBox.Show("Por favor, insira o conteúdo do post.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                btnCriar.Enabled = false;
                btnCriar.Text = "Criando...";

                await _postService.CriarPostAsync(conteudo, string.IsNullOrEmpty(imagem) ? null : imagem);

                MessageBox.Show("Post criado com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparCampos();
                await CarregarPostsAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao criar post:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnCriar.Enabled = true;
                btnCriar.Text = "Criar";
            }
        }

        private async void btnAtualizar_Click(object sender, EventArgs e)
        {
            try
            {
                if (dgvPosts.SelectedRows.Count == 0)
                {
                    MessageBox.Show("Selecione um post para atualizar.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                PostItem post = (PostItem)dgvPosts.SelectedRows[0].DataBoundItem;
                string conteudo = txtConteudo.Text.Trim();
                string imagem = txtImagem.Text.Trim();

                if (string.IsNullOrEmpty(conteudo))
                {
                    MessageBox.Show("Por favor, insira o conteúdo do post.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                btnAtualizar.Enabled = false;
                btnAtualizar.Text = "Atualizando...";

                await _postService.AtualizarPostAsync(post.id, conteudo, 
                    string.IsNullOrEmpty(imagem) ? null : imagem);

                MessageBox.Show("Post atualizado com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparCampos();
                await CarregarPostsAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao atualizar post:\n{ex.Message}", "Erro",
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
                if (dgvPosts.SelectedRows.Count == 0)
                {
                    MessageBox.Show("Selecione um post para deletar.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                PostItem post = (PostItem)dgvPosts.SelectedRows[0].DataBoundItem;

                DialogResult resultado = MessageBox.Show(
                    $"Tem certeza que deseja deletar este post?\n\n\"{post.conteudo}\"",
                    "Confirmação", MessageBoxButtons.YesNo, MessageBoxIcon.Question);

                if (resultado != DialogResult.Yes)
                    return;

                btnDeletar.Enabled = false;
                btnDeletar.Text = "Deletando...";

                await _postService.DeletarPostAsync(post.id);

                MessageBox.Show("Post deletado com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                LimparCampos();
                await CarregarPostsAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao deletar post:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnDeletar.Enabled = true;
                btnDeletar.Text = "Deletar";
            }
        }

        private async void btnCurtir_Click(object sender, EventArgs e)
        {
            try
            {
                if (dgvPosts.SelectedRows.Count == 0)
                {
                    MessageBox.Show("Selecione um post para curtir.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                PostItem post = (PostItem)dgvPosts.SelectedRows[0].DataBoundItem;

                btnCurtir.Enabled = false;
                btnCurtir.Text = "Curtindo...";

                await _postService.CurtirPostAsync(post.id);

                MessageBox.Show("Post curtido com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                await CarregarPostsAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao curtir post:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnCurtir.Enabled = true;
                btnCurtir.Text = "❤️ Curtir";
            }
        }

        private async void btnDescurtir_Click(object sender, EventArgs e)
        {
            try
            {
                if (dgvPosts.SelectedRows.Count == 0)
                {
                    MessageBox.Show("Selecione um post para descurtir.", "Atenção",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                PostItem post = (PostItem)dgvPosts.SelectedRows[0].DataBoundItem;

                btnDescurtir.Enabled = false;
                btnDescurtir.Text = "Removendo...";

                await _postService.RemoverCurtidaAsync(post.id);

                MessageBox.Show("Curtida removida com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                await CarregarPostsAsync();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao remover curtida:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnDescurtir.Enabled = true;
                btnDescurtir.Text = "💔 Descurtir";
            }
        }

        private async void btnRecarregar_Click(object sender, EventArgs e)
        {
            LimparCampos();
            _currentOffset = 0;
            _isLoadingMore = false;
            _allPostsLoaded = false;
            _loadedPostIds.Clear();
            await CarregarPostsAsync();
        }

        private async void btnCarregarPosts_Click(object sender, EventArgs e)
        {
            await CarregarPostsIncrementalAsync().ConfigureAwait(false);
        }

        private async Task CarregarPostsIncrementalAsync()
        {
            if (_isLoadingMore || _allPostsLoaded)
                return;

            try
            {
                _isLoadingMore = true;
                btnCarregarPosts.Enabled = false;
                btnCarregarPosts.Text = "Carregando mais...";

                // Buscar próximo lote com offset
                var httpClient = new System.Net.Http.HttpClient();
                httpClient.DefaultRequestHeaders.Authorization = 
                    new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _token);

                string url = $"http://localhost:8000/post/feed?offset={_currentOffset}&limit=4";
                var response = await httpClient.GetAsync(url).ConfigureAwait(false);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var json = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                var novosPosts = ParsearPosts(json);

                if (novosPosts == null || novosPosts.Count == 0)
                {
                    _allPostsLoaded = true;
                    if (InvokeRequired)
                    {
                        Invoke(new Action(() =>
                        {
                            MessageBox.Show("Todos os posts foram carregados.", "Informação",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }));
                    }
                    else
                    {
                        MessageBox.Show("Todos os posts foram carregados.", "Informação",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                    return;
                }

                // Adicionar novos posts sem duplicatas
                int novosPostsCount = 0;
                foreach (var post in novosPosts)
                {
                    if (!_loadedPostIds.Contains(post.id))
                    {
                        _loadedPostIds.Add(post.id);
                        _posts.Add(post);
                        novosPostsCount++;
                    }
                }

                // Se menos de 4 posts foram retornados, significa fim da lista
                if (novosPosts.Count < 4)
                {
                    _allPostsLoaded = true;
                }
                else
                {
                    _currentOffset += 4;
                }

                // Atualizar UI
                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        dgvPosts.DataSource = null;
                        dgvPosts.DataSource = _posts;

                        if (_allPostsLoaded)
                        {
                            MessageBox.Show("Todos os posts foram carregados.", "Informação",
                                MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }));
                }
                else
                {
                    dgvPosts.DataSource = null;
                    dgvPosts.DataSource = _posts;

                    if (_allPostsLoaded)
                    {
                        MessageBox.Show("Todos os posts foram carregados.", "Informação",
                            MessageBoxButtons.OK, MessageBoxIcon.Information);
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao carregar mais posts:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                _isLoadingMore = false;
                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        btnCarregarPosts.Enabled = !_allPostsLoaded;
                        btnCarregarPosts.Text = _allPostsLoaded ? "Todos carregados" : "Carregar Posts";
                    }));
                }
                else
                {
                    btnCarregarPosts.Enabled = !_allPostsLoaded;
                    btnCarregarPosts.Text = _allPostsLoaded ? "Todos carregados" : "Carregar Posts";
                }
            }
        }

        private void dgvPosts_SelectionChanged(object sender, EventArgs e)
        {
            if (dgvPosts.SelectedRows.Count > 0)
            {
                PostItem post = (PostItem)dgvPosts.SelectedRows[0].DataBoundItem;
                txtConteudo.Text = post.conteudo ?? "";
                txtImagem.Text = post.imagem ?? "";
            }
        }

        private void LimparCampos()
        {
            txtConteudo.Clear();
            txtImagem.Clear();
            dgvPosts.ClearSelection();
        }

        private void AjustarColunas()
        {
            dgvPosts.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
            dgvPosts.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
            dgvPosts.MultiSelect = false;
            dgvPosts.AllowUserToAddRows = false;
            dgvPosts.AllowUserToDeleteRows = false;
        }

        private List<PostItem> ParsearPosts(string json)
        {
            var posts = new List<PostItem>();

            try
            {
                // Parse simples do JSON array
                if (string.IsNullOrEmpty(json) || json == "[]")
                    return posts;

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

                    var post = new PostItem();

                    // Extrai ID
                    var idMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""id""\s*:\s*(\d+)");
                    if (idMatch.Success)
                        post.id = int.Parse(idMatch.Groups[1].Value);

                    // Extrai conteúdo
                    var conteudoMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""conteudo""\s*:\s*""([^""]*)""");
                    if (conteudoMatch.Success)
                        post.conteudo = UnescapeJson(conteudoMatch.Groups[1].Value);

                    // Extrai imagem
                    var imagemMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""imagem""\s*:\s*""([^""]*)""");
                    if (imagemMatch.Success)
                        post.imagem = UnescapeJson(imagemMatch.Groups[1].Value);

                    // Extrai likes
                    var likesMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""likes""\s*:\s*(\d+)");
                    if (likesMatch.Success)
                        post.likes = int.Parse(likesMatch.Groups[1].Value);

                    // Extrai liked
                    var likedMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""liked""\s*:\s*(true|false)");
                    if (likedMatch.Success)
                        post.liked = likedMatch.Groups[1].Value == "true";

                    // Extrai username do usuário
                    var usernameMatch = System.Text.RegularExpressions.Regex.Match(cleanItem, @"""username""\s*:\s*""([^""]*)""");
                    if (usernameMatch.Success)
                        post.username = UnescapeJson(usernameMatch.Groups[1].Value);

                    posts.Add(post);
                }
            }
            catch
            {
                // Retorna lista vazia se houver erro no parsing
            }

            return posts;
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

        private class PostItem
        {
            public int id { get; set; }
            public string conteudo { get; set; }
            public string imagem { get; set; }
            public int likes { get; set; }
            public bool liked { get; set; }
            public string username { get; set; }
        }
    }
}
