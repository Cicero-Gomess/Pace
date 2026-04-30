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
  String _mensagem = '';
  Color _corMensagem = Colors.red;

  String get apiUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
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
      final tokenResponse = await http
          .post(
            Uri.parse('$apiUrl/auth/token'),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: 'username=$email&password=$senha',
          )
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic> tokenData;

      try {
        tokenData = jsonDecode(tokenResponse.body);
      } catch (_) {
        throw Exception('Erro inesperado no servidor.');
      }

      if (tokenResponse.statusCode != 200) {
        throw Exception(tokenData['detail'] ?? 'Credenciais inválidas.');
      }

      final accessToken = tokenData['access_token'];

      final meResponse = await http
          .get(
            Uri.parse('$apiUrl/auth/me'),
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic> usuarioData;

      try {
        usuarioData = jsonDecode(meResponse.body);
      } catch (_) {
        throw Exception('Erro ao obter usuário.');
      }

      if (meResponse.statusCode != 200) {
        throw Exception(usuarioData['detail'] ?? 'Erro ao obter usuário.');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', accessToken);
      await prefs.setString('usuarioLogado', jsonEncode(usuarioData));

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

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    );
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
                  padding:
                      EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF5F7FA), Color(0xFFEEF2F7)],
                    ),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      child: Container(
                        width: isMobile ? double.infinity : 380,
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
                          children: [
                            const Text(
                              'Entrar',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 25),

                            TextField(
                              controller: _emailController,
                              decoration: _inputDecoration('Seu email'),
                            ),

                            const SizedBox(height: 15),

                            TextField(
                              controller: _senhaController,
                              obscureText: true,
                              decoration: _inputDecoration('Sua senha'),
                            ),

                            const SizedBox(height: 15),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _carregando ? null : _fazerLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: azulPrincipal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _carregando
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Login'),
                              ),
                            ),

                            if (_mensagem.isNotEmpty) ...[
                              const SizedBox(height: 15),
                              Text(
                                _mensagem,
                                style: TextStyle(color: _corMensagem),
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

  // 🔥 NAVBAR COMPLETA
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

          // 🔹 LOGO
          GestureDetector(
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: Image.asset(
              'assets/images/Ícone_Pace.png',
              height: isMobile ? 40 : 50,
            ),
          ),

          Row(
            children: [

              // 🔸 ENTRAR
              _botaoNavbar(
                texto: 'Entrar',
                ativo: true,
                isMobile: isMobile,
                onTap: () {
                  Navigator.pushNamed(context, '/entrar');
                },
              ),

              SizedBox(width: isMobile ? 12 : 20),

              // 🔸 CADASTRO
              _botaoCadastro(
                isMobile: isMobile,
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

  Widget _botaoNavbar({
    required String texto,
    required bool ativo,
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 18,
          vertical: isMobile ? 7 : 8,
        ),
        decoration: BoxDecoration(
          color: ativo ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: ativo ? azulPrincipal : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ),
    );
  }

  Widget _botaoCadastro({
    required bool isMobile,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 18,
          vertical: isMobile ? 7 : 8,
        ),
        decoration: BoxDecoration(
          color: azulClaro,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Cadastre-se',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
      ),
    );
  }
}