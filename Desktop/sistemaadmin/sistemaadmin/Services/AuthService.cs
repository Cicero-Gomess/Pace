using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
    public class AuthService
    {
        private readonly string _baseUrl = "http://localhost:8000";
        private readonly HttpClient _httpClient;

        public AuthService()
        {
            _httpClient = new HttpClient();
        }

        /// <summary>
        /// Realiza login e retorna o token de acesso.
        /// </summary>
        public async Task<string> Login(string email, string senha)
        {
            var content = new FormUrlEncodedContent(new[]
            {
                new KeyValuePair<string, string>("username", email),
                new KeyValuePair<string, string>("password", senha)
            });

            var response = await _httpClient.PostAsync($"{_baseUrl}/auth/token", content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                throw new Exception($"Erro na autenticação: {responseContent}");
            }

            // Extrai o access_token da resposta JSON
            var tokenStartIndex = responseContent.IndexOf("\"access_token\"");
            if (tokenStartIndex == -1)
                throw new Exception("Token não encontrado na resposta da API.");

            tokenStartIndex = responseContent.IndexOf("\"", tokenStartIndex + 15) + 1;
            var tokenEndIndex = responseContent.IndexOf("\"", tokenStartIndex);

            return responseContent.Substring(tokenStartIndex, tokenEndIndex - tokenStartIndex);
        }
    }
}
