import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EntrarPage extends StatefulWidget {
  const EntrarPage({super.key});

  @override
  State<EntrarPage> createState() => _EntrarPageState();
}

class _EntrarPageState extends State<EntrarPage> {
  static const Color azulPrincipal = Color(0xFF3059AA);
  static const Color azulClaro = Color(0xFF5EB1BF);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  bool _carregando = false;
  bool _mostrarSenha = false;
  String _mensagem = '';
  Color _corMensagem = Colors.red;

  String get apiUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  Future<void> _fazerLogin() async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        _mensagem = 'Preencha todos os campos.';
        _corMensagem = Colors.red;
      });
      return;
    }

    setState(() {
      _carregando = true;
      _mensagem = '';
    });

    try {
      final tokenResponse = await http.post(
        Uri.parse('$apiUrl/auth/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': email,
          'password': senha,
        },
      );

      final tokenData = jsonDecode(tokenResponse.body);

      if (tokenResponse.statusCode != 200) {
        throw Exception(tokenData['detail'] ?? 'Erro ao fazer login.');
      }

      final accessToken = tokenData['access_token'];

      final meResponse = await http.get(
        Uri.parse('$apiUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      final usuarioData = jsonDecode(meResponse.body);

      if (meResponse.statusCode != 200) {
        throw Exception(usuarioData['detail'] ?? 'Erro ao obter usuário.');
      }

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', accessToken);
      await prefs.setString(
        'usuarioLogado',
        jsonEncode({
          'id': usuarioData['id'],
          'username': usuarioData['username'],
          'email': usuarioData['email'],
          'foto': usuarioData['foto_perfil'] ?? 'assets/images/image.person.png',
        }),
      );

      setState(() {
        _mensagem = 'Login realizado com sucesso!';
        _corMensagem = Colors.green;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/feed');
    } catch (e) {
      setState(() {
        _mensagem = e.toString().replaceFirst('Exception: ', '');
        _corMensagem = Colors.red;
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F4),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          return Column(
            children: [
              _buildNavbar(isMobile),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF5F7FA), Color(0xFFEEF2F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        width: isMobile ? double.infinity : 380,
                        constraints: const BoxConstraints(maxWidth: 380),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 60,
                              offset: const Offset(0, 30),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Acesse sua conta',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6E6E73),
                              ),
                            ),
                            const SizedBox(height: 25),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Seu email',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: azulPrincipal),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _senhaController,
                              obscureText: !_mostrarSenha,
                              decoration: InputDecoration(
                                hintText: 'Sua senha',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _mostrarSenha = !_mostrarSenha;
                                    });
                                  },
                                  icon: Icon(
                                    _mostrarSenha ? Icons.visibility_off : Icons.visibility,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: azulPrincipal),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _carregando ? null : _fazerLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: azulPrincipal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _carregando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            if (_mensagem.isNotEmpty) ...[
                              const SizedBox(height: 15),
                              Text(
                                _mensagem,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _corMensagem,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavbar(bool isMobile) {
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
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: Image.asset(
              'assets/images/Ícone_Pace.png',
              height: isMobile ? 40 : 50,
              fit: BoxFit.contain,
            ),
          ),
          Row(
            children: [
              _BotaoEntrarHover(
                compact: isMobile,
                ativo: true,
                onTap: () {},
              ),
              SizedBox(width: isMobile ? 12 : 20),
              _BotaoCadastroHover(
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
}

class _BotaoEntrarHover extends StatefulWidget {
  final VoidCallback? onTap;
  final bool compact;
  final bool ativo;

  const _BotaoEntrarHover({
    this.onTap,
    this.compact = false,
    this.ativo = false,
  });

  @override
  State<_BotaoEntrarHover> createState() => _BotaoEntrarHoverState();
}

class _BotaoEntrarHoverState extends State<_BotaoEntrarHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.compact ? 14.0 : 18.0;
    final vertical = widget.compact ? 7.0 : 8.0;
    final fontSize = widget.compact ? 14.0 : 16.0;

    final fundoBranco = widget.ativo || _hover;
    final corTexto = fundoBranco ? _EntrarPageState.azulPrincipal : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          decoration: BoxDecoration(
            color: fundoBranco ? Colors.white : Colors.transparent,
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Entrar',
            style: TextStyle(
              color: corTexto,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _BotaoCadastroHover extends StatefulWidget {
  final VoidCallback? onTap;
  final bool compact;

  const _BotaoCadastroHover({
    this.onTap,
    this.compact = false,
  });

  @override
  State<_BotaoCadastroHover> createState() => _BotaoCadastroHoverState();
}

class _BotaoCadastroHoverState extends State<_BotaoCadastroHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final horizontal = widget.compact ? 14.0 : 18.0;
    final vertical = widget.compact ? 7.0 : 8.0;
    final fontSize = widget.compact ? 14.0 : 16.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          decoration: BoxDecoration(
            color: _EntrarPageState.azulClaro,
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
            'Cadastre-se',
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
