import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color azulPrincipal = Color(0xFF3059AA);
  static const Color azulEscuro = Color(0xFF1E3C72);
  static const Color azulClaro = Color(0xFF5EB1BF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 768;

          return Column(
            children: [
              _buildNavbar(context, isMobile),
              Expanded(child: _buildHero(context, isMobile)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavbar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: azulPrincipal,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Image.asset(
                'assets/images/Ícone_Pace.png',
                height: isMobile ? 40 : 50,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Row(
            children: [
              BotaoEntrarHover(
                compact: isMobile,
                onTap: () {
                  Navigator.pushNamed(context, '/entrar');
                },
              ),
              SizedBox(width: isMobile ? 12 : 20),
              BotaoCadastroHover(
                compact: isMobile,
                onTap: () {
                  Navigator.pushNamed(context, '/cadastro');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [azulPrincipal, azulEscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Center(
              child: SizedBox(
                width: isMobile ? double.infinity : 600,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: isMobile ? 32 : 50,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        children: const [
                          TextSpan(
                            text: "Organize sua vida.\n",
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: "Construa sua melhor versão.",
                            style: TextStyle(color: azulClaro),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isMobile ? 16 : 20),
                    Text(
                      "Uma rede social feita para quem busca disciplina, foco e uma comunidade que cresce junta todos os dias.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        height: 1.6,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isMobile ? 24 : 30),
                    if (isMobile)
                      Column(
                        children: [
                          BotaoPrincipalHover(
                            texto: "Começar Agora",
                            compact: true,
                            onTap: () {
                              Navigator.pushNamed(context, '/cadastro');
                            },
                          ),
                          const SizedBox(height: 14),
                          BotaoSecundarioHover(
                            texto: "Entrar",
                            compact: true,
                            onTap: () {
                              Navigator.pushNamed(context, '/entrar');
                            },
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BotaoPrincipalHover(
                            texto: "Começar Agora",
                            onTap: () {
                              Navigator.pushNamed(context, '/cadastro');
                            },
                          ),
                          const SizedBox(width: 20),
                          BotaoSecundarioHover(
                            texto: "Entrar",
                            onTap: () {
                              Navigator.pushNamed(context, '/entrar');
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BotaoEntrarHover extends StatefulWidget {
  final VoidCallback? onTap;
  final bool compact;

  const BotaoEntrarHover({
    super.key,
    this.onTap,
    this.compact = false,
  });

  @override
  State<BotaoEntrarHover> createState() => _BotaoEntrarHoverState();
}

class _BotaoEntrarHoverState extends State<BotaoEntrarHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final double horizontal = widget.compact ? 14 : 18;
    final double vertical = widget.compact ? 7 : 8;
    final double fontSize = widget.compact ? 14 : 16;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          decoration: BoxDecoration(
            color: _hover ? Colors.white : Colors.transparent,
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: _hover ? HomePage.azulPrincipal : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
            child: const Text("Entrar"),
          ),
        ),
      ),
    );
  }
}

class BotaoCadastroHover extends StatefulWidget {
  final VoidCallback? onTap;
  final bool compact;

  const BotaoCadastroHover({
    super.key,
    this.onTap,
    this.compact = false,
  });

  @override
  State<BotaoCadastroHover> createState() => _BotaoCadastroHoverState();
}

class _BotaoCadastroHoverState extends State<BotaoCadastroHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final double horizontal = widget.compact ? 14 : 18;
    final double vertical = widget.compact ? 7 : 8;
    final double fontSize = widget.compact ? 14 : 16;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          decoration: BoxDecoration(
            color: HomePage.azulClaro,
            borderRadius: BorderRadius.circular(20),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            "Cadastre-se",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}

class BotaoPrincipalHover extends StatefulWidget {
  final String texto;
  final VoidCallback? onTap;
  final bool compact;

  const BotaoPrincipalHover({
    super.key,
    required this.texto,
    this.onTap,
    this.compact = false,
  });

  @override
  State<BotaoPrincipalHover> createState() => _BotaoPrincipalHoverState();
}

class _BotaoPrincipalHoverState extends State<BotaoPrincipalHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final double horizontal = widget.compact ? 22 : 25;
    final double vertical = widget.compact ? 11 : 12;
    final double fontSize = widget.compact ? 15 : 16;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hover ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
            decoration: BoxDecoration(
              color: _hover ? HomePage.azulPrincipal : HomePage.azulClaro,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              widget.texto,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BotaoSecundarioHover extends StatefulWidget {
  final String texto;
  final VoidCallback? onTap;
  final bool compact;

  const BotaoSecundarioHover({
    super.key,
    required this.texto,
    this.onTap,
    this.compact = false,
  });

  @override
  State<BotaoSecundarioHover> createState() => _BotaoSecundarioHoverState();
}

class _BotaoSecundarioHoverState extends State<BotaoSecundarioHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final double horizontal = widget.compact ? 26 : 32;
    final double vertical = widget.compact ? 12 : 14;
    final double fontSize = widget.compact ? 15 : 16;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          decoration: BoxDecoration(
            color: _hover ? Colors.white : Colors.transparent,
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(30),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: _hover ? HomePage.azulPrincipal : Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
            child: Text(widget.texto),
          ),
        ),
      ),
    );
  }
}
