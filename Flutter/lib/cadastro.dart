import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'api_config.dart';
import 'package:http/http.dart' as http;

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  // ============================================================
  // CORES
  // ============================================================

  static const Color navy = Color(0xFF06152E);
  static const Color navyDeep = Color(0xFF041126);

  static const Color blue = Color(0xFF315CAC);
  static const Color blueDark = Color(0xFF102A58);

  static const Color cyan = Color(0xFF69C5D0);
  static const Color cyanLight = Color(0xFF9CE8EF);

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _usuarioController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _senhaController =
      TextEditingController();

  final TextEditingController _confirmarSenhaController =
      TextEditingController();

  // ============================================================
  // FOCUS
  // ============================================================

  final FocusNode _usuarioFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _senhaFocus = FocusNode();
  final FocusNode _confirmarSenhaFocus = FocusNode();

  // ============================================================
  // ESTADOS
  // ============================================================

  bool _carregando = false;

  bool _mostrarSenha = false;
  bool _mostrarConfirmarSenha = false;

  bool _aceitaTermos = false;

  String _mensagem = '';
  Color _corMensagem = Colors.red;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _senhaController.addListener(
      _atualizarSenha,
    );

    _confirmarSenhaController.addListener(
      _atualizarConfirmacaoSenha,
    );
  }

  void _atualizarSenha() {
    if (!mounted) return;

    setState(() {});
  }

  void _atualizarConfirmacaoSenha() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // API
  // ============================================================

  String get apiUrl => ApiConfig.baseUrl;

  // ============================================================
  // REGRAS DA SENHA
  // ============================================================

  bool get _senhaTem8 {
    return _senhaController.text.length >= 8;
  }

  bool get _senhaTemMaiuscula {
    return RegExp(
      r'[A-Z]',
    ).hasMatch(
      _senhaController.text,
    );
  }

  bool get _senhaTemNumero {
    return RegExp(
      r'[0-9]',
    ).hasMatch(
      _senhaController.text,
    );
  }

  bool get _senhaTemSimbolo {
    return RegExp(
      r'[!@#$%^&*(),.?":{}|<>_\-+=/\\]',
    ).hasMatch(
      _senhaController.text,
    );
  }

  int get _forcaSenha {
    int pontos = 0;

    if (_senhaTem8) pontos++;
    if (_senhaTemMaiuscula) pontos++;
    if (_senhaTemNumero) pontos++;
    if (_senhaTemSimbolo) pontos++;

    return pontos;
  }

  String get _textoForcaSenha {
    switch (_forcaSenha) {
      case 1:
        return 'Fraca';

      case 2:
        return 'Razoável';

      case 3:
        return 'Boa';

      case 4:
        return 'Forte';

      default:
        return 'Muito fraca';
    }
  }

  Color get _corForcaSenha {
    switch (_forcaSenha) {
      case 1:
        return const Color(0xFFC84040);

      case 2:
        return const Color(0xFFD89032);

      case 3:
        return const Color(0xFF4E8BBE);

      case 4:
        return const Color(0xFF1F9D72);

      default:
        return const Color(0xFFC4CDD9);
    }
  }

  bool get _senhasIguais {
    return _confirmarSenhaController.text.isNotEmpty &&
        _senhaController.text ==
            _confirmarSenhaController.text;
  }

  // ============================================================
  // CADASTRO
  // ============================================================

  Future<void> _fazerCadastro() async {
    if (_carregando) return;

    FocusScope.of(context).unfocus();

    final usuario =
        _usuarioController.text.trim();

    final email =
        _emailController.text.trim();

    final senha =
        _senhaController.text;

    final confirmar =
        _confirmarSenhaController.text;

    // ==========================================================
    // CAMPOS
    // ==========================================================

    if (usuario.isEmpty ||
        email.isEmpty ||
        senha.isEmpty ||
        confirmar.isEmpty) {
      setState(() {
        _mensagem =
            'Preencha todos os campos.';

        _corMensagem =
            const Color(0xFFC84040);
      });

      return;
    }

    // ==========================================================
    // TERMOS
    // ==========================================================

    if (!_aceitaTermos) {
      setState(() {
        _mensagem =
            'Você precisa aceitar os termos de uso.';

        _corMensagem =
            const Color(0xFFC84040);
      });

      return;
    }

    // ==========================================================
    // VALIDAÇÃO SENHA
    // ==========================================================

    if (!_senhaTem8) {
      setState(() {
        _mensagem =
            'A senha precisa ter pelo menos 8 caracteres.';

        _corMensagem =
            const Color(0xFFC84040);
      });

      return;
    }

    if (!_senhaTemMaiuscula) {
      setState(() {
        _mensagem =
            'A senha precisa ter pelo menos uma letra maiúscula.';

        _corMensagem =
            const Color(0xFFC84040);
      });

      return;
    }

    if (!_senhaTemNumero) {
      setState(() {
        _mensagem =
            'A senha precisa ter pelo menos um número.';

        _corMensagem =
            const Color(0xFFC84040);
      });

      return;
    }

    if (!_senhaTemSimbolo) {
      setState(() {
        _mensagem =
            'A senha precisa ter pelo menos um símbolo.';

        _corMensagem =
            const Color(0xFFC84040);
      });

      return;
    }

    if (senha != confirmar) {
      setState(() {
        _mensagem =
            'As senhas não coincidem.';

        _corMensagem =
            const Color(0xFFC84040);
      });

      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(() {
      _carregando = true;
      _mensagem = '';
    });

    try {
      final response = await http
          .post(
            Uri.parse(
              '$apiUrl/auth/criar_usuario',
            ),
            headers: {
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode(
              {
                'username': usuario,
                'email': email,
                'senha': senha,
              },
            ),
          )
          .timeout(
            const Duration(
              seconds: 10,
            ),
          );

      Map<String, dynamic> data;

      try {
        data = jsonDecode(
          response.body,
        );
      } catch (_) {
        throw Exception(
          'Erro inesperado no servidor.',
        );
      }

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception(
          data['detail'] ??
              'Erro ao cadastrar.',
        );
      }

      if (!mounted) return;

      setState(() {
        _mensagem =
            'Cadastro realizado com sucesso!';

        _corMensagem =
            const Color(0xFF1F9D72);
      });

      await Future.delayed(
        const Duration(
          milliseconds: 850,
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/entrar',
      );
    } catch (e) {
      if (!mounted) return;

      final mensagem = e
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      setState(() {
        _mensagem = mensagem;

        _corMensagem =
            const Color(0xFFC84040);
      });

      ScaffoldMessenger.of(context)
          .hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: Text(
                mensagem,
              ),
              backgroundColor:
                  const Color(0xFFC84040),
              behavior:
                  SnackBarBehavior.floating,
              duration:
                  const Duration(
                seconds: 3,
              ),
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
  // TERMOS E PRIVACIDADE
  // ============================================================

  Future<void> _abrirDocumentoLegal({
    required String titulo,
    required String kicker,
    required IconData icon,
    required String introTitulo,
    required String introTexto,
    required List<_LegalSectionData> secoes,
  }) async {
    final aceitou = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF020B19).withOpacity(0.72),
      builder: (dialogContext) {
        return _LegalDocumentDialog(
          titulo: titulo,
          kicker: kicker,
          icon: icon,
          introTitulo: introTitulo,
          introTexto: introTexto,
          secoes: secoes,
        );
      },
    );

    if (aceitou == true && mounted) {
      setState(() {
        _aceitaTermos = true;
        _mensagem = '';
      });
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _senhaController.removeListener(
      _atualizarSenha,
    );

    _confirmarSenhaController.removeListener(
      _atualizarConfirmacaoSenha,
    );

    _usuarioController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();

    _usuarioFocus.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    _confirmarSenhaFocus.dispose();

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
                    // ==========================================
                    // LOGO
                    // ==========================================

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

                    if (!mobile) ...[
                      const Text(
                        'Já possui uma conta?',
                        style: TextStyle(
                          color:
                              Color(
                            0xFFC1CDE0,
                          ),
                          fontSize:
                              13,
                          fontWeight:
                              FontWeight
                                  .w500,
                        ),
                      ),

                      const SizedBox(
                        width: 18,
                      ),
                    ],

                    _NavbarLoginButton(
                      text: 'Entrar',
                      compact:
                          compact,
                      onTap: () {
                        Navigator
                            .pushNamed(
                          context,
                          '/entrar',
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

        final desktop =
            width >= 1100;

        return Stack(
          fit: StackFit.expand,
          children: [
            // ==================================================
            // FUNDO
            // ==================================================

            const DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    LinearGradient(
                  begin:
                      Alignment.topLeft,
                  end:
                      Alignment.bottomRight,
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

            Positioned(
              top: -220,
              left: -180,
              child: _Glow(
                size:
                    desktop
                        ? 560
                        : 420,
                color:
                    const Color(
                  0xFF397DE4,
                ).withOpacity(
                  0.22,
                ),
              ),
            ),

            Positioned(
              right: -190,
              bottom: -200,
              child: _Glow(
                size:
                    desktop
                        ? 580
                        : 430,
                color:
                    cyan.withOpacity(
                  0.11,
                ),
              ),
            ),

            const Positioned(
              bottom: 90,
              left: 65,
              child: _TinyGlow(),
            ),

            if (desktop)
              const Positioned(
                right: 100,
                top: 120,
                child: _TinyGlow(),
              ),

            // ==================================================
            // CONTEÚDO
            // ==================================================

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(
                    maxWidth: 1360,
                    minHeight:
                        height,
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
                              : 30,
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
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        const Expanded(
          flex: 9,
          child:
              _CadastroPresentation(),
        ),

        const SizedBox(
          width: 65,
        ),

        Expanded(
          flex: 10,
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 550,
              ),
              child:
                  _buildCadastroCard(),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobile() {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 540,
        ),
        child: Column(
          children: [
            const _MobileCadastroWelcome(),

            const SizedBox(
              height: 27,
            ),

            _buildCadastroCard(),

            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCadastroCard() {
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
              0.26,
            ),
            blurRadius:
                55,
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
            CrossAxisAlignment.start,
        children: [
          // ==================================================
          // LINHA CIANO
          // ==================================================

          Align(
            alignment:
                Alignment.topCenter,
            child: Container(
              width: 110,
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
                    cyan,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          // ==================================================
          // HEADER
          // ==================================================

          const Text(
            'COMECE SUA JORNADA',
            style: TextStyle(
              color: blue,
              fontSize: 11,
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
            'Crie sua conta',
            style: TextStyle(
              color: navy,
              fontSize: 38,
              fontWeight:
                  FontWeight.w800,
              height: 1,
              letterSpacing:
                  -1.4,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'Preencha seus dados para fazer parte do Pace.',
            style: TextStyle(
              color:
                  Color(
                0xFF65758A,
              ),
              fontSize:
                  14.5,
              height:
                  1.5,
            ),
          ),

          const SizedBox(
            height: 28,
          ),

          // ==================================================
          // USUÁRIO
          // ==================================================

          const _FieldLabel(
            text:
                'Nome de usuário',
          ),

          _CadastroTextField(
            controller:
                _usuarioController,
            focusNode:
                _usuarioFocus,
            hint:
                'Escolha um nome de usuário',
            icon:
                Icons.person_outline_rounded,
            textInputAction:
                TextInputAction.next,
            onSubmitted: (_) {
              _emailFocus
                  .requestFocus();
            },
          ),

          const SizedBox(
            height: 18,
          ),

          // ==================================================
          // EMAIL
          // ==================================================

          const _FieldLabel(
            text: 'Email',
          ),

          _CadastroTextField(
            controller:
                _emailController,
            focusNode:
                _emailFocus,
            hint:
                'nome@exemplo.com',
            icon:
                Icons.mail_outline_rounded,
            keyboardType:
                TextInputType
                    .emailAddress,
            textInputAction:
                TextInputAction.next,
            onSubmitted: (_) {
              _senhaFocus
                  .requestFocus();
            },
          ),

          const SizedBox(
            height: 18,
          ),

          // ==================================================
          // SENHA
          // ==================================================

          const _FieldLabel(
            text: 'Senha',
          ),

          _CadastroTextField(
            controller:
                _senhaController,
            focusNode:
                _senhaFocus,
            hint:
                'Crie uma senha segura',
            icon:
                Icons.lock_outline_rounded,
            obscureText:
                !_mostrarSenha,
            textInputAction:
                TextInputAction.next,
            suffix:
                _PasswordToggle(
              visible:
                  _mostrarSenha,
              onTap: () {
                setState(() {
                  _mostrarSenha =
                      !_mostrarSenha;
                });
              },
            ),
            onSubmitted: (_) {
              _confirmarSenhaFocus
                  .requestFocus();
            },
          ),

          const SizedBox(
            height: 13,
          ),

          // ==================================================
          // FORÇA SENHA
          // ==================================================

          Row(
            children: [
              const Text(
                'Força da senha',
                style:
                    TextStyle(
                  color:
                      Color(
                    0xFF738298,
                  ),
                  fontSize:
                      11,
                ),
              ),

              const Spacer(),

              AnimatedSwitcher(
                duration:
                    const Duration(
                  milliseconds:
                      180,
                ),
                child: Text(
                  _textoForcaSenha,
                  key: ValueKey(
                    _textoForcaSenha,
                  ),
                  style: TextStyle(
                    color:
                        _corForcaSenha,
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 7,
          ),

          // ==================================================
          // BARRA
          // ==================================================

          ClipRRect(
            borderRadius:
                BorderRadius.circular(
              999,
            ),
            child: Container(
              height: 6,
              color:
                  const Color(
                0xFFE4EAF2,
              ),
              child: Align(
                alignment:
                    Alignment.centerLeft,
                child:
                    AnimatedFractionallySizedBox(
                  duration:
                      const Duration(
                    milliseconds:
                        250,
                  ),
                  curve:
                      Curves.easeOut,
                  widthFactor:
                      _forcaSenha /
                          4,
                  child:
                      AnimatedContainer(
                    duration:
                        const Duration(
                      milliseconds:
                          250,
                    ),
                    color:
                        _corForcaSenha,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ==================================================
          // REGRAS
          // ==================================================

          _PasswordRules(
            length:
                _senhaTem8,
            uppercase:
                _senhaTemMaiuscula,
            number:
                _senhaTemNumero,
            symbol:
                _senhaTemSimbolo,
          ),

          const SizedBox(
            height: 21,
          ),

          // ==================================================
          // CONFIRMAR SENHA
          // ==================================================

          const _FieldLabel(
            text:
                'Confirmar senha',
          ),

          _CadastroTextField(
            controller:
                _confirmarSenhaController,
            focusNode:
                _confirmarSenhaFocus,
            hint:
                'Digite a senha novamente',
            icon:
                Icons.lock_reset_rounded,
            obscureText:
                !_mostrarConfirmarSenha,
            textInputAction:
                TextInputAction.done,
            suffix:
                _PasswordToggle(
              visible:
                  _mostrarConfirmarSenha,
              onTap: () {
                setState(() {
                  _mostrarConfirmarSenha =
                      !_mostrarConfirmarSenha;
                });
              },
            ),
            onSubmitted: (_) {
              _fazerCadastro();
            },
          ),

          // ==================================================
          // COMPARAÇÃO
          // ==================================================

          if (_confirmarSenhaController
              .text
              .isNotEmpty) ...[
            const SizedBox(
              height: 9,
            ),

            Row(
              children: [
                Icon(
                  _senhasIguais
                      ? Icons
                          .check_circle_outline_rounded
                      : Icons
                          .error_outline_rounded,
                  size: 16,
                  color:
                      _senhasIguais
                          ? const Color(
                              0xFF1F9D72,
                            )
                          : const Color(
                              0xFFC84040,
                            ),
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  _senhasIguais
                      ? 'As senhas coincidem'
                      : 'As senhas não coincidem',
                  style:
                      TextStyle(
                    fontSize:
                        11,
                    color:
                        _senhasIguais
                            ? const Color(
                                0xFF1F9D72,
                              )
                            : const Color(
                                0xFFC84040,
                              ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(
            height: 23,
          ),

          // ==================================================
          // TERMOS
          // ==================================================

          _LegalConsentRow(
            value: _aceitaTermos,
            onChanged: (value) {
              setState(() {
                _aceitaTermos = value;
              });
            },
            onTermsTap: () => _abrirDocumentoLegal(
              titulo: 'Termos de Uso',
              kicker: 'PACE',
              icon: Icons.description_outlined,
              introTitulo: 'Bem-vindo ao Pace.',
              introTexto:
                  'Estes Termos de Uso estabelecem as principais regras para utilização da plataforma. Ao criar uma conta, você declara que leu e concorda com estas condições.',
              secoes: const [
                _LegalSectionData('01', 'Sobre o Pace', 'O Pace é uma plataforma de desenvolvimento pessoal criada para ajudar usuários a organizar metas, acompanhar sua evolução, utilizar ferramentas de foco e interagir com uma comunidade voltada ao progresso pessoal.'),
                _LegalSectionData('02', 'Criação e segurança da conta', 'Para utilizar determinadas funcionalidades do Pace, o usuário deverá criar uma conta utilizando informações verdadeiras e atualizadas. O usuário é responsável por manter sua senha em segurança e pelas atividades realizadas através de sua conta.'),
                _LegalSectionData('03', 'Uso adequado da plataforma', 'O usuário concorda em utilizar o Pace de maneira responsável, respeitosa e compatível com a finalidade da plataforma. Não é permitido publicar conteúdo ilegal, discriminatório, ameaçador, fraudulento, ofensivo ou que viole direitos de terceiros.'),
                _LegalSectionData('04', 'Publicações e imagens', 'Os usuários podem compartilhar textos, imagens e informações relacionadas à sua evolução, rotina, aprendizados e objetivos. O usuário é responsável pelo conteúdo publicado e deve possuir autorização para compartilhar qualquer material enviado para a plataforma.'),
                _LegalSectionData('05', 'Comunidade', 'Comportamentos abusivos, perseguição, assédio, spam ou utilização maliciosa da plataforma poderão resultar em restrições, suspensão ou encerramento da conta.'),
                _LegalSectionData('06', 'Metas, foco e evolução', 'As ferramentas de metas, foco e acompanhamento da evolução possuem finalidade organizacional e motivacional. O Pace não garante resultados específicos decorrentes da utilização dessas ferramentas.'),
                _LegalSectionData('07', 'Disponibilidade', 'A plataforma poderá passar por atualizações, manutenções ou indisponibilidades temporárias necessárias para seu desenvolvimento, segurança ou funcionamento.'),
                _LegalSectionData('08', 'Suspensão ou encerramento', 'Contas que violem estes Termos de Uso ou apresentem comportamento malicioso poderão ser restringidas, suspensas ou encerradas.'),
                _LegalSectionData('09', 'Responsabilidade do usuário', 'Cada usuário é responsável pelas informações e conteúdos compartilhados através de sua conta, incluindo textos, imagens e interações realizadas dentro da comunidade.'),
                _LegalSectionData('10', 'Alterações dos Termos', 'Estes Termos de Uso poderão ser atualizados conforme o Pace evoluir e novas funcionalidades forem adicionadas. A versão mais recente deverá permanecer disponível para consulta dos usuários.'),
              ],
            ),
            onPrivacyTap: () => _abrirDocumentoLegal(
              titulo: 'Política de Privacidade',
              kicker: 'SUA PRIVACIDADE',
              icon: Icons.verified_user_outlined,
              introTitulo: 'Seus dados importam.',
              introTexto:
                  'Esta Política explica de forma clara quais informações podem ser utilizadas pelo Pace e para quais finalidades elas são necessárias.',
              secoes: const [
                _LegalSectionData('01', 'Informações coletadas', 'Para o funcionamento da plataforma, o Pace poderá armazenar informações fornecidas pelo próprio usuário, como nome de usuário, email, senha protegida, foto de perfil, publicações, comentários, metas e informações relacionadas às sessões de foco.'),
                _LegalSectionData('02', 'Utilização dos dados', 'As informações são utilizadas para permitir autenticação, personalizar a experiência, exibir perfis e publicações, registrar metas e acompanhar a evolução do usuário dentro do Pace.'),
                _LegalSectionData('03', 'Proteção das senhas', 'A senha utilizada para acessar o Pace deve ser protegida pelo usuário e não deve ser compartilhada com terceiros. O sistema utiliza mecanismos de proteção para evitar o armazenamento da senha de forma diretamente legível.'),
                _LegalSectionData('04', 'Conteúdo compartilhado', 'Informações publicadas no feed ou em áreas da comunidade poderão ser visualizadas por outros usuários. Evite publicar informações pessoais ou sensíveis que não deseja compartilhar.'),
                _LegalSectionData('05', 'Armazenamento', 'Os dados são armazenados conforme necessário para possibilitar o funcionamento das funcionalidades oferecidas pelo Pace.'),
                _LegalSectionData('06', 'Compartilhamento de informações', 'O Pace não possui como finalidade comercializar dados pessoais dos usuários. As informações deverão ser utilizadas dentro das necessidades relacionadas ao funcionamento, desenvolvimento e segurança da plataforma.'),
                _LegalSectionData('07', 'Direitos do usuário', 'Conforme aplicável, o usuário poderá solicitar acesso, correção ou exclusão das informações relacionadas à sua conta. Esses princípios seguem as diretrizes da Lei Geral de Proteção de Dados Pessoais (LGPD).'),
                _LegalSectionData('08', 'Segurança', 'São adotadas medidas técnicas compatíveis com o projeto para reduzir riscos de acesso indevido, alteração ou exposição não autorizada das informações armazenadas.'),
                _LegalSectionData('09', 'Alterações desta política', 'Esta Política de Privacidade poderá ser atualizada caso novas funcionalidades ou novas formas de tratamento de dados sejam adicionadas ao Pace.'),
              ],
            ),
          ),

          const SizedBox(
            height: 27,
          ),

          // ==================================================
          // CRIAR CONTA
          // ==================================================

          _CadastroButton(
            carregando:
                _carregando,
            onTap:
                _fazerCadastro,
          ),

          // ==================================================
          // MENSAGEM
          // ==================================================

          AnimatedSize(
            duration:
                const Duration(
              milliseconds:
                  180,
            ),
            child:
                _mensagem.isEmpty
                    ? const SizedBox
                        .shrink()
                    : Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 16,
                        ),
                        child:
                            Center(
                          child:
                              Text(
                            _mensagem,
                            textAlign:
                                TextAlign
                                    .center,
                            style:
                                TextStyle(
                              color:
                                  _corMensagem,
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
            height: 21,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Flexible(
                child: Text(
                  'Já possui uma conta?',
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF65758A,
                    ),
                    fontSize:
                        12.5,
                  ),
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              _TextAction(
                text:
                    'Entrar',
                onTap: () {
                  Navigator
                      .pushNamed(
                    context,
                    '/entrar',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// APRESENTAÇÃO DESKTOP
// ============================================================

class _CadastroPresentation
    extends StatelessWidget {
  const _CadastroPresentation();

  @override
  Widget build(
    BuildContext context,
  ) {
    return ConstrainedBox(
      constraints:
          const BoxConstraints(
        maxWidth: 570,
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const _PresentationBadge(),

          const SizedBox(
            height: 30,
          ),

          const Text(
            'Comece sua',
            style: TextStyle(
              color:
                  Colors.white,
              fontSize:
                  58,
              fontWeight:
                  FontWeight.w800,
              height:
                  1,
              letterSpacing:
                  -2.5,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Text(
            'evolução hoje.',
            style: TextStyle(
              color:
                  Color(
                0xFF9CE8EF,
              ),
              fontSize:
                  58,
              fontWeight:
                  FontWeight.w800,
              height:
                  1,
              letterSpacing:
                  -2.5,
            ),
          ),

          const SizedBox(
            height: 26,
          ),

          ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth:
                  500,
            ),
            child:
                const Text(
              'Crie sua conta, organize suas metas e acompanhe '
              'cada passo da sua evolução dentro do Pace.',
              style:
                  TextStyle(
                color:
                    Color(
                  0xFFDCE7F5,
                ),
                fontSize:
                    17,
                height:
                    1.7,
              ),
            ),
          ),

          const SizedBox(
            height: 34,
          ),

          const _PresentationFeature(
            icon:
                Icons.track_changes_rounded,
            small:
                'Metas inteligentes',
            title:
                'Transforme objetivos em progresso',
          ),

          const SizedBox(
            height: 12,
          ),

          const _PresentationFeature(
            icon:
                Icons.bar_chart_rounded,
            small:
                'Evolução diária',
            title:
                'Acompanhe sua constância',
          ),

          const SizedBox(
            height: 12,
          ),

          const _PresentationFeature(
            icon:
                Icons.groups_rounded,
            small:
                'Comunidade ativa',
            title:
                'Cresça junto com outras pessoas',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BADGE
// ============================================================

class _PresentationBadge
    extends StatelessWidget {
  const _PresentationBadge();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
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
        border:
            Border.all(
          color:
              _CadastroColors
                  .cyan
                  .withOpacity(
            0.34,
          ),
        ),
      ),
      child:
          const Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          _BadgeDot(),

          SizedBox(
            width: 10,
          ),

          Text(
            'COMECE SUA JORNADA',
            style:
                TextStyle(
              color:
                  _CadastroColors
                      .cyanLight,
              fontSize:
                  12,
              fontWeight:
                  FontWeight.w800,
              letterSpacing:
                  0.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FEATURE
// ============================================================

class _PresentationFeature
    extends StatelessWidget {
  final IconData icon;
  final String small;
  final String title;

  const _PresentationFeature({
    required this.icon,
    required this.small,
    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 440,
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
        border:
            Border.all(
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
            blurRadius:
                25,
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
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(
              color:
                  _CadastroColors
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
                  _CadastroColors
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
                  small,
                  style:
                      const TextStyle(
                    color:
                        _CadastroColors
                            .textMuted,
                    fontSize:
                        11,
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
                    fontSize:
                        13.5,
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
// MOBILE
// ============================================================

class _MobileCadastroWelcome
    extends StatelessWidget {
  const _MobileCadastroWelcome();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Column(
      children: [
        Text(
          'COMECE SUA JORNADA',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                _CadastroColors
                    .cyanLight,
            fontSize:
                12,
            fontWeight:
                FontWeight.w800,
            letterSpacing:
                1,
          ),
        ),

        SizedBox(
          height: 10,
        ),

        Text(
          'Sua evolução começa aqui.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                Colors.white,
            fontSize:
                27,
            fontWeight:
                FontWeight.w800,
            letterSpacing:
                -0.7,
          ),
        ),

        SizedBox(
          height: 8,
        ),

        Text(
          'Crie sua conta e dê o primeiro passo.',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            color:
                _CadastroColors
                    .textSoft,
            fontSize:
                14,
            height:
                1.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// LABEL
// ============================================================

class _FieldLabel
    extends StatelessWidget {
  final String text;

  const _FieldLabel({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        text,
        style:
            const TextStyle(
          color:
              Color(
            0xFF24364E,
          ),
          fontSize:
              13,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}

// ============================================================
// INPUT
// ============================================================

class _CadastroTextField
    extends StatefulWidget {
  final TextEditingController controller;
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

  const _CadastroTextField({
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
  State<_CadastroTextField>
      createState() =>
          _CadastroTextFieldState();
}

class _CadastroTextFieldState
    extends State<_CadastroTextField> {
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
          widget.focusNode.hasFocus;
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
      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds:
              180,
        ),
        decoration:
            BoxDecoration(
          color:
              Colors.white,
          borderRadius:
              BorderRadius
                  .circular(
            14,
          ),
          border:
              Border.all(
            color: focused
                ? _CadastroColors
                    .blue
                : hover
                    ? const Color(
                        0xFFAEBED0,
                      )
                    : const Color(
                        0xFFCBD5E3,
                      ),
          ),
          boxShadow:
              focused
                  ? [
                      BoxShadow(
                        color:
                            _CadastroColors
                                .blue
                                .withOpacity(
                          0.12,
                        ),
                        blurRadius:
                            0,
                        spreadRadius:
                            4,
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
                  ? _CadastroColors
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
                  fontSize:
                      14.5,
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
                  ),
                  border:
                      InputBorder
                          .none,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical:
                        16,
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
// PASSWORD TOGGLE
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
      child:
          GestureDetector(
        onTap: onTap,
        behavior:
            HitTestBehavior
                .opaque,
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                14,
            vertical:
                15,
          ),
          child: Icon(
            visible
                ? Icons
                    .visibility_off_outlined
                : Icons
                    .visibility_outlined,
            color:
                _CadastroColors
                    .blue,
            size:
                21,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PASSWORD RULES
// ============================================================

class _PasswordRules
    extends StatelessWidget {
  final bool length;
  final bool uppercase;
  final bool number;
  final bool symbol;

  const _PasswordRules({
    required this.length,
    required this.uppercase,
    required this.number,
    required this.symbol,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Wrap(
      spacing:
          15,
      runSpacing:
          9,
      children: [
        _PasswordRule(
          text:
              '8 caracteres',
          valid:
              length,
        ),

        _PasswordRule(
          text:
              'Maiúscula',
          valid:
              uppercase,
        ),

        _PasswordRule(
          text:
              'Número',
          valid:
              number,
        ),

        _PasswordRule(
          text:
              'Símbolo',
          valid:
              symbol,
        ),
      ],
    );
  }
}

class _PasswordRule
    extends StatelessWidget {
  final String text;
  final bool valid;

  const _PasswordRule({
    required this.text,
    required this.valid,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final color = valid
        ? const Color(
            0xFF1F9D72,
          )
        : const Color(
            0xFF8795A8,
          );

    return AnimatedDefaultTextStyle(
      duration:
          const Duration(
        milliseconds:
            180,
      ),
      style:
          TextStyle(
        color:
            color,
        fontSize:
            10.5,
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration:
                const Duration(
              milliseconds:
                  180,
            ),
            child:
                Icon(
              valid
                  ? Icons
                      .check_circle_rounded
                  : Icons
                      .radio_button_unchecked,
              key:
                  ValueKey(
                valid,
              ),
              size:
                  14,
              color:
                  color,
            ),
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            text,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TERMOS E PRIVACIDADE
// ============================================================

class _LegalSectionData {
  final String numero;
  final String titulo;
  final String texto;

  const _LegalSectionData(this.numero, this.titulo, this.texto);
}

class _LegalConsentRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;

  const _LegalConsentRow({
    required this.value,
    required this.onChanged,
    required this.onTermsTap,
    required this.onPrivacyTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: value ? _CadastroColors.blue : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value
                      ? _CadastroColors.blue
                      : const Color(0xFFBDC9D8),
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Li e concordo com os ',
                style: TextStyle(color: Color(0xFF52647A), fontSize: 12.5),
              ),
              _LegalTextLink(text: 'Termos de Uso', onTap: onTermsTap),
              const Text(
                ' e com a ',
                style: TextStyle(color: Color(0xFF52647A), fontSize: 12.5),
              ),
              _LegalTextLink(
                text: 'Política de Privacidade',
                onTap: onPrivacyTap,
              ),
              const Text(
                '. *',
                style: TextStyle(color: Color(0xFFC84040), fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalTextLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _LegalTextLink({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: _CadastroColors.blue,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
            decorationColor: _CadastroColors.blue,
          ),
        ),
      ),
    );
  }
}

class _LegalDocumentDialog extends StatelessWidget {
  final String titulo;
  final String kicker;
  final IconData icon;
  final String introTitulo;
  final String introTexto;
  final List<_LegalSectionData> secoes;

  const _LegalDocumentDialog({
    required this.titulo,
    required this.kicker,
    required this.icon,
    required this.introTitulo,
    required this.introTexto,
    required this.secoes,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final mobile = size.width < 650;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: mobile ? 14 : 32,
        vertical: mobile ? 18 : 32,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: size.height * (mobile ? 0.92 : 0.88),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(mobile ? 24 : 30),
          child: Material(
            color: const Color(0xFFF9FBFE),
            child: Column(
              children: [
                _buildHeader(context, mobile),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: !mobile,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        mobile ? 20 : 34,
                        22,
                        mobile ? 20 : 34,
                        28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFF315CAC).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF315CAC).withOpacity(0.10),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  introTitulo,
                                  style: const TextStyle(
                                    color: Color(0xFF102A58),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  introTexto,
                                  style: const TextStyle(
                                    color: Color(0xFF65758A),
                                    fontSize: 13,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...secoes.map((secao) => _LegalSection(data: secao)),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildFooter(context, mobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool mobile) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        mobile ? 20 : 30,
        mobile ? 20 : 26,
        mobile ? 14 : 22,
        mobile ? 18 : 22,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A58), Color(0xFF315CAC)],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: mobile ? 44 : 50,
            height: mobile ? 44 : 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Icon(icon, color: const Color(0xFF9CE8EF), size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kicker,
                  style: const TextStyle(
                    color: Color(0xFF9CE8EF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  titulo,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: mobile ? 21 : 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Última atualização: 01 de setembro de 2026',
                  style: TextStyle(color: Color(0xFFC9D7EA), fontSize: 10.5),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool mobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 18 : 28,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFF102A58).withOpacity(0.08)),
        ),
      ),
      child: Row(
        children: [
          if (!mobile)
            const Expanded(
              child: Text(
                'Leia o documento antes de continuar.',
                style: TextStyle(color: Color(0xFF738298), fontSize: 12),
              ),
            )
          else
            const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Fechar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF315CAC),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(
                horizontal: mobile ? 15 : 20,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'Li e concordo',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection extends StatelessWidget {
  final _LegalSectionData data;

  const _LegalSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF315CAC).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              data.numero,
              style: const TextStyle(
                color: Color(0xFF315CAC),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.titulo,
                  style: const TextStyle(
                    color: Color(0xFF15243A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.texto,
                  style: const TextStyle(
                    color: Color(0xFF65758A),
                    fontSize: 12.5,
                    height: 1.55,
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
// CHECK TERMOS
// ============================================================

class _CheckOption
    extends StatelessWidget {
  final bool value;
  final String title;

  final ValueChanged<bool>
      onChanged;

  const _CheckOption({
    required this.value,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor:
          SystemMouseCursors.click,
      child:
          GestureDetector(
        onTap: () {
          onChanged(
            !value,
          );
        },
        child: Row(
          children: [
            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds:
                    160,
              ),
              width:
                  20,
              height:
                  20,
              alignment:
                  Alignment.center,
              decoration:
                  BoxDecoration(
                color: value
                    ? _CadastroColors
                        .blue
                    : Colors
                        .white,
                borderRadius:
                    BorderRadius
                        .circular(
                  6,
                ),
                border:
                    Border.all(
                  color: value
                      ? _CadastroColors
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
                      color:
                          Colors.white,
                      size:
                          14,
                    )
                  : null,
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            Color(
                          0xFF52647A,
                        ),
                        fontSize:
                            12.5,
                      ),
                    ),
                  ),

                  const Text(
                    ' *',
                    style:
                        TextStyle(
                      color:
                          Color(
                        0xFFC84040,
                      ),
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

// ============================================================
// BOTÃO CADASTRO
// ============================================================

class _CadastroButton
    extends StatefulWidget {
  final bool carregando;
  final VoidCallback onTap;

  const _CadastroButton({
    required this.carregando,
    required this.onTap,
  });

  @override
  State<_CadastroButton>
      createState() =>
          _CadastroButtonState();
}

class _CadastroButtonState
    extends State<_CadastroButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor:
          widget.carregando
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
      child:
          GestureDetector(
        onTap:
            widget.carregando
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
        child:
            AnimatedScale(
          scale: pressed
              ? 0.985
              : hover
                  ? 1.01
                  : 1,
          duration:
              const Duration(
            milliseconds:
                120,
          ),
          child:
              AnimatedContainer(
            duration:
                const Duration(
              milliseconds:
                  180,
            ),
            width:
                double.infinity,
            height:
                57,
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    Alignment
                        .topLeft,
                end:
                    Alignment
                        .bottomRight,
                colors: [
                  _CadastroColors
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
              boxShadow: [
                BoxShadow(
                  color:
                      _CadastroColors
                          .blue
                          .withOpacity(
                    hover
                        ? 0.34
                        : 0.24,
                  ),
                  blurRadius:
                      hover
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
            child:
                Center(
              child:
                  widget.carregando
                      ? const Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            SizedBox(
                              width:
                                  20,
                              height:
                                  20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.2,
                                color:
                                    Colors.white,
                              ),
                            ),

                            SizedBox(
                              width:
                                  11,
                            ),

                            Text(
                              'Criando conta...',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            const Text(
                              'Criar conta',
                              style:
                                  TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    15.5,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),

                            const SizedBox(
                              width:
                                  12,
                            ),

                            AnimatedSlide(
                              duration:
                                  const Duration(
                                milliseconds:
                                    180,
                              ),
                              offset:
                                  hover
                                      ? const Offset(
                                          0.2,
                                          0,
                                        )
                                      : Offset.zero,
                              child:
                                  const Icon(
                                Icons
                                    .arrow_forward_rounded,
                                color:
                                    Colors.white,
                                size:
                                    21,
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
// NAVBAR ENTRAR
// ============================================================

class _NavbarLoginButton
    extends StatefulWidget {
  final String text;
  final bool compact;
  final VoidCallback onTap;

  const _NavbarLoginButton({
    required this.text,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_NavbarLoginButton>
      createState() =>
          _NavbarLoginButtonState();
}

class _NavbarLoginButtonState
    extends State<_NavbarLoginButton> {
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
      child:
          GestureDetector(
        onTap:
            widget.onTap,
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
        child:
            AnimatedScale(
          scale: pressed
              ? 0.96
              : hover
                  ? 1.03
                  : 1,
          duration:
              const Duration(
            milliseconds:
                120,
          ),
          child:
              AnimatedContainer(
            duration:
                const Duration(
              milliseconds:
                  180,
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
              color:
                  hover
                      ? Colors.white
                      : Colors.white
                          .withOpacity(
                        0.04,
                      ),
              borderRadius:
                  BorderRadius
                      .circular(
                999,
              ),
              border:
                  Border.all(
                color:
                    hover
                        ? Colors.white
                        : Colors.white
                            .withOpacity(
                          0.62,
                        ),
              ),
            ),
            child:
                Text(
              widget.text,
              style:
                  TextStyle(
                color:
                    hover
                        ? _CadastroColors
                            .blueDark
                        : Colors.white,
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
      child:
          GestureDetector(
        onTap:
            widget.onTap,
        child:
            Text(
          widget.text,
          style:
              TextStyle(
            color:
                hover
                    ? _CadastroColors
                        .blueDark
                    : _CadastroColors
                        .blue,
            fontSize:
                12.5,
            fontWeight:
                FontWeight
                    .w700,
            decoration:
                hover
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
        width:
            size,
        height:
            size,
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
// PONTINHO
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
        width:
            5,
        height:
            5,
        decoration:
            BoxDecoration(
          color:
              _CadastroColors
                  .cyanLight,
          shape:
              BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  _CadastroColors
                      .cyan,
              blurRadius:
                  12,
              spreadRadius:
                  4,
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
      width:
          8,
      height:
          8,
      decoration:
          BoxDecoration(
        color:
            _CadastroColors
                .cyan,
        shape:
            BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                _CadastroColors
                    .cyan,
            blurRadius:
                8,
            spreadRadius:
                3,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CORES AUXILIARES
// ============================================================

class _CadastroColors {
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
      Color(0xFFAEBED0);
}