import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const Color azulPrincipal = Color(0xFF3059AA);
  static const Color azulPrincipal2 = Color(0xFF4C71C7);
  static const Color azulClaro = Color(0xFF5EB1BF);
  static const Color texto = Color(0xFF1B2233);
  static const Color textoSuave = Color(0xFF6F7B91);

  final TextEditingController _bioController = TextEditingController();

  bool _carregando = true;
  bool _salvandoFoto = false;
  bool _sidebarHovered = false;
  String? _sidebarItemHovered;

  Map<String, dynamic>? _usuario;
  List<Map<String, dynamic>> _meusPosts = [];

  int _totalPosts = 0;
  int _totalSeguidores = 0;
  int _totalSeguindo = 0;

  final Map<String, ImageProvider> _imageProviderCache = {};

  String get apiUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://10.0.2.2:8000';
  }

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor =>
      darkMode ? const Color(0xFF05070C) : const Color(0xFFF4F7FB);

  Color get textColor =>
      darkMode ? const Color(0xFFF3F6FF) : texto;

  Color get mutedColor =>
      darkMode ? const Color(0xFF9CA7BE) : textoSuave;

  Color get bodyTextColor =>
      darkMode ? const Color(0xFFD7DDF0) : const Color(0xFF24304A);

  Color get sidebarTextColor =>
      darkMode ? const Color(0xFFF1F5FF) : const Color(0xFF33415C);

  Color get surfaceColor =>
      darkMode ? const Color(0xD10D0D10) : Colors.white.withOpacity(0.78);

  Color get inputFillColor =>
      darkMode ? Colors.white.withOpacity(0.03) : Colors.white.withOpacity(0.84);

  @override
  void initState() {
    super.initState();
    _inicializarPerfil();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access_token');
  }

  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final token = await _token();

    return {
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _parseResponse(http.Response response, String fallback) async {
    dynamic data;

    try {
      data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      data = null;
    }

    if (response.statusCode == 401) {
      throw Exception('AUTH_401');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map && data['detail'] != null
          ? data['detail'].toString()
          : fallback;
      throw Exception(message);
    }

    return data;
  }

  Future<dynamic> _get(String path) async {
    final response = await http
        .get(Uri.parse('$apiUrl$path'), headers: await _headers())
        .timeout(const Duration(seconds: 12));

    return _parseResponse(response, 'Erro na requisição.');
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse('$apiUrl$path'),
          headers: await _headers(jsonBody: true),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 12));

    return _parseResponse(response, 'Erro na requisição.');
  }

  Map<String, dynamic> _normalizarPost(Map<String, dynamic> post) {
    final usuario = post['usuario'];

    return {
      'id': _toInt(post['id']),
      'conteudo': post['conteudo'] ?? post['texto'] ?? '',
      'texto': post['conteudo'] ?? post['texto'] ?? '',
      'imagem': post['imagem'] ?? post['imagem_url'] ?? post['image'] ?? '',
      'likes': _toInt(post['likes']),
      'data': post['data_postagem'] ?? post['data'] ?? '',
      'userId': usuario is Map ? usuario['id'] : post['usuario_id'] ?? post['userId'],
      'comentarios': <Map<String, dynamic>>[],
    };
  }

  Future<List<Map<String, dynamic>>> _buscarComentarios(int postId) async {
    try {
      final data = await _get('/comments/comentarios/$postId');
      if (data is! List) return [];

      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _carregarStatsCache(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('perfilStatsCache');
    if (raw == null) return;

    try {
      final cache = Map<String, dynamic>.from(jsonDecode(raw));
      if (cache['userId']?.toString() != userId.toString()) return;

      setState(() {
        _totalPosts = _toInt(cache['totalPosts']);
        _totalSeguidores = _toInt(cache['totalSeguidores']);
        _totalSeguindo = _toInt(cache['totalSeguindo']);
      });
    } catch (_) {}
  }

  Future<void> _salvarStatsCache() async {
    final user = _usuario;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'perfilStatsCache',
      jsonEncode({
        'userId': user['id'],
        'totalPosts': _totalPosts,
        'totalSeguidores': _totalSeguidores,
        'totalSeguindo': _totalSeguindo,
      }),
    );
  }

  Future<void> _salvarUsuarioLocal(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuarioLogado', jsonEncode(user));
  }

  Future<void> _inicializarPerfil() async {
    final prefs = await SharedPreferences.getInstance();
    final localUserRaw = prefs.getString('usuarioLogado');
    
    if (localUserRaw != null) {
      try {
        final user = Map<String, dynamic>.from(jsonDecode(localUserRaw));
        final bio = prefs.getString('bio_${user['username']}') ?? '';
        setState(() {
          _usuario = user;
          _bioController.text = bio;
          _carregando = false;
        });
        _carregarStatsCache(user['id']);
      } catch (_) {}
    }
    
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    if (_usuario == null) {
      setState(() => _carregando = true);
    }

    final token = await _token();
    if (token == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/entrar');
      return;
    }

    try {
      final user = Map<String, dynamic>.from(await _get('/profile/me'));
      final userId = user['id'];

      final resultados = await Future.wait([
        _get('/profile/$userId/followers'),
        _get('/profile/$userId/following'),
        _get('/post/feed'),
      ]);

      final seguidores = Map<String, dynamic>.from(resultados[0]);
      final seguindo = Map<String, dynamic>.from(resultados[1]);
      final feedRaw = resultados[2];

      final feed = feedRaw is List
          ? feedRaw
              .whereType<Map>()
              .map((post) => _normalizarPost(Map<String, dynamic>.from(post)))
              .toList()
          : <Map<String, dynamic>>[];

      final meusPostsBase = feed
          .where((post) => post['userId']?.toString() == userId.toString())
          .toList();

      final meusPosts = <Map<String, dynamic>>[];
      for (final post in meusPostsBase) {
        final comentarios = await _buscarComentarios(_toInt(post['id']));
        meusPosts.add({...post, 'comentarios': comentarios});
      }

      final prefs = await SharedPreferences.getInstance();
      final bio = prefs.getString('bio_${user['username']}') ?? '';

      final usuarioCompleto = {
        ...user,
        'total_seguidores': seguidores['total'] ?? 0,
        'total_seguindo': seguindo['total'] ?? 0,
      };

      await _salvarUsuarioLocal(usuarioCompleto);

      if (mounted) {
        setState(() {
          _usuario = usuarioCompleto;
          _meusPosts = meusPosts;
          _totalPosts = meusPosts.length;
          _totalSeguidores = _toInt(seguidores['total']);
          _totalSeguindo = _toInt(seguindo['total']);
          _bioController.text = bio;
          _carregando = false;
        });
      }

      await _salvarStatsCache();
    } catch (e) {
      if (e.toString().contains('AUTH_401')) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/entrar');
        return;
      }
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''), erro: true);
    } finally {
      if (mounted && _usuario == null) {
        setState(() => _carregando = false);
      }
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _postTexto(Map<String, dynamic> post) {
    return (post['texto'] ?? post['conteudo'] ?? post['content'] ?? '').toString();
  }

  String _postImagem(Map<String, dynamic> post) {
    return (post['imagem'] ?? post['imagem_url'] ?? post['image'] ?? '').toString();
  }

  int _postLikes(Map<String, dynamic> post) {
    return _toInt(post['likes'] ?? post['total_likes']);
  }

  int _postComentarios(Map<String, dynamic> post) {
    final comentarios = post['comentarios'];
    if (comentarios is List) return comentarios.length;
    return _toInt(post['comentarios_count'] ?? post['comments_count']);
  }

  String _formatDateCurta(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    const meses = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];

    final day = date.day.toString().padLeft(2, '0');
    final month = meses[date.month - 1];
    return '$day de $month. de ${date.year}';
  }

  String _fotoPerfil() {
    final user = _usuario;
    if (user == null) return '';

    return (user['foto_perfil'] ?? user['foto'] ?? user['avatar'] ?? '').toString();
  }

  ImageProvider _imageProvider(String value) {
    return _imageProviderCache.putIfAbsent(value, () {
      if (value.startsWith('data:image')) {
        final base64Data = value.split(',').last;
        return MemoryImage(base64Decode(base64Data));
      }

      if (value.startsWith('http')) {
        return NetworkImage(value);
      }

      return const AssetImage('assets/user.png');
    });
  }

  ImageProvider? _avatarProvider(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    return _imageProviderCache.putIfAbsent(url, () {
      if (url.startsWith('data:image')) {
        final base64Data = url.split(',').last;
        return MemoryImage(base64Decode(base64Data));
      }

      if (url.startsWith('http')) {
        return NetworkImage(url);
      }

      return const AssetImage('assets/user.png');
    });
  }

  Future<void> _trocarFoto() async {
    if (_usuario == null || _salvandoFoto) return;

    final picker = ImagePicker();
    final arquivo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 300,
    );

    if (arquivo == null) return;

    setState(() => _salvandoFoto = true);

    try {
      final bytes = await arquivo.readAsBytes();
      final base64Foto = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final resposta = Map<String, dynamic>.from(
        await _post('/profile/trocar_foto', {'foto_url': base64Foto}),
      );

      final novaFoto = (resposta['foto_perfil'] ?? base64Foto).toString();
      final usuarioAtualizado = {
        ...?_usuario,
        'foto_perfil': novaFoto,
        'foto': novaFoto,
      };

      setState(() => _usuario = usuarioAtualizado);
      await _salvarUsuarioLocal(usuarioAtualizado);

      _mostrarMensagem('Foto atualizada com sucesso!');
    } catch (e) {
      _mostrarMensagem(e.toString().replaceFirst('Exception: ', ''), erro: true);
    } finally {
      if (mounted) setState(() => _salvandoFoto = false);
    }
  }

  Future<void> _salvarBio() async {
    final user = _usuario;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bio_${user['username']}', _bioController.text);

    _mostrarMensagem('Bio salva com sucesso!');
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? const Color(0xFFD64545) : const Color(0xFF2EA66A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _abrirPost(Map<String, dynamic> post) {
    final imagem = _postImagem(post);
    final textoPost = _postTexto(post);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: const Color(0xBF0A101C),
      pageBuilder: (context, _, __) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const SizedBox.expand(),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 460),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: darkMode
                          ? const Color(0xD10D0D10)
                          : Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF14274D).withOpacity(0.16),
                          blurRadius: 60,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            style: IconButton.styleFrom(
                              backgroundColor: darkMode
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0x140F172A),
                            ),
                            icon: Icon(Icons.close, color: textColor),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (imagem.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 380),
                                  child: Image(
                                    key: ValueKey(imagem),
                                    image: _imageProvider(imagem),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            if (textoPost.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                textoPost,
                                textAlign: TextAlign.center,
                                style: TextStyle(height: 1.7, color: bodyTextColor),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Text(
                              '❤️ ${_postLikes(post)}   💬 ${_postComentarios(post)}',
                              style: TextStyle(
                                color: mutedColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;
          final isMedium = constraints.maxWidth < 980;

          return Stack(
            children: [
              _BackgroundDecor(darkMode: darkMode),
              Row(
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: _carregando && _usuario == null
                        ? const Center(
                            child: CircularProgressIndicator(color: azulPrincipal),
                          )
                        : _buildContent(isCompact, isMedium),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar() {
    const collapsed = 84.0;
    const expanded = 230.0;
    final width = _sidebarHovered ? expanded : collapsed;

    return MouseRegion(
      onEnter: (_) => setState(() => _sidebarHovered = true),
      onExit: (_) {
        setState(() {
          _sidebarHovered = false;
          _sidebarItemHovered = null;
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
                      _sidebarItem(Icons.add_box_outlined, 'Postar', '/postar', false),
                      _sidebarItem(Icons.notifications_none, 'Notificações', '/notificacoes', false),
                      const SizedBox(height: 18),
                      Divider(color: azulPrincipal.withOpacity(0.10)),
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

  Widget _sidebarItem(
    IconData icon,
    String label,
    String route,
    bool active,
  ) {
    final isHovered = _sidebarItemHovered == route;
    final highlighted = active || isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _sidebarItemHovered = route),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pushReplacementNamed(route),
        child: AnimatedContainer(
          key: ValueKey(route),
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
                        : const Color(0xFFC8D8F0),
                  )
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showText = _sidebarHovered && constraints.maxWidth > 90;

              return Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Icon(
                      icon,
                      color: highlighted ? azulPrincipal : sidebarTextColor,
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
                            color: highlighted ? azulPrincipal : sidebarTextColor,
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

  Widget _sidebarProfileItem() {
    const route = '/perfil';
    final foto = _fotoPerfil();

    return MouseRegion(
      onEnter: (_) => setState(() => _sidebarItemHovered = route),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          height: 50,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: darkMode
                  ? [
                      azulPrincipal.withOpacity(0.22),
                      azulClaro.withOpacity(0.10),
                    ]
                  : [
                      azulPrincipal.withOpacity(0.12),
                      azulClaro.withOpacity(0.08),
                    ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: azulPrincipal.withOpacity(0.08)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showText = _sidebarHovered && constraints.maxWidth > 90;

              return Row(
                children: [
                  KeyedSubtree(
                    key: ValueKey(foto),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFE4E9F2),
                      backgroundImage: _avatarProvider(foto),
                      child: foto.isEmpty
                          ? Icon(Icons.person, size: 16, color: sidebarTextColor)
                          : null,
                    ),
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
                          style: const TextStyle(
                            color: azulPrincipal,
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

  Widget _buildContent(bool isCompact, bool isMedium) {
    final horizontal = isCompact ? 18.0 : 42.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(horizontal, 42, horizontal, 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(isCompact),
              const SizedBox(height: 22),
              _buildProfileCard(isCompact, isMedium),
              const SizedBox(height: 34),
              _buildImagesSection(isCompact, isMedium),
              const SizedBox(height: 34),
              _buildTextPostsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: azulPrincipal.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Seu espaço no Pace',
            style: TextStyle(
              color: azulPrincipal,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Meu Perfil',
          style: TextStyle(
            fontSize: isCompact ? 30 : 40,
            height: 1.05,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 680,
          child: Text(
            'Acompanhe sua presença na comunidade, organize sua identidade e veja o impacto dos seus posts.',
            style: TextStyle(
              color: mutedColor,
              fontSize: 16,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(bool isCompact, bool isMedium) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 20 : 28),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(isCompact ? 22 : 28),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.04)
              : Colors.white.withOpacity(0.60),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14274D).withOpacity(darkMode ? 0.35 : 0.16),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: isMedium
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPhotoArea(),
                const SizedBox(height: 26),
                _buildProfileInfo(isCompact, isMedium),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: 170, child: _buildPhotoArea()),
                const SizedBox(width: 28),
                Expanded(child: _buildProfileInfo(isCompact, isMedium)),
              ],
            ),
    );
  }

  Widget _buildPhotoArea() {
    final foto = _fotoPerfil();

    return Column(
      children: [
        Container(
          width: 136,
          height: 136,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [azulPrincipal, azulClaro],
            ),
            boxShadow: [
              BoxShadow(
                color: azulPrincipal.withOpacity(0.18),
                blurRadius: 35,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: const Color(0xFFDCE5F5),
            ),
            child: ClipOval(
              child: foto.isEmpty
                  ? Icon(Icons.person, size: 64, color: mutedColor)
                  : Image(
                      key: ValueKey(foto),
                      image: _imageProvider(foto),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _salvandoFoto ? null : _trocarFoto,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: azulPrincipal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _salvandoFoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined, size: 18, color: azulPrincipal),
                  const SizedBox(width: 8),
                  const Text(
                    'Trocar foto',
                    style: TextStyle(
                      color: azulPrincipal,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(bool isCompact, bool isMedium) {
    final user = _usuario ?? {};
    final nome = (user['username'] ?? '').toString();
    final email = (user['email'] ?? '').toString();
    final crossAlign = isMedium ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(
          nome,
          textAlign: isMedium ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          textAlign: isMedium ? TextAlign.center : TextAlign.start,
          style: TextStyle(color: mutedColor, fontSize: 15),
        ),
        const SizedBox(height: 22),
        _buildStatsRow(isCompact),
        const SizedBox(height: 26),
        Container(height: 1, color: azulPrincipal.withOpacity(0.12)),
        const SizedBox(height: 24),
        isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sua bio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSalvarBioButton(fullWidth: true),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sua bio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  _buildSalvarBioButton(fullWidth: false),
                ],
              ),
        const SizedBox(height: 14),
        TextField(
          controller: _bioController,
          minLines: 4,
          maxLines: 5,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Escreva algo sobre você, seus objetivos e sua jornada...',
            hintStyle: TextStyle(color: mutedColor.withOpacity(0.8)),
            filled: true,
            fillColor: inputFillColor,
            contentPadding: const EdgeInsets.all(18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: azulPrincipal.withOpacity(0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: darkMode
                    ? Colors.white.withOpacity(0.06)
                    : azulPrincipal.withOpacity(0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: azulPrincipal.withOpacity(0.30)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalvarBioButton({required bool fullWidth}) {
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [azulPrincipal, azulPrincipal2],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: azulPrincipal.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _salvarBio,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: const Text(
          'Salvar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildStatsRow(bool isCompact) {
    if (isCompact) {
      return Column(
        children: [
          _statCard(_totalPosts, 'Posts'),
          const SizedBox(height: 14),
          _statCard(_totalSeguidores, 'Seguidores'),
          const SizedBox(height: 14),
          _statCard(_totalSeguindo, 'Seguindo'),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _statCard(_totalPosts, 'Posts')),
        const SizedBox(width: 14),
        Expanded(child: _statCard(_totalSeguidores, 'Seguidores')),
        const SizedBox(width: 14),
        Expanded(child: _statCard(_totalSeguindo, 'Seguindo')),
      ],
    );
  }

  Widget _statCard(int valor, String label) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: darkMode
              ? [
                  const Color(0xF214141A),
                  const Color(0xF20D0D10),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  const Color(0xFFF5F8FF).withOpacity(0.9),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.04)
              : azulPrincipal.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14274D).withOpacity(darkMode ? 0.35 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$valor',
            style: TextStyle(
              color: darkMode ? const Color(0xFF82A7FF) : azulPrincipal,
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.03 * 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.06 * 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String kicker, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker.toUpperCase(),
          style: const TextStyle(
            color: azulClaro,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.02 * 26,
          ),
        ),
      ],
    );
  }

  int _gridColumns(bool isCompact, bool isMedium) {
    if (isCompact) return 1;
    if (isMedium) return 2;
    return 3;
  }

  Widget _buildImagesSection(bool isCompact, bool isMedium) {
    final imagens = _meusPosts.where((post) => _postImagem(post).isNotEmpty).toList();
    final columns = _gridColumns(isCompact, isMedium);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Galeria', 'Minhas Imagens'),
        const SizedBox(height: 14),
        if (imagens.isEmpty)
          _emptyBox('Nenhuma imagem publicada ainda.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: imagens.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, index) {
              final post = imagens[index];
              return _PostImageTile(
                imagem: _postImagem(post),
                likes: _postLikes(post),
                comentarios: _postComentarios(post),
                imageProvider: _imageProvider(_postImagem(post)),
                onTap: () => _abrirPost(post),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTextPostsSection() {
    final textos = _meusPosts.where((post) => _postTexto(post).isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Conteúdo', 'Meus Posts'),
        const SizedBox(height: 14),
        if (textos.isEmpty)
          _emptyBox('Nenhum post de texto publicado ainda.')
        else
          Column(
            children: textos.map((post) {
              final data = _formatDateCurta(post['data']);
              final meta = [
                if (data.isNotEmpty) data,
                '❤️ ${_postLikes(post)}',
                '💬 ${_postComentarios(post)}',
              ].join(' • ');

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _abrirPost(post),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      decoration: BoxDecoration(
                        color: darkMode
                            ? const Color(0xD10D0D10)
                            : Colors.white.withOpacity(0.86),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: darkMode
                              ? Colors.white.withOpacity(0.04)
                              : Colors.white.withOpacity(0.70),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14274D).withOpacity(0.10),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _postTexto(post),
                            style: TextStyle(
                              color: bodyTextColor,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            meta,
                            style: TextStyle(
                              color: mutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkMode
            ? Colors.white.withOpacity(0.04)
            : Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: mutedColor),
      ),
    );
  }
}

class _PostImageTile extends StatefulWidget {
  final String imagem;
  final int likes;
  final int comentarios;
  final ImageProvider imageProvider;
  final VoidCallback onTap;

  const _PostImageTile({
    required this.imagem,
    required this.likes,
    required this.comentarios,
    required this.imageProvider,
    required this.onTap,
  });

  @override
  State<_PostImageTile> createState() => _PostImageTileState();
}

class _PostImageTileState extends State<_PostImageTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          transform: Matrix4.identity()..translate(0.0, _hovered ? -6.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hovered ? 0.12 : 0.10),
                blurRadius: _hovered ? 35 : 40,
                offset: Offset(0, _hovered ? 18 : 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedScale(
                  scale: _hovered ? 1.04 : 1,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  child: Image(
                    key: ValueKey(widget.imagem),
                    image: widget.imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 280),
                  opacity: _hovered ? 1 : 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x140F182D),
                          Color(0xB30F182D),
                        ],
                      ),
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      '❤️ ${widget.likes} • 💬 ${widget.comentarios}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
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
          top: -80,
          right: -60,
          child: _SoftOrb(
            size: 280,
            color: const Color(0x293059AA),
            blur: 80,
          ),
        ),
        Positioned(
          bottom: 80,
          left: -80,
          child: _SoftOrb(
            size: 260,
            color: const Color(0x2E5EB1BF),
            blur: 80,
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