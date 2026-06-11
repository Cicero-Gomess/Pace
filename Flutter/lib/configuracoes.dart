import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_controller.dart';

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
  static const String apiUrl = "http://127.0.0.1:8000";

  bool sidebarHovered = false;
  String? sidebarItemHovered;
  bool isLoadingUser = true;
  bool isSavingPassword = false;

  Map<String, dynamic> usuarioLogado = {};

  final TextEditingController senhaAtualController = TextEditingController();
  final TextEditingController novaSenhaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();

  bool get darkMode => widget.themeController.darkMode;

  Color get bgColor =>
      darkMode ? const Color(0xFF05070C) : const Color(0xFFF4F7FB);

  Color get textColor =>
      darkMode ? const Color(0xFFF3F6FF) : const Color(0xFF1B2233);

  Color get mutedColor =>
      darkMode ? const Color(0xFF9CA7BE) : const Color(0xFF6F7B91);

  Color get sidebarTextColor =>
      darkMode ? const Color(0xFFF1F5FF) : const Color(0xFF33415C);

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
    return prefs.getString('token');
  }

  Future<void> _initUser() async {
    final token = await _getToken();

    if (!mounted) return;

    if (token == null) {
      Navigator.of(context).pushReplacementNamed('/entrar');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/entrar');
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          usuarioLogado = Map<String, dynamic>.from(jsonDecode(response.body));
          isLoadingUser = false;
        });
      } else {
        setState(() => isLoadingUser = false);
        _showToast('Não foi possível carregar seu perfil.', Colors.red);
      }
    } catch (_) {
      setState(() => isLoadingUser = false);
      _showToast('Não foi possível carregar seu perfil.', Colors.red);
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    await widget.themeController.setDarkMode(value);

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuarioLogado');

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/entrar', (_) => false);
  }

  Future<void> _alterarSenha() async {
    final senhaAtual = senhaAtualController.text.trim();
    final novaSenha = novaSenhaController.text.trim();
    final confirmarSenha = confirmarSenhaController.text.trim();
    final token = await _getToken();

    if (senhaAtual.isEmpty || novaSenha.isEmpty || confirmarSenha.isEmpty) {
      _showToast('Preencha todos os campos antes de continuar.', Colors.red);
      return;
    }

    if (novaSenha.length < 6) {
      _showToast('A nova senha deve ter pelo menos 6 caracteres.', Colors.red);
      return;
    }

    if (novaSenha != confirmarSenha) {
      _showToast('A confirmação da nova senha não confere.', Colors.red);
      return;
    }

    if (token == null) {
      _showToast('Sua sessão expirou. Faça login novamente.', Colors.red);
      Navigator.of(context).pushReplacementNamed('/entrar');
      return;
    }

    setState(() => isSavingPassword = true);

    try {
      final response = await http.put(
        Uri.parse('$apiUrl/auth/atualizar_senha'),
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
        if (mounted) Navigator.of(context).pushReplacementNamed('/entrar');
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map && data['detail'] != null
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
        Colors.green,
      );
    } catch (e) {
      _showToast(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => isSavingPassword = false);
    }
  }

  ImageProvider _avatarProvider(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      return NetworkImage(url);
    }

    return const AssetImage('assets/user.png');
  }

  String? _fotoUsuarioLogado() {
    final foto = usuarioLogado['foto_perfil'] ?? usuarioLogado['foto'];
    if (foto == null || foto.toString().trim().isEmpty) return null;
    return foto.toString();
  }

  void _showToast(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentLeftPadding = screenWidth < 1000 ? 24.0 : 360.0;

    if (isLoadingUser) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3059AA)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _BackgroundDecor(darkMode: darkMode),
          Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    contentLeftPadding,
                    48,
                    42,
                    80,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(),
                        const SizedBox(height: 28),
                        _buildConfigGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Badge(text: 'Personalização'),
        const SizedBox(height: 14),
        Text(
          'Configurações',
          style: TextStyle(
            fontSize: 42,
            height: 1.05,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 720,
          child: Text(
            'Ajuste sua experiência no Pace e deixe o ambiente mais confortável para sua rotina.',
            style: TextStyle(
              fontSize: 16,
              height: 1.7,
              color: mutedColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 900;

        if (isSmall) {
          return Column(
            children: [
              _buildPasswordCard(),
              const SizedBox(height: 20),
              _buildAppearanceCard(),
              const SizedBox(height: 20),
              _buildAccessCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 14, child: _buildPasswordCard()),
            const SizedBox(width: 20),
            Expanded(
              flex: 10,
              child: Column(
                children: [
                  _buildAppearanceCard(),
                  const SizedBox(height: 20),
                  _buildAccessCard(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPasswordCard() {
    return _GlassCard(
      darkMode: darkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTop(
            kicker: 'Conta',
            title: 'Alterar senha',
            icon: Icons.key_outlined,
          ),
          _PasswordField(
            controller: senhaAtualController,
            label: 'Senha atual',
            hint: 'Digite sua senha atual',
            darkMode: darkMode,
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: novaSenhaController,
            label: 'Nova senha',
            hint: 'Digite sua nova senha',
            darkMode: darkMode,
          ),
          const SizedBox(height: 16),
          _PasswordField(
            controller: confirmarSenhaController,
            label: 'Confirmar nova senha',
            hint: 'Confirme sua nova senha',
            darkMode: darkMode,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isSavingPassword ? null : _alterarSenha,
              icon: isSavingPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                isSavingPassword ? 'Salvando...' : 'Salvar alteração',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3059AA),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceCard() {
    return _GlassCard(
      darkMode: darkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTop(
            kicker: 'Aparência',
            title: 'Visual do app',
            icon: Icons.dark_mode_outlined,
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo escuro',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ative um visual mais confortável para ambientes com pouca luz.',
                      style: TextStyle(
                        color: mutedColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: darkMode,
                activeColor: const Color(0xFF3059AA),
                onChanged: _toggleDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard() {
    return _GlassCard(
      darkMode: darkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTop(
            kicker: 'Sessão',
            title: 'Acesso',
            icon: Icons.verified_user_outlined,
          ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text(
                'Sair da conta',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D4D).withOpacity(0.12),
                foregroundColor: darkMode
                    ? const Color(0xFFFF7B7B)
                    : const Color(0xFFD63737),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardTop({
    required String kicker,
    required String title,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: Color(0xFF5EB1BF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF3059AA).withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF3059AA)),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    const collapsed = 84.0;
    const expanded = 230.0;
    final width = sidebarHovered ? expanded : collapsed;

    return MouseRegion(
      onEnter: (_) => setState(() => sidebarHovered = true),
      onExit: (_) {
        setState(() {
          sidebarHovered = false;
          sidebarItemHovered = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        width: width,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(
          color: darkMode
              ? const Color(0xC8080A0E)
              : Colors.white.withOpacity(0.78),
          border: Border(
            right: BorderSide(
              color: darkMode
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.55),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(darkMode ? 0.35 : 0.06),
              blurRadius: 30,
              offset: const Offset(8, 0),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Column(
              children: [
                SizedBox(
                  height: 104,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10, top: 4),
                      child: Image.asset(
                        'assets/images/Ícone_Pace.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _sidebarItem(Icons.home_outlined, 'Feed', '/feed', false),
                      _sidebarItem(Icons.track_changes, 'Metas', '/metas', false),
                      _sidebarItem(Icons.explore_outlined, 'Explorar', '/explorar', false),
                      _sidebarItem(Icons.add_box_outlined, 'Postar', '/postar', false),
                      _sidebarItem(Icons.notifications_none, 'Notificações', '/notificacoes', false),
                      const SizedBox(height: 18),
                      Divider(color: const Color(0xFF3059AA).withOpacity(0.10)),
                      const SizedBox(height: 18),
                      _sidebarItem(Icons.settings_outlined, 'Configurações', '/config', true),
                      _sidebarProfileItem(),
                      _sidebarItem(Icons.info_outline, 'Sobre', '/sobre', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String label,
    String route,
    bool active,
  ) {
    final isHovered = sidebarItemHovered == route;
    final highlighted = active || isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => sidebarItemHovered = route),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (route != '/config') {
            Navigator.of(context).pushNamed(route);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          height: 50,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: highlighted
                ? darkMode
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFEAF1F7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: highlighted
                ? Border.all(
                    color: darkMode
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFC8D8F0),
                  )
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showText = sidebarHovered && constraints.maxWidth > 90;

              return Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Icon(
                      icon,
                      color: highlighted
                          ? const Color(0xFF3059AA)
                          : sidebarTextColor,
                      size: 24,
                    ),
                  ),
                  if (showText) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: showText ? 1 : 0,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: highlighted
                                ? const Color(0xFF3059AA)
                                : sidebarTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
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

  Widget _sidebarProfileItem() {
    const route = '/perfil';
    final isHovered = sidebarItemHovered == route;

    return MouseRegion(
      onEnter: (_) => setState(() => sidebarItemHovered = route),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pushNamed('/perfil'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          height: 50,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isHovered
                ? darkMode
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFEAF1F7)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showText = sidebarHovered && constraints.maxWidth > 90;

              return Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: _avatarProvider(_fotoUsuarioLogado()),
                  ),
                  if (showText) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Perfil',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: sidebarTextColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool darkMode;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        darkMode ? const Color(0xFFF3F6FF) : const Color(0xFF1B2233);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: darkMode
                  ? const Color(0xFF9CA7BE)
                  : const Color(0xFF6F7B91),
            ),
            filled: true,
            fillColor: darkMode
                ? Colors.white.withOpacity(0.03)
                : Colors.white.withOpacity(0.82),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: darkMode
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFF3059AA).withOpacity(0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: const Color(0xFF3059AA).withOpacity(0.34),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool darkMode;

  const _GlassCard({
    required this.child,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xE00D0D10)
            : Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14274D).withOpacity(darkMode ? 0.30 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: child,
        ),
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  final bool darkMode;

  const _BackgroundDecor({required this.darkMode});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: darkMode
                  ? const [Color(0xFF05070C), Color(0xFF0B1018)]
                  : const [Color(0xFFF6F9FD), Color(0xFFEEF3F9)],
            ),
          ),
          child: const SizedBox.expand(),
        ),
        const Positioned(
          top: -120,
          right: -80,
          child: _SoftOrb(
            size: 360,
            color: Color(0x223059AA),
            blur: 120,
          ),
        ),
        const Positioned(
          bottom: 60,
          left: -100,
          child: _SoftOrb(
            size: 340,
            color: Color(0x245EB1BF),
            blur: 120,
          ),
        ),
      ],
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double blur;

  const _SoftOrb({
    required this.size,
    required this.color,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3059AA).withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF3059AA),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}