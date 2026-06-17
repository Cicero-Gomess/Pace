using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
    public class PostService : BaseService
    {
        public PostService(string token) : base(token)
        {
        }

        /// <summary>
        /// Obtém o feed de posts
        /// </summary>
        public async Task<string> GetFeedAsync()
        {
            try
            {
                System.Diagnostics.Debug.WriteLine("[PostService] Requisitando GET /post/feed");

                var response = await HttpClient.GetAsync("/post/feed").ConfigureAwait(false);

                System.Diagnostics.Debug.WriteLine($"[PostService] Response Status: {response.StatusCode}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                    System.Diagnostics.Debug.WriteLine($"[PostService] Erro: {response.StatusCode} - {errorContent}");
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                var content = await response.Content.ReadAsStringAsync().ConfigureAwait(false);
                System.Diagnostics.Debug.WriteLine($"[PostService] Feed obtido com sucesso ({content.Length} bytes)");
                return content;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[PostService] Exception: {ex.Message}");
                throw new Exception($"Erro ao obter feed: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Cria um novo post
        /// </summary>
        public async Task<string> CriarPostAsync(string conteudo, string imagem = null)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(conteudo))
                    throw new ArgumentException("Conteúdo não pode estar vazio.", nameof(conteudo));

                string json;
                if (string.IsNullOrEmpty(imagem))
                {
                    json = $"{{\"conteudo\": \"{EscapeJson(conteudo)}\"}}";
                }
                else
                {
                    json = $"{{\"conteudo\": \"{EscapeJson(conteudo)}\", \"imagem\": \"{EscapeJson(imagem)}\"}}";
                }

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await HttpClient.PostAsync("/post/criar_post", content);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao criar post: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Atualiza um post existente
        /// </summary>
        public async Task<string> AtualizarPostAsync(int id, string conteudo, string imagem = null)
        {
            try
            {
                if (id <= 0)
                    throw new ArgumentException("ID do post inválido.", nameof(id));

                if (string.IsNullOrWhiteSpace(conteudo))
                    throw new ArgumentException("Conteúdo não pode estar vazio.", nameof(conteudo));

                string json;
                if (string.IsNullOrEmpty(imagem))
                {
                    json = $"{{\"conteudo\": \"{EscapeJson(conteudo)}\"}}";
                }
                else
                {
                    json = $"{{\"conteudo\": \"{EscapeJson(conteudo)}\", \"imagem\": \"{EscapeJson(imagem)}\"}}";
                }

                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await HttpClient.PutAsync($"/post/atualizar_post/{id}", content);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao atualizar post: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Deleta um post
        /// </summary>
        public async Task<bool> DeletarPostAsync(int id)
        {
            try
            {
                if (id <= 0)
                    throw new ArgumentException("ID do post inválido.", nameof(id));

                var response = await HttpClient.DeleteAsync($"/post/deletar/{id}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return true;
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao deletar post: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Curte um post
        /// </summary>
        public async Task<string> CurtirPostAsync(int postId)
        {
            try
            {
                if (postId <= 0)
                    throw new ArgumentException("ID do post inválido.", nameof(postId));

                // CORREÇÃO CRÍTICA: PostAsync não aceita null content
                // Enviar StringContent vazio em vez de null
                var emptyContent = new StringContent(string.Empty, Encoding.UTF8, "application/json");
                var response = await HttpClient.PostAsync($"/post/curtir/{postId}", emptyContent);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao curtir post: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Remove curtida de um post
        /// </summary>
        public async Task<string> RemoverCurtidaAsync(int postId)
        {
            try
            {
                if (postId <= 0)
                    throw new ArgumentException("ID do post inválido.", nameof(postId));

                var response = await HttpClient.DeleteAsync($"/post/remover_curtida/{postId}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao remover curtida: {ex.Message}", ex);
            }
        }
    }
}
