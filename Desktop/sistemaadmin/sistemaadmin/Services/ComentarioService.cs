using System;
using System.Collections.Generic;
using System.Net.Http;
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
                var response = await HttpClient.GetAsync($"/comments/comentarios/{postId}");
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao listar comentários: {ex.Message}");
            }
        }

        /// <summary>
        /// Adiciona um novo comentário a um post
        /// </summary>
        public async Task<string> AdicionarComentarioAsync(int postId, string conteudo)
        {
            try
            {
                string json = $"{{\"conteudo\": \"{EscapeJson(conteudo)}\"}}";
                var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

                var response = await HttpClient.PostAsync($"/comments/adicionar_comentario/{postId}", content);
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao adicionar comentário: {ex.Message}");
            }
        }

        /// <summary>
        /// Atualiza um comentário existente
        /// </summary>
        public async Task<string> AtualizarComentarioAsync(int comentarioId, string conteudo)
        {
            try
            {
                string json = $"{{\"conteudo\": \"{EscapeJson(conteudo)}\"}}";
                var content = new StringContent(json, System.Text.Encoding.UTF8, "application/json");

                var response = await HttpClient.PutAsync($"/comments/atualizar_comentario/{comentarioId}", content);
                response.EnsureSuccessStatusCode();
                return await response.Content.ReadAsStringAsync();
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao atualizar comentário: {ex.Message}");
            }
        }

        /// <summary>
        /// Deleta um comentário
        /// </summary>
        public async Task<bool> DeletarComentarioAsync(int comentarioId)
        {
            try
            {
                var response = await HttpClient.DeleteAsync($"/comments/deletar_comentario/{comentarioId}");
                response.EnsureSuccessStatusCode();
                return true;
            }
            catch (Exception ex)
            {
                throw new Exception($"Erro ao deletar comentário: {ex.Message}");
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
