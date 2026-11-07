using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
    public class ComunidadeService : BaseService
    {
        public ComunidadeService(string token) : base(token)
        {
        }

        /// <summary>
        /// Obtém a lista de todas as comunidades
        /// </summary>
        public async Task<string> GetAllAsync()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("[ComunidadeService] Requisitando GET /comunidades");

                var response = await HttpClient.GetAsync("/comunidades").ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Comunidades obtidas com sucesso ({content.Length} bytes)");
                return content;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Exception: {ex.Message}");
                throw new Exception($"Erro ao obter comunidades: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Obtém os detalhes de uma comunidade específica
        /// </summary>
        public async Task<string> GetByIdAsync(int comunidadeId)
        {
            try
            {
                if (comunidadeId <= 0)
                    throw new ArgumentException("ID da comunidade inválido.", nameof(comunidadeId));

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Requisitando GET /comunidades/{comunidadeId}");

                var response = await HttpClient.GetAsync($"/comunidades/{comunidadeId}").ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Comunidade obtida com sucesso");
                return content;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Exception: {ex.Message}");
                throw new Exception($"Erro ao obter comunidade: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Atualiza uma comunidade existente (requer permissões de admin)
        /// </summary>
        public async Task<string> UpdateAsync(int comunidadeId, string nome = null, string descricao = null, string topicos = null, string privacidade = null)
        {
            try
            {
                if (comunidadeId <= 0)
                    throw new ArgumentException("ID da comunidade inválido.", nameof(comunidadeId));

                string json = "{";
                bool primeiro = true;

                if (!string.IsNullOrEmpty(nome))
                {
                    if (!primeiro) json += ", ";
                    json += $"\"nome\": \"{EscapeJson(nome)}\"";
                    primeiro = false;
                }

                if (!string.IsNullOrEmpty(descricao))
                {
                    if (!primeiro) json += ", ";
                    json += $"\"descricao\": \"{EscapeJson(descricao)}\"";
                    primeiro = false;
                }

                if (!string.IsNullOrEmpty(topicos))
                {
                    if (!primeiro) json += ", ";
                    json += $"\"topicos\": {topicos}";
                    primeiro = false;
                }

                if (!string.IsNullOrEmpty(privacidade))
                {
                    if (!primeiro) json += ", ";
                    json += $"\"privacidade\": \"{EscapeJson(privacidade)}\"";
                    primeiro = false;
                }

                json += "}";

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Requisitando PUT /comunidades/{comunidadeId}");

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await HttpClient.PutAsync($"/comunidades/{comunidadeId}", content).ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var responseContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Comunidade atualizada com sucesso");
                return responseContent;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Exception: {ex.Message}");
                throw new Exception($"Erro ao atualizar comunidade: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Exclui uma comunidade (requer permissões de admin)
        /// </summary>
        public async Task<string> DeleteAsync(int comunidadeId)
        {
            try
            {
                if (comunidadeId <= 0)
                    throw new ArgumentException("ID da comunidade inválido.", nameof(comunidadeId));

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Requisitando DELETE /comunidades/{comunidadeId}");

                var response = await HttpClient.DeleteAsync($"/comunidades/{comunidadeId}").ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Comunidade excluída com sucesso");
                return content;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Exception: {ex.Message}");
                throw new Exception($"Erro ao excluir comunidade: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Obtém a lista de membros de uma comunidade (requer permissões de admin)
        /// </summary>
        public async Task<string> GetMembersAsync(int comunidadeId)
        {
            try
            {
                if (comunidadeId <= 0)
                    throw new ArgumentException("ID da comunidade inválido.", nameof(comunidadeId));

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Requisitando GET /comunidades/{comunidadeId}/membros");

                var response = await HttpClient.GetAsync($"/comunidades/{comunidadeId}/membros").ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Membros obtidos com sucesso ({content.Length} bytes)");
                return content;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Exception: {ex.Message}");
                throw new Exception($"Erro ao obter membros: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Remove um membro de uma comunidade (requer permissões de admin)
        /// </summary>
        public async Task<string> RemoveMemberAsync(int comunidadeId, int usuarioId)
        {
            try
            {
                if (comunidadeId <= 0)
                    throw new ArgumentException("ID da comunidade inválido.", nameof(comunidadeId));

                if (usuarioId <= 0)
                    throw new ArgumentException("ID do usuário inválido.", nameof(usuarioId));

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Requisitando DELETE /comunidades/{comunidadeId}/membros/{usuarioId}");

                var response = await HttpClient.DeleteAsync($"/comunidades/{comunidadeId}/membros/{usuarioId}").ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Membro removido com sucesso");
                return content;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[ComunidadeService] Exception: {ex.Message}");
                throw new Exception($"Erro ao remover membro: {ex.Message}", ex);
            }
        }
    }
}
