using System;
using System.Drawing;
using System.IO;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;
using sistemaadmin.Services;

namespace sistemaadmin
{
    public partial class FormPerfil : Form
    {
        private readonly string _token;
        private ProfileService _profileService;
        private HttpClient _httpClient;

        public FormPerfil(string token)
        {
            InitializeComponent();
            _token = token;
            _profileService = new ProfileService(token);
            _httpClient = new HttpClient();
            _httpClient.DefaultRequestHeaders.Add("Authorization", $"Bearer {token}");
            _httpClient.Timeout = TimeSpan.FromSeconds(10);
        }

        private void FormPerfil_Load(object sender, EventArgs e)
        {
            // Exibir imagem padrão
            ExibirImagemPadrao();

            // ✅ CORREÇÃO: Chamar CarregarPerfilAsync sem Task.Run (mantém na thread principal)
            _ = CarregarPerfilAsync();
        }

        private async Task CarregarPerfilAsync()
        {
            try
            {
                btnRecarregarPerfil.Enabled = false;
                btnRecarregarPerfil.Text = "Carregando...";

                var json = await _profileService.GetMeAsync().ConfigureAwait(false);

                // Parse do JSON
                var username = ExtrairValor(json, "username");
                var email = ExtrairValor(json, "email");
                var fotoPerfil = ExtrairValor(json, "foto_perfil");

                // ✅ CORREÇÃO: Atualizar interface via Invoke (thread-safe)
                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        lblUsernameValor.Text = username;
                        lblEmailValor.Text = email;
                    }));
                }
                else
                {
                    lblUsernameValor.Text = username;
                    lblEmailValor.Text = email;
                }

                // Carregamento de foto - assíncrono e não-bloqueante
                if (!string.IsNullOrEmpty(fotoPerfil) && fotoPerfil != "null")
                {
                    await CarregarImagemAsync(fotoPerfil).ConfigureAwait(false);
                }
                else
                {
                    ExibirImagemPadrao();
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao carregar perfil:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                // ✅ CORREÇÃO: Atualizar botão via Invoke se necessário
                if (InvokeRequired)
                {
                    Invoke(new Action(() =>
                    {
                        btnRecarregarPerfil.Enabled = true;
                        btnRecarregarPerfil.Text = "🔄 Recarregar Perfil";
                    }));
                }
                else
                {
                    btnRecarregarPerfil.Enabled = true;
                    btnRecarregarPerfil.Text = "🔄 Recarregar Perfil";
                }
            }
        }

        /// <summary>
        /// Carrega a imagem de forma assíncrona e não-bloqueante.
        /// Suporta: URL (http/https), Data URI (data:image/...), caminho relativo (/api/...) e Base64 puro.
        /// </summary>
        private async Task CarregarImagemAsync(string fotoPerfil)
        {
            try
            {
                System.Diagnostics.Debug.WriteLine($"[FormPerfil] Tentando carregar imagem: {fotoPerfil?.Substring(0, Math.Min(50, fotoPerfil?.Length ?? 0))}...");

                // CASO 1: URL absoluta (http/https)
                if (fotoPerfil.StartsWith("http://") || fotoPerfil.StartsWith("https://"))
                {
                    System.Diagnostics.Debug.WriteLine("[FormPerfil] Detectado: URL absoluta");
                    await CarregarImagemPorUrlAsync(fotoPerfil);
                }
                // CASO 2: Caminho relativo da API (/api/...)
                else if (fotoPerfil.StartsWith("/"))
                {
                    System.Diagnostics.Debug.WriteLine("[FormPerfil] Detectado: Caminho relativo");
                    string urlCompleta = "http://localhost:8000" + fotoPerfil;
                    await CarregarImagemPorUrlAsync(urlCompleta);
                }
                // CASO 3: Data URI (data:image/png;base64,...)
                else if (fotoPerfil.StartsWith("data:"))
                {
                    System.Diagnostics.Debug.WriteLine("[FormPerfil] Detectado: Data URI");
                    await CarregarImagemDataUriAsync(fotoPerfil);
                }
                // CASO 4: Base64 puro
                else
                {
                    System.Diagnostics.Debug.WriteLine("[FormPerfil] Detectado: Base64 puro");
                    await CarregarImagemBase64Async(fotoPerfil);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[FormPerfil] Erro ao carregar imagem: {ex.Message}");
                ExibirImagemPadrao();
            }
        }

        /// <summary>
        /// Carrega imagem via URL com suporte a autenticação Bearer.
        /// Executado em thread separada para não bloquear UI.
        /// </summary>
        private async Task CarregarImagemPorUrlAsync(string url)
        {
            try
            {
                using (HttpResponseMessage response = await _httpClient.GetAsync(url, HttpCompletionOption.ResponseContentRead).ConfigureAwait(false))
                {
                    if (response.IsSuccessStatusCode)
                    {
                        using (Stream contentStream = await response.Content.ReadAsStreamAsync().ConfigureAwait(false))
                        {
                            // Ler todos os bytes em thread separada
                            MemoryStream memStream = new MemoryStream();
                            await contentStream.CopyToAsync(memStream).ConfigureAwait(false);
                            memStream.Position = 0;

                            // Criar imagem na thread separada para evitar bloqueio
                            Image img = Image.FromStream(memStream);

                            // Atualizar PictureBox na UI thread
                            if (InvokeRequired)
                            {
                                Invoke(new Action(() =>
                                {
                                    if (picFoto.Image != null)
                                        picFoto.Image.Dispose();
                                    picFoto.Image = img;
                                }));
                            }
                            else
                            {
                                if (picFoto.Image != null)
                                    picFoto.Image.Dispose();
                                picFoto.Image = img;
                            }
                        }
                    }
                    else
                    {
                        System.Diagnostics.Debug.WriteLine($"Erro ao baixar imagem: HTTP {response.StatusCode}");
                        ExibirImagemPadrao();
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Erro ao carregar imagem via URL: {ex.Message}");
                ExibirImagemPadrao();
            }
        }

        /// <summary>
        /// Carrega imagem a partir de Data URI (data:image/png;base64,...)
        /// </summary>
        private async Task CarregarImagemDataUriAsync(string dataUri)
        {
            try
            {
                // Extrair a parte Base64 do Data URI
                // Formato: data:image/png;base64,iVBORw0KGgo...
                int commaIndex = dataUri.IndexOf(',');
                if (commaIndex < 0)
                {
                    System.Diagnostics.Debug.WriteLine("[FormPerfil] Data URI inválido: vírgula não encontrada");
                    ExibirImagemPadrao();
                    return;
                }

                string base64String = dataUri.Substring(commaIndex + 1);
                System.Diagnostics.Debug.WriteLine("[FormPerfil] Data URI extraído, convertendo Base64...");

                await CarregarImagemBase64Async(base64String);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[FormPerfil] Erro ao carregar Data URI: {ex.Message}");
                ExibirImagemPadrao();
            }
        }

        /// <summary>
        /// Carrega imagem a partir de string Base64 puro.
        /// Executado em thread separada para não bloquear UI.
        /// </summary>
        private async Task CarregarImagemBase64Async(string base64String)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(base64String))
                {
                    System.Diagnostics.Debug.WriteLine("[FormPerfil] Base64 vazio");
                    ExibirImagemPadrao();
                    return;
                }

                // ✅ VALIDAÇÃO: Verificar se é Base64 válido antes de converter
                byte[] imageBytes = await Task.Run(() =>
                {
                    try
                    {
                        // Remover espaços em branco
                        string base64Limpo = System.Text.RegularExpressions.Regex.Replace(base64String, @"\s", "");

                        // Validar comprimento (deve ser múltiplo de 4)
                        if (base64Limpo.Length % 4 != 0)
                        {
                            System.Diagnostics.Debug.WriteLine($"[FormPerfil] Base64 inválido: comprimento não é múltiplo de 4 ({base64Limpo.Length})");
                            return null;
                        }

                        return Convert.FromBase64String(base64Limpo);
                    }
                    catch (FormatException ex)
                    {
                        System.Diagnostics.Debug.WriteLine($"[FormPerfil] Erro ao decodificar Base64: {ex.Message}");
                        return null;
                    }
                });

                if (imageBytes == null || imageBytes.Length == 0)
                {
                    System.Diagnostics.Debug.WriteLine("[FormPerfil] Base64 decodificado resultou em array vazio");
                    ExibirImagemPadrao();
                    return;
                }

                using (MemoryStream ms = new MemoryStream(imageBytes))
                {
                    // Criar imagem
                    Image img = Image.FromStream(ms);

                    // Atualizar PictureBox na UI thread
                    if (InvokeRequired)
                    {
                        Invoke(new Action(() =>
                        {
                            if (picFoto.Image != null)
                                picFoto.Image.Dispose();
                            picFoto.Image = img;
                        }));
                    }
                    else
                    {
                        if (picFoto.Image != null)
                            picFoto.Image.Dispose();
                        picFoto.Image = img;
                    }
                }

                System.Diagnostics.Debug.WriteLine("[FormPerfil] Imagem carregada com sucesso");
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[FormPerfil] Erro ao carregar imagem Base64: {ex.Message}");
                ExibirImagemPadrao();
            }
        }

        private void ExibirImagemPadrao()
        {
            try
            {
                picFoto.Image = new Bitmap(250, 250);
                using (Graphics g = Graphics.FromImage(picFoto.Image))
                {
                    g.Clear(Color.LightGray);
                    using (Font font = new Font("Segoe UI", 12, FontStyle.Bold))
                    {
                        g.DrawString("Sem Foto", font, Brushes.Gray, new PointF(70, 110));
                    }
                }
            }
            catch { }
        }

        private async void BtnAtualizarFoto_Click(object sender, EventArgs e)
        {
            try
            {
                string url = txtNovaFotoUrl.Text.Trim();

                if (string.IsNullOrEmpty(url))
                {
                    MessageBox.Show("Por favor, insira uma URL válida da foto.", "Validação",
                        MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }

                btnAtualizarFoto.Enabled = false;
                btnAtualizarFoto.Text = "Atualizando...";

                // Chamar API para atualizar foto
                await _profileService.TrocarFotoAsync(url).ConfigureAwait(false);

                MessageBox.Show("Foto atualizada com sucesso!", "Sucesso",
                    MessageBoxButtons.OK, MessageBoxIcon.Information);

                txtNovaFotoUrl.Clear();

                // Recarregar perfil de forma assíncrona
                await CarregarPerfilAsync().ConfigureAwait(false);
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Erro ao atualizar foto:\n{ex.Message}", "Erro",
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
            finally
            {
                btnAtualizarFoto.Enabled = true;
                btnAtualizarFoto.Text = "✓ Atualizar Foto";
            }
        }

        private async void BtnRecarregarPerfil_Click(object sender, EventArgs e)
        {
            await CarregarPerfilAsync().ConfigureAwait(false);
        }

        private string ExtrairValor(string json, string chave)
        {
            var regex = new Regex($@"""{chave}""\s*:\s*""([^""]*)""");
            var match = regex.Match(json);
            return match.Success ? UnescapeJson(match.Groups[1].Value) : "";
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
    }
}
