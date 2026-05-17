import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  static const String apiUrl = "http://127.0.0.1:8000";

  List<Map<String, dynamic>> posts = [];
  Map<String, dynamic> usuarioLogado = {};

  bool isLoading = true;
  bool sidebarHovered = false;

  final TextEditingController editPostController = TextEditingController();
  final TextEditingController editCommentController = TextEditingController();

  final Map<int, TextEditingController> commentControllers = {};

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

  ImageProvider _avatarProvider(String? url) {
    if (url != null && url.trim().isNotEmpty) {
      return NetworkImage(url);
    }

    return const AssetImage('assets/user.png');
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
    return {
      'id': comentario['id'],
      'conteudo': comentario['conteudo'] ??
          comentario['texto'] ??
          comentario['comentario'] ??
          '',
      'usuario': {
        'id': comentario['usuario']?['id'] ?? comentario['usuario_id'],
        'username':
            comentario['usuario']?['username'] ?? comentario['username'] ?? 'Usuário',
        'foto_perfil':
            comentario['usuario']?['foto_perfil'] ?? comentario['foto_perfil'],
      },
    };
  }

  Map<String, dynamic> _normalizarPost(Map<String, dynamic> post) {
    return {
      'id': post['id'],
      'conteudo': post['conteudo'] ?? post['texto'] ?? '',
      'imagem': post['imagem'] ?? '',
      'likes': post['likes'] ?? 0,
      'liked': post['liked'] ?? false,
      'data': post['data_postagem'] ?? post['data'],
      'usuario': {
        'id': post['usuario']?['id'] ?? post['usuario_id'],
        'username': post['usuario']?['username'] ?? 'Usuário',
        'foto_perfil': post['usuario']?['foto_perfil'],
      },
      'comentarios': post['comentarios'] is List
          ? (post['comentarios'] as List)
              .whereType<Map<String, dynamic>>()
              .map(_normalizarComentario)
              .toList()
          : <Map<String, dynamic>>[],
    };
  }

  Future<void> _initFeed() async {
    final token = await _getToken();

    if (!mounted) return;

    if (token == null) {
      Navigator.of(context).pushReplacementNamed('entrar');
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
          Navigator.of(context).pushReplacementNamed('entrar');
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
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> _getPostsAPI(String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/post/feed'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = await _parseResponse(response, 'Erro ao buscar posts.');

    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(_normalizarPost)
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

    final data = await _parseResponse(
      response,
      'Erro ao buscar comentários.',
    );

    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(_normalizarComentario)
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

      if (post.isNotEmpty) {
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
      final response = await http.put(
        Uri.parse('$apiUrl/post/atualizar_post/$postId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'conteudo': novoTexto.trim(),
          'imagem': '',
        }),
      );

      await _parseResponse(response, 'Erro ao editar post.');

      final post = posts.firstWhere(
        (item) => item['id'] == postId,
        orElse: () => {},
      );

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                        Text(title, style: AppText.dialogTitle),
                        const SizedBox(height: 6),
                        Text(message, style: AppText.muted),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const Text('Refinar publicação', style: AppText.bigTitle),
              const SizedBox(height: 8),
              const Text(
                'Atualize sua legenda com mais clareza antes de salvar.',
                style: AppText.muted,
              ),
              const SizedBox(height: 20),
              const Text(
                'Texto do post',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF33415C),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: editPostController,
                maxLines: 6,
                decoration: AppInput.textArea('Digite aqui...'),
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
                      children: const [
                        Text('Editar comentário', style: AppText.dialogTitle),
                        SizedBox(height: 6),
                        Text('Altere seu comentário.', style: AppText.muted),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: editCommentController,
                maxLines: 4,
                decoration: AppInput.textArea('Digite o novo comentário...'),
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
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7FB),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3059AA),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          const _BackgroundDecor(),
          Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(42, 42, 42, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHero(),
                      const SizedBox(height: 30),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 780),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ATUALIZAÇÕES',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: Color(0xFF5EB1BF),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Posts recentes',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B2233),
                              ),
                            ),
                            const SizedBox(height: 16),
                            posts.isEmpty ? _buildEmptyFeed() : _buildPosts(),
                          ],
                        ),
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
      constraints: const BoxConstraints(maxWidth: 1100),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 760;

          return Flex(
            direction: isSmall ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment:
                isSmall ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Badge(text: 'Comunidade em movimento'),
                    SizedBox(height: 14),
                    Text(
                      'Seu feed no Pace',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B2233),
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: 720,
                      child: Text(
                        'Acompanhe o que a comunidade está construindo, compartilhe progresso e mantenha sua rotina\ncercada de pessoas que também estão evoluindo.',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.65,
                          color: Color(0xFF6F7B91),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isSmall ? 0 : 20, height: isSmall ? 22 : 0),
              Padding(
                padding: EdgeInsets.only(
                  right: isSmall ? 0 : 110,
                  bottom: isSmall ? 0 : 2,
                ),
                child: _PrimaryButton(
                  text: 'Criar post',
                  icon: Icons.edit_square,
                  onTap: () => Navigator.of(context).pushNamed('postar'),
                ),
              ),
            ],
          );
        },
      ),
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
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3059AA).withOpacity(0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF3059AA),
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Nenhum post por enquanto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2233),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Quando a comunidade começar a publicar, tudo vai aparecer aqui. Se quiser abrir os trabalhos, crie o primeiro post agora.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.8,
              color: Color(0xFF6F7B91),
            ),
          ),
          const SizedBox(height: 24),
          _PrimaryButton(
            text: 'Criar post',
            icon: Icons.edit_square,
            onTap: () => Navigator.of(context).pushNamed('postar'),
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
    final usuario = post['usuario'] as Map<String, dynamic>;
    final comentarios = post['comentarios'] as List;
    final isMyPost = _isMine(usuario['id']);
    final postId = post['id'] as int;

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
                  backgroundImage: _avatarProvider(usuario['foto_perfil']),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usuario['username'] ?? 'Usuário', style: AppText.name),
                      const SizedBox(height: 3),
                      Text(
                        '@${usuario['username'] ?? 'usuario'}'
                        '${_formatDate(post['data']).isNotEmpty ? ' • ${_formatDate(post['data'])}' : ''}',
                        style: AppText.mutedSmall,
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
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: Color(0xFF24304A),
                ),
              ),
            ],
            if ((post['imagem'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  post['imagem'],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 220,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3059AA).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF3059AA).withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${comentarios.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D6B84),
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
                    .map((comentario) => _buildComment(postId, comentario))
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

  Widget _buildComment(int postId, dynamic comentario) {
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
            backgroundImage: _avatarProvider(usuario['foto_perfil']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3059AA).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          usuario['username'] ?? 'Usuário',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF1B2233),
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
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: Color(0xFF24304A),
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
            decoration: InputDecoration(
              hintText: 'Compartilhe algo...',
              filled: true,
              fillColor: Colors.white.withOpacity(0.84),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: const Color(0xFF3059AA).withOpacity(0.14),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: const Color(0xFF3059AA).withOpacity(0.14),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: const Color(0xFF3059AA).withOpacity(0.34),
                ),
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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3059AA).withOpacity(0.2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
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
    const collapsed = 84.0;
    const expanded = 230.0;
    final width = sidebarHovered ? expanded : collapsed;

    return MouseRegion(
      onEnter: (_) => setState(() => sidebarHovered = true),
      onExit: (_) => setState(() => sidebarHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        width: width,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.78),
          border: Border(
            right: BorderSide(color: Colors.white.withOpacity(0.55)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                Container(
                  width: sidebarHovered ? 130 : 44,
                  height: 44,
                  margin: const EdgeInsets.only(bottom: 58),
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/Ícone_Pace.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _sidebarItem(Icons.home_outlined, 'Feed', 'feed', true),
                      _sidebarItem(Icons.track_changes, 'Metas', 'metas', false),
                      _sidebarItem(Icons.explore_outlined, 'Explorar', 'explorar', false),
                      _sidebarItem(Icons.add_box_outlined, 'Postar', 'postar', false),
                      _sidebarItem(Icons.notifications_none, 'Notificações', 'notificacoes', false),
                      const SizedBox(height: 10),
                      Divider(color: const Color(0xFF3059AA).withOpacity(0.16)),
                      const SizedBox(height: 10),
                      _sidebarItem(Icons.settings_outlined, 'Configurações', 'config', false),
                      _sidebarItem(Icons.person_outline, 'Perfil', 'perfil', false),
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
  return InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: () {
      if (route != 'feed') {
        Navigator.of(context).pushNamed(route);
      }
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        gradient: active
            ? LinearGradient(
                colors: [
                  const Color(0xFF3059AA).withOpacity(0.12),
                  const Color(0xFF5EB1BF).withOpacity(0.08),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(14),
        border: active
            ? Border.all(color: const Color(0xFF3059AA).withOpacity(0.08))
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
                  color: active
                      ? const Color(0xFF3059AA)
                      : const Color(0xFF33415C),
                  size: 24,
                ),
              ),
              if (showText) ...[
                const SizedBox(width: 15),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: showText ? 1 : 0,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF3059AA)
                            : const Color(0xFF33415C),
                        fontWeight: FontWeight.w700,
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
  );
}
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: const [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFF4F7FB),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -120,
          left: 40,
          child: _SoftOrb(
            size: 420,
            color: Color(0x225EB1BF),
            blur: 120,
          ),
        ),
        Positioned(
          bottom: -120,
          left: -120,
          child: _SoftOrb(
            size: 420,
            color: Color(0x185EB1BF),
            blur: 130,
          ),
        ),
        Positioned(
          top: -140,
          right: -80,
          child: _SoftOrb(
            size: 360,
            color: Color(0x143059AA),
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

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14274D).withOpacity(0.10),
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
              color: Colors.white.withOpacity(0.84),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.65)),
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

  const _GlassDialog({
    required this.child,
    this.maxWidth = 430,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _GlassCard(
          padding: const EdgeInsets.all(24),
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
        color: const Color(0xFF3059AA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF3059AA),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
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
        label: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
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

  const _GhostButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF455572),
        backgroundColor: const Color(0xFFF0F2F5),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(text),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _DangerButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFFE55353),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
    final color = liked ? const Color(0xFFD8425C) : const Color(0xFF44536F);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: liked
              ? const Color(0xFFE64862).withOpacity(0.12)
              : const Color(0xFFEDF2FB),
          borderRadius: BorderRadius.circular(999),
          border: liked
              ? Border.all(color: const Color(0xFFE64862).withOpacity(0.14))
              : null,
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppText {
  static const name = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1B2233),
  );

  static const muted = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: Color(0xFF6F7B91),
  );

  static const mutedSmall = TextStyle(
    fontSize: 13,
    color: Color(0xFF6F7B91),
  );

  static const dialogTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1B2233),
  );

  static const bigTitle = TextStyle(
    fontSize: 28,
    height: 1.05,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1B2233),
  );
}

class AppInput {
  static InputDecoration textArea(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withOpacity(0.95),
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: const Color(0xFF3059AA).withOpacity(0.14),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: const Color(0xFF3059AA).withOpacity(0.35),
        ),
      ),
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