import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

const Color primary = Color(0xFF1769E8);
const Color primary2 = Color(0xFF0B3D91);
const Color accent = Color(0xFFFFC928);


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

String _explorarResolveMediaUrl(dynamic value) {
  final raw = value?.toString().trim() ?? '';

  if (raw.isEmpty || raw.startsWith('data:image')) {
    return raw;
  }

  final parsed = Uri.tryParse(raw);
  final baseUri = Uri.parse(ApiConfig.baseUrl);

  if (parsed != null &&
      (parsed.scheme == 'http' || parsed.scheme == 'https')) {
    const localHosts = {
      '127.0.0.1',
      'localhost',
      '10.0.2.2',
    };

    if (!localHosts.contains(parsed.host)) {
      return raw;
    }

    // No desktop, localhost já aponta para o próprio notebook.
    // Preservamos inclusive a porta original, pois a mídia pode
    // estar vindo do Live Server (5500) e não do FastAPI (8000).
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android) {
      return raw;
    }

    // No Android físico, apenas trocamos o host pelo IP usado
    // pela API, mantendo a porta original da mídia.
    return parsed
        .replace(
          scheme: baseUri.scheme,
          host: baseUri.host,
          port: parsed.hasPort ? parsed.port : baseUri.port,
        )
        .toString();
  }

  // URLs relativas continuam sendo resolvidas contra o backend.
  return ApiConfig.resolveMediaUrl(raw);
}

ImageProvider _explorarImageProvider(
  dynamic value, {
  String fallbackAsset = 'assets/user.png',
}) {
  final raw = value?.toString().trim() ?? '';

  if (raw.isEmpty) {
    return AssetImage(fallbackAsset);
  }

  if (raw.startsWith('data:image')) {
    try {
      final commaIndex = raw.indexOf(',');

      if (commaIndex == -1 || commaIndex == raw.length - 1) {
        return AssetImage(fallbackAsset);
      }

      return MemoryImage(
        base64Decode(
          raw.substring(commaIndex + 1),
        ),
      );
    } catch (_) {
      return AssetImage(fallbackAsset);
    }
  }

  final resolved = _explorarResolveMediaUrl(raw);

  if (resolved.startsWith('http://') ||
      resolved.startsWith('https://')) {
    return NetworkImage(resolved);
  }

  return AssetImage(fallbackAsset);
}

