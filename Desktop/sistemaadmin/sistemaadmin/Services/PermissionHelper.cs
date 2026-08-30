using System;
using System.Text.RegularExpressions;

namespace sistemaadmin.Services
{
    /// <summary>
    /// Classe auxiliar para gerenciar permissões e roles do usuário
    /// 
    /// NOTA CRÍTICA (30/08/2026):
    /// O contrato atual da API (Backend) NÃO fornece informações de permissões via JWT ou /profile/me.
    /// O campo "admin" não está incluído no token JWT retornado por /auth/token.
    /// O endpoint /profile/me também não retorna o campo "admin".
    /// 
    /// Consequência: As verificações de permissão abaixo NÃO funcionarão até que o Backend
    /// seja atualizado para incluir essas informações.
    /// 
    /// Para futuro: Quando o Backend adicionar suporte, o PermissionHelper será automaticamente
    /// compatível, desde que o token JWT inclua campos como:
    ///   - "admin": true/false
    ///   - "role": "admin" ou "moderator"
    ///   - ou outro campo de permissão definido pela API
    /// 
    /// Para agora: Use IsPermissionDataAvailable() para verificar se as permissões estão disponíveis
    /// antes de usar IsAdmin(). Trate a falta de permissões como "acesso negado" por segurança.
    /// </summary>
    public class PermissionHelper
    {
        /// <summary>
        /// Verifica se as informações de permissão estão disponíveis no token
        /// Esta é uma verificação de "sanidade" para saber se o Backend fornece o suporte
        /// </summary>
        public static bool IsPermissionDataAvailable(string token)
        {
            if (string.IsNullOrWhiteSpace(token))
            {
                System.Diagnostics.Debug.WriteLine("[PermissionHelper] Token vazio - permissões não disponíveis");
                return false;
            }

            try
            {
                var parts = token.Split('.');
                if (parts.Length < 2)
                {
                    System.Diagnostics.Debug.WriteLine("[PermissionHelper] Token JWT inválido");
                    return false;
                }

                string payload = parts[1];
                while (payload.Length % 4 != 0)
                    payload += "=";

                byte[] base64Bytes;
                try
                {
                    base64Bytes = Convert.FromBase64String(payload);
                }
                catch
                {
                    System.Diagnostics.Debug.WriteLine("[PermissionHelper] Falha ao decodificar Base64");
                    return false;
                }

                string payloadJson = System.Text.Encoding.UTF8.GetString(base64Bytes);
                System.Diagnostics.Debug.WriteLine($"[PermissionHelper] Payload JWT: {payloadJson}");

                // Verificar se contém qualquer campo de permissão
                bool hasAdminField = Regex.IsMatch(payloadJson, @"""admin""", RegexOptions.IgnoreCase);
                bool hasRoleField = Regex.IsMatch(payloadJson, @"""(?:rol|role)""", RegexOptions.IgnoreCase);
                bool hasModField = Regex.IsMatch(payloadJson, @"""(?:mod|moderator)""", RegexOptions.IgnoreCase);

                bool available = hasAdminField || hasRoleField || hasModField;
                System.Diagnostics.Debug.WriteLine($"[PermissionHelper] Dados de permissão disponíveis: {available}");
                return available;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[PermissionHelper] Erro ao verificar disponibilidade de permissões: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Verifica se um usuário é administrador
        /// Tenta extrair o campo "admin" do token JWT ou dos dados do usuário
        /// 
        /// ATENÇÃO: Esta função retornará FALSE se o Backend não fornecer essas informações.
        /// Use IsPermissionDataAvailable() primeiro para saber se as permissões estão disponíveis.
        /// </summary>
        public static bool IsAdmin(string token)
        {
            if (string.IsNullOrWhiteSpace(token))
                return false;

            try
            {
                // JWT típico tem formato: header.payload.signature
                var parts = token.Split('.');
                if (parts.Length < 2)
                    return false;

                // O payload é Base64URL
                string payload = parts[1];

                // Adicionar padding se necessário
                while (payload.Length % 4 != 0)
                    payload += "=";

                // Decodificar Base64
                byte[] base64Bytes;
                try
                {
                    base64Bytes = Convert.FromBase64String(payload);
                }
                catch
                {
                    return false;
                }

                string payloadJson = System.Text.Encoding.UTF8.GetString(base64Bytes);
                System.Diagnostics.Debug.WriteLine($"[PermissionHelper] Payload JWT: {payloadJson}");

                // Procurar por campo "admin": true
                // Pode estar em formato: "admin": true ou "admin":true
                var adminMatch = Regex.Match(payloadJson, @"""admin""?\s*:\s*true", RegexOptions.IgnoreCase);
                if (adminMatch.Success)
                {
                    System.Diagnostics.Debug.WriteLine("[PermissionHelper] Usuário é admin");
                    return true;
                }

                // Também verificar campo "rol" ou "role" para "admin"
                var roleMatch = Regex.Match(payloadJson, @"""(?:rol|role)""?\s*:\s*""admin""", RegexOptions.IgnoreCase);
                if (roleMatch.Success)
                {
                    System.Diagnostics.Debug.WriteLine("[PermissionHelper] Usuário tem role admin");
                    return true;
                }

                System.Diagnostics.Debug.WriteLine("[PermissionHelper] Usuário não é admin (ou dados não disponíveis)");
                return false;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[PermissionHelper] Erro ao verificar permissões: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Verifica se um usuário é moderador
        /// 
        /// ATENÇÃO: Esta função retornará FALSE se o Backend não fornecer essas informações.
        /// O contrato atual da API não inclui informações de moderador.
        /// </summary>
        public static bool IsModerator(string token)
        {
            if (string.IsNullOrWhiteSpace(token))
                return false;

            try
            {
                var parts = token.Split('.');
                if (parts.Length < 2)
                    return false;

                string payload = parts[1];
                while (payload.Length % 4 != 0)
                    payload += "=";

                byte[] base64Bytes;
                try
                {
                    base64Bytes = Convert.FromBase64String(payload);
                }
                catch
                {
                    return false;
                }

                string payloadJson = System.Text.Encoding.UTF8.GetString(base64Bytes);

                // Verificar permissão moderador
                var modMatch = Regex.Match(payloadJson, @"""(?:mod|moderator)""?\s*:\s*true", RegexOptions.IgnoreCase);
                if (modMatch.Success)
                    return true;

                // Verificar role moderator
                var roleMatch = Regex.Match(payloadJson, @"""(?:rol|role)""?\s*:\s*""moderator?""", RegexOptions.IgnoreCase);
                return roleMatch.Success;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[PermissionHelper] Erro ao verificar moderador: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Verifica se um usuário tem permissão específica
        /// 
        /// ATENÇÃO: Esta função retornará FALSE se o Backend não fornecer essas informações.
        /// O contrato atual da API não inclui campos de permissão genérica.
        /// </summary>
        public static bool HasPermission(string token, string permission)
        {
            if (string.IsNullOrWhiteSpace(token) || string.IsNullOrWhiteSpace(permission))
                return false;

            try
            {
                var parts = token.Split('.');
                if (parts.Length < 2)
                    return false;

                string payload = parts[1];
                while (payload.Length % 4 != 0)
                    payload += "=";

                byte[] base64Bytes;
                try
                {
                    base64Bytes = Convert.FromBase64String(payload);
                }
                catch
                {
                    return false;
                }

                string payloadJson = System.Text.Encoding.UTF8.GetString(base64Bytes);

                // Procurar pela permissão específica (booleana)
                var permMatch = Regex.Match(payloadJson, $@"""{permission}""?\s*:\s*true", RegexOptions.IgnoreCase);
                return permMatch.Success;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[PermissionHelper] Erro ao verificar permissão '{permission}': {ex.Message}");
                return false;
            }
        }
    }
}
