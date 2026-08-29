using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using sistemaadmin.Models;

namespace sistemaadmin.Services
{
    public class MetaService : BaseService
    {
        public MetaService(string token) : base(token)
        {
        }

        /// <summary>
        /// Lista todas as metas do usuário autenticado
        /// GET /metas/listar_metas
        /// </summary>
        public async Task<string> ListarMetasAsync()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("[MetaService] Requisitando GET /metas/listar_metas");

                var response = await HttpClient.GetAsync("/metas/listar_metas").ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[MetaService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[MetaService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[MetaService] Metas obtidas com sucesso ({content.Length} bytes)");
                return content;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[MetaService] Exception: {ex.Message}");
                throw new Exception($"Erro ao listar metas: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Busca uma meta específica por ID
        /// GET /metas/buscar_meta_id/{meta_id}
        /// </summary>
        public async Task<string> BuscarMetaAsync(int metaId)
        {
            try
            {
                if (metaId <= 0)
                    throw new ArgumentException("ID da meta inválido.", nameof(metaId));

                System.Diagnostics.Debug.WriteLine($"[MetaService] Requisitando GET /metas/buscar_meta_id/{metaId}");

                var response = await HttpClient.GetAsync($"/metas/buscar_meta_id/{metaId}").ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[MetaService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[MetaService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[MetaService] Meta obtida com sucesso");
                return content;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[MetaService] Exception: {ex.Message}");
                throw new Exception($"Erro ao buscar meta: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Cria uma nova meta
        /// POST /metas/criar_meta
        /// </summary>
        public async Task<string> CriarMetaAsync(string titulo, string categoria, string descricao = null, DateTime? prazo = null)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(titulo))
                    throw new ArgumentException("Título não pode estar vazio.", nameof(titulo));

                if (string.IsNullOrWhiteSpace(categoria))
                    throw new ArgumentException("Categoria não pode estar vazia.", nameof(categoria));

                // Construir JSON manualmente para evitar problemas de serialização
                string prazoJson = prazo.HasValue 
                    ? $"\"{prazo:yyyy-MM-dd}\"" 
                    : "null";

                string json = $"{{\"titulo\": \"{EscapeJson(titulo)}\", " +
                             $"\"categoria\": \"{EscapeJson(categoria)}\", " +
                             $"\"descricao\": \"{EscapeJson(descricao ?? "")}\", " +
                             $"\"prazo\": {prazoJson}}}";

                System.Diagnostics.Debug.WriteLine($"[MetaService] Requisitando POST /metas/criar_meta");
                System.Diagnostics.Debug.WriteLine($"[MetaService] JSON: {json}");

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await HttpClient.PostAsync("/metas/criar_meta", content).ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[MetaService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[MetaService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var responseContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[MetaService] Meta criada com sucesso");
                return responseContent;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[MetaService] Exception: {ex.Message}");
                throw new Exception($"Erro ao criar meta: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Atualiza uma meta existente
        /// PUT /metas/atualizar_meta/{meta_id}
        /// </summary>
        public async Task<string> AtualizarMetaAsync(int metaId, string titulo = null, string categoria = null, 
                                                     string descricao = null, DateTime? prazo = null, string status = null)
        {
            try
            {
                if (metaId <= 0)
                    throw new ArgumentException("ID da meta inválido.", nameof(metaId));

                // Construir JSON apenas com os campos fornecidos
                var jsonParts = new List<string>();

                if (!string.IsNullOrWhiteSpace(titulo))
                    jsonParts.Add($"\"titulo\": \"{EscapeJson(titulo)}\"");

                if (!string.IsNullOrWhiteSpace(categoria))
                    jsonParts.Add($"\"categoria\": \"{EscapeJson(categoria)}\"");

                if (descricao != null)
                    jsonParts.Add($"\"descricao\": \"{EscapeJson(descricao)}\"");

                if (prazo.HasValue)
                    jsonParts.Add($"\"prazo\": \"{prazo:yyyy-MM-dd}\"");

                if (!string.IsNullOrWhiteSpace(status))
                    jsonParts.Add($"\"status\": \"{EscapeJson(status)}\"");

                if (jsonParts.Count == 0)
                    throw new ArgumentException("Pelo menos um campo deve ser fornecido para atualização.");

                string json = "{" + string.Join(", ", jsonParts) + "}";

                System.Diagnostics.Debug.WriteLine($"[MetaService] Requisitando PUT /metas/atualizar_meta/{metaId}");
                System.Diagnostics.Debug.WriteLine($"[MetaService] JSON: {json}");

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await HttpClient.PutAsync($"/metas/atualizar_meta/{metaId}", content).ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[MetaService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[MetaService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var responseContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[MetaService] Meta atualizada com sucesso");
                return responseContent;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[MetaService] Exception: {ex.Message}");
                throw new Exception($"Erro ao atualizar meta: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Deleta uma meta
        /// DELETE /metas/deletar_meta/{meta_id}
        /// </summary>
        public async Task<bool> DeletarMetaAsync(int metaId)
        {
            try
            {
                if (metaId <= 0)
                    throw new ArgumentException("ID da meta inválido.", nameof(metaId));

                System.Diagnostics.Debug.WriteLine($"[MetaService] Requisitando DELETE /metas/deletar_meta/{metaId}");

                var response = await HttpClient.DeleteAsync($"/metas/deletar_meta/{metaId}").ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[MetaService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[MetaService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                System.Diagnostics.Debug.WriteLine($"[MetaService] Meta deletada com sucesso");
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[MetaService] Exception: {ex.Message}");
                throw new Exception($"Erro ao deletar meta: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Remove escape de caracteres JSON
        /// </summary>
        public string UnescapeJson(string text)
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
