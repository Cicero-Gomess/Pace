import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ============================================================
  // CORES
  // ============================================================

  static const Color navy = Color(0xFF06152E);
  static const Color navyDeep = Color(0xFF041126);
  static const Color navyLight = Color(0xFF0A234A);

  static const Color blue = Color(0xFF174B9C);
  static const Color blueMedium = Color(0xFF123E80);

  static const Color cyan = Color(0xFF58D4E5);
  static const Color cyanLight = Color(0xFF8CECF3);

  static const Color textSoft = Color(0xFFC8D5E7);
  static const Color textMuted = Color(0xFF9EB0C8);

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
        final bool compact = width <= 380;

        return Container(
          width: double.infinity,
          color: navyDeep,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1360,
              ),
              child: Container(
                height: mobile ? 70 : 80,
                padding: EdgeInsets.symmetric(
                  horizontal: mobile ? 18 : 38,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // LOGO
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
                        child: Image.asset(
                          'assets/images/pace_icon.png',
                          width: mobile ? 46 : 52,
                          height: mobile ? 46 : 52,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ENTRAR
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
                      width: mobile ? 9 : 12,
                    ),

                    // CADASTRO
                    _TopButton(
                      text: 'Cadastre-se',
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

        // Dashboard só aparece em telas realmente grandes.
        final bool desktop = width >= 1050;

        final bool tablet = width >= 700 && width < 1050;
        final bool smallMobile = width <= 380;

        return Stack(
          fit: StackFit.expand,
          children: [
            // ======================================================
            // BACKGROUND
            // ======================================================

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    0,
                    0.34,
                    0.68,
                    1,
                  ],
                  colors: [
                    Color(0xFF1D55A5),
                    Color(0xFF123E80),
                    Color(0xFF092653),
                    Color(0xFF05152F),
                  ],
                ),
              ),
            ),

            // ======================================================
            // GLOWS
            // ======================================================

            Positioned(
              top: -220,
              left: -170,
              child: _Glow(
                size: desktop ? 560 : 400,
                color: const Color(0xFF397DE4).withOpacity(0.22),
              ),
            ),

            Positioned(
              top: 20,
              right: -200,
              child: _Glow(
                size: desktop ? 560 : 380,
                color: cyan.withOpacity(0.13),
              ),
            ),

            Positioned(
              bottom: -250,
              left: desktop ? width * 0.32 : -140,
              child: _Glow(
                size: desktop ? 650 : 420,
                color: const Color(0xFF1768CF).withOpacity(0.12),
              ),
            ),

            // ======================================================
            // DETALHES
            // ======================================================

            Positioned(
              top: desktop ? 130 : 250,
              right: desktop ? 120 : 45,
              child: const _TinyGlow(),
            ),

            Positioned(
              bottom: desktop ? 100 : 150,
              left: desktop ? 90 : 55,
              child: const _TinyGlow(),
            ),

            // ======================================================
            // CONTEÚDO
            // ======================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 1360,
                    minHeight: height,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop
                          ? 48
                          : tablet
                              ? 42
                              : smallMobile
                                  ? 20
                                  : 26,
                      vertical: desktop ? 48 : 42,
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
        // ========================================================
        // LADO ESQUERDO
        // ========================================================

        Expanded(
          flex: 10,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 610,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroBadge(),

                const SizedBox(height: 30),

                const Text(
                  'Organize sua vida.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 58,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -2.5,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Construa sua\nmelhor versão.',
                  style: TextStyle(
                    color: cyanLight,
                    fontSize: 58,
                    fontWeight: FontWeight.w800,
                    height: 1.04,
                    letterSpacing: -2.5,
                  ),
                ),

                const SizedBox(height: 27),

                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 550,
                  ),
                  child: const Text(
                    'Uma rede social feita para quem busca disciplina, '
                    'foco e uma comunidade que cresce junta todos os dias.',
                    style: TextStyle(
                      color: textSoft,
                      fontSize: 17,
                      height: 1.7,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    SizedBox(
                      width: 220,
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
                      width: 210,
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

                const SizedBox(height: 40),

                const Wrap(
                  spacing: 24,
                  runSpacing: 18,
                  children: [
                    _DesktopBenefit(
                      icon: Icons.track_changes_rounded,
                      text: 'Metas com propósito',
                    ),
                    _DesktopBenefit(
                      icon: Icons.groups_rounded,
                      text: 'Comunidade ativa',
                    ),
                    _DesktopBenefit(
                      icon: Icons.trending_up_rounded,
                      text: 'Evolução constante',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 80),

        // ========================================================
        // DASHBOARD DIREITO
        // ========================================================

        const Expanded(
          flex: 9,
          child: _JourneyVisual(),
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
          maxWidth: 560,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeroBadge(),

            SizedBox(
              height: smallMobile ? 28 : 36,
            ),

            Text(
              'Organize sua vida.',
              style: TextStyle(
                color: Colors.white,
                fontSize: smallMobile ? 36 : 42,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -1.7,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Construa sua\nmelhor versão.',
              style: TextStyle(
                color: cyanLight,
                fontSize: smallMobile ? 36 : 42,
                fontWeight: FontWeight.w800,
                height: 1.06,
                letterSpacing: -1.7,
              ),
            ),

            SizedBox(
              height: smallMobile ? 25 : 31,
            ),

            Text(
              'Uma rede social feita para quem busca disciplina, '
              'foco e uma comunidade que cresce junta todos os dias.',
              style: TextStyle(
                color: textSoft,
                fontSize: smallMobile ? 15 : 16,
                height: 1.7,
              ),
            ),

            SizedBox(
              height: smallMobile ? 28 : 34,
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

            const SizedBox(height: 14),

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
              height: smallMobile ? 35 : 43,
            ),

            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Feature(
                    icon: Icons.track_changes_rounded,
                    text: 'Metas com\npropósito',
                  ),
                ),

                SizedBox(width: 8),

                Expanded(
                  child: _Feature(
                    icon: Icons.groups_rounded,
                    text: 'Comunidade\nativa',
                  ),
                ),

                SizedBox(width: 8),

                Expanded(
                  child: _Feature(
                    icon: Icons.trending_up_rounded,
                    text: 'Evolução\nconstante',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD DESKTOP
// ============================================================================

class _JourneyVisual extends StatelessWidget {
  const _JourneyVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 560,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Glow atrás do dashboard
          Positioned(
            child: Container(
              width: 470,
              height: 470,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    HomePage.cyan.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Dashboard
          Container(
            width: 445,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.13),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.09),
                  Colors.white.withOpacity(0.03),
                ],
              ),
              color: const Color(0xFF071B3C).withOpacity(0.92),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 55,
                  offset: const Offset(0, 25),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _JourneyHeader(),

                SizedBox(height: 28),

                _ProgressCard(),

                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _StatisticCard(
                        value: '08',
                        label: 'Metas ativas',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatisticCard(
                        value: '24',
                        label: 'Dias em foco',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatisticCard(
                        value: '05',
                        label: 'Comunidades',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ========================================================
          // CARD PROGRESSO
          // ========================================================

          const Positioned(
            top: 26,
            left: -18,
            child: _FloatingInfoCard(
              icon: Icons.check_rounded,
              smallTitle: 'Progresso',
              title: 'Mais um passo concluído',
            ),
          ),

          // ========================================================
          // CARD SEQUÊNCIA
          // ========================================================

          const Positioned(
            top: 110,
            right: -35,
            child: _StreakCard(),
          ),

          // ========================================================
          // CARD COMUNIDADE
          // ========================================================

          const Positioned(
            right: -15,
            bottom: 35,
            child: _CommunityCard(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HEADER DO DASHBOARD
// ============================================================================

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUA JORNADA',
                style: TextStyle(
                  color: HomePage.cyanLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Evolua todos os dias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: HomePage.cyan,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: HomePage.cyan.withOpacity(0.35),
                blurRadius: 10,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PROGRESSO
// ============================================================================

class _ProgressCard extends StatelessWidget {
  const _ProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Progresso semanal',
                  style: TextStyle(
                    color: HomePage.textSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '72%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 9,
              child: Stack(
                children: [
                  Container(
                    color: Colors.white.withOpacity(0.12),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.72,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            HomePage.cyan,
                            HomePage.cyanLight,
                          ],
                        ),
                      ),
                    ),
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

// ============================================================================
// ESTATÍSTICA
// ============================================================================

class _StatisticCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatisticCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.09),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            label,
            style: const TextStyle(
              color: HomePage.textSoft,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CARD FLUTUANTE
// ============================================================================

class _FloatingInfoCard extends StatelessWidget {
  final IconData icon;
  final String smallTitle;
  final String title;

  const _FloatingInfoCard({
    required this.icon,
    required this.smallTitle,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: _floatingDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 41,
            height: 41,
            decoration: BoxDecoration(
              color: HomePage.cyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: HomePage.cyanLight,
            ),
          ),

          const SizedBox(width: 11),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                smallTitle,
                style: const TextStyle(
                  color: HomePage.textMuted,
                  fontSize: 10.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
// STREAK
// ============================================================================

class _StreakCard extends StatelessWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: _floatingDecoration(),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '12',
            style: TextStyle(
              color: HomePage.cyanLight,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sequência',
                style: TextStyle(
                  color: HomePage.textMuted,
                  fontSize: 10.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Dias de evolução',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
// COMUNIDADE
// ============================================================================

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: _floatingDecoration(),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AvatarGroup(),

          SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comunidade',
                style: TextStyle(
                  color: HomePage.textMuted,
                  fontSize: 10.5,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Cresça junto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
// AVATARES
// ============================================================================

class _AvatarGroup extends StatelessWidget {
  const _AvatarGroup();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 34,
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            child: _Avatar(
              text: 'JS',
              color: Color(0xFF315CAC),
            ),
          ),
          const Positioned(
            left: 22,
            child: _Avatar(
              text: 'PY',
              color: Color(0xFF22427D),
            ),
          ),
          Positioned(
            left: 44,
            child: _Avatar(
              text: '+',
              color: HomePage.cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String text;
  final Color color;

  const _Avatar({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF0B2551),
          width: 2,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================================
// DECORAÇÃO DOS CARDS
// ============================================================================

BoxDecoration _floatingDecoration() {
  return BoxDecoration(
    color: const Color(0xFF071938).withOpacity(0.96),
    borderRadius: BorderRadius.circular(17),
    border: Border.all(
      color: Colors.white.withOpacity(0.12),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.27),
        blurRadius: 28,
        offset: const Offset(0, 13),
      ),
    ],
  );
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
        horizontal: 15,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF071E43).withOpacity(0.75),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: HomePage.cyan.withOpacity(0.32),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BadgeDot(),
          SizedBox(width: 10),
          Text(
            'EVOLUA NO SEU RITMO',
            style: TextStyle(
              color: HomePage.cyanLight,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
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
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: HomePage.cyan.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HomePage.cyan.withOpacity(0.13),
            ),
          ),
          child: Icon(
            icon,
            color: HomePage.cyanLight,
            size: 19,
          ),
        ),

        const SizedBox(width: 9),

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
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF0D2A56).withOpacity(0.75),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.09),
            ),
          ),
          child: Icon(
            icon,
            color: HomePage.cyanLight,
            size: 29,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// NAV BUTTON
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
              ? 0.96
              : hover
                  ? 1.03
                  : 1,
          duration: const Duration(milliseconds: 130),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: widget.compact ? 39 : 42,
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 13 : 18,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.outlined
                  ? hover
                      ? Colors.white.withOpacity(0.07)
                      : Colors.transparent
                  : hover
                      ? HomePage.cyanLight
                      : HomePage.cyan,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: widget.outlined
                    ? hover
                        ? Colors.white
                        : Colors.white.withOpacity(0.60)
                    : HomePage.cyanLight.withOpacity(0.45),
              ),
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                color: widget.outlined
                    ? HomePage.cyanLight
                    : Colors.white,
                fontSize: widget.compact ? 11.5 : 13,
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
                  ? 1.018
                  : 1,
          duration: const Duration(milliseconds: 130),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: hover
                    ? [
                        HomePage.cyanLight,
                        HomePage.cyan,
                      ]
                    : [
                        const Color(0xFF57D5E9),
                        const Color(0xFF53C5D9),
                      ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: HomePage.cyanLight.withOpacity(0.65),
              ),
              boxShadow: [
                BoxShadow(
                  color: HomePage.cyan.withOpacity(
                    hover ? 0.24 : 0.14,
                  ),
                  blurRadius: hover ? 30 : 22,
                  offset: const Offset(0, 10),
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
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(width: 13),

                AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  offset: hover
                      ? const Offset(0.18, 0)
                      : Offset.zero,
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 21,
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
                  ? 1.018
                  : 1,
          duration: const Duration(milliseconds: 130),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hover
                  ? Colors.white
                  : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: hover
                    ? Colors.white
                    : HomePage.cyanLight.withOpacity(0.78),
              ),
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                color: hover
                    ? HomePage.navyLight
                    : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DECORAÇÕES
// ============================================================================

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyGlow extends StatelessWidget {
  const _TinyGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: HomePage.cyanLight,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: HomePage.cyan,
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeDot extends StatelessWidget {
  const _BadgeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: HomePage.cyan,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: HomePage.cyan,
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}