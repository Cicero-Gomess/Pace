using System;
using System.Net.Http;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
    /// <summary>
    /// Serviço para gerenciar perfil do usuário.
    /// Consumindo endpoints: GET /profile/me, POST /profile/trocar_foto
    /// </summary>
    public class ProfileService : BaseService
    {
        public ProfileService(string token) : base(token)
        {
        }

        /// <summary>
        /// Obtém dados do perfil do usuário autenticado
        /// </summary>
        public async Task<string> GetMeAsync()
        {
            try
            {
                var response = await HttpClient.GetAsync("/profile/me");
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao obter perfil: {ex.Message}");
            }
        }

        /// <summary>
        /// Altera a foto de perfil do usuário
        /// </summary>
        public async Task<string> TrocarFotoAsync(string fotoBase64)
        {
            try
            {
                if (string.IsNullOrEmpty(fotoBase64))
                    throw new Exception("Foto não pode estar vazia.");

                string json = $"{{\"foto_perfil\": \"{EscapeJson(fotoBase64)}\"}}";
                var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

                var response = await HttpClient.PostAsync("/profile/trocar_foto", content);
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao trocar foto: {ex.Message}");
            }
        }

        /// <summary>
        /// Escapa caracteres especiais para JSON
        /// </summary>
        private string EscapeJson(string text)
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
