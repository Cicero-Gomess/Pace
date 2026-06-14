using System;

namespace sistemaadmin.Models
{
    /// <summary>
    /// DTO para representação de Usuário da API
    /// </summary>
    public class UsuarioDTO
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Email { get; set; }
        public string FotoPerfil { get; set; }
    }

    /// <summary>
    /// DTO para representação de Post da API
    /// </summary>
    public class PostDTO
    {
        public int Id { get; set; }
        public string Conteudo { get; set; }
        public string Imagem { get; set; }
        public string DataPostagem { get; set; }
        public int Likes { get; set; }
        public bool Liked { get; set; }
        public UsuarioDTO Usuario { get; set; }
    }
}
