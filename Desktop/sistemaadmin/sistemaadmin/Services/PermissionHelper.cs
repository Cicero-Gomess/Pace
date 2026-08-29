using System;
using System.Text.RegularExpressions;

namespace sistemaadmin.Services
{
    /// <summary>
    /// Classe auxiliar para gerenciar permissões e roles do usuário
    /// Extrai informações do token JWT ou de dados do usuário
    /// </summary>
    public class PermissionHelper
    {
        /// <summary>
        /// Verifica se um usuário é administrador
        /// Tenta extrair o campo "admin" do token JWT ou dos dados do usuário
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

                System.Diagnostics.Debug.WriteLine("[PermissionHelper] Usuário não é admin");
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
