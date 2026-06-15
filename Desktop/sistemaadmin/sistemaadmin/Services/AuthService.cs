using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
    public class AuthService
    {
        private readonly string _baseUrl = "http://localhost:8000";
        private static HttpClient _sharedHttpClient;

        public AuthService()
        {
            // Usar HttpClient singleton para evitar socket exhaustion
            if (_sharedHttpClient == null)
            {
                _sharedHttpClient = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
            }
        }

        /// <summary>
        /// Realiza login e retorna o token de acesso.
        /// Compatível com FastAPI OAuth2PasswordRequestForm
        /// </summary>
        public async Task<string> Login(string email, string senha)
        {
            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(senha))
                throw new Exception("Email e senha são obrigatórios.");

            try
            {
                // FormUrlEncodedContent é o correto para OAuth2PasswordRequestForm
                var content = new FormUrlEncodedContent(new[]
                {
                    new KeyValuePair<string, string>("username", email.Trim()),
                    new KeyValuePair<string, string>("password", senha.Trim())
                });

                // DEBUG: Mostrar o que está sendo enviado
                var bodyContent = await content.ReadAsStringAsync();
                System.Diagnostics.Debug.WriteLine($"[AuthService] Enviando: {bodyContent}");
                System.Diagnostics.Debug.WriteLine($"[AuthService] Content-Type: {content.Headers.ContentType}");

                var response = await _sharedHttpClient.PostAsync($"{_baseUrl}/auth/token", content);
                var responseContent = await response.Content.ReadAsStringAsync();

                System.Diagnostics.Debug.WriteLine($"[AuthService] Response Status: {response.StatusCode}");
                System.Diagnostics.Debug.WriteLine($"[AuthService] Response Body: {responseContent}");

                if (!response.IsSuccessStatusCode)
                {
                    // Mostrar erro detalhado
                    string errorDetail = $"HTTP {response.StatusCode}";
                    try
                    {
                        // Tentar extrair mensagem de erro da API
                        var errorMatch = Regex.Match(responseContent, @"""detail"":\s*""?([^"",}]+)""?");
                        if (errorMatch.Success)
                            errorDetail += $": {errorMatch.Groups[1].Value}";
                        else if (!string.IsNullOrEmpty(responseContent))
                            errorDetail += $": {responseContent}";
                    }
                    catch { }

                    throw new Exception($"Erro na autenticação: {errorDetail}");
                }

                // Extrair o access_token da resposta JSON
                var token = ExtractToken(responseContent);
                if (string.IsNullOrEmpty(token))
                    throw new Exception($"Token não encontrado na resposta da API: {responseContent}");

                return token;
            }
            catch (HttpRequestException ex)
            {
                throw new Exception($"Erro de conexão com a API em {_baseUrl}: {ex.Message}", ex);
            }
            catch (TaskCanceledException ex)
            {
                throw new Exception($"Timeout ao conectar na API em {_baseUrl}: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Extrai o token JWT da resposta JSON usando múltiplas estratégias
        /// </summary>
        private string ExtractToken(string jsonResponse)
        {
            if (string.IsNullOrWhiteSpace(jsonResponse))
                return null;

            try
            {
                // Estratégia 1: Regex (mais robusto)
                var regex = new Regex(@"""access_token""\s*:\s*""([^""]+)""");
                var match = regex.Match(jsonResponse);
                if (match.Success && match.Groups.Count > 1)
                {
                    var token = match.Groups[1].Value;
                    if (!string.IsNullOrEmpty(token))
                    {
                        System.Diagnostics.Debug.WriteLine($"[AuthService] Token extraído (Regex): {token.Substring(0, 20)}...");
                        return token;
                    }
                }

                // Estratégia 2: IndexOf (fallback mais simples)
                var startIndex = jsonResponse.IndexOf("\"access_token\"");
                if (startIndex >= 0)
                {
                    startIndex = jsonResponse.IndexOf("\"", startIndex + 16) + 1;
                    if (startIndex > 0)
                    {
                        var endIndex = jsonResponse.IndexOf("\"", startIndex);
                        if (endIndex > startIndex)
                        {
                            var token = jsonResponse.Substring(startIndex, endIndex - startIndex);
                            if (!string.IsNullOrEmpty(token))
                            {
                                System.Diagnostics.Debug.WriteLine($"[AuthService] Token extraído (IndexOf): {token.Substring(0, 20)}...");
                                return token;
                            }
                        }
                    }
                }

                return null;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[AuthService] Erro ao extrair token: {ex.Message}");
                return null;
            }
        }
    }
}
