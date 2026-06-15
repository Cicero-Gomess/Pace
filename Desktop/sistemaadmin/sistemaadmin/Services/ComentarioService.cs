using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace sistemaadmin.Services
{
    public class ComentarioService : BaseService
    {
        public ComentarioService(string token) : base(token)
        {
        }

        /// <summary>
        /// Lista todos os comentários de um post
        /// </summary>
        public async Task<string> ListarComentariosAsync(int postId)
        {
            try
            {
                if (postId <= 0)
                    throw new ArgumentException("ID do post inválido.", nameof(postId));

                var response = await HttpClient.GetAsync($"/comments/comentarios/{postId}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao listar comentários: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Adiciona um novo comentário a um post
        /// </summary>
        public async Task<string> AdicionarComentarioAsync(int postId, string conteudo)
        {
            try
            {
                if (postId <= 0)
                    throw new ArgumentException("ID do post inválido.", nameof(postId));

                if (string.IsNullOrWhiteSpace(conteudo))
                    throw new ArgumentException("Conteúdo não pode estar vazio.", nameof(conteudo));

                string json = $"{{\"conteudo\": \"{EscapeJson(conteudo)}\"}}";
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await HttpClient.PostAsync($"/comments/adicionar_comentario/{postId}", content);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao adicionar comentário: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Atualiza um comentário existente
        /// </summary>
        public async Task<string> AtualizarComentarioAsync(int comentarioId, string conteudo)
        {
            try
            {
                if (comentarioId <= 0)
                    throw new ArgumentException("ID do comentário inválido.", nameof(comentarioId));

                if (string.IsNullOrWhiteSpace(conteudo))
                    throw new ArgumentException("Conteúdo não pode estar vazio.", nameof(conteudo));

                string json = $"{{\"conteudo\": \"{EscapeJson(conteudo)}\"}}";
                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await HttpClient.PutAsync($"/comments/atualizar_comentario/{comentarioId}", content);

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao atualizar comentário: {ex.Message}", ex);
            }
        }

        /// <summary>
        /// Deleta um comentário
        /// </summary>
        public async Task<bool> DeletarComentarioAsync(int comentarioId)
        {
            try
            {
                if (comentarioId <= 0)
                    throw new ArgumentException("ID do comentário inválido.", nameof(comentarioId));

                var response = await HttpClient.DeleteAsync($"/comments/deletar_comentario/{comentarioId}");

                if (!response.IsSuccessStatusCode)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    throw new Exception($"HTTP {response.StatusCode}: {errorContent}");
                }

                return true;
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao deletar comentário: {ex.Message}", ex);
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
