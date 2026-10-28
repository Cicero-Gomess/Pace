import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'theme_controller.dart';

const Color _primary = Color(0xFF1769E8);
const Color _accent = Color(0xFFFFC928);
const Color _danger = Color(0xFFD9534F);
const String _apiUrl = 'http://127.0.0.1:8000';

class ConfigPage extends StatefulWidget {
  final ThemeController themeController;

  const ConfigPage({
    super.key,
    required this.themeController,
  });

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController senhaAtualController = TextEditingController();
  final TextEditingController novaSenhaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();

  bool isLoadingUser = true;
  bool isSavingPassword = false;
  bool sidebarHovered = false;
  String? sidebarItemHovered;

  bool showCurrentPassword = false;
  bool showNewPassword = false;
  bool showConfirmPassword = false;

  Map<String, dynamic> usuarioLogado = {};

  bool get darkMode => widget.themeController.darkMode;

  Color get bg =>
      darkMode ? const Color(0xFF06101F) : const Color(0xFFEAF3FB);

  Color get text =>
      darkMode ? const Color(0xFFF2F6FF) : const Color(0xFF06152D);

  Color get muted =>
      darkMode ? const Color(0xFF98A8BF) : const Color(0xFF61758F);

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  @override
  void dispose() {
    senhaAtualController.dispose();
    novaSenhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access_token');
  }