ImageProvider _cachedImageProvider(dynamic value) {
  final key = value?.toString().trim() ?? '';

  if (key.isEmpty) {
    return const AssetImage('assets/user.png');
  }

  return _explorarImageCache.putIfAbsent(
    key,
    () => _explorarImageProvider(key),
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
  List<Map<String, dynamic>> _communities = [];

  String _activeExploreTab = 'people';
  bool _loadingCommunities = false;
  bool _creatingCommunity = false;

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor =>
      darkMode ? const Color(0xFF041126) : const Color(0xFFEAF3FB);

  Color get textColor =>
      darkMode ? const Color(0xFFF7FAFF) : const Color(0xFF06152D);

  Color get textSoftColor =>
      darkMode ? const Color(0xFFC7D5E8) : const Color(0xFF203B61);

  Color get mutedColor =>
      darkMode ? const Color(0xFF8FA5C0) : const Color(0xFF61758F);

  Color get sidebarTextColor => const Color(0xFFC7D5E8);

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


  Future<List<Map<String, dynamic>>> _buscarComunidades(
    String token,
  ) async {
    final response = await http
        .get(
          ApiConfig.uri('/comunidades'),
          headers: _authHeaders(token),
        )
        .timeout(const Duration(seconds: 12));

    final data = await _parseResponse(
      response,
      'Não foi possível carregar as comunidades.',
    );

    if (data is! List) {
      return <Map<String, dynamic>>[];
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _carregarComunidades({
    bool showLoading = true,
  }) async {
    final token = await _getToken();

    if (token == null || token.isEmpty || !mounted) {
      return;
    }

    if (showLoading) {
      setState(() {
        _loadingCommunities = true;
      });
    }

    try {
      final comunidades = await _buscarComunidades(token);

      if (!mounted) {
        return;
      }

      setState(() {
        _communities = comunidades;
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
          _loadingCommunities = false;
        });
      }
    }
  }

  void _trocarAbaExplorar(String tab) {
    final next = tab == 'communities' ? 'communities' : 'people';

    if (_activeExploreTab == next) {
      return;
    }

    setState(() {
      _activeExploreTab = next;
      _searchController.clear();
      _profiles = <Map<String, dynamic>>[];
    });

    if (next == 'communities') {
      _carregarComunidades();
    }
  }

  List<Map<String, dynamic>> get _comunidadesFiltradas {
    final termo = _searchController.text.trim().toLowerCase();

    if (termo.isEmpty) {
      return _communities;
    }

    return _communities.where((community) {
      final topicos = (community['topicos'] is List)
          ? (community['topicos'] as List).join(' ')
          : '';

      final base = [
        community['nome'],
        community['descricao'],
        topicos,
      ].join(' ').toLowerCase();

      return base.contains(termo);
    }).toList();
  }

  Future<void> _toggleCommunityMembership(
    Map<String, dynamic> community,
  ) async {
    if (community['sou_criador'] == true) {
      return;
    }

    final token = await _getToken();

    if (token == null || token.isEmpty) {
      return;
    }

    final id = _toInt(community['id']);

    if (id <= 0) {
      return;
    }

    final participating = community['sou_membro'] == true;

    try {
      final request = participating
          ? http.delete(
              ApiConfig.uri('/comunidades/$id/participar'),
              headers: _authHeaders(token),
            )
          : http.post(
              ApiConfig.uri('/comunidades/$id/participar'),
              headers: _authHeaders(token),
            );

      final response = await request.timeout(
        const Duration(seconds: 12),
      );

      await _parseResponse(
        response,
        participating
            ? 'Não foi possível sair da comunidade.'
            : 'Não foi possível entrar na comunidade.',
      );

      await _carregarComunidades(showLoading: false);
    } catch (e) {
      _showToast(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    }
  }

  Future<void> _abrirDetalhesComunidade(
    Map<String, dynamic> community,
  ) async {
    final id = _toInt(community['id']);

    if (id <= 0) {
      return;
    }

    final token = await _getToken();

    if (token == null || token.isEmpty || !mounted) {
      return;
    }

    Map<String, dynamic> current = Map<String, dynamic>.from(community);

    try {
      final response = await http.get(
        ApiConfig.uri('/comunidades/$id'),
        headers: _authHeaders(token),
      );

      final data = await _parseResponse(
        response,
        'Não foi possível carregar a comunidade.',
      );

      if (data is Map) {
        current = Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.62),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: darkMode
                    ? const Color(0xFF0C1627)
                    : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primary.withOpacity(0.16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      darkMode ? 0.36 : 0.12,
                    ),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  final topics = current['topicos'] is List
                      ? List<dynamic>.from(current['topicos'])
                      : <dynamic>[];

                  final isCreator = current['sou_criador'] == true;
                  final isMember = current['sou_membro'] == true;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFF071A36),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.groups_2_outlined,
                              color: accent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              (current['nome'] ?? 'Comunidade').toString(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(
                              Icons.close_rounded,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        (current['descricao'] ?? 'Sem descrição.').toString(),
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      if (topics.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: topics.map((topic) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '#${topic.toString()}',
                                style: const TextStyle(
                                  color: Color(0xFF7EB0FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Icon(
                            Icons.people_alt_outlined,
                            color: mutedColor,
                            size: 18,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${_toInt(current['membros_count'])} '
                            '${_toInt(current['membros_count']) == 1 ? 'membro' : 'membros'}',
                            style: TextStyle(
                              color: mutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (isCreator)
                            _CommunityStatusPill(
                              text: 'Criador',
                              highlighted: true,
                              darkMode: darkMode,
                            )
                          else
                            _CommunityStatusPill(
                              text: isMember ? 'Participando' : 'Disponível',
                              highlighted: isMember,
                              darkMode: darkMode,
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      if (!isCreator)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              await _toggleCommunityMembership(current);

                              final refreshed = _communities.firstWhere(
                                (item) =>
                                    _toInt(item['id']) == id,
                                orElse: () => current,
                              );

                              setModalState(() {
                                current = Map<String, dynamic>.from(refreshed);
                              });
                            },
                            icon: Icon(
                              isMember
                                  ? Icons.logout_rounded
                                  : Icons.group_add_outlined,
                            ),
                            label: Text(
                              isMember
                                  ? 'Sair da comunidade'
                                  : 'Participar da comunidade',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: isMember
                                  ? const Color(0xFF132742)
                                  : primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _abrirCriarComunidade() async {
    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();
    final topicosController = TextEditingController();

    String privacy = 'publica';
    String? errorMessage;

    final created = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.62),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              if (_creatingCommunity) {
                return;
              }

              final nome = nomeController.text.trim();
              final descricao = descricaoController.text.trim();
              final topicos = topicosController.text
                  .split(',')
                  .map((item) => item.trim().replaceFirst(RegExp(r'^#'), ''))
                  .where((item) => item.isNotEmpty)
                  .toSet()
                  .take(5)
                  .toList();

              if (nome.length < 3) {
                setModalState(() {
                  errorMessage = 'Use pelo menos 3 caracteres no nome.';
                });
                return;
              }

              if (descricao.length < 10) {
                setModalState(() {
                  errorMessage = 'Escreva uma descrição um pouco maior.';
                });
                return;
              }

              if (topicos.isEmpty) {
                setModalState(() {
                  errorMessage = 'Adicione pelo menos um tópico.';
                });
                return;
              }

              final token = await _getToken();

              if (token == null || token.isEmpty) {
                return;
              }

              setModalState(() {
                _creatingCommunity = true;
                errorMessage = null;
              });

              try {
                final response = await http
                    .post(
                      ApiConfig.uri('/comunidades'),
                      headers: _authHeaders(token, json: true),
                      body: jsonEncode({
                        'nome': nome,
                        'descricao': descricao,
                        'topicos': topicos,
                        'privacidade': privacy,
                      }),
                    )
                    .timeout(const Duration(seconds: 12));

                await _parseResponse(
                  response,
                  'Não foi possível criar a comunidade.',
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop(true);
              } catch (e) {
                setModalState(() {
                  errorMessage = e
                      .toString()
                      .replaceFirst('Exception: ', '');
                  _creatingCommunity = false;
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 590),
                child: Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: darkMode
                        ? const Color(0xFF0C1627)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: primary.withOpacity(0.16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          darkMode ? 0.38 : 0.14,
                        ),
                        blurRadius: 44,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NOVA COMUNIDADE',
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Criar comunidade',
                                    style: TextStyle(
                                      color: darkMode
                                          ? Colors.white
                                          : const Color(0xFF06152D),
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              icon: Icon(
                                Icons.close_rounded,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _CommunityTextField(
                          controller: nomeController,
                          label: 'Nome da comunidade',
                          hint: 'Ex: Clube de Literatura',
                          maxLength: 50,
                          darkMode: darkMode,
                        ),
                        const SizedBox(height: 14),
                        _CommunityTextField(
                          controller: descricaoController,
                          label: 'Descrição',
                          hint: 'Conte brevemente sobre o objetivo da comunidade.',
                          maxLength: 220,
                          maxLines: 4,
                          darkMode: darkMode,
                        ),
                        const SizedBox(height: 14),
                        _CommunityTextField(
                          controller: topicosController,
                          label: 'Tópicos',
                          hint: 'Ex: Literatura, Livros, Escrita',
                          darkMode: darkMode,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Privacidade',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _PrivacyOption(
                                selected: privacy == 'publica',
                                icon: Icons.public_rounded,
                                title: 'Pública',
                                onTap: () {
                                  setModalState(() {
                                    privacy = 'publica';
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _PrivacyOption(
                                selected: privacy == 'privada',
                                icon: Icons.lock_outline_rounded,
                                title: 'Privada',
                                onTap: () {
                                  setModalState(() {
                                    privacy = 'privada';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFFF6B7A),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _creatingCommunity ? null : submit,
                            icon: _creatingCommunity
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add_rounded),
                            label: const Text('Criar comunidade'),
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
          },
        );
      },
    );

    nomeController.dispose();
    descricaoController.dispose();
    topicosController.dispose();

    if (mounted) {
      setState(() {
        _creatingCommunity = false;
      });
    }

    if (created == true) {
      await _carregarComunidades(showLoading: false);

      _showToast(
        'Comunidade criada com sucesso.',
        const Color(0xFF1E9E72),
      );
    }
  }

  Future<void> _recarregar() async {
    if (_activeExploreTab == 'communities') {
      await _carregarComunidades();
      return;
    }

    final termo = _searchController.text.trim();

    if (termo.length < 2) {
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
      ApiConfig.uri('/post/usuario/$userId').replace(
        queryParameters: const {
          'offset': '0',
          'limit': '20',
        },
      ),
      headers: _authHeaders(token),
    );

    final postsData = await _parseResponse(
      postsResponse,
      'Erro ao carregar posts.',
    );

    final posts = postsData is List
        ? postsData
              .whereType<Map>()
              .map((item) {
                final post = Map<String, dynamic>.from(item);

                post['commentsCount'] = _toInt(
                  post['commentsCount'] ??
                      post['comentariosCount'] ??
                      post['commentCount'] ??
                      post['totalComentarios'] ??
                      post['total_comentarios'],
                );

                return post;
              })
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

    final page = Stack(
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
                SizedBox(height: mobile ? 20 : 24),
                _buildExploreTabs(),
                SizedBox(height: mobile ? 16 : 18),
                _buildSearch(),
                SizedBox(height: mobile ? 24 : 30),
                if (_activeExploreTab == 'people') ...[
                  if (!mobile) ...[
                    _buildHighlights(false),
                    const SizedBox(height: 38),
                  ],
                  _buildProfilesSection(mobile),
                ] else
                  _buildCommunitiesSection(mobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool mobile) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              child: Divider(
                color: Color(0xFFFFC928),
                thickness: 3,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'COMUNIDADE',
              style: TextStyle(
                color: Color(0xFF1769E8),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.25,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Explorar',
          style: TextStyle(
            color: textColor,
            fontSize: mobile ? 36 : 44,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Encontre pessoas, comunidades e conteúdos para continuar evoluindo.',
          style: TextStyle(
            color: mutedColor,
            fontSize: mobile ? 12.5 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (mobile) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: title),
          const SizedBox(width: 12),
          _PrimaryButton(
            text: 'Postar',
            icon: Icons.add_rounded,
            onTap: () => Navigator.of(context).pushNamed('/postar'),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: title),
        const SizedBox(width: 24),
        _PrimaryButton(
          text: 'Compartilhar algo',
          icon: Icons.edit_outlined,
          onTap: () => Navigator.of(context).pushNamed('/postar'),
        ),
      ],
    );
  }


  Widget _buildExploreTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0E1B31)
            : Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF06152D).withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ExploreTabButton(
            icon: Icons.people_outline_rounded,
            text: 'Pessoas',
            selected: _activeExploreTab == 'people',
            onTap: () => _trocarAbaExplorar('people'),
          ),
          const SizedBox(width: 4),
          _ExploreTabButton(
            icon: Icons.groups_2_outlined,
            text: 'Comunidades',
            selected: _activeExploreTab == 'communities',
            onTap: () => _trocarAbaExplorar('communities'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return _GlassPanel(
      darkMode: darkMode,
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 58),
        decoration: BoxDecoration(
          color: darkMode
              ? Colors.white.withOpacity(0.035)
              : Colors.white,
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
                onSubmitted: (value) {
                  if (_activeExploreTab == 'people') {
                    _executarBusca(value.trim());
                  } else {
                    setState(() {});
                  }
                },
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: _activeExploreTab == 'people'
                      ? 'Digite um nome e toque em pesquisar'
                      : 'Pesquisar comunidades',
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
                onTap: () {
                  if (_activeExploreTab == 'people') {
                    _executarBusca(
                      _searchController.text.trim(),
                    );
                  } else {
                    setState(() {});
                  }
                },
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


  Widget _buildCommunitiesSection(bool mobile) {
    final filtered = _comunidadesFiltradas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMUNIDADES',
                    style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Encontre seu espaço',
                    style: TextStyle(
                      color: textColor,
                      fontSize: mobile ? 28 : 31,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            _PrimaryButton(
              text: mobile ? 'Criar' : 'Criar comunidade',
              icon: Icons.add_rounded,
              onTap: _abrirCriarComunidade,
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (_loadingCommunities)
          _EmptyStateShell(
            darkMode: darkMode,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: CircularProgressIndicator(
                  color: primary,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          )
        else if (filtered.isEmpty)
          _EmptyStateShell(
            darkMode: darkMode,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 34,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.groups_2_outlined,
                    color: primary,
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchController.text.trim().isEmpty
                        ? 'Nenhuma comunidade encontrada'
                        : 'Nenhuma comunidade corresponde à busca',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _searchController.text.trim().isEmpty
                        ? 'Crie a primeira comunidade ou atualize a página.'
                        : 'Tente pesquisar por outro nome ou tópico.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              int columns;

              if (constraints.maxWidth >= 980) {
                columns = 3;
              } else if (constraints.maxWidth >= 650) {
                columns = 2;
              } else {
                columns = 1;
              }

              const gap = 16.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: filtered.map((community) {
                  return SizedBox(
                    width: width,
                    child: _buildCommunityCard(community),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommunityCard(
    Map<String, dynamic> community,
  ) {
    final topics = community['topicos'] is List
        ? List<dynamic>.from(community['topicos'])
        : <dynamic>[];

    final isCreator = community['sou_criador'] == true;
    final isMember = community['sou_membro'] == true;
    final members = _toInt(community['membros_count']);
    final privacy = (community['privacidade'] ?? 'publica').toString();

    return SizedBox(
      height: 285,
      child: Material(
        color: Colors.transparent,
      child: InkWell(
        onTap: () => _abrirDetalhesComunidade(community),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: darkMode
                ? const Color(0xFF0E1B31)
                : Colors.white.withOpacity(0.94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: darkMode
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFF06152D).withOpacity(0.08),
            ),
            boxShadow: [
              if (!darkMode)
                BoxShadow(
                  color: const Color(0xFF06152D).withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF071A36),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.groups_2_outlined,
                      color: accent,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  _CommunityStatusPill(
                    text: privacy == 'privada' ? 'Privada' : 'Pública',
                    highlighted: false,
                    darkMode: darkMode,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                (community['nome'] ?? 'Comunidade').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (community['descricao'] ?? 'Sem descrição.').toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: topics.take(3).map((topic) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#${topic.toString()}',
                      style: const TextStyle(
                        color: Color(0xFF7EB0FF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    '$members ${members == 1 ? 'membro' : 'membros'}',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (isCreator)
                    _CommunityStatusPill(
                      text: 'Criador',
                      highlighted: true,
                      darkMode: darkMode,
                    )
                  else if (isMember)
                    _CommunityStatusPill(
                      text: 'Participando',
                      highlighted: true,
                      darkMode: darkMode,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: darkMode
                    ? Colors.white.withOpacity(0.08)
                    : const Color(0xFF06152D).withOpacity(0.08),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    color: primary,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Clique para ver detalhes',
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      ),
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
            InkWell(
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
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Evolução contínua',
                    style: TextStyle(
                      color: Color(0xFF8FA5C0),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
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
                    ),
                    _mobileDrawerItem(
                      Icons.explore_outlined,
                      'Explorar',
                      '/explorar',
                      active: true,
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
              color: active
                  ? const Color(0xFF174A9B)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: active
                  ? Border.all(
                      color: const Color(0xFF1769E8).withOpacity(0.10),
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
                      color: active ? Colors.white : const Color(0xFFC7D5E8),
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
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _cachedImageProvider(_fotoPerfil(_usuarioLogado)),
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
                      _sidebarItem(Icons.home_rounded, 'Feed', '/feed', false),
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
                  color: Colors.white.withOpacity(0.08),
                ),
                const SizedBox(height: 8),
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

  Widget _sidebarItem(IconData icon, String label, String route, bool active) {
    final isHovered = _sidebarItemHovered == route;
    final highlighted = active || isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _sidebarItemHovered = route),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (route != '/explorar') {
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
              final showText = constraints.maxWidth >= 150;

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

  Widget _sidebarProfileItem() {
    const route = '/perfil';
    final isHovered = _sidebarItemHovered == route;

    return MouseRegion(
      onEnter: (_) => setState(() => _sidebarItemHovered = route),
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
              final showText = constraints.maxWidth >= 150;

              return Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: _cachedImageProvider(_fotoPerfil(_usuarioLogado)),
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


class _ExploreTabButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ExploreTabButton({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF0B3D91)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : const Color(0xFF8FA5C0),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF8FA5C0),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommunityStatusPill extends StatelessWidget {
  final String text;
  final bool highlighted;
  final bool darkMode;

  const _CommunityStatusPill({
    required this.text,
    required this.highlighted,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? (darkMode ? const Color(0xFFEAF3FB) : const Color(0xFF0B3D91))
            : const Color(0xFF1769E8).withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlighted
              ? (darkMode ? const Color(0xFF0B3D91) : Colors.white)
              : const Color(0xFF7EB0FF),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CommunityTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final bool darkMode;

  const _CommunityTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.darkMode,
    this.maxLength,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final text = darkMode
        ? const Color(0xFFF7FAFF)
        : const Color(0xFF06152D);
    final muted = darkMode
        ? const Color(0xFF8FA5C0)
        : const Color(0xFF61758F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          style: TextStyle(
            color: text,
            fontSize: 13.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: muted,
              fontSize: 12.5,
            ),
            counterText: '',
            filled: true,
            fillColor: darkMode
                ? const Color(0xFF071426)
                : const Color(0xFFF4F8FD),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: const Color(0xFF1769E8).withOpacity(0.12),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: const Color(0xFF1769E8).withOpacity(0.12),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF1769E8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _PrivacyOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF1769E8).withOpacity(0.13)
                : const Color(0xFF071426),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1769E8)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? const Color(0xFF7EB0FF)
                    : const Color(0xFF8FA5C0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(0xFFC7D5E8),
                    fontSize: 12,
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
        child: Container(
          color: darkMode
              ? const Color(0xFF041126)
              : const Color(0xFFEAF3FB),
          child: CustomPaint(
            painter: _ExplorarGridPainter(
              darkMode: darkMode,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplorarGridPainter extends CustomPainter {
  final bool darkMode;

  const _ExplorarGridPainter({
    required this.darkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = darkMode
          ? Colors.white.withOpacity(0.018)
          : const Color(0xFF1769E8).withOpacity(0.035)
      ..strokeWidth = 1;

    const step = 38.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExplorarGridPainter oldDelegate) {
    return oldDelegate.darkMode != darkMode;
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
          gradient: widget.main && !widget.darkMode
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
            color: widget.main && !widget.darkMode
                ? Colors.white.withOpacity(0.10)
                : widget.darkMode
                ? Colors.white.withOpacity(0.055)
                : primary.withOpacity(0.11),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.main && !widget.darkMode
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
          _explorarImageProvider(value),
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

    return SizedBox(
      width: double.infinity,
      child: _GlassPanel(
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
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.darkMode
                        ? const Color(0xFF0E203A)
                        : Colors.white,
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
                  child: _DeferredAvatar(
                    value: (
                      widget.profile['foto_perfil'] ??
                      widget.profile['foto'] ??
                      widget.profile['avatar'] ??
                      ''
                    ).toString(),
                    width: 54,
                    height: 54,
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
    return SizedBox(
      width: double.infinity,
      child: _GlassPanel(
        darkMode: darkMode,
        radius: 26,
        padding: const EdgeInsets.symmetric(
          horizontal: 26,
          vertical: 40,
        ),
        child: Center(child: child),
      ),
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

class _ModalPostCard extends StatefulWidget {
  final bool darkMode;
  final Map<String, dynamic> post;

  const _ModalPostCard({
    required this.darkMode,
    required this.post,
  });

  @override
  State<_ModalPostCard> createState() => _ModalPostCardState();
}

class _ModalPostCardState extends State<_ModalPostCard> {
  bool _commentsOpen = false;
  bool _commentsLoading = false;
  bool _commentsLoaded = false;
  bool _likeLoading = false;
  List<Map<String, dynamic>> _comments = [];
  late int _commentsCount;
  late int _likes;
  late bool _liked;

  @override
  void initState() {
    super.initState();
    _commentsCount = _toInt(
      widget.post['commentsCount'] ??
          widget.post['comentariosCount'] ??
          widget.post['commentCount'] ??
          widget.post['totalComentarios'] ??
          widget.post['total_comentarios'],
    );

    _likes = _toInt(
      widget.post['likes'] ??
          widget.post['total_curtidas'],
    );

    _liked = widget.post['liked'] == true;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access_token');
  }

  Future<void> _toggleLike() async {
    if (_likeLoading) return;

    final postId = _toInt(widget.post['id']);
    if (postId <= 0) return;

    final token = await _getToken();
    if (token == null || token.isEmpty || !mounted) return;

    final likedAntes = _liked;
    final likesAntes = _likes;

    setState(() {
      _likeLoading = true;
      _liked = !likedAntes;
      _likes = likedAntes
          ? (_likes > 0 ? _likes - 1 : 0)
          : _likes + 1;
    });

    try {
      final uri = ApiConfig.uri(
        likedAntes
            ? '/post/remover_curtida/$postId'
            : '/post/curtir/$postId',
      );

      final response = likedAntes
          ? await http.delete(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
              },
            )
          : await http.post(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
              },
            );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Erro ao atualizar curtida.');
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _liked = likedAntes;
        _likes = likesAntes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível atualizar a curtida.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _likeLoading = false;
        });
      }
    }
  }

  Future<void> _toggleComments() async {
    if (_commentsOpen) {
      setState(() {
        _commentsOpen = false;
      });
      return;
    }

    setState(() {
      _commentsOpen = true;
    });

    if (_commentsLoaded || _commentsLoading) return;

    final postId = _toInt(widget.post['id']);
    if (postId <= 0) return;

    final token = await _getToken();
    if (token == null || token.isEmpty || !mounted) return;

    setState(() {
      _commentsLoading = true;
    });

    try {
      final response = await http.get(
        ApiConfig.uri('/comments/comentarios/$postId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      dynamic data;
      try {
        data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      } catch (_) {
        data = null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Erro ao carregar comentários.');
      }

      final comments = data is List
          ? data
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _comments = comments;
        _commentsCount = comments.length;
        _commentsLoaded = true;
        _commentsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _commentsOpen = false;
        _commentsLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não foi possível carregar os comentários.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final darkMode = widget.darkMode;
    final post = widget.post;

    final text = darkMode ? Colors.white : const Color(0xFF06152D);
    final muted =
        darkMode ? const Color(0xFF8FA5C0) : const Color(0xFF61758F);

    final conteudo =
        (post['conteudo'] ?? post['texto'] ?? '').toString().trim();

    final imagem =
        (post['imagem'] ?? post['imagem_url'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF071A36)
            : Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFF06152D).withOpacity(0.06),
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
            if (conteudo.isNotEmpty) const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image(
                  image: _cachedImageProvider(imagem),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
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
              InkWell(
                onTap: _likeLoading ? null : _toggleLike,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _liked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _liked
                            ? const Color(0xFFD8425C)
                            : muted,
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_likes',
                        style: TextStyle(
                          color: _liked
                              ? const Color(0xFFD8425C)
                              : muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: _toggleComments,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.mode_comment_outlined,
                        color: _commentsOpen ? primary : muted,
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_commentsCount',
                        style: TextStyle(
                          color: _commentsOpen ? primary : muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_commentsOpen) ...[
            const SizedBox(height: 14),

            if (_commentsLoading)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Carregando comentários...',
                    style: TextStyle(
                      color: Color(0xFF61758F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else if (_comments.isEmpty)
              Text(
                'Nenhum comentário ainda.',
                style: TextStyle(
                  color: muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Column(
                children: _comments.map((comment) {
                  final usuario = comment['usuario'];
                  final username = usuario is Map
                      ? (usuario['username'] ?? 'Usuário').toString()
                      : (comment['username'] ?? 'Usuário').toString();

                  final conteudoComentario =
                      (comment['conteudo'] ??
                              comment['texto'] ??
                              comment['comentario'] ??
                              '')
                          .toString();

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: darkMode
                          ? Colors.white.withOpacity(0.045)
                          : const Color(0xFFEAF3FB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@$username',
                          style: TextStyle(
                            color: text,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          conteudoComentario,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12.5,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}