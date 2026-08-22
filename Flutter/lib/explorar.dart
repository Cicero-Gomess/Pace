import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'pace_shell.dart';

const Color primary = Color(0xFF315CAC);
const Color primary2 = Color(0xFF416FC4);
const Color accent = Color(0xFF69C5D0);


dynamic _decodeJsonOnIsolate(String source) {
  return jsonDecode(source);
}

Uint8List? _decodeDataImageOnIsolate(String source) {
  try {
    final commaIndex = source.indexOf(',');
    if (commaIndex < 0 || commaIndex >= source.length - 1) {
      return null;
    }

    return base64Decode(source.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}


final Map<String, ImageProvider> _explorarImageCache = <String, ImageProvider>{};


Future<void> _avatarDecodeQueue = Future<void>.value();
final Map<String, Uint8List> _avatarBytesCache = <String, Uint8List>{};

Future<Uint8List?> _decodeAvatarSerially(String source) {
  final cached = _avatarBytesCache[source];
  if (cached != null) {
    return Future<Uint8List?>.value(cached);
  }

  final completer = Completer<Uint8List?>();

  _avatarDecodeQueue = _avatarDecodeQueue.then((_) async {
    try {
      Uint8List? bytes;

      if (kIsWeb) {
        bytes = _decodeDataImageOnIsolate(source);
      } else {
        bytes = await compute(_decodeDataImageOnIsolate, source);
      }

      if (bytes != null) {
        // Cache only a few search avatars to prevent unlimited memory growth.
        if (_avatarBytesCache.length >= 6) {
          _avatarBytesCache.remove(_avatarBytesCache.keys.first);
        }
        _avatarBytesCache[source] = bytes;
      }

      if (!completer.isCompleted) {
        completer.complete(bytes);
      }
    } catch (_) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
  });

  return completer.future;
}

ImageProvider _cachedImageProvider(dynamic value) {
  final key = value?.toString().trim() ?? '';

  if (key.isEmpty) {
    return const AssetImage('assets/user.png');
  }

  return _explorarImageCache.putIfAbsent(
    key,
    () => ApiConfig.imageProvider(key),
  );
}

class ExplorarPage extends StatefulWidget {
  const ExplorarPage({super.key});

  @override
  State<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends State<ExplorarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  Timer? _startupTimer;

  bool _loading = true;
  bool _searching = false;
  bool _sidebarHovered = false;
  String? _sidebarItemHovered;

  Map<String, dynamic> _usuarioLogado = {};
  List<Map<String, dynamic>> _profiles = [];

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor =>
      darkMode ? const Color(0xFF05070C) : const Color(0xFFF4F8FD);

  Color get textColor =>
      darkMode ? const Color(0xFFF2F6FF) : const Color(0xFF172033);

  Color get textSoftColor =>
      darkMode ? const Color(0xFFDCE5F4) : const Color(0xFF2D3950);

  Color get mutedColor =>
      darkMode ? const Color(0xFF98A8BF) : const Color(0xFF6F7F96);

  Color get sidebarTextColor =>
      darkMode ? const Color(0xFFF1F5FF) : const Color(0xFF33415B);

  Color get cardColor => darkMode
      ? const Color(0xFF0C1627).withOpacity(0.94)
      : Colors.white.withOpacity(0.92);

  @override
  void initState() {
    super.initState();

    // Mantém o cache sob controle, especialmente no Android.
    PaintingBinding.instance.imageCache.maximumSize = 28;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 14 << 20;


    // A transição de rota do Pace dura 650 ms. Se começarmos a processar
    // JSON/Base64 no meio dela, o frame pode congelar com Feed e Explorar
    // desenhados ao mesmo tempo. Esperamos a animação terminar primeiro.
    _startupTimer = Timer(
      const Duration(milliseconds: 720),
      () {
        if (mounted) {
          _inicializar();
        }
      },
    );
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access_token');
  }

  Map<String, String> _authHeaders(String token, {bool json = false}) {
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<dynamic> _parseResponse(
    http.Response response,
    String fallback,
  ) async {
    dynamic data;

    try {
      if (response.body.isEmpty) {
        data = null;
      } else if (response.body.length >= 12000 && !kIsWeb) {
        // Fotos Base64 deixam algumas respostas grandes. Decodificar JSON
        // no isolate principal trava animação e rolagem.
        data = await compute(_decodeJsonOnIsolate, response.body);
      } else {
        data = jsonDecode(response.body);
      }
    } catch (_) {
      data = null;
    }

    if (response.statusCode == 401) {
      throw Exception('AUTH_401');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map ? data['detail'] : null;
      throw Exception(detail?.toString() ?? fallback);
    }

    return data;
  }

  Future<void> _inicializar() async {
    final token = await _getToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.of(context).pushReplacementNamed('/entrar');
      return;
    }

    try {
      final meResponse = await http
          .get(
            ApiConfig.uri('/profile/me'),
            headers: _authHeaders(token),
          )
          .timeout(const Duration(seconds: 12));

      final meData = await _parseResponse(
        meResponse,
        'Não foi possível carregar seu perfil.',
      );

      if (!mounted) return;

      setState(() {
        _usuarioLogado = Map<String, dynamic>.from(meData as Map);
        _profiles = <Map<String, dynamic>>[];
        _loading = false;
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
        _loading = false;
      });

      _showToast(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    }
  }

  Future<void> _executarBusca(String termo) async {
    final termoLimpo = termo.trim();

    if (termoLimpo.length < 2) {
      if (!mounted) return;

      setState(() {
        _profiles = <Map<String, dynamic>>[];
        _searching = false;
      });

      return;
    }

    final token = await _getToken();
    if (token == null || token.isEmpty || !mounted) return;

    setState(() {
      _searching = true;
    });

    try {
      final perfis = await _buscarPerfis(
        token: token,
        termo: termoLimpo,
        showLoading: false,
      );

      if (!mounted) return;

      setState(() {
        _profiles = perfis;
      });
    } catch (e) {
      if (e.toString().contains('AUTH_401')) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/entrar');
        }
        return;
      }

      _showToast(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _buscarPerfis({
    required String token,
    required String termo,
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _searching = true;
      });
    }

    final uri = ApiConfig.uri('/profile/buscar_por_username/').replace(
      queryParameters: {
        'username': termo,
        'skip': '0',
        // Mantemos poucos cards por vez para evitar decodificar várias
        // fotos Base64 simultaneamente no celular.
        'limit': '4',
      },
    );

    final response = await http
        .get(
          uri,
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 12));

    final data = await _parseResponse(
      response,
      'Não foi possível buscar perfis.',
    );

    if (data is! List) {
      return [];
    }

    // IMPORTANTE:
    // Não fazemos mais /profile/{id} para cada usuário.
    // O endpoint de busca já devolve foto, estatísticas e "segue".
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _recarregar() async {
    final termo = _searchController.text.trim();

    if (termo.isEmpty) {
      if (!mounted) return;

      setState(() {
        _profiles = <Map<String, dynamic>>[];
      });

      return;
    }

    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    final perfis = await _buscarPerfis(
      token: token,
      termo: termo,
    );

    if (!mounted) return;

    setState(() {
      _profiles = perfis;
    });
  }

  Future<void> _toggleFollow(Map<String, dynamic> profile) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    final id = _toInt(profile['id']);
    if (id <= 0) return;

    final wasFollowing = profile['segue'] == true;

    setState(() {
      profile['segue'] = !wasFollowing;

      final seguidores = _toInt(profile['total_seguidores']);
      profile['total_seguidores'] = wasFollowing
          ? (seguidores > 0 ? seguidores - 1 : 0)
          : seguidores + 1;
    });

    try {
      final response = wasFollowing
          ? await http.post(
              ApiConfig.uri('/profile/unfollow/$id'),
              headers: _authHeaders(token),
            )
          : await http.post(
              ApiConfig.uri('/profile/follow/$id'),
              headers: _authHeaders(token),
            );

      await _parseResponse(
        response,
        wasFollowing
            ? 'Não foi possível deixar de seguir.'
            : 'Não foi possível seguir este usuário.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        profile['segue'] = wasFollowing;

        final seguidores = _toInt(profile['total_seguidores']);
        profile['total_seguidores'] = wasFollowing
            ? seguidores + 1
            : (seguidores > 0 ? seguidores - 1 : 0);
      });

      if (e.toString().contains('AUTH_401')) {
        Navigator.of(context).pushReplacementNamed('/entrar');
        return;
      }

      _showToast(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    }
  }

  Future<void> _abrirPerfil(Map<String, dynamic> profile) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) return;

    final userId = _toInt(profile['id']);
    if (userId <= 0) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar',
      barrierColor: const Color(0x9908101C),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (dialogContext, _, __) {
        return _ProfileModalShell(
          darkMode: darkMode,
          child: FutureBuilder<_ProfileModalData>(
            future: _carregarDadosModal(token, userId, profile),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 380,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return SizedBox(
                  height: 330,
                  child: Center(
                    child: _ModalError(
                      darkMode: darkMode,
                      onClose: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                );
              }

              final data = snapshot.data!;

              return _buildProfileModal(
                dialogContext,
                data.profile,
                data.posts,
              );
            },
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.96,
              end: 1,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<_ProfileModalData> _carregarDadosModal(
    String token,
    int userId,
    Map<String, dynamic> fallback,
  ) async {
    Map<String, dynamic> profile = {...fallback};

    try {
      final response = await http.get(
        ApiConfig.uri('/profile/$userId'),
        headers: _authHeaders(token),
      );

      final data = await _parseResponse(
        response,
        'Erro ao carregar perfil.',
      );

      if (data is Map) {
        profile = {
          ...profile,
          ...Map<String, dynamic>.from(data),
        };
      }
    } catch (_) {}

    final postsResponse = await http.get(
      ApiConfig.uri('/post/feed'),
      headers: _authHeaders(token),
    );

    final postsData = await _parseResponse(
      postsResponse,
      'Erro ao carregar posts.',
    );

    final posts = postsData is List
        ? postsData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where(
                (post) {
                  final usuario = post['usuario'];
                  if (usuario is Map) {
                    return usuario['id']?.toString() == userId.toString();
                  }
                  return post['usuario_id']?.toString() == userId.toString();
                },
              )
              .take(6)
              .toList()
        : <Map<String, dynamic>>[];

    return _ProfileModalData(
      profile: profile,
      posts: posts,
    );
  }

  Widget _buildProfileModal(
    BuildContext dialogContext,
    Map<String, dynamic> profile,
    List<Map<String, dynamic>> posts,
  ) {
    final username = _username(profile);
    final foto = _fotoPerfil(profile);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 26, 26, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 620;

                  final avatarSize = compact ? 82.0 : 96.0;

                  final avatar = Container(
                    width: avatarSize,
                    height: avatarSize,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: primary.withOpacity(0.14),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.14),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: _DeferredAvatar(
                      value: foto,
                      width: avatarSize - 6,
                      height: avatarSize - 6,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );

                  final meta = Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                            color: textColor,
                            fontSize: compact ? 25 : 29,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ProfileTag(
                              text:
                                  '${_toInt(profile['total_posts'])} publicações',
                              darkMode: darkMode,
                            ),
                            _ProfileTag(
                              text:
                                  '${_toInt(profile['total_seguidores'])} seguidores',
                              darkMode: darkMode,
                            ),
                            _ProfileTag(
                              text:
                                  '${_toInt(profile['total_seguindo'])} seguindo',
                              darkMode: darkMode,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        avatar,
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [meta],
                        ),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      const SizedBox(width: 20),
                      meta,
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Publicações recentes',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (posts.isEmpty)
                _ModalEmptyPosts(darkMode: darkMode)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 2 : 1;
                    final gap = 14.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: posts.map((post) {
                        return SizedBox(
                          width: width,
                          child: _ModalPostCard(
                            darkMode: darkMode,
                            post: post,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),

        Positioned(
          top: 14,
          right: 14,
          child: _CircleIconButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 760;
    final tablet = width >= 760 && width < 1080;

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: primary),
        ),
      );
    }

    final avatar =
        _usuarioLogado['foto_perfil'] ??
        _usuarioLogado['foto'] ??
        _usuarioLogado['avatar'];

    return PaceShell(
      currentRoute: '/explorar',
      username: _usuarioLogado['username']?.toString() ?? 'Meu perfil',
      avatarValue: avatar?.toString(),
      backgroundColor: bgColor,
      child: Stack(
        children: [
          _BackgroundDecor(darkMode: darkMode),
          _buildContent(
            horizontalPadding: mobile
                ? (width <= 430 ? 16 : 20)
                : (tablet ? 28 : 38),
            topPadding: mobile ? 24 : (tablet ? 32 : 42),
            bottomPadding: mobile ? 70 : 80,
            mobile: mobile,
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required double horizontalPadding,
    required double topPadding,
    required double bottomPadding,
    required bool mobile,
  }) {
    return RefreshIndicator(
      color: primary,
      onRefresh: _recarregar,
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
                _buildHero(mobile),
                SizedBox(height: mobile ? 24 : 28),
                _buildSearch(),
                SizedBox(height: mobile ? 24 : 34),
                if (!mobile) ...[
                  _buildHighlights(false),
                  const SizedBox(height: 38),
                ],
                _buildProfilesSection(mobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool mobile) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ExplorarBadge(
          text: 'Descubra novas conexões',
        ),
        SizedBox(height: mobile ? 18 : 14),
        Text(
          'Explore pessoas,\nideias e energia',
          style: TextStyle(
            color: textColor,
            fontSize: mobile ? 37 : 50,
            height: 1.01,
            fontWeight: FontWeight.w900,
            letterSpacing: mobile ? -1.6 : -2.2,
          ),
        ),
        SizedBox(height: mobile ? 15 : 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            'Encontre perfis inspiradores, tópicos em alta e conteúdos '
            'que podem ajudar você a construir uma rotina mais forte '
            'dentro do Pace.',
            style: TextStyle(
              color: mutedColor,
              fontSize: mobile ? 15.5 : 16.5,
              height: 1.7,
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
            text: 'Compartilhar algo',
            icon: Icons.auto_awesome_rounded,
            onTap: () => Navigator.of(context).pushNamed('/postar'),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: copy),
        const SizedBox(width: 30),
        _PrimaryButton(
          text: 'Compartilhar algo',
          icon: Icons.auto_awesome_rounded,
          onTap: () => Navigator.of(context).pushNamed('/postar'),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return _GlassPanel(
      darkMode: darkMode,
      radius: 28,
      padding: const EdgeInsets.all(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 58),
        decoration: BoxDecoration(
          color: darkMode
              ? Colors.white.withOpacity(0.035)
              : Colors.white.withOpacity(0.80),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _searching
                ? primary.withOpacity(0.26)
                : primary.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search_rounded,
              color: _searching ? primary : mutedColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => _executarBusca(value.trim()),
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Digite um nome e toque em pesquisar',
                  hintStyle: TextStyle(
                    color: mutedColor,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.only(right: 14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: primary,
                  ),
                ),
              )
            else ...[
              if (_searchController.text.isNotEmpty)
                _CircleIconButton(
                  icon: Icons.close_rounded,
                  onTap: () {
                    _searchController.clear();
                    if (mounted) {
                      setState(() {
                        _profiles = <Map<String, dynamic>>[];
                      });
                    }
                  },
                ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.search_rounded,
                onTap: () => _executarBusca(
                  _searchController.text.trim(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHighlights(bool mobile) {
    final main = _HighlightCard(
      darkMode: darkMode,
      main: true,
      kicker: 'EM ALTA AGORA',
      title: 'Pequenas rotinas,\ngrandes viradas',
      description:
          'Descubra pessoas que estão mostrando consistência real e '
          'compartilhe sua própria evolução com a comunidade.',
      footer: const [
        _HighlightMeta(
          icon: Icons.local_fire_department_rounded,
          text: 'Tendências quentes',
        ),
        _HighlightMeta(
          icon: Icons.groups_rounded,
          text: 'Comunidade ativa',
        ),
      ],
    );

    final second = _HighlightCard(
      darkMode: darkMode,
      kicker: 'SUGESTÃO DO DIA',
      title: 'Encontre parceiros de evolução',
      description:
          'Perfis com hábitos parecidos com os seus podem acelerar sua constância.',
    );

    final third = _HighlightCard(
      darkMode: darkMode,
      kicker: 'NOVA ENERGIA',
      title: 'Conteúdos para sair da inércia',
      description:
          'Veja posts curtos e diretos para colocar você em movimento hoje.',
    );

    if (mobile) {
      return Column(
        children: [
          main,
          const SizedBox(height: 14),
          second,
          const SizedBox(height: 14),
          third,
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tablet = constraints.maxWidth < 980;

        if (tablet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: second),
                  const SizedBox(width: 16),
                  Expanded(child: third),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 14, child: main),
            const SizedBox(width: 18),
            Expanded(flex: 10, child: second),
            const SizedBox(width: 18),
            Expanded(flex: 10, child: third),
          ],
        );
      },
    );
  }

  Widget _buildProfilesSection(bool mobile) {
    final termo = _searchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PESSOAS',
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          termo.isEmpty ? 'Encontre alguém no Pace' : 'Resultados da pesquisa',
          style: TextStyle(
            color: textColor,
            fontSize: mobile ? 28 : 31,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 18),

        if (termo.length < 2)
          _SearchStartState(
            darkMode: darkMode,
          )
        else if (_searching)
          _LoadingProfiles(
            darkMode: darkMode,
          )
        else if (_profiles.isEmpty)
          _EmptyProfiles(
            darkMode: darkMode,
            search: termo,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              int columns;

              if (constraints.maxWidth >= 1040) {
                columns = 3;
              } else if (constraints.maxWidth >= 680) {
                columns = 2;
              } else {
                columns = 1;
              }

              const gap = 18.0;
              final cardWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _profiles.map((profile) {
                  return SizedBox(
                    width: cardWidth,
                    child: RepaintBoundary(
                      child: _SearchProfileCard(
                        darkMode: darkMode,
                        profile: profile,
                        onOpen: () => _abrirPerfil(profile),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
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
              color: primary.withOpacity(0.08),
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
                      color: darkMode ? Colors.white : primary,
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
                  : primary.withOpacity(0.09),
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
                color: primary.withOpacity(0.10),
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
                    ),
                    _mobileDrawerItem(
                      Icons.explore_outlined,
                      'Explorar',
                      '/explorar',
                      active: true,
                    ),
                    _mobileDrawerItem(
                      Icons.edit_square,
                      'Postar',
                      '/postar',
                    ),

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
                color: primary.withOpacity(0.10),
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
              Future.delayed(
                const Duration(milliseconds: 120),
                () {
                  if (mounted) {
                    Navigator.of(context).pushNamed(route);
                  }
                },
              );
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
                        primary.withOpacity(0.14),
                        accent.withOpacity(0.09),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(15),
              border: active
                  ? Border.all(
                      color: primary.withOpacity(0.10),
                    )
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
                        ? primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: active ? primary : sidebarTextColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? primary : sidebarTextColor,
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
    final username =
        _usuarioLogado['username']?.toString().trim().isNotEmpty == true
        ? _usuarioLogado['username'].toString()
        : 'Meu perfil';

    final foto =
        _usuarioLogado['foto_perfil'] ??
        _usuarioLogado['foto'] ??
        _usuarioLogado['avatar'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();

          Future.delayed(
            const Duration(milliseconds: 120),
            () {
              if (mounted) {
                Navigator.of(context).pushNamed('/perfil');
              }
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primary.withOpacity(darkMode ? 0.10 : 0.055),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: ResizeImage(_cachedImageProvider(foto), width: 120, height: 120),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
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
              Icon(
                Icons.chevron_right_rounded,
                color: mutedColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    const collapsed = 88.0;
    const expanded = 244.0;
    final width = _sidebarHovered ? expanded : collapsed;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _sidebarHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _sidebarHovered = false;
          _sidebarItemHovered = null;
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
            right: BorderSide(
              color: primary.withOpacity(0.09),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF112348)
                  .withOpacity(darkMode ? 0.28 : 0.08),
              blurRadius: 34,
              offset: const Offset(12, 0),
            ),
          ],
        ),
        child: ClipRect(
          child: Column(
              children: [
                SizedBox(
                  height: 70,
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 9),
                        child: _PaceLogo(),
                      ),
                      if (_sidebarHovered) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 170),
                            opacity: _sidebarHovered ? 1 : 0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pace',
                                  style: TextStyle(
                                    color: primary,
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
                  color: primary.withOpacity(0.10),
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _sidebarSectionLabel('COMUNIDADE'),
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
                        true,
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
                  color: primary.withOpacity(0.08),
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
    );
  }

  Widget _sidebarSectionLabel(String label) {
    if (!_sidebarHovered) {
      return const SizedBox(height: 6);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: _sidebarHovered ? 1 : 0,
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

  Widget _sidebarItem(
    IconData icon,
    String label,
    String route,
    bool active,
  ) {
    final hovered = _sidebarItemHovered == route;
    final expanded = _sidebarHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _sidebarItemHovered = route;
        });
      },
      onExit: (_) {
        setState(() {
          _sidebarItemHovered = null;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: active
                ? null
                : () {
                    Navigator.of(context).pushNamed(route);
                  },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                gradient: active
                    ? LinearGradient(
                        colors: [
                          primary.withOpacity(0.15),
                          accent.withOpacity(0.09),
                        ],
                      )
                    : null,
                color: !active && hovered
                    ? primary.withOpacity(0.07)
                    : null,
                borderRadius: BorderRadius.circular(14),
                border: active
                    ? Border.all(
                        color: primary.withOpacity(0.08),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active || hovered
                          ? primary.withOpacity(0.07)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icon,
                      color: active ? primary : sidebarTextColor,
                      size: 21,
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: expanded ? 1 : 0,
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? primary : sidebarTextColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebarProfileItem() {
    final expanded = _sidebarHovered;

    final username =
        _usuarioLogado['username']?.toString().trim().isNotEmpty == true
        ? _usuarioLogado['username'].toString()
        : 'Meu perfil';

    final foto =
        _usuarioLogado['foto_perfil'] ??
        _usuarioLogado['foto'] ??
        _usuarioLogado['avatar'];

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/perfil'),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(
              color: primary.withOpacity(darkMode ? 0.10 : 0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: primary.withOpacity(0.12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image(
                      image: ResizeImage(_cachedImageProvider(foto), width: 220, height: 220),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                if (expanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      opacity: expanded ? 1 : 0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ver perfil',
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
                  Icon(
                    Icons.chevron_right_rounded,
                    color: mutedColor,
                    size: 17,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _username(Map<String, dynamic> profile) {
    final value = profile['username']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Usuário';
  }

  String _fotoPerfil(Map<String, dynamic> profile) {
    return (profile['foto_perfil'] ??
            profile['foto'] ??
            profile['avatar'] ??
            '')
        .toString();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _showToast(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _ProfileModalData {
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> posts;

  const _ProfileModalData({
    required this.profile,
    required this.posts,
  });
}

class _BackgroundDecor extends StatelessWidget {
  final bool darkMode;

  const _BackgroundDecor({
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: darkMode
                      ? const [
                          Color(0xFF081120),
                          Color(0xFF050B15),
                        ]
                      : const [
                          Color(0xFFF4F8FD),
                          Color(0xFFEAF1F9),
                          Color(0xFFE4EDF8),
                        ],
                ),
              ),
              child: const SizedBox.expand(),
            ),

            Positioned(
              right: -160,
              top: -170,
              child: _BlurOrb(
                size: 430,
                color: primary.withOpacity(darkMode ? 0.12 : 0.17),
              ),
            ),

            Positioned(
              left: -150,
              bottom: 50,
              child: _BlurOrb(
                size: 390,
                color: accent.withOpacity(darkMode ? 0.08 : 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0.48),
              color.withOpacity(0.16),
              Colors.transparent,
            ],
            stops: const [0.0, 0.30, 0.58, 1.0],
          ),
        ),
      ),
    );
  }
}

class _PaceLogo extends StatelessWidget {
  const _PaceLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/pace_icon.png',
      width: 46,
      height: 46,
      fit: BoxFit.contain,
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final bool darkMode;
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _GlassPanel({
    required this.darkMode,
    required this.child,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: darkMode
                  ? [
                      const Color(0xFF0C1627).withOpacity(0.96),
                      const Color(0xFF0A121F).withOpacity(0.92),
                    ]
                  : [
                      Colors.white.withOpacity(0.96),
                      const Color(0xFFF7FAFF).withOpacity(0.88),
                    ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: darkMode
                  ? Colors.white.withOpacity(0.055)
                  : primary.withOpacity(0.11),
            ),
            boxShadow: [
              BoxShadow(
                color: darkMode
                    ? Colors.black.withOpacity(0.28)
                    : const Color(0xFF15284D).withOpacity(0.11),
                blurRadius: 46,
                offset: const Offset(0, 18),
              ),
            ],
          ),
        child: child,
      ),
    );
  }
}

class _ExplorarBadge extends StatelessWidget {
  final String text;

  const _ExplorarBadge({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: primary.withOpacity(0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.17),
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
              color: primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        child: AnimatedScale(
          scale: pressed
              ? 0.98
              : hover
              ? 1.02
              : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  primary,
                  primary2,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(hover ? 0.28 : 0.20),
                  blurRadius: hover ? 30 : 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

class _HighlightCard extends StatefulWidget {
  final bool darkMode;
  final bool main;
  final String kicker;
  final String title;
  final String description;
  final List<Widget> footer;

  const _HighlightCard({
    required this.darkMode,
    this.main = false,
    required this.kicker,
    required this.title,
    required this.description,
    this.footer = const [],
  });

  @override
  State<_HighlightCard> createState() => _HighlightCardState();
}

class _HighlightCardState extends State<_HighlightCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final normalText = widget.darkMode
        ? const Color(0xFFF2F6FF)
        : const Color(0xFF172033);

    final muted = widget.darkMode
        ? const Color(0xFF98A8BF)
        : const Color(0xFF6F7F96);

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(
          0,
          hover ? -4 : 0,
          0,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: widget.main
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF315CAC),
                    Color(0xFF4071CD),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.darkMode
                      ? [
                          const Color(0xFF0C1627).withOpacity(0.96),
                          const Color(0xFF0A121F).withOpacity(0.92),
                        ]
                      : [
                          Colors.white.withOpacity(0.96),
                          const Color(0xFFF7FAFF).withOpacity(0.88),
                        ],
                ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: widget.main
                ? Colors.white.withOpacity(0.10)
                : widget.darkMode
                ? Colors.white.withOpacity(0.055)
                : primary.withOpacity(0.11),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.main
                  ? primary.withOpacity(0.20)
                  : widget.darkMode
                  ? Colors.black.withOpacity(0.24)
                  : const Color(0xFF15284D).withOpacity(hover ? 0.13 : 0.09),
              blurRadius: hover ? 38 : 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.kicker,
              style: TextStyle(
                color: widget.main
                    ? Colors.white.withOpacity(0.88)
                    : accent,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.25,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              widget.title,
              style: TextStyle(
                color: widget.main ? Colors.white : normalText,
                fontSize: widget.main ? 29 : 21,
                height: 1.12,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              widget.description,
              style: TextStyle(
                color: widget.main
                    ? Colors.white.withOpacity(0.88)
                    : muted,
                fontSize: 14,
                height: 1.65,
              ),
            ),
            if (widget.footer.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: widget.footer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HighlightMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HighlightMeta({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.90),
          size: 18,
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.90),
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}


class _DeferredAvatar extends StatefulWidget {
  final String value;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _DeferredAvatar({
    required this.value,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_DeferredAvatar> createState() => _DeferredAvatarState();
}

class _DeferredAvatarState extends State<_DeferredAvatar> {
  Uint8List? _bytes;
  bool _loadingBase64 = false;

  bool get _isBase64 => widget.value.trim().startsWith('data:image');

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _DeferredAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _bytes = null;
      _loadingBase64 = false;
      _loadIfNeeded();
    }
  }

  Future<void> _loadIfNeeded() async {
    final value = widget.value.trim();

    if (value.isEmpty || !_isBase64 || _loadingBase64) {
      return;
    }

    _loadingBase64 = true;

    final result = await _decodeAvatarSerially(value);

    if (!mounted) return;

    setState(() {
      _bytes = result;
      _loadingBase64 = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    final value = widget.value.trim();

    if (_isBase64 && _bytes != null) {
      child = Image.memory(
        _bytes!,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        cacheWidth: 120,
        cacheHeight: 120,
        gaplessPlayback: true,
      );
    } else if (_isBase64 && _bytes == null) {
      child = Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withOpacity(0.12),
              accent.withOpacity(0.12),
            ],
          ),
        ),
        child: const SizedBox(
          width: 17,
          height: 17,
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            color: primary,
          ),
        ),
      );
    } else if (!_isBase64 && value.isNotEmpty) {
      child = Image(
        image: ResizeImage(
          ApiConfig.imageProvider(value),
          width: 180,
          height: 180,
        ),
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/user.png',
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
        ),
      );
    } else {
      child = Image.asset(
        'assets/user.png',
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      ),
    );
  }
}


class _SearchStartState extends StatelessWidget {
  final bool darkMode;

  const _SearchStartState({
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        darkMode ? Colors.white : const Color(0xFF172033);

    final muted =
        darkMode ? const Color(0xFF98A8BF) : const Color(0xFF6F7F96);

    return _GlassPanel(
      darkMode: darkMode,
      radius: 26,
      padding: const EdgeInsets.symmetric(
        horizontal: 26,
        vertical: 34,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color: primary,
              size: 31,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Pesquise alguém para começar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Digite pelo menos 2 letras e toque no ícone de pesquisa. '
            'Os perfis só são carregados quando você solicitar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchProfileCard extends StatefulWidget {
  final bool darkMode;
  final Map<String, dynamic> profile;
  final VoidCallback onOpen;

  const _SearchProfileCard({
    required this.darkMode,
    required this.profile,
    required this.onOpen,
  });

  @override
  State<_SearchProfileCard> createState() => _SearchProfileCardState();
}

class _SearchProfileCardState extends State<_SearchProfileCard> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final username =
        widget.profile['username']?.toString().trim().isNotEmpty == true
        ? widget.profile['username'].toString()
        : 'Usuário';

    final text =
        widget.darkMode ? const Color(0xFFF2F6FF) : const Color(0xFF172033);

    final muted =
        widget.darkMode ? const Color(0xFF98A8BF) : const Color(0xFF6F7F96);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onOpen,
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        child: AnimatedScale(
          scale: pressed
              ? 0.985
              : hover
                  ? 1.01
                  : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.darkMode
                    ? [
                        const Color(0xFF0C1627).withOpacity(0.96),
                        const Color(0xFF0A121F).withOpacity(0.92),
                      ]
                    : [
                        Colors.white.withOpacity(0.96),
                        const Color(0xFFF7FAFF).withOpacity(0.90),
                      ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: widget.darkMode
                    ? Colors.white.withOpacity(0.055)
                    : primary.withOpacity(0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.darkMode
                      ? Colors.black.withOpacity(0.20)
                      : const Color(0xFF14274D).withOpacity(
                          hover ? 0.12 : 0.07,
                        ),
                  blurRadius: hover ? 32 : 24,
                  offset: const Offset(0, 13),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        primary.withOpacity(0.16),
                        accent.withOpacity(0.16),
                      ],
                    ),
                    border: Border.all(
                      color: primary.withOpacity(0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withOpacity(0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    username.isNotEmpty
                        ? username.characters.first.toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 23,
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
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: primary,
                    size: 20,
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

class _ProfileCard extends StatefulWidget {
  final bool darkMode;
  final Map<String, dynamic> profile;
  final String imageValue;
  final VoidCallback onOpen;
  final VoidCallback onFollow;

  const _ProfileCard({
    required this.darkMode,
    required this.profile,
    required this.imageValue,
    required this.onOpen,
    required this.onFollow,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool hover = false;

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final username =
        widget.profile['username']?.toString().trim().isNotEmpty == true
        ? widget.profile['username'].toString()
        : 'Usuário';

    final following = widget.profile['segue'] == true;

    final text = widget.darkMode
        ? const Color(0xFFF2F6FF)
        : const Color(0xFF172033);

    final muted = widget.darkMode
        ? const Color(0xFF98A8BF)
        : const Color(0xFF6F7F96);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.translationValues(
          0,
          hover ? -5 : 0,
          0,
        ),
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.darkMode
                ? [
                    const Color(0xFF0C1627).withOpacity(0.96),
                    const Color(0xFF0A121F).withOpacity(0.92),
                  ]
                : [
                    Colors.white.withOpacity(0.96),
                    const Color(0xFFF7FAFF).withOpacity(0.88),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.darkMode
                ? Colors.white.withOpacity(0.055)
                : primary.withOpacity(0.11),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.darkMode
                  ? Colors.black.withOpacity(0.24)
                  : const Color(0xFF14274D)
                        .withOpacity(hover ? 0.13 : 0.09),
              blurRadius: hover ? 40 : 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: widget.onOpen,
              borderRadius: BorderRadius.circular(18),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.16),
                          blurRadius: 22,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _DeferredAvatar(
                      value: widget.imageValue,
                      width: 58,
                      height: 58,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$username',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: muted.withOpacity(0.70),
                    size: 19,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 17),

            Text(
              'Acompanhe a evolução, hábitos e publicações deste perfil.',
              style: TextStyle(
                color: muted,
                fontSize: 13.5,
                height: 1.60,
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ProfilePill(
                  text: '${_toInt(widget.profile['total_posts'])} posts',
                  darkMode: widget.darkMode,
                ),
                _ProfilePill(
                  text:
                      '${_toInt(widget.profile['total_seguidores'])} seguidores',
                  darkMode: widget.darkMode,
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _FollowButton(
                    following: following,
                    onTap: widget.onFollow,
                  ),
                ),
                const SizedBox(width: 10),
                _CircleIconButton(
                  icon: Icons.person_outline_rounded,
                  onTap: widget.onOpen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  final String text;
  final bool darkMode;

  const _ProfilePill({
    required this.text,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: darkMode
            ? Colors.white.withOpacity(0.055)
            : primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: darkMode
              ? const Color(0xFFDBE5F8)
              : const Color(0xFF4C5972),
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  final String text;
  final bool darkMode;

  const _ProfileTag({
    required this.text,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return _ProfilePill(
      text: text,
      darkMode: darkMode,
    );
  }
}

class _FollowButton extends StatefulWidget {
  final bool following;
  final VoidCallback onTap;

  const _FollowButton({
    required this.following,
    required this.onTap,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        child: AnimatedScale(
          scale: pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: widget.following
                  ? null
                  : const LinearGradient(
                      colors: [
                        primary,
                        primary2,
                      ],
                    ),
              color: widget.following
                  ? primary.withOpacity(hover ? 0.12 : 0.08)
                  : null,
              borderRadius: BorderRadius.circular(14),
              border: widget.following
                  ? Border.all(
                      color: primary.withOpacity(0.18),
                    )
                  : null,
              boxShadow: widget.following
                  ? null
                  : [
                      BoxShadow(
                        color: primary.withOpacity(0.16),
                        blurRadius: 20,
                        offset: const Offset(0, 9),
                      ),
                    ],
            ),
            child: Text(
              widget.following ? 'Seguindo' : 'Seguir',
              style: TextStyle(
                color: widget.following ? primary : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: darkMode
                ? Colors.white.withOpacity(hover ? 0.08 : 0.055)
                : primary.withOpacity(hover ? 0.11 : 0.065),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            widget.icon,
            color: primary,
            size: 21,
          ),
        ),
      ),
    );
  }
}

class _LoadingProfiles extends StatelessWidget {
  final bool darkMode;

  const _LoadingProfiles({
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return _EmptyStateShell(
      darkMode: darkMode,
      child: const Column(
        children: [
          CircularProgressIndicator(
            color: primary,
            strokeWidth: 2.4,
          ),
          SizedBox(height: 18),
          Text(
            'Buscando perfis reais',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Aguarde um momento enquanto carregamos os perfis criados na plataforma.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6F7F96),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfiles extends StatelessWidget {
  final bool darkMode;
  final String search;

  const _EmptyProfiles({
    required this.darkMode,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    final text = search.isEmpty
        ? 'Ainda não há outros perfis para mostrar.'
        : 'Nenhum perfil encontrado para “$search”.';

    return _EmptyStateShell(
      darkMode: darkMode,
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            color: primary,
            size: 38,
          ),
          const SizedBox(height: 14),
          Text(
            'Nada por aqui ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkMode ? Colors.white : const Color(0xFF172033),
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6F7F96),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateShell extends StatelessWidget {
  final bool darkMode;
  final Widget child;

  const _EmptyStateShell({
    required this.darkMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      darkMode: darkMode,
      radius: 26,
      padding: const EdgeInsets.symmetric(
        horizontal: 26,
        vertical: 40,
      ),
      child: Center(child: child),
    );
  }
}

class _ProfileModalShell extends StatelessWidget {
  final bool darkMode;
  final Widget child;

  const _ProfileModalShell({
    required this.darkMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 920,
                maxHeight: 820,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                    decoration: BoxDecoration(
                      color: darkMode
                          ? const Color(0xFF0A0C12).withOpacity(0.96)
                          : Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: darkMode
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.72),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0E1A34).withOpacity(0.24),
                          blurRadius: 70,
                          offset: const Offset(0, 28),
                        ),
                      ],
                    ),
                    child: child,
                  ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalError extends StatelessWidget {
  final bool darkMode;
  final VoidCallback onClose;

  const _ModalError({
    required this.darkMode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFE55353),
            size: 42,
          ),
          const SizedBox(height: 14),
          Text(
            'Não foi possível carregar este perfil.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkMode ? Colors.white : const Color(0xFF172033),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          _PrimaryButton(
            text: 'Fechar',
            icon: Icons.close_rounded,
            onTap: onClose,
          ),
        ],
      ),
    );
  }
}

class _ModalEmptyPosts extends StatelessWidget {
  final bool darkMode;

  const _ModalEmptyPosts({
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: darkMode
            ? Colors.white.withOpacity(0.035)
            : primary.withOpacity(0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : primary.withOpacity(0.09),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: primary,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            'Este usuário ainda não publicou nada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: darkMode ? Colors.white : const Color(0xFF172033),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalPostCard extends StatelessWidget {
  final bool darkMode;
  final Map<String, dynamic> post;

  const _ModalPostCard({
    required this.darkMode,
    required this.post,
  });

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final text = darkMode ? Colors.white : const Color(0xFF172033);
    final muted = darkMode
        ? const Color(0xFF98A8BF)
        : const Color(0xFF6F7F96);

    final conteudo =
        (post['conteudo'] ?? post['texto'] ?? '').toString().trim();

    final imagem =
        (post['imagem'] ?? post['imagem_url'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF080A0E).withOpacity(0.88)
            : Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : primary.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conteudo.isNotEmpty)
            Text(
              conteudo,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: text,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),

          if (imagem.isNotEmpty) ...[
            if (conteudo.isNotEmpty)
              const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image(
                  image: _cachedImageProvider(imagem),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: primary.withOpacity(0.05),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: muted,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          Row(
            children: [
              Icon(
                post['liked'] == true
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: post['liked'] == true
                    ? const Color(0xFFD8425C)
                    : muted,
                size: 17,
              ),
              const SizedBox(width: 6),
              Text(
                '${_toInt(post['likes'])}',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
