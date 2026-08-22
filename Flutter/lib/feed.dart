import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'pace_shell.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String get apiUrl => ApiConfig.baseUrl;

  List<Map<String, dynamic>> posts = [];
  Map<String, dynamic> usuarioLogado = {};

  bool isLoading = true;
  bool sidebarHovered = false;
  String? sidebarItemHovered;

  final TextEditingController editPostController = TextEditingController();
  final TextEditingController editCommentController = TextEditingController();
  final Map<int, TextEditingController> commentControllers = {};

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor =>
      darkMode ? const Color(0xFF05070C) : const Color(0xFFF4F7FB);

  Color get textColor =>
      darkMode ? const Color(0xFFF3F6FF) : const Color(0xFF1B2233);

  Color get mutedColor =>
      darkMode ? const Color(0xFF9CA7BE) : const Color(0xFF6F7B91);

  Color get bodyTextColor =>
      darkMode ? const Color(0xFFD7DDF0) : const Color(0xFF24304A);

  Color get labelColor =>
      darkMode ? const Color(0xFFD7DDF0) : const Color(0xFF33415C);

  Color get sidebarTextColor =>
      darkMode ? const Color(0xFFF1F5FF) : const Color(0xFF33415C);

  Color get inputFillColor => darkMode
      ? Colors.white.withOpacity(0.04)
      : Colors.white.withOpacity(0.84);

  @override
  void initState() {
    super.initState();
    _initFeed();
  }

  @override
  void dispose() {
    editPostController.dispose();
    editCommentController.dispose();

    for (final controller in commentControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  TextEditingController _commentControllerFor(int postId) {
    return commentControllers.putIfAbsent(
      postId,
      () => TextEditingController(),
    );
  }

  ImageProvider _avatarProvider(String? value) {
    return ApiConfig.imageProvider(value);
  }

  String? _fotoUsuarioLogado() {
    final foto = usuarioLogado['foto_perfil'] ?? usuarioLogado['foto'];
    if (foto == null || foto.toString().trim().isEmpty) return null;
    return foto.toString();
  }

  Future<dynamic> _parseResponse(
    http.Response response,
    String fallbackMessage,
  ) async {
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
          : fallbackMessage;

      throw Exception(message);
    }

    return data;
  }

  Map<String, dynamic> _normalizarComentario(Map<String, dynamic> comentario) {
    final usuario = comentario['usuario'];

    return {
      'id': NumberParser.toInt(comentario['id']),
      'conteudo':
          comentario['conteudo'] ??
          comentario['texto'] ??
          comentario['comentario'] ??
          '',
      'usuario': {
        'id': usuario is Map ? usuario['id'] : comentario['usuario_id'],
        'username': usuario is Map
            ? usuario['username'] ?? 'Usuário'
            : comentario['username'] ?? 'Usuário',
        'foto_perfil': usuario is Map
            ? usuario['foto_perfil'] ?? usuario['foto']
            : comentario['foto_perfil'] ?? comentario['foto'],
      },
    };
  }

  Map<String, dynamic> _normalizarPost(Map<String, dynamic> post) {
    final usuario = post['usuario'];

    return {
      'id': NumberParser.toInt(post['id']),
      'conteudo': post['conteudo'] ?? post['texto'] ?? '',
      'imagem': post['imagem'] ?? '',
      'likes': NumberParser.toInt(post['likes']),
      'liked': post['liked'] ?? false,
      'data': post['data_postagem'] ?? post['data'],
      'usuario': {
        'id': usuario is Map ? usuario['id'] : post['usuario_id'],
        'username': usuario is Map
            ? usuario['username'] ?? 'Usuário'
            : 'Usuário',
        'foto_perfil': usuario is Map
            ? usuario['foto_perfil'] ?? usuario['foto']
            : post['foto_perfil'] ?? post['foto'],
      },
      'comentarios': post['comentarios'] is List
          ? (post['comentarios'] as List)
                .where((item) => item is Map)
                .map(
                  (item) => _normalizarComentario(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : <Map<String, dynamic>>[],
    };
  }

  Future<void> _initFeed() async {
    final token = await _getToken();

    if (!mounted) return;

    if (token == null) {
      Navigator.of(context).pushReplacementNamed('/entrar');
      return;
    }

    try {
      final usuarioData = await _buscarUsuarioAPI(token);
      final postsData = await _getPostsAPI(token);

      for (final post in postsData) {
        post['comentarios'] = await _buscarComentariosAPI(token, post['id']);
      }

      if (!mounted) return;

      setState(() {
        usuarioLogado = usuarioData;
        posts = postsData;
        isLoading = false;
      });
    } catch (e) {
      if (e.toString().contains('AUTH_401')) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/entrar');
        }
        return;
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showToast('Não foi possível carregar o feed.', Colors.red);
    }
  }

  Future<Map<String, dynamic>> _buscarUsuarioAPI(String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/profile/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = await _parseResponse(response, 'Erro ao buscar usuário.');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<List<Map<String, dynamic>>> _getPostsAPI(String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/post/feed'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = await _parseResponse(response, 'Erro ao buscar posts.');

    if (data is! List) return [];

    return data
        .where((item) => item is Map)
        .map((item) => _normalizarPost(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _buscarComentariosAPI(
    String token,
    int postId,
  ) async {
    final response = await http.get(
      Uri.parse('$apiUrl/comments/comentarios/$postId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = await _parseResponse(response, 'Erro ao buscar comentários.');

    if (data is! List) return [];

    return data
        .where((item) => item is Map)
        .map(
          (item) =>
              _normalizarComentario(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> _toggleLike(int postId) async {
    final token = await _getToken();
    if (token == null) return;

    final post = posts.firstWhere(
      (item) => item['id'] == postId,
      orElse: () => {},
    );

    if (post.isEmpty) return;

    final bool likedBefore = post['liked'] == true;
    final int likesBefore = NumberParser.toInt(post['likes']);

    setState(() {
      post['liked'] = !likedBefore;
      post['likes'] = likedBefore ? likesBefore - 1 : likesBefore + 1;
      if (post['likes'] < 0) post['likes'] = 0;
    });

    try {
      final response = likedBefore
          ? await http.delete(
              Uri.parse('$apiUrl/post/remover_curtida/$postId'),
              headers: {'Authorization': 'Bearer $token'},
            )
          : await http.post(
              Uri.parse('$apiUrl/post/curtir/$postId'),
              headers: {'Authorization': 'Bearer $token'},
            );

      await _parseResponse(response, 'Erro ao curtir post.');
    } catch (e) {
      setState(() {
        post['liked'] = likedBefore;
        post['likes'] = likesBefore;
      });

      _showToast('Erro ao curtir post.', Colors.red);
    }
  }

  Future<void> _criarComentario(int postId) async {
    final token = await _getToken();
    if (token == null) return;

    final controller = _commentControllerFor(postId);
    final texto = controller.text.trim();

    if (texto.isEmpty) {
      _showToast('Escreva um comentário antes de enviar.', Colors.orange);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiUrl/comments/adicionar_comentario/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'conteudo': texto}),
      );

      final data = await _parseResponse(response, 'Erro ao comentar.');

      final post = posts.firstWhere(
        (item) => item['id'] == postId,
        orElse: () => {},
      );

      if (post.isNotEmpty && data is Map) {
        setState(() {
          post['comentarios'].add(
            _normalizarComentario(Map<String, dynamic>.from(data)),
          );
          controller.clear();
        });

        _showToast('Comentário publicado com sucesso!', Colors.green);
      }
    } catch (e) {
      _showToast('Erro ao comentar.', Colors.red);
    }
  }

  Future<void> _editarPost(int postId, String novoTexto) async {
    final token = await _getToken();
    if (token == null) return;

    if (novoTexto.trim().isEmpty) {
      _showToast('O texto do post não pode ficar vazio.', Colors.orange);
      return;
    }

    try {
      final post = posts.firstWhere(
        (item) => item['id'] == postId,
        orElse: () => {},
      );

      final response = await http.put(
        Uri.parse('$apiUrl/post/atualizar_post/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conteudo': novoTexto.trim(),
          'imagem': post['imagem'] ?? '',
        }),
      );

      await _parseResponse(response, 'Erro ao editar post.');

      if (post.isNotEmpty) {
        setState(() {
          post['conteudo'] = novoTexto.trim();
        });

        _showToast('Post atualizado com sucesso!', Colors.green);
      }
    } catch (e) {
      _showToast('Erro ao editar post.', Colors.red);
    }
  }

  Future<void> _excluirPost(int postId) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/post/deletar/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      await _parseResponse(response, 'Erro ao excluir post.');

      setState(() {
        posts.removeWhere((post) => post['id'] == postId);
      });

      _showToast('Post excluído com sucesso!', Colors.green);
    } catch (e) {
      _showToast('Erro ao excluir post.', Colors.red);
    }
  }

  Future<void> _editarComentario(int comentarioId, String novoTexto) async {
    final token = await _getToken();
    if (token == null) return;

    if (novoTexto.trim().isEmpty) {
      _showToast('O comentário não pode ficar vazio.', Colors.orange);
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('$apiUrl/comments/atualizar_comentario/$comentarioId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'conteudo': novoTexto.trim()}),
      );

      await _parseResponse(response, 'Erro ao editar comentário.');

      for (final post in posts) {
        final comentarios = post['comentarios'] as List;

        for (final comentario in comentarios) {
          if (comentario['id'] == comentarioId) {
            setState(() {
              comentario['conteudo'] = novoTexto.trim();
            });

            _showToast('Comentário atualizado com sucesso!', Colors.green);
            return;
          }
        }
      }
    } catch (e) {
      _showToast('Erro ao editar comentário.', Colors.red);
    }
  }

  Future<void> _excluirComentario(int comentarioId) async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/comments/deletar_comentario/$comentarioId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      await _parseResponse(response, 'Erro ao excluir comentário.');

      setState(() {
        for (final post in posts) {
          (post['comentarios'] as List).removeWhere(
            (comentario) => comentario['id'] == comentarioId,
          );
        }
      });

      _showToast('Comentário excluído com sucesso!', Colors.green);
    } catch (e) {
      _showToast('Erro ao excluir comentário.', Colors.red);
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

  void _showDeletePostDialog(int postId) {
    _showConfirmDialog(
      icon: Icons.error_outline,
      title: 'Excluir post',
      message: 'Tem certeza que deseja excluir este post?',
      confirmText: 'Excluir',
      onConfirm: () => _excluirPost(postId),
    );
  }

  void _showDeleteCommentDialog(int comentarioId) {
    _showConfirmDialog(
      icon: Icons.message_outlined,
      title: 'Excluir comentário',
      message: 'Tem certeza que deseja excluir este comentário?',
      confirmText: 'Excluir',
      onConfirm: () => _excluirComentario(comentarioId),
    );
  }

  void _showConfirmDialog({
    required IconData icon,
    required String title,
    required String message,
    required String confirmText,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return _GlassDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: const Color(0xFFE55353), size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.dialogTitle(darkMode)),
                        const SizedBox(height: 6),
                        Text(message, style: AppText.muted(darkMode)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostButton(
                    text: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  _DangerButton(
                    text: confirmText,
                    onTap: () async {
                      Navigator.pop(context);
                      await onConfirm();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditPostDialog(int postId) {
    final post = posts.firstWhere(
      (item) => item['id'] == postId,
      orElse: () => {},
    );

    if (post.isEmpty) return;

    editPostController.text = post['conteudo'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return _GlassDialog(
          maxWidth: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _CircleIconButton(
                  icon: Icons.close,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF3059AA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'EDITOR DE POST',
                  style: TextStyle(
                    color: Color(0xFF3059AA),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Refinar publicação', style: AppText.bigTitle(darkMode)),
              const SizedBox(height: 8),
              Text(
                'Atualize sua legenda com mais clareza antes de salvar.',
                style: AppText.muted(darkMode),
              ),
              const SizedBox(height: 20),
              Text(
                'Texto do post',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: editPostController,
                maxLines: 6,
                style: TextStyle(color: textColor),
                cursorColor: const Color(0xFF3059AA),
                decoration: AppInput.textArea(
                  'Digite aqui...',
                  darkMode: darkMode,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostButton(
                    text: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  _PrimaryButton(
                    text: 'Salvar alterações',
                    icon: Icons.check,
                    onTap: () async {
                      Navigator.pop(context);
                      await _editarPost(postId, editPostController.text);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCommentDialog(int comentarioId) {
    Map<String, dynamic>? comentario;

    for (final post in posts) {
      for (final item in post['comentarios'] as List) {
        if (item['id'] == comentarioId) {
          comentario = Map<String, dynamic>.from(item);
          break;
        }
      }
    }

    if (comentario == null) return;

    editCommentController.text = comentario['conteudo'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return _GlassDialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF3059AA),
                    size: 34,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar comentário',
                          style: AppText.dialogTitle(darkMode),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Altere seu comentário.',
                          style: AppText.muted(darkMode),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: editCommentController,
                maxLines: 4,
                style: TextStyle(color: textColor),
                cursorColor: const Color(0xFF3059AA),
                decoration: AppInput.textArea(
                  'Digite o novo comentário...',
                  darkMode: darkMode,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostButton(
                    text: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  _PrimaryButton(
                    text: 'Salvar',
                    icon: Icons.check,
                    onTap: () async {
                      Navigator.pop(context);
                      await _editarComentario(
                        comentarioId,
                        editCommentController.text,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  bool _isMine(dynamic userId) {
    return userId?.toString() == usuarioLogado['id']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mobile = screenWidth < 760;
    final tablet = screenWidth >= 760 && screenWidth < 1080;

    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF315CAC)),
        ),
      );
    }

    return PaceShell(
      currentRoute: '/feed',
      username: usuarioLogado['username']?.toString() ?? 'Meu perfil',
      avatarValue: _fotoUsuarioLogado(),
      backgroundColor: bgColor,
      child: Stack(
        children: [
          _BackgroundDecor(darkMode: darkMode),
          _buildFeedContent(
            horizontalPadding: mobile
                ? (screenWidth <= 430 ? 16 : 20)
                : (tablet ? 28 : 38),
            topPadding: mobile ? 24 : (tablet ? 32 : 38),
            bottomPadding: mobile ? 70 : 90,
            mobile: mobile,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent({
    required double horizontalPadding,
    required double topPadding,
    required double bottomPadding,
    required bool mobile,
  }) {
    return RefreshIndicator(
      color: const Color(0xFF315CAC),
      onRefresh: _recarregarFeed,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          topPadding,
          horizontalPadding,
          bottomPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(),
                SizedBox(height: mobile ? 30 : 36),

                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFeedHeader(mobile),
                        const SizedBox(height: 16),
                        posts.isEmpty ? _buildEmptyFeed() : _buildPosts(),
                      ],
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

  Future<void> _recarregarFeed() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final usuarioData = await _buscarUsuarioAPI(token);
      final postsData = await _getPostsAPI(token);

      for (final post in postsData) {
        try {
          post['comentarios'] = await _buscarComentariosAPI(
            token,
            NumberParser.toInt(post['id']),
          );
        } catch (_) {
          post['comentarios'] = <Map<String, dynamic>>[];
        }
      }

      if (!mounted) return;

      setState(() {
        usuarioLogado = usuarioData;
        posts = postsData;
      });
    } catch (e) {
      if (e.toString().contains('AUTH_401')) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/entrar');
        }
        return;
      }

      _showToast('Não foi possível atualizar o feed.', Colors.red);
    }
  }

  Widget _buildFeedHeader(bool mobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ATUALIZAÇÕES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: Color(0xFF69C5D0),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Posts recentes',
                style: TextStyle(
                  fontSize: mobile ? 27 : 29,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        if (!mobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: darkMode
                  ? Colors.white.withOpacity(0.04)
                  : Colors.white.withOpacity(0.62),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF315CAC).withOpacity(0.08),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OnlineDot(),
                SizedBox(width: 8),
                Text(
                  'Atualizado agora',
                  style: TextStyle(
                    color: Color(0xFF6F7F96),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMobileTopBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: darkMode
              ? const Color(0xF2080A0E)
              : Colors.white.withOpacity(0.88),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF315CAC).withOpacity(0.08),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15284D).withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    'assets/images/pace_icon.png',
                    width: 42,
                    height: 42,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pace',
                    style: TextStyle(
                      color: darkMode ? Colors.white : const Color(0xFF315CAC),
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toque na logo para abrir o menu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _CircleIconButton(
              icon: Icons.notifications_none_rounded,
              onTap: () => Navigator.of(context).pushNamed('/notificacoes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      width: 292,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 8, 0, 8),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: darkMode
                ? const Color(0xFF0B0D12).withOpacity(0.98)
                : const Color(0xFFF8FBFF).withOpacity(0.98),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(28),
            ),
            border: Border.all(
              color: darkMode
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFF315CAC).withOpacity(0.09),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(darkMode ? 0.34 : 0.14),
                blurRadius: 42,
                offset: const Offset(12, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/pace_icon.png',
                    width: 46,
                    height: 46,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pace',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        Text(
                          'Evolução contínua',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(
                height: 1,
                color: const Color(0xFF315CAC).withOpacity(0.10),
              ),
              const SizedBox(height: 18),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _drawerSectionLabel('COMUNIDADE'),
                    _mobileDrawerItem(
                      Icons.home_rounded,
                      'Feed',
                      '/feed',
                      active: true,
                    ),
                    _mobileDrawerItem(
                      Icons.explore_outlined,
                      'Explorar',
                      '/explorar',
                    ),
                    _mobileDrawerItem(Icons.edit_square, 'Postar', '/postar'),

                    const SizedBox(height: 12),
                    _drawerSectionLabel('DESENVOLVIMENTO'),
                    _mobileDrawerItem(
                      Icons.track_changes_rounded,
                      'Metas',
                      '/metas',
                    ),
                    _mobileDrawerItem(
                      Icons.psychology_outlined,
                      'Sala de foco',
                      '/foco',
                    ),
                    _mobileDrawerItem(
                      Icons.trending_up_rounded,
                      'Evolução',
                      '/evolucao',
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: const Color(0xFF315CAC).withOpacity(0.10),
              ),
              const SizedBox(height: 12),
              _mobileDrawerItem(
                Icons.notifications_none_rounded,
                'Notificações',
                '/notificacoes',
              ),
              _mobileDrawerItem(
                Icons.settings_outlined,
                'Configurações',
                '/config',
              ),
              _mobileProfileItem(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Text(
        text,
        style: TextStyle(
          color: mutedColor.withOpacity(0.8),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.25,
        ),
      ),
    );
  }

  Widget _mobileDrawerItem(
    IconData icon,
    String label,
    String route, {
    bool active = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();

            if (!active) {
              Future.delayed(const Duration(milliseconds: 120), () {
                if (mounted) Navigator.of(context).pushNamed(route);
              });
            }
          },
          borderRadius: BorderRadius.circular(15),
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      colors: [
                        const Color(0xFF315CAC).withOpacity(0.14),
                        const Color(0xFF69C5D0).withOpacity(0.09),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(15),
              border: active
                  ? Border.all(color: const Color(0xFF315CAC).withOpacity(0.10))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF315CAC).withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: active ? const Color(0xFF315CAC) : sidebarTextColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF315CAC)
                          : sidebarTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!active)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: mutedColor.withOpacity(0.65),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobileProfileItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          Future.delayed(const Duration(milliseconds: 120), () {
            if (mounted) Navigator.of(context).pushNamed('/perfil');
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF315CAC).withOpacity(darkMode ? 0.10 : 0.055),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _avatarProvider(_fotoUsuarioLogado()),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuarioLogado['username']?.toString() ?? 'Meu perfil',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ver perfil',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: mutedColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;

        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Badge(text: 'Comunidade em movimento'),
            SizedBox(height: mobile ? 18 : 16),
            Text(
              'Seu feed no Pace',
              style: TextStyle(
                fontSize: mobile ? 38 : 52,
                height: 1.01,
                fontWeight: FontWeight.w800,
                letterSpacing: mobile ? -1.7 : -2.4,
                color: textColor,
              ),
            ),
            SizedBox(height: mobile ? 16 : 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Text(
                'Acompanhe o que a comunidade está construindo, compartilhe '
                'progresso e mantenha sua rotina cercada de pessoas que também '
                'estão evoluindo.',
                style: TextStyle(
                  fontSize: mobile ? 16 : 16.5,
                  height: mobile ? 1.62 : 1.65,
                  color: mutedColor,
                ),
              ),
            ),
          ],
        );

        if (mobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              copy,
              const SizedBox(height: 22),
              _PrimaryButton(
                text: 'Criar post',
                icon: Icons.edit_square,
                onTap: () => Navigator.of(context).pushNamed('/postar'),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: copy),
            const SizedBox(width: 32),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _PrimaryButton(
                text: 'Criar post',
                icon: Icons.edit_square,
                onTap: () => Navigator.of(context).pushNamed('/postar'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyFeed() {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3059AA).withOpacity(0.14),
                  const Color(0xFF5EB1BF).withOpacity(0.18),
                ],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF3059AA),
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Nenhum post por enquanto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Quando a comunidade começar a publicar, tudo vai aparecer aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.8, color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPosts() {
    return Column(
      children: posts.asMap().entries.map((entry) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 450 + entry.key * 70),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - value)),
                child: child,
              ),
            );
          },
          child: _buildPostCard(entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final usuario = Map<String, dynamic>.from(post['usuario'] ?? {});
    final comentarios = post['comentarios'] as List;
    final isMyPost = _isMine(usuario['id']);
    final postId = NumberParser.toInt(post['id']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: _avatarProvider(
                    usuario['foto_perfil']?.toString(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario['username'] ?? 'Usuário',
                        style: AppText.name(darkMode),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${usuario['username'] ?? 'usuario'}'
                        '${_formatDate(post['data']).isNotEmpty ? ' • ${_formatDate(post['data'])}' : ''}',
                        style: AppText.mutedSmall(darkMode),
                      ),
                    ],
                  ),
                ),
                if (isMyPost) ...[
                  _CircleIconButton(
                    icon: Icons.edit_outlined,
                    onTap: () => _showEditPostDialog(postId),
                  ),
                  const SizedBox(width: 8),
                  _CircleIconButton(
                    icon: Icons.delete_outline,
                    danger: true,
                    onTap: () => _showDeletePostDialog(postId),
                  ),
                ],
              ],
            ),
            if ((post['conteudo'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                post['conteudo'],
                style: TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: bodyTextColor,
                ),
              ),
            ],
            if ((post['imagem'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image(
                  image: ApiConfig.imageProvider(
                    post['imagem'],
                    fallbackAsset: 'assets/user.png',
                  ),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 220,
                      color: darkMode
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: mutedColor,
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _LikeButton(
                  liked: post['liked'] == true,
                  likes: NumberParser.toInt(post['likes']),
                  onTap: () => _toggleLike(postId),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF3059AA,
                    ).withOpacity(darkMode ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: darkMode
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFF3059AA).withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        size: 18,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${comentarios.length}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (comentarios.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                children: comentarios
                    .map((comentario) => _buildComment(comentario))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            _buildCommentInput(postId),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(dynamic comentario) {
    final item = Map<String, dynamic>.from(comentario);
    final usuario = Map<String, dynamic>.from(item['usuario'] ?? {});
    final isMyComment = _isMine(usuario['id']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundImage: _avatarProvider(
              usuario['foto_perfil']?.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF3059AA,
                ).withOpacity(darkMode ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: darkMode
                      ? Colors.white.withOpacity(0.06)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          usuario['username'] ?? 'Usuário',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (isMyComment) ...[
                        _TinyIconButton(
                          icon: Icons.edit_outlined,
                          onTap: () => _showEditCommentDialog(item['id']),
                        ),
                        const SizedBox(width: 6),
                        _TinyIconButton(
                          icon: Icons.delete_outline,
                          danger: true,
                          onTap: () => _showDeleteCommentDialog(item['id']),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['conteudo'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: bodyTextColor,
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

  Widget _buildCommentInput(int postId) {
    final controller = _commentControllerFor(postId);

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onSubmitted: (_) => _criarComentario(postId),
            style: TextStyle(color: textColor),
            cursorColor: const Color(0xFF3059AA),
            decoration: InputDecoration(
              hintText: 'Compartilhe algo...',
              hintStyle: TextStyle(color: mutedColor),
              filled: true,
              fillColor: inputFillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: darkMode
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFF3059AA).withOpacity(0.14),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: const Color(0xFF3059AA).withOpacity(0.34),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3059AA), Color(0xFF4C71C7)],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white, size: 19),
            onPressed: () => _criarComentario(postId),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    const collapsed = 88.0;
    const expanded = 244.0;
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: darkMode
              ? const Color(0xF20B0D12)
              : const Color(0xFFF8FBFF).withOpacity(0.92),
          border: Border(
            right: BorderSide(color: const Color(0xFF315CAC).withOpacity(0.09)),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF112348,
              ).withOpacity(darkMode ? 0.28 : 0.08),
              blurRadius: 34,
              offset: const Offset(12, 0),
            ),
          ],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                  child: Row(
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
                      if (sidebarHovered) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 170),
                            opacity: sidebarHovered ? 1 : 0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pace',
                                  style: TextStyle(
                                    color: Color(0xFF315CAC),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Evolução contínua',
                                  style: TextStyle(
                                    color: mutedColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: const Color(0xFF315CAC).withOpacity(0.10),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _sidebarSectionLabel('COMUNIDADE'),
                      _sidebarItem(Icons.home_rounded, 'Feed', '/feed', true),
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

                      const SizedBox(height: 10),
                      _sidebarSectionLabel('DESENVOLVIMENTO'),
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

                Divider(
                  height: 1,
                  color: const Color(0xFF315CAC).withOpacity(0.08),
                ),
                const SizedBox(height: 8),
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
        ),
      ),
    );
  }

  Widget _sidebarSectionLabel(String label) {
    if (!sidebarHovered) {
      return const SizedBox(height: 6);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: sidebarHovered ? 1 : 0,
        child: Text(
          label,
          style: TextStyle(
            color: mutedColor.withOpacity(0.78),
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.25,
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

  Widget _sidebarItem(IconData icon, String label, String route, bool active) {
    final isHovered = sidebarItemHovered == route;
    final highlighted = active || isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => sidebarItemHovered = route),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (route != '/feed') {
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

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: const Color(0xFF37B47E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF37B47E).withOpacity(0.20),
            blurRadius: 0,
            spreadRadius: 4,
          ),
        ],
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

  const _SoftOrb({required this.size, required this.color, required this.blur});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14274D).withOpacity(darkMode ? 0.30 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xE00D0D10)
                  : Colors.white.withOpacity(0.84),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: darkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.65),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const _GlassDialog({required this.child, this.maxWidth = 430});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _GlassCard(padding: const EdgeInsets.all(24), child: child),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF315CAC).withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF315CAC).withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFF69C5D0),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF69C5D0).withOpacity(0.16),
                  blurRadius: 0,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF315CAC),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF416BC2),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3059AA).withOpacity(0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 21),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _GhostButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: darkMode
            ? const Color(0xFFD7DDF0)
            : const Color(0xFF455572),
        backgroundColor: darkMode
            ? Colors.white.withOpacity(0.06)
            : const Color(0xFFF0F2F5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(text),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _DangerButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFFE55353),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(text),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: danger
          ? const Color(0xFFE55353).withOpacity(0.10)
          : const Color(0xFF3059AA).withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 20,
            color: danger ? const Color(0xFFE55353) : const Color(0xFF3059AA),
          ),
        ),
      ),
    );
  }
}

class _TinyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  const _TinyIconButton({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: danger
          ? const Color(0xFFE55353).withOpacity(0.10)
          : const Color(0xFF3059AA).withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 16,
            color: danger ? const Color(0xFFE55353) : const Color(0xFF3059AA),
          ),
        ),
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool liked;
  final int likes;
  final VoidCallback onTap;

  const _LikeButton({
    required this.liked,
    required this.likes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final color = liked
        ? const Color(0xFFD8425C)
        : darkMode
        ? const Color(0xFFD7DDF0)
        : const Color(0xFF44536F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: liked
              ? const Color(0xFFE64862).withOpacity(0.12)
              : darkMode
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFEDF2FB),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: liked
                ? const Color(0xFFE64862).withOpacity(0.14)
                : darkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              '$likes',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class AppText {
  static TextStyle name(bool darkMode) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: darkMode ? const Color(0xFFF3F6FF) : const Color(0xFF1B2233),
    );
  }

  static TextStyle muted(bool darkMode) {
    return TextStyle(
      fontSize: 15,
      height: 1.5,
      color: darkMode ? const Color(0xFF9CA7BE) : const Color(0xFF6F7B91),
    );
  }

  static TextStyle mutedSmall(bool darkMode) {
    return TextStyle(
      fontSize: 13,
      color: darkMode ? const Color(0xFF9CA7BE) : const Color(0xFF6F7B91),
    );
  }

  static TextStyle dialogTitle(bool darkMode) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: darkMode ? const Color(0xFFF3F6FF) : const Color(0xFF1B2233),
    );
  }

  static TextStyle bigTitle(bool darkMode) {
    return TextStyle(
      fontSize: 28,
      height: 1.05,
      fontWeight: FontWeight.bold,
      color: darkMode ? const Color(0xFFF3F6FF) : const Color(0xFF1B2233),
    );
  }
}

class AppInput {
  static InputDecoration textArea(String hint, {required bool darkMode}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: darkMode ? const Color(0xFF9CA7BE) : const Color(0xFF6F7B91),
      ),
      filled: true,
      fillColor: darkMode
          ? Colors.white.withOpacity(0.04)
          : Colors.white.withOpacity(0.95),
      contentPadding: const EdgeInsets.all(18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: darkMode
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF3059AA).withOpacity(0.14),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: const Color(0xFF3059AA).withOpacity(0.35),
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class NumberParser {
  static int toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
