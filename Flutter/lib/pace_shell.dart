import 'dart:async';

import 'package:flutter/material.dart';

import 'api_config.dart';

const Color pacePrimary = Color(0xFF315CAC);
const Color pacePrimary2 = Color(0xFF416FC4);
const Color paceAccent = Color(0xFF69C5D0);

class PaceShell extends StatelessWidget {
  final String currentRoute;
  final Widget child;
  final String username;
  final String? avatarValue;
  final Color backgroundColor;

  const PaceShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.username = 'Meu perfil',
    this.avatarValue,
    this.backgroundColor = const Color(0xFFF4F8FD),
  });

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 760;

    if (mobile) {
      return _MobilePaceShell(
        currentRoute: currentRoute,
        username: username,
        avatarValue: avatarValue,
        backgroundColor: backgroundColor,
        child: child,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            left: 88,
            child: RepaintBoundary(child: child),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: RepaintBoundary(
              child: _DesktopSidebar(
                currentRoute: currentRoute,
                username: username,
                avatarValue: avatarValue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobilePaceShell extends StatefulWidget {
  final String currentRoute;
  final Widget child;
  final String username;
  final String? avatarValue;
  final Color backgroundColor;

  const _MobilePaceShell({
    required this.currentRoute,
    required this.child,
    required this.username,
    required this.avatarValue,
    required this.backgroundColor,
  });

  @override
  State<_MobilePaceShell> createState() => _MobilePaceShellState();
}

class _MobilePaceShellState extends State<_MobilePaceShell> {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      backgroundColor: widget.backgroundColor,
      drawer: Drawer(
        width: 292,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SafeArea(
          child: _SidebarSurface(
            currentRoute: widget.currentRoute,
            username: widget.username,
            avatarValue: widget.avatarValue,
            expanded: true,
            mobile: true,
            onClose: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: darkMode
                    ? const Color(0xFF090B10)
                    : Colors.white.withOpacity(0.96),
                border: Border(
                  bottom: BorderSide(
                    color: pacePrimary.withOpacity(0.08),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF15284D).withOpacity(0.055),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: InkWell(
                      onTap: () => _key.currentState?.openDrawer(),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Image.asset(
                          'assets/images/pace_icon.png',
                          width: 42,
                          height: 42,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pace',
                          style: TextStyle(
                            color: darkMode ? Colors.white : pacePrimary,
                            fontSize: 18,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toque na logo para abrir o menu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: darkMode
                                ? const Color(0xFF98A8BF)
                                : const Color(0xFF6F7F96),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _MiniAction(
                    icon: Icons.notifications_none_rounded,
                    onTap: () => _go(context, '/notificacoes', widget.currentRoute),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RepaintBoundary(child: widget.child),
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatefulWidget {
  final String currentRoute;
  final String username;
  final String? avatarValue;

  const _DesktopSidebar({
    required this.currentRoute,
    required this.username,
    required this.avatarValue,
  });

  @override
  State<_DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends State<_DesktopSidebar> {
  bool expanded = false;
  bool showLabels = false;
  Timer? _labelTimer;

  @override
  void dispose() {
    _labelTimer?.cancel();
    super.dispose();
  }

  void _openSidebar() {
    if (expanded) return;

    _labelTimer?.cancel();

    setState(() {
      expanded = true;
      showLabels = false;
    });

    // Espera a sidebar ganhar largura suficiente antes de revelar os textos.
    // Isso elimina o pequeno overflow vermelho durante a abertura.
    _labelTimer = Timer(
      const Duration(milliseconds: 125),
      () {
        if (!mounted || !expanded) return;
        setState(() => showLabels = true);
      },
    );
  }

  void _closeSidebar() {
    _labelTimer?.cancel();

    // Primeiro esconde os textos; só depois a largura começa a fechar.
    // Assim nenhum label é espremido durante a animação.
    if (showLabels) {
      setState(() => showLabels = false);
    }

    Future.microtask(() {
      if (!mounted) return;
      if (expanded) {
        setState(() => expanded = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _openSidebar(),
      onExit: (_) => _closeSidebar(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutQuart,
        width: expanded ? 244 : 88,
        height: double.infinity,
        child: _SidebarSurface(
          currentRoute: widget.currentRoute,
          username: widget.username,
          avatarValue: widget.avatarValue,
          expanded: showLabels,
          mobile: false,
        ),
      ),
    );
  }
}

class _SidebarSurface extends StatelessWidget {
  final String currentRoute;
  final String username;
  final String? avatarValue;
  final bool expanded;
  final bool mobile;
  final VoidCallback? onClose;

  const _SidebarSurface({
    required this.currentRoute,
    required this.username,
    required this.avatarValue,
    required this.expanded,
    required this.mobile,
    this.onClose,
  });

  bool get _showText => expanded || mobile;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFF1F5FF) : const Color(0xFF33415B);
    final muted = dark ? const Color(0xFF98A8BF) : const Color(0xFF6F7F96);

    return Container(
      margin: mobile ? const EdgeInsets.fromLTRB(10, 8, 0, 8) : EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF0B0D12) : const Color(0xFFF8FBFF),
        borderRadius: mobile
            ? const BorderRadius.horizontal(right: Radius.circular(28))
            : BorderRadius.zero,
        border: Border(
          right: BorderSide(color: pacePrimary.withOpacity(0.09)),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF112348).withOpacity(dark ? 0.28 : 0.08),
            blurRadius: 32,
            offset: const Offset(10, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 70,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 9),
                  child: Image.asset(
                    'assets/images/pace_icon.png',
                    width: 46,
                    height: 46,
                    fit: BoxFit.contain,
                  ),
                ),
                if (_showText) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRect(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 190),
                        curve: Curves.easeOut,
                        opacity: 1,
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 230),
                          curve: Curves.easeOutCubic,
                          offset: Offset.zero,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pace',
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  color: pacePrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Evolução contínua',
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (mobile && onClose != null)
                  _MiniAction(
                    icon: Icons.close_rounded,
                    onTap: onClose!,
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: pacePrimary.withOpacity(0.10)),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _section('COMUNIDADE', muted),
                _item(context, Icons.home_rounded, 'Feed', '/feed', text),
                _item(context, Icons.explore_outlined, 'Explorar', '/explorar', text),
                _item(context, Icons.edit_square, 'Postar', '/postar', text),
                const SizedBox(height: 10),
                _section('DESENVOLVIMENTO', muted),
                _item(context, Icons.track_changes_rounded, 'Metas', '/metas', text),
                _item(context, Icons.psychology_outlined, 'Sala de foco', '/foco', text),
                _item(context, Icons.trending_up_rounded, 'Evolução', '/evolucao', text),
              ],
            ),
          ),
          Divider(height: 1, color: pacePrimary.withOpacity(0.08)),
          const SizedBox(height: 8),
          _item(
            context,
            Icons.notifications_none_rounded,
            'Notificações',
            '/notificacoes',
            text,
          ),
          _item(
            context,
            Icons.settings_outlined,
            'Configurações',
            '/config',
            text,
          ),
          _profile(context, text, muted),
        ],
      ),
    );
  }

  Widget _section(String value, Color muted) {
    return SizedBox(
      height: 28,
      child: ClipRect(
        child: _showText
            ? AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                opacity: 1,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: Offset.zero,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          color: muted.withOpacity(0.78),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.25,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    Color normalText,
  ) {
    return _SidebarButton(
      icon: icon,
      label: label,
      showText: _showText,
      active: currentRoute == route,
      normalText: normalText,
      onTap: () {
        if (mobile) Navigator.of(context).pop();
        _go(context, route, currentRoute);
      },
    );
  }

  Widget _profile(BuildContext context, Color text, Color muted) {
    final active = currentRoute == '/perfil';
    return _SidebarButton(
      showText: _showText,
      active: active,
      normalText: text,
      onTap: () {
        if (mobile) Navigator.of(context).pop();
        _go(context, '/perfil', currentRoute);
      },
      leading: Container(
        width: 38,
        height: 38,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pacePrimary.withOpacity(0.12)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(
            image: ApiConfig.imageProvider(avatarValue),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      ),
      label: username.trim().isEmpty ? 'Meu perfil' : username,
      subtitle: 'Ver perfil',
    );
  }
}

class _SidebarButton extends StatefulWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final String? subtitle;
  final bool showText;
  final bool active;
  final Color normalText;
  final VoidCallback onTap;

  const _SidebarButton({
    this.icon,
    this.leading,
    required this.label,
    this.subtitle,
    required this.showText,
    required this.active,
    required this.normalText,
    required this.onTap,
  });

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.active || hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!hovered) setState(() => hovered = true);
      },
      onExit: (_) {
        if (hovered) setState(() => hovered = false);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                gradient: widget.active
                    ? LinearGradient(
                        colors: [
                          pacePrimary.withOpacity(0.15),
                          paceAccent.withOpacity(0.09),
                        ],
                      )
                    : null,
                color: !widget.active && hovered
                    ? pacePrimary.withOpacity(0.06)
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: widget.active
                    ? Border.all(color: pacePrimary.withOpacity(0.08))
                    : null,
              ),
              child: Row(
                children: [
                  widget.leading ??
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: highlighted
                              ? pacePrimary.withOpacity(0.07)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          widget.icon,
                          color: widget.active
                              ? pacePrimary
                              : widget.normalText,
                          size: 21,
                        ),
                      ),
                  if (widget.showText) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: ClipRect(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 170),
                          curve: Curves.easeOut,
                          opacity: 1,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 210),
                            curve: Curves.easeOutCubic,
                            offset: Offset.zero,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: widget.active
                                        ? pacePrimary
                                        : widget.normalText,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: widget.normalText.withOpacity(0.65),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: pacePrimary.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: pacePrimary, size: 21),
      ),
    );
  }
}

void _go(BuildContext context, String route, String currentRoute) {
  if (route == currentRoute) return;
  Navigator.of(context).pushReplacementNamed(route);
}
