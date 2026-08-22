import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EntrarPage extends StatefulWidget {
  const EntrarPage({super.key});

  @override
  State<EntrarPage> createState() => _EntrarPageState();
}

class _EntrarPageState extends State<EntrarPage> {
  // ============================================================
  // CORES
  // ============================================================

  static const Color navy = Color(0xFF06152E);
  static const Color navyDeep = Color(0xFF041126);
  static const Color navyLight = Color(0xFF0A234A);

  static const Color blue = Color(0xFF315CAC);
  static const Color blueMedium = Color(0xFF234884);
  static const Color blueDark = Color(0xFF102A58);

  static const Color cyan = Color(0xFF69C5D0);
  static const Color cyanLight = Color(0xFF9CE8EF);

  static const Color textSoft = Color(0xFFDCE7F5);
  static const Color textMuted = Color(0xFFAEBED1);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _senhaController =
      TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _senhaFocus = FocusNode();

  // ============================================================
  // ESTADOS
  // ============================================================

  bool _carregando = false;
  bool _mostrarSenha = false;
  bool _lembrarDeMim = false;

  String _mensagem = '';
  Color _corMensagem = Colors.red;

  // ============================================================
  // API
  // ============================================================

  String get apiUrl => ApiConfig.baseUrl;

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _fazerLogin() async {
    if (_carregando) return;

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final senha = _senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        _mensagem = 'Por favor, preencha email e senha.';
        _corMensagem = const Color(0xFFD97706);
      });

      return;
    }

    setState(() {
      _carregando = true;
      _mensagem = '';
    });

    try {
      final tokenResponse = await http
          .post(
            Uri.parse('$apiUrl/auth/token'),
            headers: {
              'Content-Type':
                  'application/x-www-form-urlencoded',
            },
            body: {
              'username': email,
              'password': senha,
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );

      Map<String, dynamic> tokenData;

      try {
        tokenData = jsonDecode(tokenResponse.body);
      } catch (_) {
        throw Exception(
          'Erro inesperado no servidor.',
        );
      }

      if (tokenResponse.statusCode != 200) {
        final error =
            tokenData['detail'] ??
            'Email ou senha incorretos.';

        throw Exception(error);
      }

      final accessToken =
          tokenData['access_token'];

      if (accessToken == null ||
          accessToken.toString().isEmpty) {
        throw Exception(
          'Token não recebido do servidor.',
        );
      }

      // ========================================================
      // USUÁRIO
      // ========================================================

      final meResponse = await http
          .get(
            Uri.parse('$apiUrl/auth/me'),
            headers: {
              'Authorization':
                  'Bearer $accessToken',
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );

      Map<String, dynamic> usuarioData;

      try {
        usuarioData =
            jsonDecode(meResponse.body);
      } catch (_) {
        throw Exception(
          'Erro ao obter os dados do usuário.',
        );
      }

      if (meResponse.statusCode != 200) {
        throw Exception(
          usuarioData['detail'] ??
              'Erro ao obter usuário.',
        );
      }

      // ========================================================
      // SALVAR LOGIN
      // ========================================================

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'token',
        accessToken.toString(),
      );

      await prefs.setString(
        'usuarioLogado',
        jsonEncode(usuarioData),
      );

      await prefs.setBool(
        'lembrarDeMim',
        _lembrarDeMim,
      );

      if (!mounted) return;

      setState(() {
        _mensagem =
            'Login realizado com sucesso!';
        _corMensagem =
            const Color(0xFF169B62);
      });

      await Future.delayed(
        const Duration(milliseconds: 450),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/feed',
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem =
          e
              .toString()
              .replaceFirst(
                'Exception: ',
                '',
              );

      setState(() {
        _mensagem = mensagem;
        _corMensagem =
            const Color(0xFFB42318);
      });

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: Text(mensagem),
              backgroundColor:
                  const Color(0xFFB42318),
              behavior:
                  SnackBarBehavior.floating,
              duration:
                  const Duration(seconds: 3),
            ),
          );
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // ============================================================
  // ESQUECI A SENHA
  // ============================================================

  void _esqueciMinhaSenha() {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
          const SnackBar(
            content: Text(
              'A recuperação de senha ainda não está disponível.',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();

    _emailFocus.dispose();
    _senhaFocus.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildNavbar(),
            Expanded(
              child: _buildPage(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAVBAR
  // ============================================================

  Widget _buildNavbar() {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final width =
            constraints.maxWidth;

        final mobile =
            width < 700;

        final compact =
            width <= 380;

        return Container(
          width: double.infinity,
          color: navyDeep,
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 1360,
              ),
              child: Container(
                height:
                    mobile ? 70 : 80,
                padding:
                    EdgeInsets.symmetric(
                  horizontal:
                      mobile ? 18 : 38,
                ),
                decoration:
                    BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white
                          .withOpacity(
                            0.08,
                          ),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // LOGO
                    MouseRegion(
                      cursor:
                          SystemMouseCursors
                              .click,
                      child:
                          GestureDetector(
                        onTap: () {
                          Navigator
                              .pushNamedAndRemoveUntil(
                            context,
                            '/',
                            (route) =>
                                false,
                          );
                        },
                        child:
                            Image.asset(
                          'assets/images/pace_icon.png',
                          width: mobile
                              ? 46
                              : 52,
                          height: mobile
                              ? 46
                              : 52,
                          fit:
                              BoxFit.contain,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Texto desktop
                    if (!mobile) ...[
                      const Text(
                        'Ainda não tem uma conta?',
                        style: TextStyle(
                          color:
                              Color(
                            0xFFC1CDE0,
                          ),
                          fontSize: 13,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),

                      const SizedBox(
                        width: 18,
                      ),
                    ],

                    _NavbarButton(
                      text:
                          'Cadastre-se',
                      compact: compact,
                      onTap: () {
                        Navigator
                            .pushNamed(
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
  // PÁGINA
  // ============================================================

  Widget _buildPage() {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final width =
            constraints.maxWidth;

        final height =
            constraints.maxHeight;

        // A parte visual só entra
        // quando realmente existe espaço.
        final desktop =
            width >= 1050;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Fundo base
            const DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topLeft,
                  end: Alignment
                      .bottomRight,
                  colors: [
                    Color(
                      0xFF1D55A5,
                    ),
                    Color(
                      0xFF123E80,
                    ),
                    Color(
                      0xFF092653,
                    ),
                    Color(
                      0xFF05152F,
                    ),
                  ],
                  stops: [
                    0,
                    0.34,
                    0.68,
                    1,
                  ],
                ),
              ),
            ),

            // Glow
            Positioned(
              top: -200,
              left: -180,
              child: _Glow(
                size:
                    desktop ? 560 : 430,
                color:
                    const Color(
                  0xFF397DE4,
                ).withOpacity(
                  0.22,
                ),
              ),
            ),

            Positioned(
              right: -180,
              bottom: -190,
              child: _Glow(
                size:
                    desktop ? 570 : 430,
                color: cyan
                    .withOpacity(
                      0.10,
                    ),
              ),
            ),

            // Pontos decorativos
            const Positioned(
              left: 70,
              bottom: 100,
              child: _TinyGlow(),
            ),

            if (desktop)
              const Positioned(
                right: 100,
                top: 120,
                child: _TinyGlow(),
              ),

            // Conteúdo
            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    maxWidth: 1360,
                    minHeight: height,
                  ),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(
                      horizontal:
                          desktop
                              ? 48
                              : 20,
                      vertical:
                          desktop
                              ? 46
                              : 32,
                    ),
                    child: desktop
                        ? _buildDesktop()
                        : _buildMobile(),
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

  Widget _buildDesktop() {
    return Row(
      children: [
        // ======================================================
        // LADO VISUAL
        // ======================================================

        const Expanded(
          flex: 10,
          child: _LoginPresentation(),
        ),

        const SizedBox(width: 70),

        // ======================================================
        // FORMULÁRIO
        // ======================================================

        Expanded(
          flex: 9,
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 500,
              ),
              child: _LoginCard(
                emailController:
                    _emailController,
                senhaController:
                    _senhaController,
                emailFocus:
                    _emailFocus,
                senhaFocus:
                    _senhaFocus,
                carregando:
                    _carregando,
                mostrarSenha:
                    _mostrarSenha,
                lembrarDeMim:
                    _lembrarDeMim,
                mensagem:
                    _mensagem,
                corMensagem:
                    _corMensagem,
                onMostrarSenha: () {
                  setState(() {
                    _mostrarSenha =
                        !_mostrarSenha;
                  });
                },
                onLembrarChanged:
                    (value) {
                  setState(() {
                    _lembrarDeMim =
                        value;
                  });
                },
                onLogin:
                    _fazerLogin,
                onForgotPassword:
                    _esqueciMinhaSenha,
                onCadastro: () {
                  Navigator
                      .pushNamed(
                    context,
                    '/cadastro',
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE / TABLET
  // ============================================================

  Widget _buildMobile() {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 520,
        ),
        child: Column(
          children: [
            // Pequeno título superior
            const _MobileWelcome(),

            const SizedBox(
              height: 28,
            ),

            _LoginCard(
              emailController:
                  _emailController,
              senhaController:
                  _senhaController,
              emailFocus:
                  _emailFocus,
              senhaFocus:
                  _senhaFocus,
              carregando:
                  _carregando,
              mostrarSenha:
                  _mostrarSenha,
              lembrarDeMim:
                  _lembrarDeMim,
              mensagem:
                  _mensagem,
              corMensagem:
                  _corMensagem,
              onMostrarSenha: () {
                setState(() {
                  _mostrarSenha =
                      !_mostrarSenha;
                });
              },
              onLembrarChanged:
                  (value) {
                setState(() {
                  _lembrarDeMim =
                      value;
                });
              },
              onLogin:
                  _fazerLogin,
              onForgotPassword:
                  _esqueciMinhaSenha,
              onCadastro: () {
                Navigator.pushNamed(
                  context,
                  '/cadastro',
                );
              },
            ),

            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// APRESENTAÇÃO DESKTOP
// ============================================================

class _LoginPresentation
    extends StatelessWidget {
  const _LoginPresentation();

  @override
  Widget build(
    BuildContext context,
  ) {
    return ConstrainedBox(
      constraints:
          const BoxConstraints(
        maxWidth: 580,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFF071E43,
              ).withOpacity(
                0.72,
              ),
              borderRadius:
                  BorderRadius.circular(
                999,
              ),
              border: Border.all(
                color:
                    _EntrarColors.cyan
                        .withOpacity(
                  0.34,
                ),
              ),
            ),
            child: const Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                _BadgeDot(),

                SizedBox(
                  width: 10,
                ),

                Text(
                  'CONTINUE DE ONDE PAROU',
                  style: TextStyle(
                    color:
                        _EntrarColors
                            .cyanLight,
                    fontSize: 12,
                    fontWeight:
                        FontWeight
                            .w800,
                    letterSpacing:
                        0.7,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 31,
          ),

          const Text(
            'Seu progresso',
            style: TextStyle(
              color:
                  Colors.white,
              fontSize: 58,
              fontWeight:
                  FontWeight.w800,
              height: 1,
              letterSpacing:
                  -2.5,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'continua aqui.',
            style: TextStyle(
              color:
                  _EntrarColors
                      .cyanLight,
              fontSize: 58,
              fontWeight:
                  FontWeight.w800,
              height: 1,
              letterSpacing:
                  -2.5,
            ),
          ),

          const SizedBox(
            height: 27,
          ),

           ConstrainedBox(
            constraints:
                BoxConstraints(
              maxWidth: 500,
            ),
            child: Text(
              'Entre na sua conta e retome suas metas, '
              'conexões e conquistas dentro do Pace.',
              style: TextStyle(
                color:
                    _EntrarColors
                        .textSoft,
                fontSize: 17,
                height: 1.7,
              ),
            ),
          ),

          const SizedBox(
            height: 34,
          ),

          const _PresentationCard(
            icon:
                Icons.check_rounded,
            kicker:
                'Organização',
            title:
                'Metas claras e consistentes',
          ),

          const SizedBox(
            height: 12,
          ),

          const _PresentationCard(
            number: '12',
            kicker:
                'Sequência atual',
            title:
                'Dias de evolução',
          ),

          const SizedBox(
            height: 12,
          ),

          const _CommunityPresentationCard(),
        ],
      ),
    );
  }
}

// ============================================================
// CARD APRESENTAÇÃO
// ============================================================

class _PresentationCard
    extends StatelessWidget {
  final IconData? icon;
  final String? number;

  final String kicker;
  final String title;

  const _PresentationCard({
    this.icon,
    this.number,
    required this.kicker,
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 430,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF071938,
        ).withOpacity(
          0.68,
        ),
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: Colors.white
              .withOpacity(
                0.11,
              ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(
                  0.14,
                ),
            blurRadius: 25,
            offset:
                const Offset(
              0,
              12,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          if (number != null)
            SizedBox(
              width: 43,
              child: Text(
                number!,
                style:
                    const TextStyle(
                  color:
                      _EntrarColors
                          .cyanLight,
                  fontSize: 26,
                  fontWeight:
                      FontWeight
                          .w800,
                  letterSpacing:
                      -1,
                ),
              ),
            )
          else
            Container(
              width: 42,
              height: 42,
              decoration:
                  BoxDecoration(
                color:
                    _EntrarColors
                        .cyan
                        .withOpacity(
                  0.12,
                ),
                borderRadius:
                    BorderRadius
                        .circular(
                  12,
                ),
              ),
              child: Icon(
                icon,
                color:
                    _EntrarColors
                        .cyanLight,
                size: 22,
              ),
            ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  kicker,
                  style:
                      const TextStyle(
                    color:
                        _EntrarColors
                            .textMuted,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize: 13.5,
                    fontWeight:
                        FontWeight
                            .w700,
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

// ============================================================
// CARD COMUNIDADE
// ============================================================

class _CommunityPresentationCard
    extends StatelessWidget {
  const _CommunityPresentationCard();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 430,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFF071938,
        ).withOpacity(
          0.68,
        ),
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: Colors.white
              .withOpacity(
                0.11,
              ),
        ),
      ),
      child: const Row(
        children: [
          _AvatarGroup(),

          SizedBox(
            width: 14,
          ),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                'Comunidade',
                style: TextStyle(
                  color:
                      _EntrarColors
                          .textMuted,
                  fontSize: 11,
                ),
              ),

              SizedBox(
                height: 4,
              ),

              Text(
                'Cresça junto com outras pessoas',
                style: TextStyle(
                  color:
                      Colors.white,
                  fontSize: 13.5,
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AVATARES
// ============================================================

class _AvatarGroup
    extends StatelessWidget {
  const _AvatarGroup();

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: 80,
      height: 36,
      child: Stack(
        children: const [
          Positioned(
            left: 0,
            child: _Avatar(
              text: 'JS',
              color:
                  Color(
                0xFF315CAC,
              ),
            ),
          ),
          Positioned(
            left: 23,
            child: _Avatar(
              text: 'PY',
              color:
                  Color(
                0xFF22427D,
              ),
            ),
          ),
          Positioned(
            left: 46,
            child: _Avatar(
              text: '+',
              color:
                  _EntrarColors
                      .cyan,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar
    extends StatelessWidget {
  final String text;
  final Color color;

  const _Avatar({
    required this.text,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 34,
      height: 34,
      alignment:
          Alignment.center,
      decoration:
          BoxDecoration(
        color: color,
        shape:
            BoxShape.circle,
        border: Border.all(
          color:
              const Color(
            0xFF0B2551,
          ),
          width: 2,
        ),
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight:
              FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// MOBILE WELCOME
// ============================================================

class _MobileWelcome
    extends StatelessWidget {
  const _MobileWelcome();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Column(
      children: [
        Text(
          'Bem-vindo de volta',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                _EntrarColors
                    .cyanLight,
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
            letterSpacing: 1,
          ),
        ),

        SizedBox(height: 10),

        Text(
          'Continue sua jornada.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight:
                FontWeight.w800,
            letterSpacing:
                -0.7,
          ),
        ),

        SizedBox(height: 8),

        Text(
          'Entre na sua conta e volte a evoluir.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                _EntrarColors
                    .textSoft,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// LOGIN CARD
// ============================================================

class _LoginCard
    extends StatelessWidget {
  final TextEditingController
      emailController;

  final TextEditingController
      senhaController;

  final FocusNode emailFocus;
  final FocusNode senhaFocus;

  final bool carregando;
  final bool mostrarSenha;
  final bool lembrarDeMim;

  final String mensagem;
  final Color corMensagem;

  final VoidCallback onMostrarSenha;
  final ValueChanged<bool>
      onLembrarChanged;

  final VoidCallback onLogin;
  final VoidCallback
      onForgotPassword;

  final VoidCallback onCadastro;

  const _LoginCard({
    required this.emailController,
    required this.senhaController,
    required this.emailFocus,
    required this.senhaFocus,
    required this.carregando,
    required this.mostrarSenha,
    required this.lembrarDeMim,
    required this.mensagem,
    required this.corMensagem,
    required this.onMostrarSenha,
    required this.onLembrarChanged,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onCadastro,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 30,
        vertical: 34,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFF9FBFE,
        ),
        borderRadius:
            BorderRadius.circular(
          28,
        ),
        border: Border.all(
          color:
              const Color(
            0xFF102A58,
          ).withOpacity(
            0.08,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(
              0xFF031126,
            ).withOpacity(
              0.28,
            ),
            blurRadius: 55,
            offset:
                const Offset(
              0,
              24,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          // Barrinha ciano
          Align(
            alignment:
                Alignment.topCenter,
            child: Container(
              width: 105,
              height: 3,
              decoration:
                  BoxDecoration(
                borderRadius:
                    BorderRadius
                        .circular(
                  999,
                ),
                gradient:
                    const LinearGradient(
                  colors: [
                    Colors.transparent,
                    _EntrarColors
                        .cyan,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          const Text(
            'BEM-VINDO DE VOLTA',
            style: TextStyle(
              color:
                  _EntrarColors.blue,
              fontSize: 11.5,
              fontWeight:
                  FontWeight.w800,
              letterSpacing:
                  0.9,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Text(
            'Entrar',
            style: TextStyle(
              color:
                  _EntrarColors.navy,
              fontSize: 39,
              fontWeight:
                  FontWeight.w800,
              height: 1,
              letterSpacing:
                  -1.5,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'Acesse sua conta para continuar sua jornada.',
            style: TextStyle(
              color:
                  Color(
                0xFF65758A,
              ),
              fontSize: 14.5,
              height: 1.5,
            ),
          ),

          const SizedBox(
            height: 31,
          ),

          // ====================================================
          // EMAIL
          // ====================================================

          const Text(
            'Email',
            style: TextStyle(
              color:
                  Color(
                0xFF24364E,
              ),
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          _LoginTextField(
            controller:
                emailController,
            focusNode:
                emailFocus,
            hint:
                'nome@exemplo.com',
            icon: Icons
                .alternate_email_rounded,
            keyboardType:
                TextInputType
                    .emailAddress,
            textInputAction:
                TextInputAction
                    .next,
            onSubmitted: (_) {
              senhaFocus
                  .requestFocus();
            },
          ),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // SENHA LABEL
          // ====================================================

          Row(
            children: [
              const Text(
                'Senha',
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF24364E,
                  ),
                  fontSize: 13,
                  fontWeight:
                      FontWeight
                          .w700,
                ),
              ),

              const Spacer(),

              _TextAction(
                text:
                    'Esqueci minha senha',
                onTap:
                    onForgotPassword,
              ),
            ],
          ),

          const SizedBox(
            height: 8,
          ),

          // ====================================================
          // SENHA
          // ====================================================

          _LoginTextField(
            controller:
                senhaController,
            focusNode:
                senhaFocus,
            hint:
                'Digite sua senha',
            icon:
                Icons.lock_outline_rounded,
            obscureText:
                !mostrarSenha,
            textInputAction:
                TextInputAction.done,
            suffix:
                _PasswordToggle(
              visible:
                  mostrarSenha,
              onTap:
                  onMostrarSenha,
            ),
            onSubmitted: (_) {
              onLogin();
            },
          ),

          const SizedBox(
            height: 17,
          ),

          // ====================================================
          // LEMBRAR
          // ====================================================

          _RememberOption(
            value:
                lembrarDeMim,
            onChanged:
                onLembrarChanged,
          ),

          const SizedBox(
            height: 23,
          ),

          // ====================================================
          // BOTÃO
          // ====================================================

          _LoginButton(
            carregando:
                carregando,
            onTap:
                onLogin,
          ),

          // ====================================================
          // MENSAGEM
          // ====================================================

          AnimatedSize(
            duration:
                const Duration(
              milliseconds: 180,
            ),
            child:
                mensagem.isEmpty
                    ? const SizedBox
                        .shrink()
                    : Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 16,
                        ),
                        child: Center(
                          child: Text(
                            mensagem,
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                TextStyle(
                              color:
                                  corMensagem,
                              fontSize:
                                  12.5,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                        ),
                      ),
          ),

          const SizedBox(
            height: 20,
          ),

          // Cadastro também no mobile
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Flexible(
                child: Text(
                  'Ainda não tem uma conta?',
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF65758A,
                    ),
                    fontSize: 12.5,
                  ),
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              _TextAction(
                text:
                    'Cadastre-se',
                onTap:
                    onCadastro,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INPUT
// ============================================================

class _LoginTextField
    extends StatefulWidget {
  final TextEditingController
      controller;

  final FocusNode focusNode;

  final String hint;
  final IconData icon;

  final bool obscureText;

  final TextInputType?
      keyboardType;

  final TextInputAction?
      textInputAction;

  final Widget? suffix;

  final ValueChanged<String>?
      onSubmitted;

  const _LoginTextField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffix,
    this.onSubmitted,
  });

  @override
  State<_LoginTextField>
      createState() =>
          _LoginTextFieldState();
}

class _LoginTextFieldState
    extends State<_LoginTextField> {
  bool hover = false;
  bool focused = false;

  @override
  void initState() {
    super.initState();

    focused =
        widget.focusNode.hasFocus;

    widget.focusNode
        .addListener(
      _focusListener,
    );
  }

  void _focusListener() {
    if (!mounted) return;

    setState(() {
      focused =
          widget.focusNode
              .hasFocus;
    });
  }

  @override
  void dispose() {
    widget.focusNode
        .removeListener(
      _focusListener,
    );

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final active =
        hover || focused;

    return MouseRegion(
      cursor:
          SystemMouseCursors.text,
      onEnter: (_) {
        setState(() {
          hover = true;
        });
      },
      onExit: (_) {
        setState(() {
          hover = false;
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 180,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          border: Border.all(
            color: focused
                ? _EntrarColors
                    .blue
                : active
                    ? const Color(
                        0xFFAABBD0,
                      )
                    : const Color(
                        0xFFCBD5E3,
                      ),
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color:
                        _EntrarColors
                            .blue
                            .withOpacity(
                      0.12,
                    ),
                    blurRadius: 0,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 14,
            ),

            Icon(
              widget.icon,
              color: focused
                  ? _EntrarColors
                      .blue
                  : const Color(
                      0xFF8292A8,
                    ),
              size: 20,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child:
                  TextField(
                controller:
                    widget
                        .controller,
                focusNode:
                    widget
                        .focusNode,
                obscureText:
                    widget
                        .obscureText,
                keyboardType:
                    widget
                        .keyboardType,
                textInputAction:
                    widget
                        .textInputAction,
                onSubmitted:
                    widget
                        .onSubmitted,
                style:
                    const TextStyle(
                  color:
                      Color(
                    0xFF15243A,
                  ),
                  fontSize: 14.5,
                  fontWeight:
                      FontWeight
                          .w500,
                ),
                decoration:
                    InputDecoration(
                  hintText:
                      widget.hint,
                  hintStyle:
                      const TextStyle(
                    color:
                        Color(
                      0xFF96A3B5,
                    ),
                    fontWeight:
                        FontWeight
                            .w400,
                  ),
                  border:
                      InputBorder
                          .none,
                  enabledBorder:
                      InputBorder
                          .none,
                  focusedBorder:
                      InputBorder
                          .none,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 18,
                  ),
                ),
              ),
            ),

            if (widget.suffix !=
                null)
              widget.suffix!,

            if (widget.suffix ==
                null)
              const SizedBox(
                width: 14,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MOSTRAR SENHA
// ============================================================

class _PasswordToggle
    extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;

  const _PasswordToggle({
    required this.visible,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor:
          SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior:
            HitTestBehavior.opaque,
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 14,
            vertical: 17,
          ),
          child: Icon(
            visible
                ? Icons
                    .visibility_off_outlined
                : Icons
                    .visibility_outlined,
            color:
                _EntrarColors.blue,
            size: 21,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LEMBRAR DE MIM
// ============================================================

class _RememberOption
    extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>
      onChanged;

  const _RememberOption({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor:
          SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          onChanged(!value);
        },
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 160,
              ),
              width: 20,
              height: 20,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color: value
                    ? _EntrarColors
                        .blue
                    : Colors.white,
                borderRadius:
                    BorderRadius
                        .circular(
                  6,
                ),
                border: Border.all(
                  color: value
                      ? _EntrarColors
                          .blue
                      : const Color(
                          0xFFBDC9D8,
                        ),
                ),
              ),
              child: value
                  ? const Icon(
                      Icons
                          .check_rounded,
                      size: 15,
                      color:
                          Colors.white,
                    )
                  : null,
            ),

            const SizedBox(
              width: 9,
            ),

            const Text(
              'Lembrar de mim',
              style: TextStyle(
                color:
                    Color(
                  0xFF52647A,
                ),
                fontSize: 13,
                fontWeight:
                    FontWeight
                        .w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BOTÃO ENTRAR
// ============================================================

class _LoginButton
    extends StatefulWidget {
  final bool carregando;
  final VoidCallback onTap;

  const _LoginButton({
    required this.carregando,
    required this.onTap,
  });

  @override
  State<_LoginButton>
      createState() =>
          _LoginButtonState();
}

class _LoginButtonState
    extends State<_LoginButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor: widget.carregando
          ? SystemMouseCursors
              .basic
          : SystemMouseCursors
              .click,
      onEnter: (_) {
        if (!widget.carregando) {
          setState(() {
            hover = true;
          });
        }
      },
      onExit: (_) {
        setState(() {
          hover = false;
        });
      },
      child: GestureDetector(
        onTap: widget.carregando
            ? null
            : widget.onTap,
        onTapDown: (_) {
          if (!widget.carregando) {
            setState(() {
              pressed = true;
            });
          }
        },
        onTapUp: (_) {
          setState(() {
            pressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            pressed = false;
          });
        },
        child: AnimatedScale(
          scale: pressed
              ? 0.985
              : hover
                  ? 1.01
                  : 1,
          duration:
              const Duration(
            milliseconds: 120,
          ),
          child:
              AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 180,
            ),
            width:
                double.infinity,
            height: 58,
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  _EntrarColors
                      .blue,
                  Color(
                    0xFF244B91,
                  ),
                ],
              ),
              borderRadius:
                  BorderRadius
                      .circular(
                15,
              ),
              border: Border.all(
                color:
                    _EntrarColors
                        .blue
                        .withOpacity(
                  0.20,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      _EntrarColors
                          .blue
                          .withOpacity(
                    hover
                        ? 0.34
                        : 0.24,
                  ),
                  blurRadius: hover
                      ? 30
                      : 22,
                  offset:
                      const Offset(
                    0,
                    10,
                  ),
                ),
              ],
            ),
            child: Center(
              child: widget
                      .carregando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        color:
                            Colors.white,
                        strokeWidth:
                            2.3,
                      ),
                    )
                  : Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        const Text(
                          'Entrar',
                          style:
                              TextStyle(
                            color:
                                Colors
                                    .white,
                            fontSize:
                                15.5,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        AnimatedSlide(
                          duration:
                              const Duration(
                            milliseconds:
                                180,
                          ),
                          offset: hover
                              ? const Offset(
                                  0.2,
                                  0,
                                )
                              : Offset
                                  .zero,
                          child:
                              const Icon(
                            Icons
                                .arrow_forward_rounded,
                            color:
                                Colors.white,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TEXTO CLICÁVEL
// ============================================================

class _TextAction
    extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _TextAction({
    required this.text,
    required this.onTap,
  });

  @override
  State<_TextAction>
      createState() =>
          _TextActionState();
}

class _TextActionState
    extends State<_TextAction> {
  bool hover = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor:
          SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          hover = true;
        });
      },
      onExit: (_) {
        setState(() {
          hover = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.text,
          style: TextStyle(
            color: hover
                ? _EntrarColors
                    .blueDark
                : _EntrarColors
                    .blue,
            fontSize: 12.5,
            fontWeight:
                FontWeight.w700,
            decoration: hover
                ? TextDecoration
                    .underline
                : TextDecoration
                    .none,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NAVBAR BUTTON
// ============================================================

class _NavbarButton
    extends StatefulWidget {
  final String text;
  final bool compact;
  final VoidCallback onTap;

  const _NavbarButton({
    required this.text,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_NavbarButton>
      createState() =>
          _NavbarButtonState();
}

class _NavbarButtonState
    extends State<_NavbarButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor:
          SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          hover = true;
        });
      },
      onExit: (_) {
        setState(() {
          hover = false;
        });
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) {
          setState(() {
            pressed = true;
          });
        },
        onTapUp: (_) {
          setState(() {
            pressed = false;
          });
        },
        onTapCancel: () {
          setState(() {
            pressed = false;
          });
        },
        child: AnimatedScale(
          scale: pressed
              ? 0.96
              : hover
                  ? 1.03
                  : 1,
          duration:
              const Duration(
            milliseconds: 120,
          ),
          child:
              AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 180,
            ),
            height:
                widget.compact
                    ? 39
                    : 42,
            padding:
                EdgeInsets.symmetric(
              horizontal:
                  widget.compact
                      ? 13
                      : 18,
            ),
            alignment:
                Alignment.center,
            decoration:
                BoxDecoration(
              color: hover
                  ? _EntrarColors
                      .cyanLight
                  : _EntrarColors
                      .cyan,
              borderRadius:
                  BorderRadius
                      .circular(
                999,
              ),
              border: Border.all(
                color:
                    _EntrarColors
                        .cyanLight
                        .withOpacity(
                  0.45,
                ),
              ),
              boxShadow: hover
                  ? [
                      BoxShadow(
                        color:
                            _EntrarColors
                                .cyan
                                .withOpacity(
                          0.22,
                        ),
                        blurRadius:
                            20,
                        offset:
                            const Offset(
                          0,
                          8,
                        ),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.text,
              style: TextStyle(
                color:
                    Colors.white,
                fontSize:
                    widget.compact
                        ? 11.5
                        : 13,
                fontWeight:
                    FontWeight
                        .w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GLOW
// ============================================================

class _Glow
    extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(
          shape:
              BoxShape.circle,
          gradient:
              RadialGradient(
            colors: [
              color,
              color.withOpacity(
                0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GLOW PEQUENO
// ============================================================

class _TinyGlow
    extends StatelessWidget {
  const _TinyGlow();

  @override
  Widget build(
    BuildContext context,
  ) {
    return IgnorePointer(
      child: Container(
        width: 5,
        height: 5,
        decoration:
            BoxDecoration(
          color:
              _EntrarColors
                  .cyanLight,
          shape:
              BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  _EntrarColors
                      .cyan,
              blurRadius: 12,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BADGE DOT
// ============================================================

class _BadgeDot
    extends StatelessWidget {
  const _BadgeDot();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 8,
      height: 8,
      decoration:
          BoxDecoration(
        color:
            _EntrarColors.cyan,
        shape:
            BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                _EntrarColors
                    .cyan,
            blurRadius: 8,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CORES AUXILIARES
// ============================================================

class _EntrarColors {
  static const Color navy =
      Color(0xFF06152E);

  static const Color blue =
      Color(0xFF315CAC);

  static const Color blueDark =
      Color(0xFF102A58);

  static const Color cyan =
      Color(0xFF69C5D0);

  static const Color cyanLight =
      Color(0xFF9CE8EF);

  static const Color textSoft =
      Color(0xFFDCE7F5);

  static const Color textMuted =
      Color(0xFFAEBED1);
}