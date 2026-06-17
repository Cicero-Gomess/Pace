using System;
using System.Drawing;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
    /// <summary>
    /// Serviço base que fornece um HttpClient configurado com autenticação Bearer.
    /// Usa singleton HttpClient para evitar socket exhaustion e melhorar performance.
    /// </summary>
    public class BaseService
    {
        private static HttpClient _sharedHttpClient;
        private static object _lockObject = new object();

        protected HttpClient HttpClient 
        { 
            get 
            { 
                return GetOrCreateHttpClient(); 
            } 
        }

        protected string BaseUrl = "http://localhost:8000";
        protected string Token { get; set; }

        public BaseService(string token)
        {
            if (string.IsNullOrWhiteSpace(token))
                throw new ArgumentException("Token não pode estar vazio.", nameof(token));

            Token = token;
            InitializeHttpClient(token);
        }

        /// <summary>
        /// Obter ou criar HttpClient singleton (thread-safe)
        /// </summary>
        private static HttpClient GetOrCreateHttpClient()
        {
            if (_sharedHttpClient == null)
            {
                lock (_lockObject)
                {
                    if (_sharedHttpClient == null)
                    {
                        _sharedHttpClient = new HttpClient 
                        { 
                            Timeout = TimeSpan.FromSeconds(30) 
                        };
                        _sharedHttpClient.DefaultRequestHeaders.Add("User-Agent", "WindowsFormsApp/1.0");

                        System.Diagnostics.Debug.WriteLine("[BaseService] HttpClient singleton criado");
                    }
                }
            }
            return _sharedHttpClient;
        }

        /// <summary>
        /// Inicializar HttpClient com token de autenticação Bearer
        /// </summary>
        private void InitializeHttpClient(string token)
        {
            var client = GetOrCreateHttpClient();

            // Configurar base URL se não estiver configurada
            if (client.BaseAddress == null || string.IsNullOrEmpty(client.BaseAddress.AbsoluteUri))
            {
                client.BaseAddress = new Uri(BaseUrl);
                System.Diagnostics.Debug.WriteLine($"[BaseService] Base URL configurada: {BaseUrl}");
            }

            // Configurar header de autenticação Bearer
            // Remover header anterior se existir
            client.DefaultRequestHeaders.Authorization = null;

            // Adicionar novo header
            client.DefaultRequestHeaders.Authorization = 
                new AuthenticationHeaderValue("Bearer", token);

            System.Diagnostics.Debug.WriteLine($"[BaseService] Bearer token configurado (primeiros 20 chars: {token.Substring(0, Math.Min(20, token.Length))}...)");
        }

        /// <summary>
        /// Escapar string para JSON
        /// </summary>
        protected string EscapeJson(string text)
        {
            if (string.IsNullOrEmpty(text))
                return string.Empty;

            return text
                .Replace("\\", "\\\\")
                .Replace("\"", "\\\"")
                .Replace("\n", "\\n")
                .Replace("\r", "\\r")
                .Replace("\t", "\\t");
        }

        /// <summary>
        /// Baixa uma imagem de forma assíncrona com suporte a autenticação Bearer.
        /// Ideal para URLs protegidas que requerem token JWT.
        /// </summary>
        /// <param name="imageUrl">URL da imagem (http/https)</param>
        /// <param name="timeout">Timeout em segundos (padrão: 10)</param>
        /// <returns>Image carregada ou null se falhar</returns>
        public async Task<Image> BaixarImagemAsync(string imageUrl, int timeout = 10)
        {
            if (string.IsNullOrWhiteSpace(imageUrl))
                return null;

            try
            {
                using (var client = new HttpClient { Timeout = TimeSpan.FromSeconds(timeout) })
                {
                    // Adicionar Bearer token se for URL protegida
                    client.DefaultRequestHeaders.Authorization = 
                        new AuthenticationHeaderValue("Bearer", Token);

                    System.Diagnostics.Debug.WriteLine($"[BaseService] Iniciando download de imagem: {imageUrl}");

                    using (var response = await client.GetAsync(imageUrl, HttpCompletionOption.ResponseContentRead).ConfigureAwait(false))
                    {
                        if (response.IsSuccessStatusCode)
                        {
                            using (var contentStream = await response.Content.ReadAsStreamAsync().ConfigureAwait(false))
                            {
                                MemoryStream memStream = new MemoryStream();
                                await contentStream.CopyToAsync(memStream).ConfigureAwait(false);
                                memStream.Position = 0;

                                // Criar imagem em thread separada para evitar bloqueio
                                var image = await Task.Run(() => Image.FromStream(memStream));
                                System.Diagnostics.Debug.WriteLine("[BaseService] Imagem carregada com sucesso");
                                return image;
                            }
                        }
                        else
                        {
                            System.Diagnostics.Debug.WriteLine($"[BaseService] Erro HTTP {response.StatusCode} ao baixar imagem");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[BaseService] Erro ao baixar imagem: {ex.Message}");
            }

            return null;
        }
    }
}
