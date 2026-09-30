import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ============================================================
  // IDENTIDADE PACE
  // ============================================================

  static const Color navy = Color(0xFF06152D);
  static const Color navyDeep = Color(0xFF041126);
  static const Color navyLight = Color(0xFF0A2245);

  static const Color blue = Color(0xFF1769E8);
  static const Color blueDark = Color(0xFF0B3D91);
  static const Color blueSoft = Color(0xFFE8F3FF);

  static const Color ice = Color(0xFFEAF3FB);
  static const Color iceStrong = Color(0xFFD7E8F7);

  static const Color yellow = Color(0xFFFFC928);

  static const Color textWhite = Color(0xFFF7FAFF);
  static const Color textSoft = Color(0xFFC7D5E8);
  static const Color textMuted = Color(0xFF8FA5C0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildNavbar(context),
            Expanded(
              child: _buildHero(context),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAVBAR
  // ============================================================

  Widget _buildNavbar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final bool mobile = width < 700;
        final bool compact = width <= 390;

        return Container(
          width: double.infinity,
          color: navyDeep,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1380,
              ),
              child: Container(
                height: mobile ? 68 : 78,
                padding: EdgeInsets.symmetric(
                  horizontal: mobile ? 18 : 42,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) => false,
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: mobile ? 42 : 46,
                              height: mobile ? 42 : 46,
                              padding: const EdgeInsets.all(3),
                              child: Image.asset(
                                'assets/images/pace_icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (!compact) ...[
                              const SizedBox(width: 10),
                              const Column(
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
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    'Evolução contínua',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    _TopButton(
                      text: 'Entrar',
                      outlined: true,
                      compact: compact,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/entrar',
                        );
                      },
                    ),

                    SizedBox(
                      width: mobile ? 8 : 12,
                    ),

                    _TopButton(
                      text: compact ? 'Criar conta' : 'Cadastre-se',
                      compact: compact,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/cadastro',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final bool desktop = width >= 1080;
        final bool tablet = width >= 700 && width < 1080;
        final bool smallMobile = width <= 390;

        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                color: navy,
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                color: yellow,
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              width: desktop ? 410 : 180,
              height: desktop ? 410 : 180,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              right: 0,
              width: desktop ? 500 : 260,
              height: desktop ? 430 : 260,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CornerPainter(),
                ),
              ),
            ),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 1380,
                    minHeight: height,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop
                          ? 48
                          : tablet
                              ? 38
                              : smallMobile
                                  ? 18
                                  : 24,
                      vertical: desktop ? 52 : 38,
                    ),
                    child: desktop
                        ? _buildDesktopHero(context)
                        : _buildMobileHero(
                            context,
                            smallMobile,
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopHero(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 10,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroBadge(),

                const SizedBox(height: 28),

                const Text(
                  'Transforme objetivos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 58,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2.7,
                  ),
                ),

                const SizedBox(height: 9),

                const Text(
                  'em progresso real.',
                  style: TextStyle(
                    color: blueSoft,
                    fontSize: 58,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2.7,
                  ),
                ),

                const SizedBox(height: 26),

                Container(
                  width: 72,
                  height: 4,
                  decoration: BoxDecoration(
                    color: yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Metas, foco, evolução e comunidade reunidos '
                  'em um só lugar para ajudar você a continuar avançando.',
                  style: TextStyle(
                    color: textSoft,
                    fontSize: 17,
                    height: 1.65,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    SizedBox(
                      width: 210,
                      child: _MainButton(
                        text: 'Começar agora',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/cadastro',
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 14),

                    SizedBox(
                      width: 205,
                      child: _SecondaryButton(
                        text: 'Já tenho uma conta',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/entrar',
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 38),

                const Wrap(
                  spacing: 26,
                  runSpacing: 16,
                  children: [
                    _DesktopBenefit(
                      icon: Icons.flag_rounded,
                      text: 'Metas',
                    ),
                    _DesktopBenefit(
                      icon: Icons.timer_rounded,
                      text: 'Foco',
                    ),
                    _DesktopBenefit(
                      icon: Icons.show_chart_rounded,
                      text: 'Evolução',
                    ),
                    _DesktopBenefit(
                      icon: Icons.groups_rounded,
                      text: 'Comunidade',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 70),

        const Expanded(
          flex: 9,
          child: _ProductPreview(),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE / TABLET
  // ============================================================

  Widget _buildMobileHero(
    BuildContext context,
    bool smallMobile,
  ) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 580,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroBadge(),

            SizedBox(
              height: smallMobile ? 26 : 34,
            ),

            Text(
              'Transforme objetivos',
              style: TextStyle(
                color: Colors.white,
                fontSize: smallMobile ? 37 : 44,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -1.8,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'em progresso real.',
              style: TextStyle(
                color: blueSoft,
                fontSize: smallMobile ? 37 : 44,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -1.8,
              ),
            ),

            const SizedBox(height: 22),

            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                color: yellow,
                borderRadius: BorderRadius.circular(20),
              ),
            ),

            SizedBox(
              height: smallMobile ? 20 : 24,
            ),

            Text(
              'Metas, foco, evolução e comunidade reunidos '
              'em um só lugar para ajudar você a continuar avançando.',
              style: TextStyle(
                color: textSoft,
                fontSize: smallMobile ? 14.5 : 16,
                height: 1.65,
              ),
            ),

            SizedBox(
              height: smallMobile ? 27 : 32,
            ),

            _MainButton(
              text: 'Começar agora',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/cadastro',
                );
              },
            ),

            const SizedBox(height: 12),

            _SecondaryButton(
              text: 'Já tenho uma conta',
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/entrar',
                );
              },
            ),

            SizedBox(
              height: smallMobile ? 34 : 42,
            ),

            const Row(
              children: [
                Expanded(
                  child: _Feature(
                    icon: Icons.flag_rounded,
                    text: 'Metas',
                  ),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: _Feature(
                    icon: Icons.timer_rounded,
                    text: 'Foco',
                  ),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: _Feature(
                    icon: Icons.show_chart_rounded,
                    text: 'Evolução',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            const _MobileProductPreview(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PREVIEW PRINCIPAL DO PRODUTO
// ============================================================================

class _ProductPreview extends StatelessWidget {
  const _ProductPreview();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 570,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          Positioned(
            top: 25,
            right: 0,
            child: Container(
              width: 455,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFD9E7F5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 55,
                    offset: const Offset(0, 25),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  _PreviewHeader(),
                  _PreviewBody(),
                ],
              ),
            ),
          ),

          const Positioned(
            top: 8,
            left: 0,
            child: _FloatingGoalCard(),
          ),

          const Positioned(
            bottom: 54,
            left: -10,
            child: _FloatingFocusCard(),
          ),

          const Positioned(
            right: -16,
            bottom: 6,
            child: _FloatingCommunityCard(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CABEÇALHO PREVIEW
// ============================================================================

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      decoration: const BoxDecoration(
        color: HomePage.navy,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(27),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/pace_icon.png',
            width: 34,
            height: 34,
          ),

          const SizedBox(width: 10),

          const Text(
            'Pace',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const Spacer(),

          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: HomePage.yellow,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'Seu espaço',
            style: TextStyle(
              color: HomePage.textSoft,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CORPO PREVIEW
// ============================================================================

class _PreviewBody extends StatelessWidget {
  const _PreviewBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        22,
        24,
        22,
        22,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DESENVOLVIMENTO',
            style: TextStyle(
              color: HomePage.blue,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Seu progresso',
            style: TextStyle(
              color: HomePage.navy,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Acompanhe sua evolução no Pace.',
            style: TextStyle(
              color: Color(0xFF60738B),
              fontSize: 12.5,
            ),
          ),

          const SizedBox(height: 22),

          const _PaceIndexCard(),

          const SizedBox(height: 15),

          const Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  icon: Icons.flag_rounded,
                  value: '8',
                  label: 'Metas',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.timer_rounded,
                  value: '4h',
                  label: 'Foco',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniMetric(
                  icon: Icons.local_fire_department_rounded,
                  value: '12',
                  label: 'Sequência',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: HomePage.blueSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                _ActivityIcon(),

                SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seu ritmo está crescendo',
                        style: TextStyle(
                          color: HomePage.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Continue avançando um passo por vez.',
                        style: TextStyle(
                          color: Color(0xFF60738B),
                          fontSize: 11,
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
}

// ============================================================================
// ÍNDICE PACE
// ============================================================================

class _PaceIndexCard extends StatelessWidget {
  const _PaceIndexCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: HomePage.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Índice Pace',
                style: TextStyle(
                  color: HomePage.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              Text(
                '72 / 100',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: Colors.white.withOpacity(0.10),
                ),
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HomePage.blue,
                          Color(0xFF3C8DFF),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: 15,
                color: HomePage.yellow,
              ),
              SizedBox(width: 6),
              Text(
                'Evolução consistente nesta semana',
                style: TextStyle(
                  color: HomePage.textSoft,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MINI MÉTRICA
// ============================================================================

class _MiniMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDCE8F4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: HomePage.blue,
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: HomePage.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF71849C),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ÍCONE ATIVIDADE
// ============================================================================

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: HomePage.blue,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.show_chart_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

// ============================================================================
// CARDS FLUTUANTES
// ============================================================================

class _FloatingGoalCard extends StatelessWidget {
  const _FloatingGoalCard();

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingIcon(
            icon: Icons.check_rounded,
            accent: HomePage.blue,
          ),

          SizedBox(width: 11),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'META CONCLUÍDA',
                style: TextStyle(
                  color: HomePage.blue,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Mais um passo completo',
                style: TextStyle(
                  color: HomePage.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingFocusCard extends StatelessWidget {
  const _FloatingFocusCard();

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingIcon(
            icon: Icons.timer_rounded,
            accent: HomePage.yellow,
          ),

          SizedBox(width: 11),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOCO',
                style: TextStyle(
                  color: Color(0xFF9B7000),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              SizedBox(height: 3),
              Text(
                '25 min concluídos',
                style: TextStyle(
                  color: HomePage.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingCommunityCard extends StatelessWidget {
  const _FloatingCommunityCard();

  @override
  Widget build(BuildContext context) {
    return _FloatingCard(
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingIcon(
            icon: Icons.groups_rounded,
            accent: HomePage.blueDark,
          ),

          SizedBox(width: 11),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMUNIDADE',
                style: TextStyle(
                  color: HomePage.blueDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Evolua junto',
                style: TextStyle(
                  color: HomePage.navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final Widget child;

  const _FloatingCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD8E5F2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _FloatingIcon({
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.11),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: accent,
        size: 20,
      ),
    );
  }
}

// ============================================================================
// PREVIEW MOBILE
// ============================================================================

class _MobileProductPreview extends StatelessWidget {
  const _MobileProductPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2245),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.dashboard_rounded,
                color: HomePage.yellow,
                size: 18,
              ),

              SizedBox(width: 8),

              Text(
                'Seu espaço no Pace',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 17),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ÍNDICE PACE',
                  style: TextStyle(
                    color: HomePage.blueSoft,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),

                SizedBox(height: 7),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '72',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(width: 4),

                    Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        '/100',
                        style: TextStyle(
                          color: HomePage.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    Spacer(),

                    Icon(
                      Icons.trending_up_rounded,
                      color: HomePage.yellow,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const Row(
            children: [
              Expanded(
                child: _MobileMetric(
                  value: '8',
                  label: 'Metas',
                ),
              ),
              SizedBox(width: 9),
              Expanded(
                child: _MobileMetric(
                  value: '4h',
                  label: 'Foco',
                ),
              ),
              SizedBox(width: 9),
              Expanded(
                child: _MobileMetric(
                  value: '12',
                  label: 'Sequência',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileMetric extends StatelessWidget {
  final String value;
  final String label;

  const _MobileMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: HomePage.textMuted,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BADGE
// ============================================================================

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: HomePage.blue.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HomePage.blue.withOpacity(0.28),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BadgeMark(),

          SizedBox(width: 9),

          Text(
            'DESENVOLVIMENTO PESSOAL',
            style: TextStyle(
              color: HomePage.blueSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeMark extends StatelessWidget {
  const _BadgeMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 3,
      decoration: BoxDecoration(
        color: HomePage.yellow,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

// ============================================================================
// BENEFÍCIO DESKTOP
// ============================================================================

class _DesktopBenefit extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DesktopBenefit({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: HomePage.blue.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: HomePage.blueSoft,
            size: 17,
          ),
        ),

        const SizedBox(width: 8),

        Text(
          text,
          style: const TextStyle(
            color: HomePage.textSoft,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BENEFÍCIO MOBILE
// ============================================================================

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Feature({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: HomePage.blue.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: HomePage.blueSoft,
              size: 21,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BOTÃO NAVBAR
// ============================================================================

class _TopButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool outlined;
  final bool compact;

  const _TopButton({
    required this.text,
    required this.onTap,
    required this.compact,
    this.outlined = false,
  });

  @override
  State<_TopButton> createState() => _TopButtonState();
}

class _TopButtonState extends State<_TopButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => hover = true);
      },
      onExit: (_) {
        setState(() => hover = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) {
          setState(() => pressed = true);
        },
        onTapUp: (_) {
          setState(() => pressed = false);
        },
        onTapCancel: () {
          setState(() => pressed = false);
        },
        child: AnimatedScale(
          scale: pressed
              ? 0.97
              : hover
                  ? 1.025
                  : 1,
          duration: const Duration(
            milliseconds: 130,
          ),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 170,
            ),
            height: widget.compact ? 39 : 42,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 12 : 18,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.outlined
                  ? hover
                      ? Colors.white.withOpacity(0.06)
                      : Colors.transparent
                  : hover
                      ? const Color(0xFF2D79EB)
                      : HomePage.blue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.outlined
                    ? Colors.white.withOpacity(
                        hover ? 0.75 : 0.25,
                      )
                    : HomePage.blue,
              ),
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                color: widget.outlined
                    ? Colors.white
                    : Colors.white,
                fontSize: widget.compact ? 11 : 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BOTÃO PRINCIPAL
// ============================================================================

class _MainButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _MainButton({
    required this.text,
    required this.onTap,
  });

  @override
  State<_MainButton> createState() => _MainButtonState();
}

class _MainButtonState extends State<_MainButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => hover = true);
      },
      onExit: (_) {
        setState(() => hover = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) {
          setState(() => pressed = true);
        },
        onTapUp: (_) {
          setState(() => pressed = false);
        },
        onTapCancel: () {
          setState(() => pressed = false);
        },
        child: AnimatedScale(
          scale: pressed
              ? 0.98
              : hover
                  ? 1.015
                  : 1,
          duration: const Duration(
            milliseconds: 130,
          ),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              color: hover
                  ? const Color(0xFF2E7DF0)
                  : HomePage.blue,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFF4C91F2),
              ),
              boxShadow: [
                BoxShadow(
                  color: HomePage.blue.withOpacity(
                    hover ? 0.30 : 0.20,
                  ),
                  blurRadius: hover ? 24 : 17,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(width: 10),

                AnimatedSlide(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  offset: hover
                      ? const Offset(0.18, 0)
                      : Offset.zero,
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BOTÃO SECUNDÁRIO
// ============================================================================

class _SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.text,
    required this.onTap,
  });

  @override
  State<_SecondaryButton> createState() =>
      _SecondaryButtonState();
}

class _SecondaryButtonState
    extends State<_SecondaryButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => hover = true);
      },
      onExit: (_) {
        setState(() => hover = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) {
          setState(() => pressed = true);
        },
        onTapUp: (_) {
          setState(() => pressed = false);
        },
        onTapCancel: () {
          setState(() => pressed = false);
        },
        child: AnimatedScale(
          scale: pressed
              ? 0.98
              : hover
                  ? 1.015
                  : 1,
          duration: const Duration(
            milliseconds: 130,
          ),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            width: double.infinity,
            height: 55,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hover
                  ? Colors.white.withOpacity(0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(
                  hover ? 0.50 : 0.20,
                ),
              ),
            ),
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DETALHES DE FUNDO
// ============================================================================

class _GridPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;

    const double spacing = 34;

    for (
      double x = 0;
      x <= size.width;
      x += spacing
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (
      double y = 0;
      y <= size.height;
      y += spacing
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final bluePaint = Paint()
      ..color = HomePage.blue.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final yellowPaint = Paint()
      ..color = HomePage.yellow.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    final pathBlue = Path()
      ..moveTo(size.width * 0.32, size.height)
      ..lineTo(size.width, size.height * 0.20)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      pathBlue,
      bluePaint,
    );

    final pathYellow = Path()
      ..moveTo(size.width * 0.72, size.height)
      ..lineTo(size.width, size.height * 0.73)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      pathYellow,
      yellowPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}