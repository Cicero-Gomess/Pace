import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostarPage extends StatefulWidget {
  const PostarPage({super.key});

  @override
  State<PostarPage> createState() => _PostarPageState();
}

class _PostarPageState extends State<PostarPage> {
  static const String apiUrl = "http://127.0.0.1:8000";

  bool sidebarHovered = false;
  String? sidebarItemHovered;
  bool isLoadingUser = true;
  bool isPublishing = false;

  Map<String, dynamic> usuarioLogado = {};

  final TextEditingController textoController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  Uint8List? imagemBytes;
  String? imagemNome;
  String? imagemBase64;

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor =>
      darkMode ? const Color(0xFF05070C) : const Color(0xFFF4F7FB);

  Color get textColor =>
      darkMode ? const Color(0xFFF3F6FF) : const Color(0xFF1B2233);

  Color get mutedColor =>
      darkMode ? const Color(0xFF9CA7BE) : const Color(0xFF6F7B91);

  Color get labelColor =>
      darkMode ? const Color(0xFFD7DDF0) : const Color(0xFF495874);

  Color get sidebarTextColor =>
      darkMode ? const Color(0xFFF1F5FF) : const Color(0xFF33415C);

  Color get inputFillColor =>
      darkMode ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.86);

  final List<Map<String, String>> chips = const [
    {
      'label': 'Progresso',
      'text': 'Hoje avancei um pouco mais naquilo que quero construir.',
    },
    {
      'label': 'Aprendizado',
      'text': 'Uma coisa que aprendi hoje e quero lembrar amanhã.',
    },
    {
      'label': 'Rotina',
      'text': 'O que estou tentando melhorar na minha rotina essa semana.',
    },
    {
      'label': 'Consistência',
      'text': 'Algo simples que me ajudou a manter consistência hoje.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initUser();
    textoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    textoController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _initUser() async {
    final token = await _getToken();

    if (!mounted) return;

    if (token == null) {
      Navigator.of(context).pushReplacementNamed('/entrar');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 401) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/entrar');
        return;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          usuarioLogado = Map<String, dynamic>.from(jsonDecode(response.body));
          isLoadingUser = false;
        });
      } else {
        setState(() => isLoadingUser = false);
        _showToast('Não foi possível carregar seu perfil.', Colors.red);
      }
    } catch (_) {
      setState(() => isLoadingUser = false);
      _showToast('Não foi possível carregar seu perfil.', Colors.red);
    }
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

  String _username() {
    return usuarioLogado['username']?.toString() ?? 'Usuário';
  }

  String _extensaoImagem(String name) {
    final lower = name.toLowerCase();

    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    if (lower.endsWith('.gif')) return 'gif';

    return 'jpeg';
  }

  void _usarChip(String texto) {
    final atual = textoController.text.trim();

    if (atual.isEmpty) {
      textoController.text = texto;
    } else {
      textoController.text = '$atual $texto';
    }

    textoController.selection = TextSelection.fromPosition(
      TextPosition(offset: textoController.text.length),
    );
  }

  Future<void> _selecionarImagem() async {
    try {
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        final file = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 82,
          maxWidth: 1280,
        );

        if (file == null) return;

        final bytes = await file.readAsBytes();
        final name = file.name;
        final ext = _extensaoImagem(name);

        setState(() {
          imagemBytes = bytes;
          imagemNome = name;
          imagemBase64 = 'data:image/$ext;base64,${base64Encode(bytes)}';
        });

        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        _showToast('Não foi possível carregar a imagem.', Colors.red);
        return;
      }

      final name = file.name;
      final ext = _extensaoImagem(name);

      setState(() {
        imagemBytes = bytes;
        imagemNome = name;
        imagemBase64 = 'data:image/$ext;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      _showToast('Erro ao selecionar imagem: $e', Colors.red);
    }
  }

  void _removerImagem() {
    setState(() {
      imagemBytes = null;
      imagemNome = null;
      imagemBase64 = null;
    });
  }

  Future<void> _publicarPost() async {
    final token = await _getToken();
    if (token == null) return;

    final texto = textoController.text.trim();

    if (texto.isEmpty && imagemBase64 == null) {
      _showToast('Escreva algo ou selecione uma imagem.', Colors.orange);
      return;
    }

    setState(() => isPublishing = true);

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/post/criar_post'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conteudo': texto,
          'imagem': imagemBase64 ?? '',
        }),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 401) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/entrar');
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map && data['detail'] != null
            ? data['detail'].toString()
            : 'Erro ao publicar.';
        throw Exception(message);
      }

      if (!mounted) return;

      _showToast('Post publicado com sucesso!', Colors.green);
      Navigator.of(context).pushReplacementNamed('/feed');
    } catch (e) {
      _showToast(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => isPublishing = false);
    }
  }

  void _showToast(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentLeftPadding = screenWidth < 1000 ? 24.0 : 360.0;

    if (isLoadingUser) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF3059AA)),
        ),
      );
    }

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
                    48,
                    42,
                    90,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 28),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1040),
                        child: _buildComposerCard(),
                      ),
                    ],
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
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1040),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 850;

          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Badge(text: 'Compartilhe sua jornada'),
              const SizedBox(height: 14),
              SizedBox(
                width: 650,
                child: Text(
                  'Crie algo que mova sua rotina',
                  style: TextStyle(
                    fontSize: 42,
                    height: 1.02,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 720,
                child: Text(
                  'Mostre progresso, registre aprendizados ou publique algo que possa inspirar outras pessoas dentro do Pace. Quanto mais real, melhor.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.75,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          );

          final tip = _GlassSmall(
            darkMode: darkMode,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF3059AA), size: 20),
                const SizedBox(width: 10),
                Text(
                  'Postagens autênticas geram mais conexão.',
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 18),
                tip,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: copy),
              const SizedBox(width: 20),
              tip,
            ],
          );
        },
      ),
    );
  }

  Widget _buildComposerCard() {
    return _GlassCard(
      darkMode: darkMode,
      radius: 30,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardTop(),
          const SizedBox(height: 20),
          _buildChips(),
          const SizedBox(height: 22),
          Text(
            'Conte para a comunidade o que está acontecendo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: textoController,
            maxLength: 200,
            maxLines: 7,
            style: TextStyle(color: textColor),
            cursorColor: const Color(0xFF3059AA),
            decoration: InputDecoration(
              hintText: 'O que você está pensando?',
              hintStyle: TextStyle(color: mutedColor),
              counterText: '',
              filled: true,
              fillColor: inputFillColor,
              contentPadding: const EdgeInsets.all(18),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: darkMode
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFF3059AA).withOpacity(0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(
                  color: const Color(0xFF3059AA).withOpacity(0.34),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${textoController.text.length}/200',
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildActions(),
          if (imagemBytes != null) ...[
            const SizedBox(height: 18),
            _buildPreview(),
          ],
          const SizedBox(height: 22),
          _PublishButton(
            loading: isPublishing,
            onTap: isPublishing ? null : _publicarPost,
          ),
        ],
      ),
    );
  }

  Widget _buildCardTop() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NOVO POST',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: Color(0xFF5EB1BF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Criar publicação',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        );

        final profile = Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF3059AA).withOpacity(darkMode ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: _avatarProvider(_fotoUsuarioLogado()),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _username(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Compartilhando agora',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 16),
              profile,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            title,
            profile,
          ],
        );
      },
    );
  }

  Widget _buildChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: chips.map((chip) {
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _usarChip(chip['text']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF3059AA).withOpacity(darkMode ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              chip['label']!,
              style: TextStyle(
                color: darkMode ? const Color(0xFFD7DDF0) : const Color(0xFF4D5A73),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _selecionarImagem,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF3059AA).withOpacity(darkMode ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(0xFF3059AA),
                ),
                SizedBox(width: 10),
                Text(
                  'Adicionar imagem',
                  style: TextStyle(
                    color: Color(0xFF3059AA),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, color: mutedColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Você pode postar só texto ou texto com imagem.',
              style: TextStyle(
                color: mutedColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3059AA).withOpacity(darkMode ? 0.10 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF3059AA).withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              imagemBytes!,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Imagem pronta',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  imagemNome ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removerImagem,
            icon: const Icon(Icons.close, color: Color(0xFFE55353)),
          ),
        ],
      ),
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
                      _sidebarItem(Icons.track_changes, 'Metas', '/metas', false),
                      _sidebarItem(Icons.explore_outlined, 'Explorar', '/explorar', false),
                      _sidebarItem(Icons.add_box_outlined, 'Postar', '/postar', true),
                      _sidebarItem(Icons.notifications_none, 'Notificações', '/notificacoes', false),
                      const SizedBox(height: 18),
                      Divider(color: const Color(0xFF3059AA).withOpacity(0.10)),
                      const SizedBox(height: 18),
                      _sidebarItem(Icons.settings_outlined, 'Configurações', '/config', false),
                      _sidebarProfileItem(),
                      _sidebarItem(Icons.info_outline, 'Sobre', '/sobre', false),
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
          if (route != '/postar') {
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
                        : active
                            ? const Color(0xFFB8CCEA)
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool darkMode;

  const _GlassCard({
    required this.child,
    required this.darkMode,
    this.padding = const EdgeInsets.all(22),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14274D).withOpacity(darkMode ? 0.30 : 0.16),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xE00D0D10)
                  : Colors.white.withOpacity(0.84),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: darkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.68),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassSmall extends StatelessWidget {
  final Widget child;
  final bool darkMode;

  const _GlassSmall({
    required this.child,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: darkMode
                ? const Color(0xE00D0D10)
                : Colors.white.withOpacity(0.70),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: darkMode
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.60),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF14274D).withOpacity(darkMode ? 0.24 : 0.10),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
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
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;

  const _PublishButton({
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3059AA), Color(0xFF4C71C7)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3059AA).withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send, size: 20),
        label: Text(
          loading ? 'Publicando...' : 'Publicar agora',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}