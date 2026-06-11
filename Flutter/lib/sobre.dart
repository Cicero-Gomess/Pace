import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SobrePage extends StatefulWidget {
  const SobrePage({super.key});

  @override
  State<SobrePage> createState() => _SobrePageState();
}

class _Developer {
  final String nome;
  final String cargo;
  final String descricao;
  final String foto;
  final List<String> habilidades;

  const _Developer({
    required this.nome,
    required this.cargo,
    required this.descricao,
    required this.foto,
    required this.habilidades,
  });
}

class _SobrePageState extends State<SobrePage> {
  static const String apiUrl = 'http://127.0.0.1:8000';

  static const List<_Developer> desenvolvedores = [
    _Developer(
      nome: 'Cicero Gomes da Silva Junior',
      cargo: 'Desenvolvedor',
      descricao:
          'Atua na construcao das telas, organizacao da experiencia do usuario e integracao das funcionalidades do Pace.',
      foto: 'assets/images/dev_cicero.jpg',
      habilidades: ['Flutter', 'UI', 'Integracao'],
    ),
    _Developer(
      nome: 'Eduardo Cosme da Silva',
      cargo: 'Desenvolvedor',
      descricao:
          'Contribui com a logica da aplicacao, estrutura das funcionalidades e melhoria continua da navegacao.',
      foto: 'assets/images/dev_eduardo.jpg',
      habilidades: ['Dart', 'Rotas', 'Componentes'],
    ),
    _Developer(
      nome: 'Henrique de Godoy',
      cargo: 'Desenvolvedor',
      descricao:
          'Participa do desenvolvimento visual, organizacao do projeto e refinamento das telas principais.',
      foto: 'assets/images/dev_henrique.jpg',
      habilidades: ['Design', 'Flutter', 'Layout'],
    ),
    _Developer(
      nome: 'Yury Gabriel de Souza',
      cargo: 'Desenvolvedor',
      descricao:
          'Colabora na implementacao de recursos, testes de uso e ajustes para deixar a aplicacao mais completa.',
      foto: 'assets/images/dev_yury.jpg',
      habilidades: ['Funcionalidades', 'Testes', 'UX'],
    ),
  ];

  bool sidebarHovered = false;
  String? sidebarItemHovered;
  Map<String, dynamic> usuarioLogado = {};

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

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
    _loadOptionalUser();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadOptionalUser() async {
    final token = await _getToken();
    if (token == null || !mounted) return;

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        setState(() {
          usuarioLogado = Map<String, dynamic>.from(jsonDecode(response.body));
        });
      }
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentLeftPadding = screenWidth < 1000 ? 24.0 : 180.0;

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
                    42,
                    42,
                    70,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHero(),
                          const SizedBox(height: 28),
                          _buildMissionCard(),
                          const SizedBox(height: 28),
                          _buildDevelopersGrid(),
                        ],
                      ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 860;
        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Badge(text: 'Equipe Pace'),
            const SizedBox(height: 14),
            Text(
              'Sobre nos',
              style: TextStyle(
                fontSize: isSmall ? 36 : 46,
                height: 1.02,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Conheca os desenvolvedores responsaveis por dar forma ao Pace, unindo tecnologia, organizacao e cuidado com a experiencia de quem usa o aplicativo.',
              style: TextStyle(
                fontSize: 16,
                height: 1.75,
                color: mutedColor,
              ),
            ),
          ],
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              const SizedBox(height: 18),
              _TeamCounter(total: desenvolvedores.length, darkMode: darkMode),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 24),
            SizedBox(
              width: 286,
              child: _TeamCounter(
                total: desenvolvedores.length,
                darkMode: darkMode,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMissionCard() {
    return _GlassCard(
      darkMode: darkMode,
      padding: const EdgeInsets.all(26),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 780;
          final icon = Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF3059AA).withOpacity(0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: Color(0xFF3059AA),
              size: 30,
            ),
          );
          final textBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nossa proposta',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'O Pace foi desenvolvido para ajudar pessoas a acompanhar metas, compartilhar progresso e encontrar motivacao dentro de uma comunidade focada em evolucao.',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
            ],
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(height: 18),
                textBlock,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 18),
              Expanded(child: textBlock),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDevelopersGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 720
            ? 1
            : width < 1050
                ? 2
                : 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: desenvolvedores.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: columns == 1 ? 0.92 : 0.72,
          ),
          itemBuilder: (context, index) {
            return _DeveloperCard(
              developer: desenvolvedores[index],
              darkMode: darkMode,
              textColor: textColor,
              mutedColor: mutedColor,
            );
          },
        );
      },
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
                      _sidebarItem(
                        Icons.track_changes,
                        'Metas',
                        '/metas',
                        false,
                      ),
                      _sidebarItem(
                        Icons.explore_outlined,
                        'Explorar',
                        '/explorar',
                        false,
                      ),
                      _sidebarItem(
                        Icons.add_box_outlined,
                        'Postar',
                        '/postar',
                        false,
                      ),
                      _sidebarItem(
                        Icons.notifications_none,
                        'Notificacoes',
                        '/notificacoes',
                        false,
                      ),
                      const SizedBox(height: 18),
                      Divider(color: const Color(0xFF3059AA).withOpacity(0.10)),
                      const SizedBox(height: 18),
                      _sidebarItem(
                        Icons.settings_outlined,
                        'Configuracoes',
                        '/config',
                        false,
                      ),
                      _sidebarProfileItem(),
                      _sidebarItem(Icons.info_outline, 'Sobre', '/sobre', true),
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
          curve: Curves.easeOutCubic,
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
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: showText ? 1 : 0,
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
          if (route != '/sobre') {
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
}

