using System;
using System.Net.Http;
using System.Net.Http.Headers;

namespace sistemaadmin.Services
{
    /// <summary>
    /// Serviço base que fornece um HttpClient configurado com autenticação Bearer.
    /// </summary>
    public class BaseService
    {
        protected HttpClient HttpClient { get; }
        protected string BaseUrl = "http://localhost:8000";

        public BaseService(string token)
        {
            HttpClient = new HttpClient();
            HttpClient.BaseAddress = new Uri(BaseUrl);

            // Configurar header de autenticação
            HttpClient.DefaultRequestHeaders.Authorization = 
                new AuthenticationHeaderValue("Bearer", token);
        }
    }
}
