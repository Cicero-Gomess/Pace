import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  static const Color azulPrincipal = Color(0xFF1769E8);
  static const Color azulPrincipal2 = Color(0xFF0B3D91);
  static const Color azulClaro = Color(0xFF69C5D0);
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

  String get apiUrl => ApiConfig.baseUrl;

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor =>
      darkMode ? const Color(0xFF06101F) : const Color(0xFFEAF3FB);

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
        _get('/post/usuario/$userId?offset=0&limit=50'),
      ]);

      final seguidores = Map<String, dynamic>.from(resultados[0]);
      final seguindo = Map<String, dynamic>.from(resultados[1]);
      final postsRaw = resultados[2];

      final meusPostsBase = postsRaw is List
          ? postsRaw
              .whereType<Map>()
              .map((post) => _normalizarPost(Map<String, dynamic>.from(post)))
              .toList()
          : <Map<String, dynamic>>[];

      final meusPosts = await Future.wait(
        meusPostsBase.map((post) async {
          try {
            final comentarios =
                await _buscarComentarios(_toInt(post['id']));
            return {...post, 'comentarios': comentarios};
          } catch (_) {
            return {...post, 'comentarios': <Map<String, dynamic>>[]};
          }
        }),
      );

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
    return _imageProviderCache.putIfAbsent(
      value,
      () => ApiConfig.imageProvider(value),
    );
  }

  ImageProvider? _avatarProvider(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    return _imageProviderCache.putIfAbsent(
      value,
      () => ApiConfig.imageProvider(value),
    );
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
                                borderRadius: BorderRadius.circular(14),
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
          final isMedium = constraints.maxWidth < 1080;

          return Stack(
            children: [
              _BackgroundDecor(darkMode: darkMode),
              Row(
                children: [
                  if (!isCompact) _buildSidebar(),
                  Expanded(
                    child: _carregando && _usuario == null
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: azulPrincipal,
                            ),
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
    const collapsed = 88.0;
    const expanded = 244.0;
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
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF06152D),
          border: Border(
            right: BorderSide(
              color: azulPrincipal.withOpacity(0.09),
            ),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final showBrand =
                      constraints.maxWidth >= 150;

                  return Row(
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
                      if (showBrand) ...[
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
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
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Evolução contínua',
                                style: TextStyle(
                                  color: Color(0xFF8FA5C0),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Divider(color: azulPrincipal.withOpacity(0.10)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _sectionLabel('COMUNIDADE'),
                  _sidebarItem(
                    Icons.home_rounded,
                    'Feed',
                    '/feed',
                    false,
                  ),
                  _sidebarItem(
                    Icons.explore_outlined,
                    'Explorar',
                    '/explorar',
                    false,
                  ),
                  _sidebarItem(
                    Icons.edit_square,
                    'Postar',
                    '/postar',
                    false,
                  ),
                  const SizedBox(height: 8),
                  _sectionLabel('DESENVOLVIMENTO'),
                  _sidebarItem(
                    Icons.track_changes_rounded,
                    'Metas',
                    '/metas',
                    false,
                  ),
                  _sidebarItem(
                    Icons.psychology_outlined,
                    'Sala de foco',
                    '/foco',
                    false,
                  ),
                  _sidebarItem(
                    Icons.trending_up_rounded,
                    'Evolução',
                    '/evolucao',
                    false,
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08)),
            _sidebarItem(
              Icons.notifications_none_rounded,
              'Notificações',
              '/notificacoes',
              false,
            ),
            _sidebarItem(
              Icons.settings_outlined,
              'Configurações',
              '/config',
              false,
            ),
            _sidebarProfileItem(),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final show =
              _sidebarHovered && constraints.maxWidth > 90;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: show
                  ? Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF8FA5C0),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String label,
    String route,
    bool active,
  ) {
    final hovered = _sidebarItemHovered == route;
    final highlighted = active || hovered;

    return MouseRegion(
      onEnter: (_) =>
          setState(() => _sidebarItemHovered = route),
      onExit: (_) {
        if (_sidebarItemHovered == route) {
          setState(() => _sidebarItemHovered = null);
        }
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            Navigator.of(context).pushNamed(route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 50,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: highlighted
                ? Colors.white.withOpacity(0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: highlighted
                ? Border.all(
                    color: Colors.white.withOpacity(0.08),
                  )
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final show =
                  _sidebarHovered && constraints.maxWidth > 90;

              return Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Icon(
                      icon,
                      color: highlighted
                          ? Colors.white
                          : const Color(0xFFC7D5E8),
                      size: 23,
                    ),
                  ),
                  if (show) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: highlighted
                              ? Colors.white
                              : const Color(0xFFC7D5E8),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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
    final foto = _fotoPerfil();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF174A9B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: azulPrincipal.withOpacity(0.55),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final show =
              _sidebarHovered && constraints.maxWidth > 90;

          return Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -12,
                    top: 1,
                    bottom: 1,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC928),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF173154),
                    backgroundImage: _avatarProvider(foto),
                    child: foto.isEmpty
                        ? const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
              if (show) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_usuario?['username'] ??
                                _usuario?['nome_usuario'] ??
                                'Meu perfil')
                            .toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Ver perfil',
                        style: TextStyle(
                          color: Color(0xFF9FB3CE),
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(bool isCompact, bool isMedium) {
    final horizontal = isCompact ? 18.0 : (isMedium ? 28.0 : 38.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontal,
        isCompact ? 24 : 34,
        horizontal,
        80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(isCompact),
              const SizedBox(height: 18),
              _buildProfileCard(isCompact, isMedium),
              const SizedBox(height: 16),
              if (!isCompact && !isMedium)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 11,
                      child: _buildImagesSection(isCompact, isMedium),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 10,
                      child: _buildTextPostsSection(),
                    ),
                  ],
                )
              else ...[
                _buildImagesSection(isCompact, isMedium),
                const SizedBox(height: 14),
                _buildTextPostsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isCompact) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            SizedBox(
              width: 18,
              child: Divider(
                thickness: 3,
                color: Color(0xFFFFC928),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'COMUNIDADE',
              style: TextStyle(
                color: azulPrincipal,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Meu perfil',
          style: TextStyle(
            fontSize: isCompact ? 34 : 42,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sua identidade e suas publicações no Pace.',
          style: TextStyle(
            color: mutedColor,
            fontSize: 14,
          ),
        ),
      ],
    );

    if (isCompact) return copy;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: copy),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: darkMode
                ? const Color(0xFF0F1B2F)
                : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: darkMode
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFF06152D).withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: azulPrincipal,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Perfil pessoal',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(bool isCompact, bool isMedium) {
    final user = _usuario ?? {};
    final nome = (user['username'] ?? user['nome_usuario'] ?? '').toString();
    final email = (user['email'] ?? '').toString();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0A1C36)
            : Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.07)
              : const Color(0xFF06152D).withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(darkMode ? 0.14 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: isCompact ? 96 : 138,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: darkMode
                    ? const [
                        Color(0xFF0B3D91),
                        Color(0xFF123E80),
                        Color(0xFF174A9B),
                      ]
                    : const [
                        Color(0xFF1769E8),
                        Color(0xFF2A78EC),
                        Color(0xFF4B8CF0),
                      ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 56,
                  top: -52,
                  child: Transform.rotate(
                    angle: 0.28,
                    child: Container(
                      width: 180,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 24,
                  bottom: 18,
                  child: Container(
                    width: 88,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC928),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isCompact ? 18 : 20,
              0,
              isCompact ? 18 : 20,
              isCompact ? 18 : 20,
            ),
            child: isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -46),
                        child: _buildPhotoArea(),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -32),
                        child: _buildProfileBodyCompact(nome, email),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 170,
                        child: Transform.translate(
                          offset: const Offset(0, -54),
                          child: _buildPhotoArea(),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: _buildProfileBodyDesktop(nome, email),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBodyDesktop(String nome, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 27,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7A3),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Color(0xFFB97A00),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Em evolução',
                    style: TextStyle(
                      color: Color(0xFF9B6800),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildStatsRow(false),
        const SizedBox(height: 14),
        Divider(
          height: 1,
          color: darkMode
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF06152D).withOpacity(0.08),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(
              Icons.edit_note_rounded,
              color: azulPrincipal,
              size: 18,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Sobre você',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _buildSalvarBioButton(fullWidth: false),
          ],
        ),
        const SizedBox(height: 8),
        _buildBioField(),
      ],
    );
  }

  Widget _buildProfileBodyCompact(String nome, String email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nome,
          style: TextStyle(
            color: textColor,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          email,
          style: TextStyle(
            color: mutedColor,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        _buildStatsRow(true),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                'Sobre você',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _buildSalvarBioButton(fullWidth: false),
          ],
        ),
        const SizedBox(height: 8),
        _buildBioField(),
      ],
    );
  }

  Widget _buildBioField() {
    return TextField(
      controller: _bioController,
      minLines: 3,
      maxLines: 4,
      maxLength: 300,
      style: TextStyle(
        color: textColor,
        fontSize: 12.5,
      ),
      decoration: InputDecoration(
        hintText: 'Escreva algo sobre você...',
        hintStyle: TextStyle(
          color: mutedColor.withOpacity(0.84),
          fontSize: 12,
        ),
        counterStyle: TextStyle(
          color: mutedColor,
          fontSize: 9.5,
        ),
        filled: true,
        fillColor: darkMode
            ? const Color(0xFF0D2341)
            : const Color(0xFFF8FBFE),
        contentPadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkMode
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFF06152D).withOpacity(0.07),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: darkMode
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFF06152D).withOpacity(0.07),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: azulPrincipal.withOpacity(0.42),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoArea() {
    final foto = _fotoPerfil();

    return Column(
      children: [
        Container(
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1769E8),
                Color(0xFF66C5D0),
                Color(0xFFFFC928),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xFF0A1C36)
                  : Colors.white,
              borderRadius: BorderRadius.circular(19),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: foto.isEmpty
                  ? Container(
                      color: const Color(0xFF102846),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person_rounded,
                        size: 52,
                        color: mutedColor,
                      ),
                    )
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
        const SizedBox(height: 10),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _salvandoFoto ? null : _trocarFoto,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: azulPrincipal.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: azulPrincipal.withOpacity(0.10),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _salvandoFoto
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt_outlined,
                          size: 15,
                          color: azulPrincipal,
                        ),
                  const SizedBox(width: 6),
                  const Text(
                    'Trocar foto',
                    style: TextStyle(
                      color: azulPrincipal,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
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
    final cards = [
      _statCard(
        _totalPosts,
        'Posts',
        Icons.grid_view_rounded,
      ),
      _statCard(
        _totalSeguidores,
        'Seguidores',
        Icons.group_outlined,
      ),
      _statCard(
        _totalSeguindo,
        'Seguindo',
        Icons.person_add_alt_1_outlined,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 10),
        Expanded(child: cards[1]),
        const SizedBox(width: 10),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _statCard(
    int valor,
    String label,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0D2341)
            : const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFF06152D).withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: azulPrincipal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: azulPrincipal,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$valor',
                  style: const TextStyle(
                    color: azulPrincipal,
                    fontSize: 18,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String kicker,
    String title, {
    String? badge,
    IconData? badgeIcon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker.toUpperCase(),
                style: const TextStyle(
                  color: azulClaro,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xFF102846)
                  : const Color(0xFFEAF3FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if (badgeIcon != null) ...[
                  Icon(
                    badgeIcon,
                    size: 13,
                    color: mutedColor,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  badge,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
    final imagens =
        _meusPosts.where((post) => _postImagem(post).isNotEmpty).toList();
    final columns = _gridColumns(isCompact, isMedium);

    return _contentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Publicações', 'Minhas imagens', badge: 'Galeria', badgeIcon: Icons.photo_library_outlined),
          const SizedBox(height: 16),
          if (imagens.isEmpty)
            _emptyBox('Suas imagens publicadas aparecerão aqui.')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: imagens.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.18,
              ),
              itemBuilder: (_, index) {
                final post = imagens[index];
                final imagem = _postImagem(post);

                return _PostImageTile(
                  imagem: imagem,
                  likes: _postLikes(post),
                  comentarios: _postComentarios(post),
                  imageProvider: _imageProvider(imagem),
                  onTap: () => _abrirPost(post),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTextPostsSection() {
    final textos =
        _meusPosts.where((post) => _postTexto(post).isNotEmpty).toList();

    return _contentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Atividade', 'Meus posts', badge: 'Histórico', badgeIcon: Icons.forum_outlined),
          const SizedBox(height: 16),
          if (textos.isEmpty)
            _emptyBox('Nenhum post de texto publicado ainda.')
          else
            Column(
              children: textos.map((post) {
                final data = _formatDateCurta(post['data']);
                final likes = _postLikes(post);
                final comentarios = _postComentarios(post);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _abrirPost(post),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
                        decoration: BoxDecoration(
                          color: darkMode
                              ? const Color(0xFF0D2341)
                              : const Color(0xFFF8FBFE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: darkMode
                                ? Colors.white.withOpacity(0.06)
                                : const Color(0xFF06152D).withOpacity(0.06),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _postTexto(post),
                              style: TextStyle(
                                color: bodyTextColor,
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                if (data.isNotEmpty)
                                  _postMetaItem(
                                    Icons.schedule_rounded,
                                    data,
                                  ),
                                _postMetaItem(
                                  Icons.favorite_border_rounded,
                                  '$likes',
                                ),
                                _postMetaItem(
                                  Icons.chat_bubble_outline_rounded,
                                  '$comentarios',
                                ),
                              ],
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
      ),
    );
  }

  Widget _postMetaItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: mutedColor),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            color: mutedColor,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _contentCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0A1C36)
            : Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.07)
              : const Color(0xFF06152D).withOpacity(0.07),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(darkMode ? 0.10 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0D2341)
            : const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFF06152D).withOpacity(0.06),
        ),
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
            color: darkMode ? const Color(0xFF06101F) : const Color(0xFFEAF3FB),
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