import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

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

  // ============================================================
  // FILTROS / COMUNIDADES LOCAIS
  // Mesma ideia da versão web, usando SharedPreferences como
  // armazenamento local no Flutter.
  // ============================================================

  static const String _communityStorageKey = 'paceCommunities';
  static const String _communityMembersStorageKey = 'paceCommunityMembers';
  static const String _communityPostsStorageKey = 'paceCommunityPosts';
  static const String _followingStorageKey = 'paceFollowing';
  static const String _feedFilterStorageKey = 'paceFeedFilter';
  static const String _communityFilterStorageKey = 'paceCommunityFilter';

  List<Map<String, dynamic>> comunidadesLocais = [];
  List<Map<String, dynamic>> membrosComunidadesLocais = [];
  List<Map<String, dynamic>> vinculosPostsComunidadesLocais = [];
  Set<String> seguindoIdsLocais = <String>{};

  String filtroFeedAtivo = 'general';
  String comunidadeFiltroAtiva = 'all';

  bool isLoading = true;
  bool sidebarHovered = false;
  String? sidebarItemHovered;

  // Resumo de evolução exibido no feed desktop.
  int _sequenciaAtual = 0;
  int _focoHojeSegundos = 0;
  Map<String, dynamic>? _metaDestaque;
  bool _progressoCarregando = true;

  final TextEditingController editPostController = TextEditingController();
  final TextEditingController editCommentController = TextEditingController();
  final Map<int, TextEditingController> commentControllers = {};

  // Mantém os mesmos ImageProvider entre rebuilds.
  // Assim abrir/fechar comentários não faz avatar/imagem "piscar".
  final Map<String, ImageProvider> _imageProviderCache = {};

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor =>
      darkMode ? const Color(0xFF041126) : const Color(0xFFEAF3FB);

  Color get textColor =>
      darkMode ? const Color(0xFFF7FAFF) : const Color(0xFF06152D);

  Color get mutedColor =>
      darkMode ? const Color(0xFF8FA5C0) : const Color(0xFF61758F);

  Color get bodyTextColor =>
      darkMode ? const Color(0xFFC7D5E8) : const Color(0xFF203B61);

  Color get labelColor =>
      darkMode ? const Color(0xFFD7E8F7) : const Color(0xFF203B61);

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

  ImageProvider _cachedImageProvider(
    dynamic value, {
    String fallbackAsset = 'assets/user.png',
  }) {
    final raw = value?.toString().trim() ?? '';
    final key = '$fallbackAsset::$raw';

    return _imageProviderCache.putIfAbsent(
      key,
      () => ApiConfig.imageProvider(
        raw.isEmpty ? null : raw,
        fallbackAsset: fallbackAsset,
      ),
    );
  }

  ImageProvider _avatarProvider(String? value) {
    return _cachedImageProvider(value);
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
      'commentsCount': NumberParser.toInt(
        post['commentsCount'] ??
            post['comentariosCount'] ??
            post['commentCount'] ??
            post['totalComentarios'] ??
            post['total_comentarios'],
      ),
      'comentariosCarregados': false,
      'comentariosAbertos': false,
      'comentariosCarregando': false,
      'data': post['data_postagem'] ?? post['data'],
      'comunidadeId':
          post['comunidadeId'] ??
          post['communityId'] ??
          post['comunidade_id'] ??
          post['community_id'],
      'comunidadeNome':
          post['comunidadeNome'] ??
          post['communityName'] ??
          post['comunidade_nome'] ??
          post['community_name'],
      'seguindo': post['seguindo'] ?? post['following'] ?? false,
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

  List<Map<String, dynamic>> _decodeLocalList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];

      return decoded
          .where((item) => item is Map)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _carregarDadosLocaisFeed() async {
    final prefs = await SharedPreferences.getInstance();

    final comunidades = _decodeLocalList(
      prefs.getString(_communityStorageKey),
    );

    final membros = _decodeLocalList(
      prefs.getString(_communityMembersStorageKey),
    );

    final vinculos = _decodeLocalList(
      prefs.getString(_communityPostsStorageKey),
    );

    final seguindoRaw = _decodeLocalList(
      prefs.getString(_followingStorageKey),
    );

    final seguindoIds = <String>{};

    for (final item in seguindoRaw) {
      final id =
          item['id'] ??
          item['usuarioId'] ??
          item['usuario_id'] ??
          item['userId'] ??
          item['user_id'] ??
          item['seguindoId'] ??
          item['seguindo_id'];

      if (id != null) seguindoIds.add(id.toString());
    }

    // Também aceita uma lista simples de IDs salva como JSON.
    final rawFollowing = prefs.getString(_followingStorageKey);
    if (rawFollowing != null) {
      try {
        final decoded = jsonDecode(rawFollowing);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is num || item is String) {
              seguindoIds.add(item.toString());
            }
          }
        }
      } catch (_) {}
    }

    filtroFeedAtivo = prefs.getString(_feedFilterStorageKey) ?? 'general';
    comunidadeFiltroAtiva =
        prefs.getString(_communityFilterStorageKey) ?? 'all';

    if (!{'general', 'following', 'communities'}.contains(filtroFeedAtivo)) {
      filtroFeedAtivo = 'general';
    }

    comunidadesLocais = comunidades;
    membrosComunidadesLocais = membros;
    vinculosPostsComunidadesLocais = vinculos;
    seguindoIdsLocais = seguindoIds;
  }

  Future<void> _salvarFiltroFeed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_feedFilterStorageKey, filtroFeedAtivo);
    await prefs.setString(_communityFilterStorageKey, comunidadeFiltroAtiva);
  }

  String? _obterComunidadeIdDoPost(Map<String, dynamic> post) {
    final id =
        post['comunidadeId'] ??
        post['communityId'] ??
        post['comunidade_id'] ??
        post['community_id'];

    if (id == null || id.toString().trim().isEmpty) return null;
    return id.toString();
  }

  String _idUsuarioAtual() {
    final id = usuarioLogado['id'];
    return id == null ? '' : id.toString();
  }

  List<Map<String, dynamic>> get _minhasComunidades {
    final userId = _idUsuarioAtual();
    if (userId.isEmpty) return <Map<String, dynamic>>[];

    final idsParticipando = membrosComunidadesLocais
        .where((membro) {
          final usuarioId =
              membro['usuarioId'] ??
              membro['usuario_id'] ??
              membro['userId'] ??
              membro['user_id'];

          return usuarioId?.toString() == userId;
        })
        .map((membro) {
          return (
                membro['comunidadeId'] ??
                membro['comunidade_id'] ??
                membro['communityId'] ??
                membro['community_id']
              )
              ?.toString();
        })
        .whereType<String>()
        .toSet();

    return comunidadesLocais.where((comunidade) {
      return idsParticipando.contains(comunidade['id']?.toString());
    }).toList();
  }

  Map<String, dynamic>? _comunidadePorId(String? comunidadeId) {
    if (comunidadeId == null) return null;

    for (final comunidade in comunidadesLocais) {
      if (comunidade['id']?.toString() == comunidadeId) {
        return comunidade;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _aplicarVinculosComunidades(
    List<Map<String, dynamic>> source,
  ) {
    final vinculosPorPost = <String, Map<String, dynamic>>{};

    for (final vinculo in vinculosPostsComunidadesLocais) {
      final postId =
          vinculo['postId'] ??
          vinculo['post_id'];

      if (postId != null) {
        vinculosPorPost[postId.toString()] = vinculo;
      }
    }

    return source.map((post) {
      final copia = Map<String, dynamic>.from(post);
      final vinculo = vinculosPorPost[copia['id']?.toString()];

      final comunidadeId =
          _obterComunidadeIdDoPost(copia) ??
          (
            vinculo?['comunidadeId'] ??
            vinculo?['comunidade_id'] ??
            vinculo?['communityId'] ??
            vinculo?['community_id']
          )?.toString();

      if (comunidadeId == null || comunidadeId.isEmpty) {
        copia['comunidadeId'] = null;
        copia['comunidadeNome'] = null;
        return copia;
      }

      final comunidade = _comunidadePorId(comunidadeId);

      copia['comunidadeId'] = comunidadeId;
      copia['comunidadeNome'] =
          comunidade?['nome']?.toString() ??
          vinculo?['comunidadeNome']?.toString() ??
          vinculo?['nome']?.toString() ??
          'Comunidade';

      return copia;
    }).toList();
  }

  List<Map<String, dynamic>> get _postsFiltrados {
    if (filtroFeedAtivo == 'following') {
      return posts.where((post) {
        final usuario = post['usuario'];
        final userId = usuario is Map
            ? usuario['id']?.toString()
            : post['usuario_id']?.toString();

        if (userId == null) return false;

        // Se houver IDs locais, eles são a fonte principal.
        if (seguindoIdsLocais.isNotEmpty) {
          return seguindoIdsLocais.contains(userId);
        }

        // Compatibilidade com feeds que já tragam a informação.
        return post['seguindo'] == true || post['following'] == true;
      }).toList();
    }

    if (filtroFeedAtivo == 'communities') {
      final idsPermitidos = _minhasComunidades
          .map((comunidade) => comunidade['id']?.toString())
          .whereType<String>()
          .toSet();

      return posts.where((post) {
        final comunidadeId = _obterComunidadeIdDoPost(post);

        if (comunidadeId == null || !idsPermitidos.contains(comunidadeId)) {
          return false;
        }

        return comunidadeFiltroAtiva == 'all' ||
            comunidadeId == comunidadeFiltroAtiva;
      }).toList();
    }

    return posts;
  }

  Future<void> _alterarFiltroFeed(String filtro) async {
    setState(() {
      filtroFeedAtivo = filtro;

      if (filtro != 'communities') {
        comunidadeFiltroAtiva = 'all';
      }
    });

    await _salvarFiltroFeed();
  }

  Future<void> _alterarFiltroComunidade(String comunidadeId) async {
    setState(() {
      filtroFeedAtivo = 'communities';
      comunidadeFiltroAtiva = comunidadeId;
    });

    await _salvarFiltroFeed();
  }

  Future<void> _initFeed() async {
    final token = await _getToken();

    if (!mounted) return;

    if (token == null) {
      Navigator.of(context).pushReplacementNamed('/entrar');
      return;
    }

    try {
      await _carregarDadosLocaisFeed();

      final usuarioData = await _buscarUsuarioAPI(token);
      usuarioLogado = usuarioData;

      final postsDaApi = await _getPostsAPI(token);
      final postsData = _aplicarVinculosComunidades(postsDaApi);

      // Igual ao web: comentários NÃO são carregados junto com o feed.
      // Eles só são buscados quando o usuário abre o painel de comentários.
      if (!mounted) return;

      setState(() {
        usuarioLogado = usuarioData;
        posts = postsData;
        isLoading = false;
      });

      // Atualiza somente os números dos comentários em segundo plano.
      // As listas de comentários continuam sendo buscadas apenas ao clicar.
      _carregarContagensComentariosEmSegundoPlano(token, postsData);

      // O painel é complementar: se a API de metas/sessões falhar,
      // o feed continua funcionando normalmente.
      await _carregarPainelProgresso(token);
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

  Future<void> _carregarContagensComentariosEmSegundoPlano(
    String token,
    List<Map<String, dynamic>> postsAlvo,
  ) async {
    final resultados = await Future.wait(
      postsAlvo.map((post) async {
        final postId = NumberParser.toInt(post['id']);

        if (postId <= 0) {
          return MapEntry(postId, NumberParser.toInt(post['commentsCount']));
        }

        try {
          final comentarios = await _buscarComentariosAPI(token, postId);
          return MapEntry(postId, comentarios.length);
        } catch (_) {
          return MapEntry(postId, NumberParser.toInt(post['commentsCount']));
        }
      }),
    );

    if (!mounted) return;

    setState(() {
      for (final resultado in resultados) {
        final post = posts.firstWhere(
          (item) => NumberParser.toInt(item['id']) == resultado.key,
          orElse: () => <String, dynamic>{},
        );

        if (post.isNotEmpty && post['comentariosCarregados'] != true) {
          post['commentsCount'] = resultado.value;
        }
      }
    });
  }

  Future<void> _alternarComentarios(int postId) async {
    final post = posts.firstWhere(
      (item) => NumberParser.toInt(item['id']) == postId,
      orElse: () => <String, dynamic>{},
    );

    if (post.isEmpty) return;

    final abertos = post['comentariosAbertos'] == true;

    if (abertos) {
      setState(() {
        post['comentariosAbertos'] = false;
      });
      return;
    }

    setState(() {
      post['comentariosAbertos'] = true;
    });

    if (post['comentariosCarregados'] == true) {
      return;
    }

    if (post['comentariosCarregando'] == true) {
      return;
    }

    final token = await _getToken();
    if (token == null) return;

    setState(() {
      post['comentariosCarregando'] = true;
    });

    try {
      final comentarios = await _buscarComentariosAPI(token, postId);

      if (!mounted) return;

      setState(() {
        post['comentarios'] = comentarios;
        post['commentsCount'] = comentarios.length;
        post['comentariosCarregados'] = true;
        post['comentariosCarregando'] = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        post['comentariosAbertos'] = false;
        post['comentariosCarregando'] = false;
      });

      if (e.toString().contains('AUTH_401')) {
        Navigator.of(context).pushReplacementNamed('/entrar');
        return;
      }

      _showToast('Não foi possível carregar os comentários.', Colors.red);
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
          post['commentsCount'] = (post['comentarios'] as List).length;
          post['comentariosCarregados'] = true;
          post['comentariosAbertos'] = true;
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
          final comentarios = post['comentarios'] as List;
          comentarios.removeWhere(
            (comentario) => comentario['id'] == comentarioId,
          );

          if (post['comentariosCarregados'] == true) {
            post['commentsCount'] = comentarios.length;
          }
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
                  color: const Color(0xFF1769E8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'EDITOR DE POST',
                  style: TextStyle(
                    color: Color(0xFF1769E8),
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
                cursorColor: const Color(0xFF1769E8),
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
                    color: Color(0xFF1769E8),
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
                cursorColor: const Color(0xFF1769E8),
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
    final tablet = screenWidth >= 760 && screenWidth < 1100;
    final desktop = screenWidth >= 1100;

    if (isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1769E8)),
        ),
      );
    }

    final page = Stack(
      children: [
        _BackgroundDecor(darkMode: darkMode),
        _buildFeedContent(
          horizontalPadding: mobile
              ? (screenWidth <= 430 ? 16 : 20)
              : (tablet ? 28 : 42),
          topPadding: mobile ? 24 : (tablet ? 30 : 32),
          bottomPadding: mobile ? 70 : 90,
          mobile: mobile,
          desktop: desktop,
        ),
      ],
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: mobile ? _buildMobileDrawer() : null,
      body: Row(
        children: [
          if (!mobile) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                if (mobile) _buildMobileTopBar(),
                Expanded(child: page),
              ],
            ),
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
    required bool desktop,
  }) {
    final postsVisiveis = _postsFiltrados;

    final feedColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFeedFilters(mobile),
        const SizedBox(height: 24),
        _buildFeedHeader(mobile),
        const SizedBox(height: 16),
        postsVisiveis.isEmpty
            ? _buildEmptyFeed()
            : _buildPosts(postsVisiveis),
      ],
    );

    return RefreshIndicator(
      color: const Color(0xFF1769E8),
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
                SizedBox(height: mobile ? 28 : 26),

                if (desktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: feedColumn,
                      ),
                      const SizedBox(width: 34),
                      SizedBox(
                        width: 292,
                        child: _buildProgressPanel(),
                      ),
                    ],
                  )
                else
                  feedColumn,
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
      await _carregarDadosLocaisFeed();

      final usuarioData = await _buscarUsuarioAPI(token);
      usuarioLogado = usuarioData;

      final postsDaApi = await _getPostsAPI(token);
      final postsData = _aplicarVinculosComunidades(postsDaApi);

      // Refresh também mantém o lazy load dos comentários.
      if (!mounted) return;

      setState(() {
        usuarioLogado = usuarioData;
        posts = postsData;
      });

      _carregarContagensComentariosEmSegundoPlano(token, postsData);

      await _carregarPainelProgresso(token);
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


  Future<void> _carregarPainelProgresso(String token) async {
    try {
      final metasResponse = await http.get(
        Uri.parse('$apiUrl/metas/listar_metas'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final metasData = await _parseResponse(
        metasResponse,
        'Erro ao buscar metas.',
      );

      final metas = metasData is List
          ? metasData
              .where((item) => item is Map)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList()
          : <Map<String, dynamic>>[];

      Map<String, dynamic>? metaAtiva;

      final emAndamento = metas
          .where(
            (meta) =>
                (meta['status'] ?? '').toString().toLowerCase() ==
                'em andamento',
          )
          .toList();

      if (emAndamento.isNotEmpty) {
        emAndamento.sort((a, b) {
          final prazoA = _parseDateOnly(a['prazo']);
          final prazoB = _parseDateOnly(b['prazo']);

          if (prazoA != null && prazoB != null) {
            return prazoA.compareTo(prazoB);
          }

          if (prazoA != null) return -1;
          if (prazoB != null) return 1;

          return NumberParser.toInt(a['id']).compareTo(
            NumberParser.toInt(b['id']),
          );
        });

        metaAtiva = emAndamento.first;
      }

      final sessoes = <Map<String, dynamic>>[];

      for (final meta in metas) {
        final id = NumberParser.toInt(meta['id']);
        if (id <= 0) continue;

        try {
          final response = await http.get(
            Uri.parse('$apiUrl/sessoes/meta/$id'),
            headers: {'Authorization': 'Bearer $token'},
          );

          final data = await _parseResponse(
            response,
            'Erro ao buscar sessões.',
          );

          if (data is List) {
            sessoes.addAll(
              data
                  .where((item) => item is Map)
                  .map((item) => Map<String, dynamic>.from(item as Map)),
            );
          }
        } catch (_) {
          // Uma meta sem sessões não deve quebrar o restante do feed.
        }
      }

      final hoje = _dateKey(DateTime.now());

      final focoHoje = sessoes
          .where((sessao) => _dateKeyFromValue(sessao['inicio']) == hoje)
          .fold<int>(
            0,
            (total, sessao) =>
                total + NumberParser.toInt(sessao['duracao']),
          );

      final sequencia = _calcularSequencia(sessoes);

      if (!mounted) return;

      setState(() {
        _sequenciaAtual = sequencia;
        _focoHojeSegundos = focoHoje;
        _metaDestaque = metaAtiva;
        _progressoCarregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _progressoCarregando = false;
      });
    }
  }

  DateTime? _parseDateOnly(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return null;

    final raw = value.toString().trim();
    return DateTime.tryParse(raw.length == 10 ? '${raw}T12:00:00' : raw);
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String? _dateKeyFromValue(dynamic value) {
    if (value == null) return null;
    final date = DateTime.tryParse(value.toString());
    if (date == null) return null;
    return _dateKey(date.toLocal());
  }

  int _calcularSequencia(List<Map<String, dynamic>> sessoes) {
    final diasAtivos = sessoes
        .where((sessao) => NumberParser.toInt(sessao['duracao']) > 0)
        .map((sessao) => _dateKeyFromValue(sessao['inicio']))
        .whereType<String>()
        .toSet();

    if (diasAtivos.isEmpty) return 0;

    var cursor = DateTime.now();

    if (!diasAtivos.contains(_dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var sequencia = 0;

    while (diasAtivos.contains(_dateKey(cursor))) {
      sequencia++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return sequencia;
  }

  String _formatarDuracao(int segundos) {
    final total = segundos < 0 ? 0 : segundos;
    final horas = total ~/ 3600;
    final minutos = (total % 3600) ~/ 60;

    if (horas > 0) {
      return minutos > 0 ? '${horas}h ${minutos}min' : '${horas}h';
    }

    return minutos > 0 ? '${minutos}min' : '0min';
  }

  String _descricaoMetaDestaque() {
    final meta = _metaDestaque;

    if (meta == null) {
      return 'Crie uma meta e transforme intenção em direção.';
    }

    final prazo = _parseDateOnly(meta['prazo']);

    if (prazo != null) {
      final dia = prazo.day.toString().padLeft(2, '0');
      final mes = prazo.month.toString().padLeft(2, '0');
      return 'Prazo: $dia/$mes/${prazo.year}';
    }

    final descricao = (meta['descricao'] ?? '').toString().trim();

    return descricao.isNotEmpty
        ? descricao
        : 'Continue avançando no seu ritmo.';
  }

  Widget _buildProgressPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: darkMode ? const Color(0xFF0A2245) : const Color(0xFFF9FBFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFD7E8F7),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06152D).withOpacity(
              darkMode ? 0.26 : 0.08,
            ),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: _progressoCarregando
          ? const SizedBox(
              height: 280,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1769E8),
                  strokeWidth: 2.5,
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionEyebrow(
                  text: 'SEU RITMO',
                  icon: Icons.auto_awesome_rounded,
                  color: Color(0xFFB67D00),
                ),
                const SizedBox(height: 12),
                Text(
                  'Seu progresso',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Pequenos passos também contam.',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Divider(
                  height: 1,
                  color: darkMode
                      ? Colors.white.withOpacity(0.08)
                      : const Color(0xFFD7E8F7),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressMetricCard(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFB67D00),
                        iconBackground: const Color(0xFFFFF3C6),
                        label: 'Sequência',
                        value: '$_sequenciaAtual',
                        caption: _sequenciaAtual == 1
                            ? 'dia de constância'
                            : 'dias de constância',
                        darkMode: darkMode,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ProgressMetricCard(
                        icon: Icons.timer_rounded,
                        iconColor: const Color(0xFF1769E8),
                        iconBackground: const Color(0xFFE8F3FF),
                        label: 'Foco hoje',
                        value: _formatarDuracao(_focoHojeSegundos),
                        caption: 'Tempo dedicado hoje',
                        darkMode: darkMode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: darkMode
                        ? Colors.white.withOpacity(0.035)
                        : const Color(0xFFF1F7FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: darkMode
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFD7E8F7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.track_changes_rounded,
                            size: 15,
                            color: Color(0xFF1769E8),
                          ),
                          const SizedBox(width: 7),
                          const Expanded(
                            child: Text(
                              'META EM DESTAQUE',
                              style: TextStyle(
                                color: Color(0xFF1769E8),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC928).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _metaDestaque == null
                                  ? 'Começar'
                                  : 'Em andamento',
                              style: const TextStyle(
                                color: Color(0xFF8A6200),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (_metaDestaque?['titulo'] ??
                                'Sua primeira meta começa aqui')
                            .toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _descricaoMetaDestaque(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 10.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => Navigator.of(context).pushNamed('/evolucao'),
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ver minha evolução',
                            style: TextStyle(
                              color: Color(0xFF1769E8),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 17,
                          color: Color(0xFF1769E8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeedFilters(bool mobile) {
    final comunidades = _minhasComunidades;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 10 : 8),
      decoration: BoxDecoration(
        color: darkMode
            ? Colors.white.withOpacity(0.035)
            : const Color(0xFFDCE9F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.07)
              : const Color(0xFF06152D).withOpacity(0.045),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile)
            Row(
              children: [
                Expanded(
                  child: _FeedFilterButton(
                    label: 'Feed geral',
                    icon: Icons.auto_awesome_rounded,
                    active: filtroFeedAtivo == 'general',
                    compact: true,
                    onTap: () => _alterarFiltroFeed('general'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _FeedFilterButton(
                    label: 'Seguindo',
                    icon: Icons.people_alt_outlined,
                    active: filtroFeedAtivo == 'following',
                    compact: true,
                    onTap: () => _alterarFiltroFeed('following'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _FeedFilterButton(
                    label: 'Comunidades',
                    icon: Icons.forum_outlined,
                    active: filtroFeedAtivo == 'communities',
                    compact: true,
                    onTap: () => _alterarFiltroFeed('communities'),
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FeedFilterButton(
                  label: 'Feed geral',
                  icon: Icons.auto_awesome_rounded,
                  active: filtroFeedAtivo == 'general',
                  onTap: () => _alterarFiltroFeed('general'),
                ),
                _FeedFilterButton(
                  label: 'Seguindo',
                  icon: Icons.people_alt_outlined,
                  active: filtroFeedAtivo == 'following',
                  onTap: () => _alterarFiltroFeed('following'),
                ),
                _FeedFilterButton(
                  label: 'Comunidades',
                  icon: Icons.forum_outlined,
                  active: filtroFeedAtivo == 'communities',
                  onTap: () => _alterarFiltroFeed('communities'),
                ),
              ],
            ),

          if (filtroFeedAtivo == 'communities') ...[
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: darkMode
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFF06152D).withOpacity(0.06),
            ),
            const SizedBox(height: 10),

            if (comunidades.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 17,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você ainda não participa de nenhuma comunidade.',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CommunityFilterButton(
                      label: 'Todas',
                      active: comunidadeFiltroAtiva == 'all',
                      onTap: () => _alterarFiltroComunidade('all'),
                    ),
                    const SizedBox(width: 8),
                    ...comunidades.expand((comunidade) {
                      final id = comunidade['id']?.toString() ?? '';
                      final nome =
                          comunidade['nome']?.toString() ?? 'Comunidade';

                      return [
                        _CommunityFilterButton(
                          label: nome,
                          active: comunidadeFiltroAtiva == id,
                          onTap: () => _alterarFiltroComunidade(id),
                        ),
                        const SizedBox(width: 8),
                      ];
                    }),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
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
                  color: Color(0xFF1769E8),
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
                color: Colors.white.withOpacity(0.08),
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
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF041126),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFFFC928),
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'assets/images/pace_icon.png',
                    width: 43,
                    height: 43,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pace',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Evolução contínua',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF8FA5C0),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: const Color(0xFF0A2245),
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => Navigator.of(context).pushNamed('/notificacoes'),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
              ),
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
            color: const Color(0xFF06152D),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(28),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
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
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        Text(
                          'Evolução contínua',
                          style: TextStyle(
                            color: const Color(0xFF8FA5C0),
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
                color: Colors.white.withOpacity(0.08),
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
                color: Colors.white.withOpacity(0.08),
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
          color: const Color(0xFF8FA5C0),
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
              color: active
                  ? const Color(0xFF174A9B)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: active
                  ? Border.all(color: const Color(0xFF1769E8).withOpacity(0.10))
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
                        ? const Color(0xFF1769E8).withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: active ? Colors.white : const Color(0xFFC7D5E8),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : const Color(0xFFC7D5E8),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!active)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: const Color(0xFF8FA5C0),
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
            color: Colors.white.withOpacity(0.06),
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
                    const Text(
                      'Meu perfil',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ver perfil',
                      style: TextStyle(
                        color: Color(0xFF8FA5C0),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8FA5C0),
                size: 20,
              ),
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

        if (!mobile) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionEyebrow(
                      text: 'COMUNIDADE',
                      showLine: true,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Feed',
                      style: TextStyle(
                        fontSize: 44,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.8,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              _PrimaryButton(
                text: 'Criar post',
                icon: Icons.add_rounded,
                dark: true,
                onTap: () => Navigator.of(context).pushNamed('/postar'),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionEyebrow(
                    text: 'COMUNIDADE',
                    showLine: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Feed',
                    style: TextStyle(
                      fontSize: 36,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _PrimaryButton(
              text: 'Criar post',
              icon: Icons.add_rounded,
              dark: true,
              onTap: () => Navigator.of(context).pushNamed('/postar'),
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
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1769E8).withOpacity(0.14),
                  const Color(0xFF5EB1BF).withOpacity(0.18),
                ],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF1769E8),
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

  Widget _buildPosts(List<Map<String, dynamic>> postsVisiveis) {
    return Column(
      children: postsVisiveis.asMap().entries.map((entry) {
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
    final comentariosAbertos = post['comentariosAbertos'] == true;
    final comentariosCarregando = post['comentariosCarregando'] == true;
    final totalComentarios = post['comentariosCarregados'] == true
        ? comentarios.length
        : NumberParser.toInt(post['commentsCount']);
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
            if ((post['comunidadeId'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _alterarFiltroComunidade(
                  post['comunidadeId'].toString(),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1769E8).withOpacity(
                      darkMode ? 0.16 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF1769E8).withOpacity(0.16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.groups_2_outlined,
                        size: 15,
                        color: Color(0xFF1769E8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Publicado em ${post['comunidadeNome'] ?? 'Comunidade'}',
                        style: const TextStyle(
                          color: Color(0xFF0B3D91),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

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
                  image: _cachedImageProvider(
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _alternarComentarios(postId),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: comentariosAbertos
                            ? const Color(0xFF1769E8).withOpacity(
                                darkMode ? 0.20 : 0.11,
                              )
                            : const Color(0xFF1769E8).withOpacity(
                                darkMode ? 0.12 : 0.06,
                              ),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: comentariosAbertos
                              ? const Color(0xFF1769E8).withOpacity(0.28)
                              : darkMode
                                  ? Colors.white.withOpacity(0.08)
                                  : const Color(0xFF1769E8).withOpacity(0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.mode_comment_outlined,
                            size: 18,
                            color: comentariosAbertos
                                ? const Color(0xFF1769E8)
                                : mutedColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$totalComentarios',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: comentariosAbertos
                                  ? const Color(0xFF1769E8)
                                  : mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (comentariosAbertos) ...[
              const SizedBox(height: 14),

              if (comentariosCarregando)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1769E8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Carregando comentários...',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (comentarios.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Nenhum comentário ainda.',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Column(
                    children: comentarios
                        .map((comentario) => _buildComment(comentario))
                        .toList(),
                  ),

                const SizedBox(height: 4),
                _buildCommentInput(postId),
              ],
            ],
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
                  0xFF1769E8,
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
            cursorColor: const Color(0xFF1769E8),
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
                      : const Color(0xFF1769E8).withOpacity(0.14),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: const Color(0xFF1769E8).withOpacity(0.34),
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
              colors: [Color(0xFF1769E8), Color(0xFF0B3D91)],
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
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF06152D),
          border: Border(
            right: BorderSide(color: const Color(0xFF1769E8).withOpacity(0.09)),
          ),
          boxShadow: const [],
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Column(
              children: [
                SizedBox(
                  height: 70,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // O texto só entra quando a largura REAL da animação
                      // já comporta logo + espaçamento + textos.
                      // Isso evita RenderFlex/overflow no primeiro frame.
                      final showBrandText = constraints.maxWidth >= 150;

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
                          if (showBrandText) ...[
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pace',
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Evolução contínua',
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    style: TextStyle(
                                      color: Color(0xFF8FA5C0),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
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
                Divider(
                  height: 1,
                  color: const Color(0xFF1769E8).withOpacity(0.10),
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
                  color: Colors.white.withOpacity(0.08),
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
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showText = constraints.maxWidth >= 130;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: showText
                  ? Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
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
                ? Colors.white.withOpacity(0.07)
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: showText ? 1 : 0,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meu perfil',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ver perfil',
                              style: TextStyle(
                                color: Color(0xFF8FA5C0),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF8FA5C0),
                      size: 18,
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
                ? (active
                    ? const Color(0xFF174A9B)
                    : Colors.white.withOpacity(0.07))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: highlighted
                ? Border.all(
                    color: active
                        ? const Color(0xFF1769E8).withOpacity(0.55)
                        : Colors.white.withOpacity(0.08),
                  )
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showText = sidebarHovered && constraints.maxWidth > 90;

              return Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (active)
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
                      SizedBox(
                        width: 24,
                        child: Icon(
                          icon,
                          color: highlighted
                              ? Colors.white
                              : const Color(0xFFC7D5E8),
                          size: 24,
                        ),
                      ),
                    ],
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
                                ? Colors.white
                                : const Color(0xFFC7D5E8),
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

class _FeedFilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool compact;

  const _FeedFilterButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFF0A2245) : const Color(0xFFF5FAFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 13,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? const Color(0xFF1769E8).withOpacity(0.24)
                  : const Color(0xFF06152D).withOpacity(0.07),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: active ? Colors.white : const Color(0xFF06152D),
              ),
              SizedBox(width: compact ? 4 : 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? Colors.white : const Color(0xFF06152D),
                    fontSize: compact ? 10.5 : 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityFilterButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CommunityFilterButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? const Color(0xFFE8F3FF)
          : Colors.white.withOpacity(0.78),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? const Color(0xFF1769E8).withOpacity(0.30)
                  : const Color(0xFF06152D).withOpacity(0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? const Color(0xFF0B3D91)
                  : const Color(0xFF61758F),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
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


class _SectionEyebrow extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final bool showLine;

  const _SectionEyebrow({
    required this.text,
    this.icon,
    this.color = const Color(0xFF1769E8),
    this.showLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLine) ...[
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC928),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 9),
        ],
        if (icon != null) ...[
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
        ],
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.05,
          ),
        ),
      ],
    );
  }
}

class _ProgressMetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String value;
  final String caption;
  final bool darkMode;

  const _ProgressMetricCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    required this.value,
    required this.caption,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode
            ? Colors.white.withOpacity(0.035)
            : const Color(0xFFF4F8FC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFD7E8F7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: darkMode
                  ? iconColor.withOpacity(0.12)
                  : iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              color: darkMode
                  ? const Color(0xFF8FA5C0)
                  : const Color(0xFF61758F),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: darkMode
                  ? const Color(0xFFF7FAFF)
                  : const Color(0xFF06152D),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: darkMode
                  ? const Color(0xFF8FA5C0)
                  : const Color(0xFF61758F),
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedGridPainter extends CustomPainter {
  final bool darkMode;

  const _FeedGridPainter({required this.darkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (darkMode ? Colors.white : const Color(0xFF06152D))
          .withOpacity(darkMode ? 0.018 : 0.025)
      ..strokeWidth = 1;

    const spacing = 34.0;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FeedGridPainter oldDelegate) {
    return oldDelegate.darkMode != darkMode;
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
            color: darkMode
                ? const Color(0xFF041126)
                : const Color(0xFFEAF3FB),
          ),
          child: const SizedBox.expand(),
        ),
        // Grade extremamente sutil para repetir a linguagem visual do index.
        Positioned(
          top: 0,
          left: 0,
          child: IgnorePointer(
            child: CustomPaint(
              size: const Size(360, 360),
              painter: _FeedGridPainter(darkMode: darkMode),
            ),
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
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06152D).withOpacity(darkMode ? 0.30 : 0.08),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: darkMode
                  ? const Color(0xF00A2245)
                  : const Color(0xFFF9FBFE),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: darkMode
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFD7E8F7),
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
        color: const Color(0xFF1769E8).withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF1769E8).withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC928),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC928).withOpacity(0.16),
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
              color: Color(0xFF0B3D91),
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
  final bool dark;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF06152D)
            : const Color(0xFF1769E8),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: dark
                ? const Color(0xFF06152D).withOpacity(0.22)
                : const Color(0xFF1769E8).withOpacity(0.24),
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
          : const Color(0xFF1769E8).withOpacity(0.08),
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
            color: danger ? const Color(0xFFE55353) : const Color(0xFF1769E8),
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
          : const Color(0xFF1769E8).withOpacity(0.08),
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
            color: danger ? const Color(0xFFE55353) : const Color(0xFF1769E8),
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
              : const Color(0xFF1769E8).withOpacity(0.14),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: const Color(0xFF1769E8).withOpacity(0.35),
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
