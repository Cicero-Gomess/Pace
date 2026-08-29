using System;

namespace sistemaadmin.Models
{
    /// <summary>
    /// DTO para representação de Meta (Goal) da API
    /// </summary>
    public class MetaDTO
    {
        public int Id { get; set; }
        public int IdUsuario { get; set; }
        public string Titulo { get; set; }
        public DateTime? Prazo { get; set; }
        public string Categoria { get; set; }
        public string Descricao { get; set; }
        public string Status { get; set; }

        /// <summary>
        /// Retorna string formatada da meta para exibição
        /// </summary>
        public override string ToString()
        {
            return $"{Titulo} - {Status}";
        }
    }

    /// <summary>
    /// DTO para criação de Meta
    /// </summary>
    public class MetaCreateDTO
    {
        public string Titulo { get; set; }
        public DateTime? Prazo { get; set; }
        public string Categoria { get; set; }
        public string Descricao { get; set; }
    }

    /// <summary>
    /// DTO para atualização de Meta
    /// </summary>
    public class MetaUpdateDTO
    {
        public string Titulo { get; set; }
        public DateTime? Prazo { get; set; }
        public string Categoria { get; set; }
        public string Descricao { get; set; }
        public string Status { get; set; }
    }
}
