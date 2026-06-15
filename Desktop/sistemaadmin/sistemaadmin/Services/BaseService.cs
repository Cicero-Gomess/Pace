using System;
using System.Net.Http;
using System.Net.Http.Headers;

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
            if (string.IsNullOrEmpty(client.BaseAddress?.AbsoluteUri))
            {
                client.BaseAddress = new Uri(BaseUrl);
            }

            // Configurar header de autenticação Bearer
            // Remover header anterior se existir
            client.DefaultRequestHeaders.Authorization = null;

            // Adicionar novo header
            client.DefaultRequestHeaders.Authorization = 
                new AuthenticationHeaderValue("Bearer", token);
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
    }
}
