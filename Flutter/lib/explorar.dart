import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExplorarPage extends StatefulWidget {
  const ExplorarPage({super.key});

  @override
  State<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarProfile {
  final int? id;
  final String nome;
  final String username;
  final String bio;
  final String avatar;
  final List<String> tags;

  const _ExplorarProfile({
    this.id,
    required this.nome,
    required this.username,
    required this.bio,
    required this.avatar,
    this.tags = const [],
  });
}

class _ExplorarPageState extends State<ExplorarPage> {
  static const String apiUrl = 'http://127.0.0.1:8000';

  static const _fallbackProfiles = [
    _ExplorarProfile(
      nome: 'Lara Mendes',
      username: '@laradisciplina',
      bio: 'Transformando rotina em resultado com constÃ¢ncia.',
      avatar: '',
      tags: ['Disciplina', 'Mindset'],
    ),
  ];

  final TextEditingController searchController = TextEditingController();

  List<_ExplorarProfile> profilesData = [];

  Map<String, dynamic> usuarioLogado = {};

  bool isLoadingProfiles = true;
  bool sidebarHovered = false;
  String? sidebarItemHovered;
  String filtroAtual = 'todos';
  String termoAtual = '';

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get textColor =>
      darkMode ? const Color(0xFFF3F6FF) : const Color(0xFF1B2233);

  Color get mutedColor =>
      darkMode ? const Color(0xFF9CA7BE) : const Color(0xFF6F7B91);

  Color get sidebarTextColor =>
      darkMode ? const Color(0xFFF1F5FF) : const Color(0xFF33415C);

  @override
  void initState() {
    super.initState();
    _loadOptionalUser();
    _renderProfiles();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadOptionalUser() async {
    final token = await _getToken();
    if (token == null || !mounted) return;

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/profile/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        setState(() {
          usuarioLogado = Map<String, dynamic>.from(jsonDecode(response.body));
        });
      }
    } catch (_) {}
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map && data['detail'] != null
          ? data['detail'].toString()
          : fallbackMessage;

      throw Exception(message);
    }

    return data;
  }

  _ExplorarProfile _buildProfileFromAPI(Map<String, dynamic> user) {
    final rawUsername = user['username']?.toString() ?? 'Perfil Pace';
    final withoutAt = rawUsername.replaceFirst(RegExp(r'^@'), '');

    return _ExplorarProfile(
      id: user['id'] is int
          ? user['id'] as int
          : int.tryParse(user['id']?.toString() ?? ''),
      nome: withoutAt,
      username: '@$withoutAt',
      bio: user['email']?.toString().isNotEmpty == true
          ? user['email'].toString()
          : 'Perfil no Pace',
      avatar: user['foto_perfil']?.toString() ?? '',
    );
  }

  Future<List<_ExplorarProfile>> _loadSavedProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('usuarios');
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return [];

      return decoded.entries.map((entry) {
        final username = entry.key.toString().replaceFirst(RegExp(r'^@'), '');
        final data = entry.value is Map
            ? Map<String, dynamic>.from(entry.value as Map)
            : <String, dynamic>{};

        return _ExplorarProfile(
          nome: username,
          username: '@$username',
          bio: data['bio']?.toString().isNotEmpty == true
              ? data['bio'].toString()
              : data['email']?.toString().isNotEmpty == true
                  ? data['email'].toString()
                  : 'Perfil salvo localmente',
          avatar: data['foto']?.toString().isNotEmpty == true
              ? data['foto'].toString()
              : data['foto_perfil']?.toString() ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _fetchProfiles(String query) async {
    try {
      final token = await _getToken();
      final encodedQuery = Uri.encodeQueryComponent(query.trim());
      var path = '$apiUrl/profile/buscar_por_username/?skip=0&limit=100';

      if (query.trim().isNotEmpty) {
        path += '&username=$encodedQuery';
      }

      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(Uri.parse(path), headers: headers);
      final data = await _parseResponse(response, 'Falha ao buscar perfis.');

      if (data is List && data.isNotEmpty) {
        profilesData = data
            .whereType<Map>()
            .map((item) => _buildProfileFromAPI(Map<String, dynamic>.from(item)))
            .toList();
        return;
      }

      profilesData = await _loadSavedProfiles();
      if (profilesData.isEmpty) {
        profilesData = List<_ExplorarProfile>.from(_fallbackProfiles);
      }
    } catch (_) {
      profilesData = await _loadSavedProfiles();
      if (profilesData.isEmpty) {
        profilesData = List<_ExplorarProfile>.from(_fallbackProfiles);
      }
    }
  }

  String _normalizarTexto(String? value) {
  var text = (value ?? '').trim().toLowerCase();

  const mapa = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };

  mapa.forEach((accent, normal) {
    text = text.replaceAll(accent, normal);
  });

  return text;
}

  String _combinarBusca(List<String> campos) {
    return _normalizarTexto(campos.join(' '));
  }

  bool _profileMatch(_ExplorarProfile profile) {
    final base = _combinarBusca([
      profile.nome,
      profile.username,
      profile.bio,
      profile.tags.join(' '),
    ]);

    final termoOk =
        termoAtual.isEmpty || base.contains(_normalizarTexto(termoAtual));

    final filtroNormalizado = _normalizarTexto(filtroAtual);
    final filtroOk = filtroAtual == 'todos' ||
        profile.tags.any(
          (tag) => _normalizarTexto(tag).contains(filtroNormalizado),
        ) ||
        base.contains(filtroNormalizado);

    return termoOk && filtroOk;
  }

  Future<void> _renderProfiles() async {
    setState(() => isLoadingProfiles = true);

    await _fetchProfiles(termoAtual);

    if (!mounted) return;

    setState(() => isLoadingProfiles = false);
  }

    ImageProvider _avatarProvider(String? url) {
  if (url != null && url.trim().isNotEmpty) {
    return NetworkImage(url);
  }

  return const NetworkImage(
    'https://ui-avatars.com/api/?name=Pace',
  );
}

  String? _fotoUsuarioLogado() {
    final foto = usuarioLogado['foto_perfil'] ?? usuarioLogado['foto'];
    if (foto == null || foto.toString().trim().isEmpty) return null;
    return foto.toString();
  }

  String _formatarDataRelativa(dynamic dataISO) {
    if (dataISO == null) return '';

    final data = DateTime.tryParse(dataISO.toString());
    if (data == null) return '';

    final diferenca = DateTime.now().difference(data);
    final segundos = diferenca.inSeconds;
    final minutos = diferenca.inMinutes;
    final horas = diferenca.inHours;
    final dias = diferenca.inDays;
    final semanas = dias ~/ 7;
    final meses = dias ~/ 30;
    final anos = dias ~/ 365;

    if (segundos < 60) return 'hÃ¡ poucos segundos';
    if (minutos < 60) {
      return 'hÃ¡ $minutos minuto${minutos == 1 ? '' : 's'}';
    }
    if (horas < 24) return 'hÃ¡ $horas hora${horas == 1 ? '' : 's'}';
    if (dias < 7) return 'hÃ¡ $dias dia${dias == 1 ? '' : 's'}';
    if (semanas < 5) {
      return 'hÃ¡ $semanas semana${semanas == 1 ? '' : 's'}';
    }
    if (meses < 12) return 'hÃ¡ $meses mÃªs${meses == 1 ? '' : 'es'}';
    return 'hÃ¡ $anos ano${anos == 1 ? '' : 's'}';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<List<Map<String, dynamic>>?> _fetchUserPosts(_ExplorarProfile profile) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$apiUrl/post/feed'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = await _parseResponse(response, 'Falha ao carregar posts.');
      if (data is! List) return [];

      final requestedUsername =
          profile.username.replaceFirst(RegExp(r'^@'), '').toLowerCase();

      return data.whereType<Map>().map((item) {
        final post = Map<String, dynamic>.from(item);
        final usuario = post['usuario'];

        final postUserId = usuario is Map
            ? usuario['id']?.toString() ?? ''
            : post['usuario_id']?.toString() ?? '';

        final postUsername = usuario is Map
            ? usuario['username']?.toString().toLowerCase() ?? ''
            : '';

        final matches = postUserId == profile.id?.toString() ||
            postUsername == requestedUsername;

        return matches ? post : null;
      }).whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _curtirPostModal(
    int postId,
    List<Map<String, dynamic>> posts,
    void Function(VoidCallback fn) modalSetState,
  ) async {
    final token = await _getToken();

    if (token == null) {
      _showToast('FaÃ§a login para curtir posts.', Colors.orange);
      return;
    }

    final index = posts.indexWhere((item) => _toInt(item['id']) == postId);
    if (index == -1) return;

    final post = posts[index];
    final likedAntes = post['liked'] == true;
    final likesAntes = _toInt(post['likes']);

    modalSetState(() {
      post['liked'] = !likedAntes;
      post['likes'] = likedAntes ? (likesAntes > 0 ? likesAntes - 1 : 0) : likesAntes + 1;
    });

    try {
      final response = likedAntes
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
      modalSetState(() {
        post['liked'] = likedAntes;
        post['likes'] = likesAntes;
      });

      _showToast('Erro ao curtir post.', Colors.red);
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

  Future<void> _openProfileModal(_ExplorarProfile profile) async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x94080E1C),
      builder: (dialogContext) {
        return _ProfileModal(
          profile: profile,
          darkMode: darkMode,
          textColor: textColor,
          mutedColor: mutedColor,
          avatarProvider: _avatarProvider,
          formatarDataRelativa: _formatarDataRelativa,
          fetchUserPosts: _fetchUserPosts,
          onLike: _curtirPostModal,
          showToast: _showToast,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentLeftPadding = screenWidth < 1000 ? 24.0 : 360.0;
    final filtrados = profilesData.where(_profileMatch).toList();

    return Scaffold(
      backgroundColor:
          darkMode ? const Color(0xFF05070C) : const Color(0xFFF4F7FB),
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
                    42,
                    42,
                    70,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHero(),
                          const SizedBox(height: 28),
                          _buildSearchShell(),
                          const SizedBox(height: 26),
                          _buildHighlightGrid(),
                          const SizedBox(height: 30),
                          _buildProfilesSection(filtrados),
                        ],
                      ),
                    ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 900;

        if (isSmall) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Badge(text: 'Descubra novas conexões'),
              const SizedBox(height: 14),
              Text(
                'Explore pessoas, ideias e energia',
                style: TextStyle(
                  fontSize: 36,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Encontre perfis inspiradores, tópicos em alta e conteúdos que podem te ajudar a construir uma rotina mais forte dentro do Pace.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.75,
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 18),
              _HeroCta(
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
                  const _Badge(text: 'Descubra novas conexões'),
                  const SizedBox(height: 14),
                  Text(
                    'Explore pessoas, ideias e energia',
                    style: TextStyle(
                      fontSize: 42,
                      height: 1.02,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Encontre perfis inspiradores, tópicos em alta e conteúdos que podem te ajudar a construir uma rotina mais forte dentro do Pace.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.75,
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            _HeroCta(
              onTap: () => Navigator.of(context).pushNamed('/postar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchShell() {
    return _GlassCard(
      darkMode: darkMode,
      padding: const EdgeInsets.all(22),
      radius: 28,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 60,
        decoration: BoxDecoration(
          color: darkMode
              ? Colors.white.withOpacity(0.03)
              : Colors.white.withOpacity(0.86),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: darkMode
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFF3059AA).withOpacity(0.10),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: mutedColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                style: TextStyle(color: textColor, fontSize: 15),
                cursorColor: const Color(0xFF3059AA),
                decoration: InputDecoration(
                  hintText:
                      'Pesquisar pessoas, hábitos, ideias ou palavras-chave',
                  hintStyle: TextStyle(color: mutedColor, fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) async {
                  termoAtual = value.trim();
                  await _renderProfiles();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isSingle = width < 760;
        final isDouble = width >= 760 && width < 980;

        if (isSingle) {
          return Column(
            children: [
              _buildMainHighlight(),
              const SizedBox(height: 18),
              _buildSecondaryHighlight(
                kicker: 'Sugestão do dia',
                title: 'Encontre parceiros de evolução',
                description:
                    'Perfis com hábitos parecidos com os seus podem acelerar sua constância.',
              ),
              const SizedBox(height: 18),
              _buildSecondaryHighlight(
                kicker: 'Nova energia',
                title: 'Conteúdos para sair da inércia',
                description:
                    'Veja posts curtos e diretos para te colocar em movimento hoje.',
              ),
            ],
          );
        }

        if (isDouble) {
          return Column(
            children: [
              _buildMainHighlight(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildSecondaryHighlight(
                      kicker: 'Sugestão do dia',
                      title: 'Encontre parceiros de evolução',
                      description:
                          'Perfis com hábitos parecidos com os seus podem acelerar sua constância.',
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _buildSecondaryHighlight(
                      kicker: 'Nova energia',
                      title: 'Conteúdos para sair da inércia',
                      description:
                          'Veja posts curtos e diretos para te colocar em movimento hoje.',
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return SizedBox(
          height: 340,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 14,
                child: _buildMainHighlight(),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 10,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildSecondaryHighlight(
                        kicker: 'Sugestão do dia',
                        title: 'Encontre parceiros de evolução',
                        description:
                            'Perfis com hábitos parecidos com os seus podem acelerar sua constância.',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: _buildSecondaryHighlight(
                        kicker: 'Nova energia',
                        title: 'Conteúdos para sair da inércia',
                        description:
                            'Veja posts curtos e diretos para te colocar em movimento hoje.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainHighlight() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xF53059AA),
            Color(0xEB4071CD),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14274D).withOpacity(darkMode ? 0.30 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EM ALTA AGORA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pequenas rotinas, grandes viradas',
            style: TextStyle(
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Descubra pessoas que estão mostrando consistência real e compartilhe sua própria evolução com a comunidade.',
            style: TextStyle(
              height: 1.7,
              color: Colors.white.withOpacity(0.88),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _HighlightMeta(icon: Icons.local_fire_department, text: 'Tendências quentes'),
              _HighlightMeta(icon: Icons.groups_outlined, text: 'Comunidade ativa'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryHighlight({
    required String kicker,
    required String title,
    required String description,
  }) {
    return _GlassCard(
      darkMode: darkMode,
      padding: const EdgeInsets.all(24),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF5EB1BF),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              height: 1.7,
              color: mutedColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilesSection(List<_ExplorarProfile> filtrados) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERFIS',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Color(0xFF5EB1BF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pessoas para acompanhar',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        if (isLoadingProfiles)
          _buildEmptyState(
            icon: Icons.refresh,
            spinning: true,
            title: 'Buscando perfis',
            description: 'Aguarde um momento...',
          )
        else if (filtrados.isEmpty)
          _buildEmptyState(
            icon: Icons.search_off,
            title: 'Nenhum perfil encontrado',
            description: 'Tente outro termo ou filtro.',
          )
        else
          _buildProfilesGrid(filtrados),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
    bool spinning = false,
  }) {
    return _GlassCard(
      darkMode: darkMode,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 42),
      radius: 28,
      child: Center(
        child: Column(
          children: [
            spinning
                ? _SpinningIcon(icon: icon)
                : Icon(icon, size: 34, color: const Color(0xFF3059AA)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedColor,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilesGrid(List<_ExplorarProfile> filtrados) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 3
            : constraints.maxWidth >= 760
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtrados.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: columns == 1 ? 1.9 : 1.45,
          ),
          itemBuilder: (context, index) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 550 + index * 40),
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
              child: _buildProfileCard(filtrados[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileCard(_ExplorarProfile profile) {
    return _GlassCard(
      darkMode: darkMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
  children: [
    CircleAvatar(
      radius: 29,
      backgroundImage: _avatarProvider(profile.avatar),
    ),
    const SizedBox(width: 14),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: mutedColor,
            ),
          ),
        ],
      ),
    ),
  ],
),
          const SizedBox(height: 16),
          Text(
            profile.bio,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedColor,
              height: 1.7,
              fontSize: 14,
            ),
          ),
          if (profile.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: profile.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: darkMode
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFF3059AA).withOpacity(0.07),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: darkMode
                              ? const Color(0xFFDBE5F8)
                              : const Color(0xFF4C5972),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const Spacer(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3059AA), Color(0xFF4C71C7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ElevatedButton(
                onPressed: () => _openProfileModal(profile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Ver perfil',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
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
                         'assets/images/Ícone_pace.png',
                           width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.bolt,
                                size: 32,
                                color: Color(0xFF3059AA),
                              );
                            },
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
                      _sidebarItem(Icons.explore_outlined, 'Explorar', '/explorar', true),
                      _sidebarItem(Icons.add_box_outlined, 'Postar', '/postar', false),
                      _sidebarItem(Icons.notifications_none, 'NotificaÃ§Ãµes', '/notificacoes', false),
                      const SizedBox(height: 18),
                      Divider(color: const Color(0xFF3059AA).withOpacity(0.10)),
                      const SizedBox(height: 18),
                      _sidebarItem(Icons.settings_outlined, 'ConfiguraÃ§Ãµes', '/config', false),
                      _sidebarProfileItem(),
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

class _ProfileModal extends StatefulWidget {
  final _ExplorarProfile profile;
  final bool darkMode;
  final Color textColor;
  final Color mutedColor;
  final ImageProvider Function(String?) avatarProvider;
  final String Function(dynamic) formatarDataRelativa;
  final Future<List<Map<String, dynamic>>?> Function(_ExplorarProfile)
      fetchUserPosts;
  final Future<void> Function(
    int postId,
    List<Map<String, dynamic>> posts,
    void Function(VoidCallback fn) modalSetState,
  ) onLike;
  final void Function(String message, Color color) showToast;

  const _ProfileModal({
    required this.profile,
    required this.darkMode,
    required this.textColor,
    required this.mutedColor,
    required this.avatarProvider,
    required this.formatarDataRelativa,
    required this.fetchUserPosts,
    required this.onLike,
    required this.showToast,
  });

  @override
  State<_ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<_ProfileModal> {
  bool postsLoading = true;
  List<Map<String, dynamic>>? posts;
  List<Map<String, dynamic>> modalPostsCache = [];

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _normalizarPostModal(Map<String, dynamic> post) {
    return {
      ...post,
      'id': _toInt(post['id']),
      'likes': _toInt(post['likes']),
      'liked': post['liked'] == true,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final result = await widget.fetchUserPosts(widget.profile);

    if (!mounted) return;

    setState(() {
      posts = result;
      postsLoading = false;
      modalPostsCache =
          result != null ? result.map(_normalizarPostModal).toList() : [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 880),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.darkMode
                        ? const Color(0xF20A0C12)
                        : Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: widget.darkMode
                          ? Colors.white.withOpacity(0.08)
                          : Colors.white.withOpacity(0.72),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.24),
                        blurRadius: 80,
                        offset: const Offset(0, 28),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image(
                                image: widget.avatarProvider(widget.profile.avatar),
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: 90,
                                    height: 90,
                                    color: const Color(0xFF3059AA).withOpacity(0.12),
                                    child: Icon(
                                      Icons.person,
                                      color: widget.mutedColor,
                                      size: 36,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.profile.nome,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: widget.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.profile.username,
                                    style: TextStyle(
                                      color: widget.mutedColor,
                                      height: 1.7,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    widget.profile.bio,
                                    style: TextStyle(
                                      color: widget.mutedColor,
                                      height: 1.7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'Postagens',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (postsLoading)
                          _ModalMessageBox(
                            darkMode: widget.darkMode,
                            text: 'Carregando...',
                          )
                        else if (posts == null)
                          _ModalMessageBox(
                            darkMode: widget.darkMode,
                            text: 'FaÃ§a login para ver as postagens.',
                          )
                        else if (posts!.isEmpty)
                          _ModalMessageBox(
                            darkMode: widget.darkMode,
                            text: 'Nenhuma postagem encontrada.',
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns =
                                  constraints.maxWidth >= 720 ? 2 : 1;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: modalPostsCache.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 18,
                                  mainAxisSpacing: 18,
                                  childAspectRatio: columns == 2 ? 0.92 : 1.05,
                                ),
                                itemBuilder: (context, index) {
                                  final post = modalPostsCache[index];
                                  final conteudo = post['conteudo']?.toString() ??
                                      'Sem descriÃ§Ã£o';
                                  final resumo = conteudo.length > 120
                                      ? '${conteudo.substring(0, 120)}...'
                                      : conteudo;
                                  final dataFmt = widget.formatarDataRelativa(
                                    post['data_postagem'] ?? post['data'],
                                  );
                                  final liked = post['liked'] == true;
                                  final postId = _toInt(post['id']);

                                  return Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: widget.darkMode
                                          ? const Color(0xEB080A0E)
                                          : Colors.white.withOpacity(0.94),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: widget.darkMode
                                            ? Colors.white.withOpacity(0.06)
                                            : const Color(0xFF3059AA)
                                                .withOpacity(0.12),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF14274D)
                                              .withOpacity(
                                            widget.darkMode ? 0.30 : 0.10,
                                          ),
                                          blurRadius: 40,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          resumo,
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: widget.textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Expanded(
                                          child: Text(
                                            conteudo,
                                            style: TextStyle(
                                              color: widget.mutedColor,
                                              height: 1.7,
                                            ),
                                          ),
                                        ),
                                        if ((post['imagem'] ?? '')
                                            .toString()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            child: Image.network(
                                              post['imagem'].toString(),
                                              width: double.infinity,
                                              height: 120,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) {
                                                return Container(
                                                  height: 120,
                                                  color: widget.darkMode
                                                      ? Colors.white
                                                          .withOpacity(0.06)
                                                      : Colors.grey.shade200,
                                                  child: Icon(
                                                    Icons
                                                        .image_not_supported_outlined,
                                                    color: widget.mutedColor,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                dataFmt,
                                                style: TextStyle(
                                                  color: widget.darkMode
                                                      ? const Color(0xFFA9B4CB)
                                                      : const Color(0xFF516386),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () => widget.onLike(
                                                postId,
                                                modalPostsCache,
                                                setState,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 180),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: liked
                                                      ? const Color(0xFFE64862)
                                                          .withOpacity(0.12)
                                                      : widget.darkMode
                                                          ? Colors.white
                                                              .withOpacity(0.06)
                                                          : const Color(
                                                                  0xFF3059AA)
                                                              .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      liked
                                                          ? Icons.favorite
                                                          : Icons.favorite_border,
                                                      size: 17,
                                                      color: liked
                                                          ? const Color(
                                                              0xFFD8425C)
                                                          : widget.darkMode
                                                              ? const Color(
                                                                  0xFFA9B4CB)
                                                              : const Color(
                                                                  0xFF516386),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '${_toInt(post['likes'])}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: liked
                                                            ? const Color(
                                                                0xFFD8425C)
                                                            : widget.darkMode
                                                                ? const Color(
                                                                    0xFFA9B4CB)
                                                                : const Color(
                                                                    0xFF516386),
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
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: widget.darkMode
                    ? const Color(0xE6141A2C)
                    : Colors.white,
                shape: const CircleBorder(),
                elevation: 8,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.close, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModalMessageBox extends StatelessWidget {
  final bool darkMode;
  final String text;

  const _ModalMessageBox({
    required this.darkMode,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xEB0A0C12)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF3059AA).withOpacity(0.12),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: darkMode ? const Color(0xFF9CA7BE) : const Color(0xFF6F7B91),
        ),
      ),
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  final IconData icon;

  const _SpinningIcon({required this.icon});

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: controller,
      child: Icon(widget.icon, size: 34, color: const Color(0xFF3059AA)),
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
        Icon(icon, size: 18, color: Colors.white.withOpacity(0.88)),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.88),
          ),
        ),
      ],
    );
  }
}

class _HeroCta extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3059AA), Color(0xFF4C71C7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3059AA).withOpacity(0.22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.edit_square, size: 21),
        label: const Text(
          'Compartilhar algo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
            size: 300,
            color: darkMode ? const Color(0x293059AA) : const Color(0x293059AA),
            blur: 80,
          ),
        ),
        Positioned(
          bottom: 40,
          left: -80,
          child: _SoftOrb(
            size: 280,
            color: darkMode ? const Color(0x2E5EB1BF) : const Color(0x2E5EB1BF),
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
            color: const Color(0xFF14274D).withOpacity(darkMode ? 0.30 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                    : Colors.white.withOpacity(0.62),
              ),
            ),
            child: child,
          ),
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
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