class _DeveloperCard extends StatelessWidget {
  final _Developer developer;
  final bool darkMode;
  final Color textColor;
  final Color mutedColor;

  const _DeveloperCard({
    required this.developer,
    required this.darkMode,
    required this.textColor,
    required this.mutedColor,
  });

  String get initials {
    final parts = developer.nome
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      darkMode: darkMode,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    developer.foto,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        color: const Color(0xFF3059AA).withOpacity(0.12),
                        child: Center(
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: const Color(0xFF3059AA),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    developer.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    developer.cargo,
                    style: const TextStyle(
                      color: Color(0xFF3059AA),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Text(
                      developer.descricao,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: developer.habilidades
                        .map((habilidade) => _SkillPill(text: habilidade))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamCounter extends StatelessWidget {
  final int total;
  final bool darkMode;

  const _TeamCounter({
    required this.total,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      darkMode: darkMode,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF5EB1BF).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.code,
              color: Color(0xFF5EB1BF),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$total desenvolvedores',
                style: TextStyle(
                  color: darkMode
                      ? const Color(0xFFF3F6FF)
                      : const Color(0xFF1B2233),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              Text(
                'criando o Pace',
                style: TextStyle(
                  color: darkMode
                      ? const Color(0xFF9CA7BE)
                      : const Color(0xFF6F7B91),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillPill extends StatelessWidget {
  final String text;

  const _SkillPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF3059AA).withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF3059AA),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool darkMode;

  const _GlassCard({
    required this.child,
    required this.darkMode,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14274D).withOpacity(darkMode ? 0.30 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xE00D0D10)
                  : Colors.white.withOpacity(0.84),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: darkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.65),
              ),
            ),
            child: child,
          ),
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
            color: darkMode ? const Color(0xFF05070C) : const Color(0xFFF4F7FB),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -120,
          left: 40,
          child: _SoftOrb(
            size: 420,
            color: darkMode ? const Color(0x1C3059AA) : const Color(0x225EB1BF),
            blur: 120,
          ),
        ),
        Positioned(
          bottom: -120,
          left: -120,
          child: _SoftOrb(
            size: 420,
            color: darkMode ? const Color(0x145EB1BF) : const Color(0x185EB1BF),
            blur: 130,
          ),
        ),
        Positioned(
          top: -140,
          right: -80,
          child: _SoftOrb(
            size: 360,
            color: darkMode ? const Color(0x1C5EB1BF) : const Color(0x143059AA),
            blur: 130,
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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
