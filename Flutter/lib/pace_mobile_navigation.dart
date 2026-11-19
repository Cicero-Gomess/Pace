import 'package:flutter/material.dart';

import 'api_config.dart';

/// Cabeçalho mobile padrão do Pace (mesmo visual do Feed).
class PaceMobileTopBar extends StatelessWidget {
  final VoidCallback onOpen;
  const PaceMobileTopBar({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF041126),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFFFC928),
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: onOpen,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'assets/images/pace_icon.png',
                    width: 43,
                    height: 43,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pace',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Evolução contínua',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF8FA5C0),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menu mobile compartilhado: a rota atual define o item selecionado.
class PaceMobileDrawer extends StatelessWidget {
  final String currentRoute;
  final Map<String, dynamic> user;
  const PaceMobileDrawer({
    super.key,
    required this.currentRoute,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      width: 292,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 8, 0, 8),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF06152D),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(28),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(darkMode ? 0.34 : 0.14),
                blurRadius: 42,
                offset: const Offset(12, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/pace_icon.png',
                    width: 46,
                    height: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pace',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        Text(
                          'Evolução contínua',
                          style: TextStyle(
                            color: const Color(0xFF8FA5C0),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _PaceDrawerClose(onTap: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 18),
              Divider(
                height: 1,
                color: Colors.white.withOpacity(0.08),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _drawerSectionLabel('COMUNIDADE'),
                    _mobileDrawerItem(
                      context,
                      Icons.home_rounded,
                      'Feed',
                      '/feed',
                    ),
                    _mobileDrawerItem(
                      context,
                      Icons.explore_outlined,
                      'Explorar',
                      '/explorar',
                    ),
                    _mobileDrawerItem(
                      context,
                      Icons.edit_square,
                      'Postar',
                      '/postar',
                    ),

                    const SizedBox(height: 12),
                    _drawerSectionLabel('DESENVOLVIMENTO'),
                    _mobileDrawerItem(
                      context,
                      Icons.track_changes_rounded,
                      'Metas',
                      '/metas',
                    ),
                    _mobileDrawerItem(
                      context,
                      Icons.psychology_outlined,
                      'Sala de foco',
                      '/foco',
                    ),
                    _mobileDrawerItem(
                      context,
                      Icons.trending_up_rounded,
                      'Evolução',
                      '/evolucao',
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: Colors.white.withOpacity(0.08),
              ),
              const SizedBox(height: 12),
              _mobileDrawerItem(
                context,
                Icons.settings_outlined,
                'Configurações',
                '/config',
              ),
              _mobileProfileItem(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF8FA5C0),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.25,
        ),
      ),
    );
  }

  Widget _mobileDrawerItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final active = currentRoute == route;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _navigate(context, route);
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFF174A9B)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: active
                  ? Border.all(color: const Color(0xFF1769E8).withOpacity(0.10))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF1769E8).withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: active ? Colors.white : const Color(0xFFC7D5E8),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : const Color(0xFFC7D5E8),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!active)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: const Color(0xFF8FA5C0),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileProfileItem(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _navigate(context, '/perfil');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: currentRoute == '/perfil'
                ? const Color(0xFF174A9B)
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: ApiConfig.imageProvider(
                  user['foto_perfil'] ?? user['foto'] ?? user['avatar'],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meu perfil',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ver perfil',
                      style: TextStyle(
                        color: Color(0xFF8FA5C0),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8FA5C0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    final page = ModalRoute.of(context);
    navigator.pop(); // fecha apenas o Drawer (histórico local do Scaffold)
    if (route == currentRoute) return;
    Future.delayed(const Duration(milliseconds: 120), () {
      if (navigator.mounted && (page == null || page.isCurrent)) {
        navigator.pushNamed(route);
      }
    });
  }
}

class _PaceDrawerClose extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _PaceDrawerClose({
    this.icon = Icons.close_rounded,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: danger
          ? const Color(0xFFE55353).withOpacity(0.10)
          : const Color(0xFF1769E8).withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 20,
            color: danger ? const Color(0xFFE55353) : const Color(0xFF1769E8),
          ),
        ),
      ),
    );
  }
}