  Future<void> _initUser() async {
    final token = await _getToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/entrar');
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiUrl/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/entrar');
        }
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          usuarioLogado = decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : {};
          isLoadingUser = false;
        });
      } else {
        if (!mounted) return;
        setState(() => isLoadingUser = false);
        _showToast(
          'Não foi possível carregar seu perfil.',
          error: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingUser = false);
      _showToast(
        'Não foi possível carregar seu perfil.',
        error: true,
      );
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    await widget.themeController.setDarkMode(value);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.64),
      builder: (context) {
        final dark =
            Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF0F1B2F)
                    : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: _danger,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Sair da conta?',
                    style: TextStyle(
                      color: dark
                          ? Colors.white
                          : const Color(0xFF06152D),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Você precisará entrar novamente para acessar o Pace.',
                    style: TextStyle(
                      color: dark
                          ? const Color(0xFF98A8BF)
                          : const Color(0xFF61758F),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _danger,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text('Sair da conta'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('access_token');
    await prefs.remove('usuarioLogado');

    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/entrar', (_) => false);
  }

  Future<void> _alterarSenha() async {
    final senhaAtual = senhaAtualController.text.trim();
    final novaSenha = novaSenhaController.text.trim();
    final confirmarSenha = confirmarSenhaController.text.trim();
    final token = await _getToken();

    if (senhaAtual.isEmpty ||
        novaSenha.isEmpty ||
        confirmarSenha.isEmpty) {
      _showToast(
        'Preencha todos os campos antes de continuar.',
        error: true,
      );
      return;
    }

    if (novaSenha.length < 6) {
      _showToast(
        'A nova senha deve ter pelo menos 6 caracteres.',
        error: true,
      );
      return;
    }

    if (novaSenha != confirmarSenha) {
      _showToast(
        'A confirmação da nova senha não confere.',
        error: true,
      );
      return;
    }

    if (token == null || token.isEmpty) {
      _showToast(
        'Sua sessão expirou. Faça login novamente.',
        error: true,
      );
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/entrar');
      }
      return;
    }

    setState(() => isSavingPassword = true);

    try {
      final response = await http.put(
        Uri.parse('$_apiUrl/auth/atualizar_senha'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'senha_atual': senhaAtual,
          'nova_senha': novaSenha,
        }),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/entrar');
        }
        return;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final message =
            data is Map && data['detail'] != null
                ? data['detail'].toString()
                : 'Erro ao atualizar a senha.';

        throw Exception(message);
      }

      senhaAtualController.clear();
      novaSenhaController.clear();
      confirmarSenhaController.clear();

      _showToast(
        data is Map && data['message'] != null
            ? data['message'].toString()
            : 'Senha atualizada com sucesso!',
      );
    } catch (error) {
      _showToast(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => isSavingPassword = false);
      }
    }
  }

  String get _username {
    return (usuarioLogado['nome_usuario'] ??
            usuarioLogado['username'] ??
            usuarioLogado['nome'] ??
            'Usuário')
        .toString();
  }

  String get _email =>
      (usuarioLogado['email'] ?? '—').toString();

  String? get _photo {
    final raw = usuarioLogado['foto_perfil'] ??
        usuarioLogado['foto'] ??
        usuarioLogado['avatar'];

    if (raw == null || raw.toString().trim().isEmpty) {
      return null;
    }

    return raw.toString().trim();
  }

  ImageProvider _avatarProvider() {
    return ApiConfig.imageProvider(
      _photo,
      fallbackAsset: 'assets/user.png',
    );
  }

  void _showToast(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? _danger : const Color(0xFF21855F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 760;
    final tablet = width >= 760 && width < 1080;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: mobile ? _mobileDrawer() : null,
      body: Row(
        children: [
          if (!mobile) _sidebar(),
          Expanded(
            child: Column(
              children: [
                if (mobile) _mobileTopBar(),
                Expanded(
                  child: Stack(
                    children: [
                      _background(),
                      if (isLoadingUser)
                        const Center(
                          child: CircularProgressIndicator(
                            color: _primary,
                          ),
                        )
                      else
                        SingleChildScrollView(
                          physics:
                              const BouncingScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            mobile ? 18 : (tablet ? 28 : 38),
                            mobile ? 20 : 28,
                            mobile ? 18 : (tablet ? 28 : 38),
                            70,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(
                                maxWidth: 1120,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _hero(mobile),
                                  const SizedBox(height: 20),
                                  _contentGrid(
                                    mobile,
                                    tablet,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: darkMode
                  ? const [
                      Color(0xFF081426),
                      Color(0xFF06101F),
                      Color(0xFF040B15),
                    ]
                  : const [
                      Color(0xFFF4F8FD),
                      Color(0xFFEAF1F9),
                      Color(0xFFE4EDF8),
                    ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(bool mobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Divider(
                      thickness: 3,
                      color: _accent,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'CONTA',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'Configurações',
                style: TextStyle(
                  color: text,
                  fontSize: mobile ? 34 : 42,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Gerencie sua conta, aparência e sessão.',
                style: TextStyle(
                  color: muted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (!mobile)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xFF0F1B2F)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: darkMode
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFF06152D)
                        .withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: _primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conta e preferências',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _contentGrid(
    bool mobile,
    bool tablet,
  ) {
    final password = _passwordCard();
    final side = Column(
      children: [
        _appearanceCard(),
        const SizedBox(height: 12),
        _accountSummaryCard(),
        const SizedBox(height: 12),
        _sessionCard(),
      ],
    );

    if (mobile || tablet) {
      return Column(
        children: [
          password,
          const SizedBox(height: 12),
          side,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: password),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: side),
      ],
    );
  }

  Widget _passwordCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            'CONTA E SEGURANÇA',
            'Alterar senha',
            'Crie uma nova senha para manter sua conta protegida.',
            Icons.key_rounded,
          ),
          const SizedBox(height: 18),
          _passwordField(
            controller: senhaAtualController,
            label: 'Senha atual',
            hint: 'Digite sua senha atual',
            icon: Icons.lock_outline_rounded,
            obscure: !showCurrentPassword,
            onToggle: () => setState(
              () => showCurrentPassword =
                  !showCurrentPassword,
            ),
          ),
          const SizedBox(height: 13),
          _passwordField(
            controller: novaSenhaController,
            label: 'Nova senha',
            hint: 'Digite sua nova senha',
            icon: Icons.shield_outlined,
            obscure: !showNewPassword,
            onToggle: () => setState(
              () => showNewPassword = !showNewPassword,
            ),
          ),
          const SizedBox(height: 13),
          _passwordField(
            controller: confirmarSenhaController,
            label: 'Confirmar nova senha',
            hint: 'Confirme sua nova senha',
            icon: Icons.verified_outlined,
            obscure: !showConfirmPassword,
            onToggle: () => setState(
              () => showConfirmPassword =
                  !showConfirmPassword,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xFF0B1729)
                  : const Color(0xFFF7FBFF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: darkMode
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFF06152D)
                        .withOpacity(0.06),
              ),
            ),
            child: Column(
              children: [
                _guidance(
                  'Use uma senha difícil de adivinhar',
                ),
                const SizedBox(height: 7),
                _guidance(
                  'Use pelo menos 6 caracteres',
                ),
                const SizedBox(height: 7),
                _guidance(
                  'Evite reutilizar sua senha atual',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed:
                  isSavingPassword ? null : _alterarSenha,
              icon: isSavingPassword
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.save_outlined,
                      size: 18,
                    ),
              label: Text(
                isSavingPassword
                    ? 'Salvando...'
                    : 'Salvar alteração',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(
            color: text,
            fontSize: 12.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: muted,
              fontSize: 11.5,
            ),
            prefixIcon: Icon(
              icon,
              color: _primary,
              size: 18,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: muted,
                size: 18,
              ),
            ),
            filled: true,
            fillColor: darkMode
                ? const Color(0xFF0D2341)
                : const Color(0xFFF8FBFE),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: darkMode
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFF06152D)
                        .withOpacity(0.07),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _primary.withOpacity(0.44),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _guidance(String label) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 15,
          color: Color(0xFF2AA879),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _appearanceCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            'APARÊNCIA',
            'Visual do app',
            'Ajuste o Pace para ficar mais confortável no seu ambiente.',
            Icons.palette_outlined,
          ),
          const SizedBox(height: 15),
          _settingRow(
            icon: darkMode
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            title: 'Modo escuro',
            description:
                'Use uma interface mais confortável em ambientes com pouca luz.',
            trailing: Switch(
              value: darkMode,
              activeColor: _primary,
              onChanged: _toggleDarkMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountSummaryCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            'SUA CONTA',
            'Resumo',
            'Informações principais da conta conectada.',
            Icons.person_outline_rounded,
          ),
          const SizedBox(height: 14),
          _summaryItem(
            'Nome de usuário',
            '@$_username',
          ),
          const SizedBox(height: 8),
          _summaryItem(
            'E-mail',
            _email,
          ),
          const SizedBox(height: 8),
          _summaryItem(
            'Tema atual',
            darkMode ? 'Escuro' : 'Claro',
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(
    String label,
    String value,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0D2341)
            : const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFF06152D)
                  .withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: text,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            'SESSÃO',
            'Acesso',
            'Encerre a sessão atual com segurança.',
            Icons.verified_user_outlined,
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.08),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: _danger.withOpacity(0.13),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: _danger,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sair da conta',
                        style: TextStyle(
                          color: text,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Seu token local será removido.',
                        style: TextStyle(
                          color: muted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _logout,
                  style: TextButton.styleFrom(
                    foregroundColor: _danger,
                  ),
                  child: const Text(
                    'Sair',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String description,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0D2341)
            : const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFF06152D)
                  .withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: _primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: muted,
                    fontSize: 9.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _cardHeader(
    String kicker,
    String title,
    String description,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: const TextStyle(
                  color: _primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _primary,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _panel({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0F1B2F)
            : Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.055)
              : const Color(0xFF06152D)
                  .withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              darkMode ? 0.14 : 0.06,
            ),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sidebar() {
    const collapsed = 88.0;
    const expanded = 244.0;
    final width =
        sidebarHovered ? expanded : collapsed;

    return MouseRegion(
      onEnter: (_) =>
          setState(() => sidebarHovered = true),
      onExit: (_) => setState(() {
        sidebarHovered = false;
        sidebarItemHovered = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        padding:
            const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF06152D),
          border: Border(
            right: BorderSide(
              color: _primary.withOpacity(0.09),
            ),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showBrand =
                      constraints.maxWidth >= 150;

                  return Row(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 9),
                        child: Image.asset(
                          'assets/images/pace_icon.png',
                          width: 46,
                          height: 46,
                        ),
                      ),
                      if (showBrand) ...[
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pace',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Evolução contínua',
                                style: TextStyle(
                                  color:
                                      Color(0xFF8FA5C0),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Divider(
              color: _primary.withOpacity(0.10),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _sectionLabel('COMUNIDADE'),
                  _navItem(
                    Icons.home_rounded,
                    'Feed',
                    '/feed',
                  ),
                  _navItem(
                    Icons.explore_outlined,
                    'Explorar',
                    '/explorar',
                  ),
                  _navItem(
                    Icons.edit_square,
                    'Postar',
                    '/postar',
                  ),
                  const SizedBox(height: 8),
                  _sectionLabel('DESENVOLVIMENTO'),
                  _navItem(
                    Icons.track_changes_rounded,
                    'Metas',
                    '/metas',
                  ),
                  _navItem(
                    Icons.psychology_outlined,
                    'Sala de foco',
                    '/foco',
                  ),
                  _navItem(
                    Icons.trending_up_rounded,
                    'Evolução',
                    '/evolucao',
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.white.withOpacity(0.08),
            ),
            _navItem(
              Icons.settings_outlined,
              'Configurações',
              '/config',
              active: true,
            ),
            _profileItem(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final show = sidebarHovered &&
              constraints.maxWidth > 90;

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: show
                  ? Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF8FA5C0),
                        fontSize: 9.5,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    String route, {
    bool active = false,
  }) {
    final hovered =
        sidebarItemHovered == route;
    final highlighted = active || hovered;

    return MouseRegion(
      onEnter: (_) => setState(
        () => sidebarItemHovered = route,
      ),
      onExit: (_) {
        if (sidebarItemHovered == route) {
          setState(() => sidebarItemHovered = null);
        }
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!active) {
            Navigator.of(context).pushNamed(route);
          }
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 220),
          height: 50,
          margin:
              const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: highlighted
                ? (active
                    ? const Color(0xFF174A9B)
                    : Colors.white.withOpacity(0.07))
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(12),
            border: highlighted
                ? Border.all(
                    color: active
                        ? _primary.withOpacity(0.55)
                        : Colors.white
                            .withOpacity(0.08),
                  )
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final show = sidebarHovered &&
                  constraints.maxWidth > 90;

              return Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (active)
                        Positioned(
                          left: -12,
                          top: 1,
                          bottom: 1,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius:
                                  BorderRadius.circular(
                                999,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: 24,
                        child: Icon(
                          icon,
                          color: highlighted
                              ? Colors.white
                              : const Color(
                                  0xFFC7D5E8,
                                ),
                          size: 23,
                        ),
                      ),
                    ],
                  ),
                  if (show) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: highlighted
                              ? Colors.white
                              : const Color(
                                  0xFFC7D5E8,
                                ),
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _profileItem() {
    return InkWell(
      onTap: () => Navigator.of(context)
          .pushNamed('/perfil'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final show = sidebarHovered &&
                constraints.maxWidth > 90;

            return Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: _avatarProvider(),
                ),
                if (show) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _username,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          'Ver perfil',
                          style: TextStyle(
                            color:
                                Color(0xFF8FA5C0),
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _mobileTopBar() {
    return Container(
      height: 64,
      padding:
          const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFF06152D),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/pace_icon.png',
            width: 34,
            height: 34,
          ),
        ],
      ),
    );
  }

  Widget _mobileDrawer() {
    return Drawer(
      backgroundColor:
          const Color(0xFF06152D),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const SizedBox(height: 10),
            Image.asset(
              'assets/images/pace_icon.png',
              width: 52,
              height: 52,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 18),
            _drawerItem(
              'Feed',
              '/feed',
              Icons.home_rounded,
            ),
            _drawerItem(
              'Explorar',
              '/explorar',
              Icons.explore_outlined,
            ),
            _drawerItem(
              'Postar',
              '/postar',
              Icons.edit_square,
            ),
            _drawerItem(
              'Metas',
              '/metas',
              Icons.track_changes_rounded,
            ),
            _drawerItem(
              'Sala de foco',
              '/foco',
              Icons.psychology_outlined,
            ),
            _drawerItem(
              'Evolução',
              '/evolucao',
              Icons.trending_up_rounded,
            ),
            _drawerItem(
              'Configurações',
              '/config',
              Icons.settings_outlined,
              active: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    String label,
    String route,
    IconData icon, {
    bool active = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: active
            ? Colors.white
            : const Color(0xFFC7D5E8),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: active
              ? Colors.white
              : const Color(0xFFC7D5E8),
          fontWeight: FontWeight.w700,
        ),
      ),
      tileColor:
          active ? const Color(0xFF174A9B) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: active
          ? () => Navigator.pop(context)
          : () =>
              Navigator.of(context).pushNamed(route),
    );
  }
}