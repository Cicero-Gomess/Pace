using System;
using System.Net.Http;
using System.Text;
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

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao obter perfil: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Altera a foto de perfil do usuário
        /// </summary>
        public async Task<string> TrocarFotoAsync(string fotoBase64)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(fotoBase64))
                    throw new ArgumentException("Foto não pode estar vazia.", nameof(fotoBase64));

                string json = $"{{\"foto_perfil\": \"{EscapeJson(fotoBase64)}\"}}";
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await HttpClient.PostAsync("/profile/trocar_foto", content);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao trocar foto: {ex.Message}", ex);
            }
        }
    }
}
