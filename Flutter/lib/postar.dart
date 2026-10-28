import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

const Color _primary = Color(0xFF1769E8);
const Color _primary2 = Color(0xFF0B3D91);
const Color _accent = Color(0xFFFFC928);

class PostarPage extends StatefulWidget {
  const PostarPage({super.key});

  @override
  State<PostarPage> createState() => _PostarPageState();
}

class _PostarPageState extends State<PostarPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController textoController = TextEditingController();
  final ImagePicker picker = ImagePicker();

  bool sidebarHovered = false;
  String? sidebarItemHovered;
  bool isLoadingUser = true;
  bool isPublishing = false;

  Map<String, dynamic> usuarioLogado = {};
  List<Map<String, dynamic>> comunidades = [];
  int? comunidadeSelecionadaId;
  bool isLoadingCommunities = true;

  Uint8List? imagemBytes;
  String? imagemNome;
  String? imagemBase64;

  String get apiUrl => ApiConfig.baseUrl;

  bool get darkMode => Theme.of(context).brightness == Brightness.dark;

  Color get bgColor =>
      darkMode ? const Color(0xFF06101F) : const Color(0xFFEAF3FB);

  Color get textColor =>
      darkMode ? const Color(0xFFF2F6FF) : const Color(0xFF06152D);

  Color get textSoftColor =>
      darkMode ? const Color(0xFFDCE5F4) : const Color(0xFF203B61);

  Color get mutedColor =>
      darkMode ? const Color(0xFF98A8BF) : const Color(0xFF61758F);

  Color get labelColor =>
      darkMode ? const Color(0xFFD7E1F1) : const Color(0xFF203B61);

  Color get sidebarTextColor =>
      darkMode ? const Color(0xFFF1F5FF) : const Color(0xFF33415B);

  Color get inputFillColor =>
      darkMode ? const Color(0xFF0B1729) : Colors.white.withOpacity(0.82);

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
    textoController.addListener(_onTextChanged);
    _initUser();
  }

  @override
  void dispose() {
    textoController.removeListener(_onTextChanged);
    textoController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access_token');
  }

  Future<void> _initUser() async {
    final token = await _getToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.of(context).pushReplacementNamed('/entrar');
      return;
    }

    try {
      final responses = await Future.wait<http.Response>([
        http
            .get(
              ApiConfig.uri('/profile/me'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 12)),
        http
            .get(
              ApiConfig.uri('/comunidades/minhas'),
              headers: {'Authorization': 'Bearer $token'},
            )
            .timeout(const Duration(seconds: 12)),
      ]);

      final profileResponse = responses[0];
      final communitiesResponse = responses[1];

      if (profileResponse.statusCode == 401 ||
          communitiesResponse.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/entrar');
        }
        return;
      }

      if (profileResponse.statusCode < 200 ||
          profileResponse.statusCode >= 300) {
        throw Exception('Não foi possível carregar seu perfil.');
      }

      final profileData = jsonDecode(profileResponse.body);

      List<Map<String, dynamic>> communitiesData = [];

      if (communitiesResponse.statusCode >= 200 &&
          communitiesResponse.statusCode < 300) {
        final decoded = communitiesResponse.body.isNotEmpty
            ? jsonDecode(communitiesResponse.body)
            : null;

        if (decoded is List) {
          communitiesData = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      if (!mounted) return;

      setState(() {
        usuarioLogado = Map<String, dynamic>.from(profileData as Map);
        comunidades = communitiesData;
        comunidadeSelecionadaId = null;
        isLoadingUser = false;
        isLoadingCommunities = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingUser = false;
        isLoadingCommunities = false;
      });

      _showToast(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    }
  }

  ImageProvider _avatarProvider(String? value) {
    return ApiConfig.imageProvider(value);
  }

  String? _fotoUsuarioLogado() {
    final foto =
        usuarioLogado['foto_perfil'] ??
        usuarioLogado['foto'] ??
        usuarioLogado['avatar'];

    if (foto == null || foto.toString().trim().isEmpty) {
      return null;
    }

    return foto.toString();
  }

  String _username() {
    final value = usuarioLogado['username']?.toString().trim();

    if (value == null || value.isEmpty) {
      return 'Usuário';
    }

    return value;
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

        if (!mounted) return;

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
        _showToast(
          'Não foi possível carregar a imagem.',
          Colors.red,
        );
        return;
      }

      final name = file.name;
      final ext = _extensaoImagem(name);

      if (!mounted) return;

      setState(() {
        imagemBytes = bytes;
        imagemNome = name;
        imagemBase64 = 'data:image/$ext;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      _showToast(
        'Erro ao selecionar imagem: $e',
        Colors.red,
      );
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
    if (token == null || token.isEmpty) return;

    final texto = textoController.text.trim();

    if (texto.isEmpty && imagemBase64 == null) {
      _showToast(
        'Escreva algo ou selecione uma imagem.',
        Colors.orange,
      );
      return;
    }

    setState(() {
      isPublishing = true;
    });

    try {
      final response = await http
          .post(
            ApiConfig.uri('/post/criar_post'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'conteudo': texto,
              'imagem': imagemBase64 ?? '',
              'comunidade_id': comunidadeSelecionadaId,
              'tipo': 'geral',
              'meta_id': null,
              'sessao_id': null,
            }),
          )
          .timeout(const Duration(seconds: 35));

      dynamic data;

      try {
        data = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 401) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/entrar');
        }
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = data is Map && data['detail'] != null
            ? data['detail'].toString()
            : 'Erro ao publicar.';

        throw Exception(message);
      }

      if (!mounted) return;

      _showToast(
        'Post publicado com sucesso!',
        Colors.green,
      );

      Navigator.of(context).pushReplacementNamed('/feed');
    } catch (e) {
      _showToast(
        e.toString().replaceFirst('Exception: ', ''),
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          isPublishing = false;
        });
      }
    }
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 760;
    final tablet = width >= 760 && width < 1080;

    if (isLoadingUser) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    final page = Stack(
      children: [
        _BackgroundDecor(darkMode: darkMode),
        _buildScrollableContent(
          horizontalPadding: mobile
              ? (width <= 430 ? 16 : 20)
              : (tablet ? 28 : 38),
          topPadding: mobile ? 22 : (tablet ? 28 : 30),
          bottomPadding: mobile ? 72 : 88,
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

  Widget _buildScrollableContent({
    required double horizontalPadding,
    required double topPadding,
    required double bottomPadding,
    required bool mobile,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(mobile),
              SizedBox(height: mobile ? 22 : 22),
              _buildComposerCard(mobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool mobile) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              child: Divider(
                color: _accent,
                thickness: 3,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'COMUNIDADE',
              style: TextStyle(
                color: _primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.25,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Postar',
          style: TextStyle(
            color: textColor,
            fontSize: mobile ? 34 : 42,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 7),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 670),
          child: Text(
            'Compartilhe progresso, aprendizados e momentos da sua jornada '
            'com outras pessoas no Pace.',
            style: TextStyle(
              color: mutedColor,
              fontSize: mobile ? 13.5 : 14.5,
              height: 1.55,
            ),
          ),
        ),
      ],
    );

    if (mobile) {
      return copy;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: copy),
        const SizedBox(width: 28),
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: darkMode
                ? const Color(0xFF0F1B2F).withOpacity(0.82)
                : Colors.white.withOpacity(0.66),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: darkMode
                  ? Colors.white.withOpacity(0.06)
                  : const Color(0xFF06152D).withOpacity(0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: darkMode
                      ? const Color(0xFF071A36)
                      : const Color(0xFF06152D),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: _accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 11),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compartilhe algo real',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'O que você vive hoje já pode inspirar alguém.',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildComposerCard(bool mobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: _SurfaceCard(
          darkMode: darkMode,
          radius: mobile ? 18 : 22,
          padding: EdgeInsets.all(mobile ? 18 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardTop(mobile),

              const SizedBox(height: 16),

              _buildCommunitySelector(mobile),

              const SizedBox(height: 14),

              Text(
                'Precisa de uma ideia?',
                style: TextStyle(
                  color: mutedColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 9),

              _buildChips(),

              const SizedBox(height: 14),

              Text(
                'Conte para a comunidade o que está acontecendo',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: labelColor,
                ),
              ),

              const SizedBox(height: 9),

              _buildTextArea(mobile),

              const SizedBox(height: 7),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${textoController.text.length}/2000',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              _buildActions(mobile),

              if (imagemBytes != null) ...[
                const SizedBox(height: 16),
                _buildPreview(mobile),
              ],

              const SizedBox(height: 16),

              _PublishButton(
                loading: isPublishing,
                onTap: isPublishing ? null : _publicarPost,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunitySelector(bool mobile) {
    final chipWidgets = <Widget>[
      _DestinationChip(
        label: 'Feed geral',
        selected: comunidadeSelecionadaId == null,
        darkMode: darkMode,
        onTap: () {
          setState(() {
            comunidadeSelecionadaId = null;
          });
        },
      ),
      ...comunidades.map((community) {
        final id = int.tryParse('${community['id']}');
        final name = (community['nome'] ?? 'Comunidade').toString();

        return _DestinationChip(
          label: name,
          selected: id != null && comunidadeSelecionadaId == id,
          darkMode: darkMode,
          onTap: id == null
              ? null
              : () {
                  setState(() {
                    comunidadeSelecionadaId = id;
                  });
                },
        );
      }),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0B1729)
            : const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFF06152D).withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: darkMode
                      ? const Color(0xFF071A36)
                      : const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.groups_2_outlined,
                  size: 18,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onde você quer publicar?',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Escolha o feed geral ou uma comunidade.',
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoadingCommunities)
            const SizedBox(
              height: 34,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primary,
                  ),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (int index = 0; index < chipWidgets.length; index++) ...[
                    chipWidgets[index],
                    if (index < chipWidgets.length - 1)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          if (!isLoadingCommunities && comunidades.isEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => Navigator.of(context).pushNamed('/explorar'),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: mutedColor,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Você ainda não participa de nenhuma comunidade. '
                        'Explore comunidades para encontrar uma.',
                        style: TextStyle(
                          color: mutedColor,
                          fontSize: 10.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildCardTop(bool mobile) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NOVO POST',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.35,
            color: _accent,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Criar publicação',
          style: TextStyle(
            color: textColor,
            fontSize: mobile ? 22 : 23.5,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
      ],
    );

    final profile = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: darkMode
            ? Colors.white.withOpacity(0.05)
            : _primary.withOpacity(0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primary.withOpacity(0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: mobile ? 19 : 21,
            backgroundImage: _avatarProvider(
              _fotoUsuarioLogado(),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: mobile ? 13.5 : 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Compartilhando agora',
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (mobile) {
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
        Expanded(child: title),
        const SizedBox(width: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 290),
          child: profile,
        ),
      ],
    );
  }

  Widget _buildChips() {
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: chips.map((chip) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () => _usarChip(chip['text']!),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _primary.withOpacity(darkMode ? 0.13 : 0.07),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _primary.withOpacity(0.07),
                ),
              ),
              child: Text(
                chip['label']!,
                style: TextStyle(
                  color: darkMode
                      ? const Color(0xFFDCE5F4)
                      : const Color(0xFF4D5A73),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextArea(bool mobile) {
    return TextField(
      controller: textoController,
      maxLength: 2000,
      minLines: mobile ? 5 : 5,
      maxLines: mobile ? 7 : 6,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      style: TextStyle(
        color: textColor,
        fontSize: mobile ? 15 : 15.5,
        height: 1.6,
      ),
      cursorColor: _primary,
      decoration: InputDecoration(
        hintText: 'O que você está pensando?',
        hintStyle: TextStyle(
          color: mutedColor,
          fontWeight: FontWeight.w400,
        ),
        counterText: '',
        filled: true,
        fillColor: inputFillColor,
        contentPadding: EdgeInsets.all(mobile ? 16 : 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: darkMode
                ? Colors.white.withOpacity(0.07)
                : _primary.withOpacity(0.11),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: _primary.withOpacity(0.34),
            width: 1.4,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildActions(bool mobile) {
    final imageButton = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: _selecionarImagem,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _primary.withOpacity(darkMode ? 0.13 : 0.075),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _primary.withOpacity(0.08),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: _primary,
                size: 20,
              ),
              SizedBox(width: 9),
              Text(
                'Adicionar imagem',
                style: TextStyle(
                  color: _primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final support = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.info_outline_rounded,
          color: mutedColor,
          size: 17,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Você pode postar só texto ou texto com imagem.',
            style: TextStyle(
              color: mutedColor,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );

    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imageButton,
          const SizedBox(height: 12),
          support,
        ],
      );
    }

    return Row(
      children: [
        imageButton,
        const SizedBox(width: 18),
        Expanded(child: support),
      ],
    );
  }

  Widget _buildPreview(bool mobile) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _primary.withOpacity(darkMode ? 0.09 : 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.065)
              : _primary.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.memory(
              imagemBytes!,
              width: mobile ? 58 : 66,
              height: mobile ? 58 : 66,
              fit: BoxFit.cover,
              cacheWidth: 220,
              cacheHeight: 220,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Imagem pronta',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  imagemNome ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remover imagem',
            onPressed: _removerImagem,
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFFE55353),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE
  // ---------------------------------------------------------------------------

  Widget _buildMobileTopBar() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: darkMode
              ? const Color(0xF2080A0E)
              : Colors.white.withOpacity(0.92),
          border: Border(
            bottom: BorderSide(
              color: _primary.withOpacity(0.08),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF15284D).withOpacity(0.055),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            InkWell(
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pace',
                    style: TextStyle(
                      color: darkMode ? Colors.white : _primary,
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
                ? const Color(0xFF0B0D12).withOpacity(0.99)
                : const Color(0xFFF8FBFF).withOpacity(0.99),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(28),
            ),
            border: Border.all(
              color: darkMode
                  ? Colors.white.withOpacity(0.06)
                  : _primary.withOpacity(0.09),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  darkMode ? 0.32 : 0.13,
                ),
                blurRadius: 38,
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
                color: _primary.withOpacity(0.10),
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
                    ),
                    _mobileDrawerItem(
                      Icons.edit_square,
                      'Postar',
                      '/postar',
                      active: true,
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
                color: _primary.withOpacity(0.10),
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
                const Duration(milliseconds: 100),
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
                        _primary.withOpacity(0.14),
                        _accent.withOpacity(0.09),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(15),
              border: active
                  ? Border.all(
                      color: _primary.withOpacity(0.10),
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
                        ? _primary.withOpacity(0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: active ? _primary : sidebarTextColor,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? _primary : sidebarTextColor,
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

          Future.delayed(
            const Duration(milliseconds: 100),
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
            color: _primary.withOpacity(
              darkMode ? 0.10 : 0.055,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: _avatarProvider(
                  _fotoUsuarioLogado(),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username(),
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

  // ---------------------------------------------------------------------------
  // DESKTOP SIDEBAR
  // ---------------------------------------------------------------------------

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
            right: BorderSide(
              color: const Color(0xFF1769E8).withOpacity(0.09),
            ),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 70,
              child: LayoutBuilder(
                builder: (context, constraints) {
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
                    true,
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
      onExit: (_) {
        if (sidebarItemHovered == route) {
          setState(() => sidebarItemHovered = null);
        }
      },
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
    final isHovered = sidebarItemHovered == route;

    return MouseRegion(
      onEnter: (_) => setState(() => sidebarItemHovered = route),
      onExit: (_) {
        if (sidebarItemHovered == route) {
          setState(() => sidebarItemHovered = null);
        }
      },
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
                    backgroundImage: _avatarProvider(
                      _fotoUsuarioLogado(),
                    ),
                  ),
                  if (showText) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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

}

// =============================================================================
// VISUAL HELPERS
// =============================================================================

class _BackgroundDecor extends StatelessWidget {
  final bool darkMode;

  const _BackgroundDecor({
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: darkMode
                  ? const [
                      Color(0xFF081426),
                      Color(0xFF06101F),
                      Color(0xFF040B15),
                    ]
                  : const [
                      Color(0xFFF4F8FD),
                      Color(0xFFEAF1F9),
                      Color(0xFFE4EDF8),
                    ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoftGradientOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftGradientOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.46),
            color.withOpacity(0.14),
            Colors.transparent,
          ],
          stops: const [0.0, 0.30, 0.60, 1.0],
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final bool darkMode;
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _SurfaceCard({
    required this.darkMode,
    required this.child,
    required this.padding,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: darkMode
              ? [
                  const Color(0xFF0F1B2F),
                  const Color(0xFF0F1B2F),
                ]
              : [
                  Colors.white.withOpacity(0.97),
                  const Color(0xFFF8FBFF).withOpacity(0.94),
                ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: darkMode
              ? Colors.white.withOpacity(0.055)
              : _primary.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: darkMode
                ? Colors.black.withOpacity(0.20)
                : const Color(0xFF15284D).withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge({
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
        color: _primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _primary.withOpacity(0.07),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.16),
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
              color: _primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTip extends StatelessWidget {
  final bool darkMode;
  final Color textColor;

  const _HeroTip({
    required this.darkMode,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF0C1627).withOpacity(0.92)
            : Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _primary.withOpacity(0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15284D).withOpacity(
              darkMode ? 0.16 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: _primary,
            size: 19,
          ),
          const SizedBox(width: 9),
          Text(
            'Postagens autênticas geram mais conexão.',
            style: TextStyle(
              color: textColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool darkMode;
  final VoidCallback? onTap;

  const _DestinationChip({
    required this.label,
    required this.selected,
    required this.darkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? (darkMode
                    ? const Color(0xFF071A36)
                    : const Color(0xFFE9F2FF))
                : (darkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? _primary.withOpacity(darkMode ? 0.45 : 0.28)
                  : (darkMode
                      ? Colors.white.withOpacity(0.07)
                      : const Color(0xFF06152D).withOpacity(0.07)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? (darkMode ? Colors.white : const Color(0xFF0B3D91))
                  : (darkMode
                      ? const Color(0xFFD7E1F1)
                      : const Color(0xFF203B61)),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}


class _PublishButton extends StatefulWidget {
  final bool loading;
  final VoidCallback? onTap;

  const _PublishButton({
    required this.loading,
    required this.onTap,
  });

  @override
  State<_PublishButton> createState() => _PublishButtonState();
}

class _PublishButtonState extends State<_PublishButton> {
  bool hover = false;
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return MouseRegion(
      cursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (enabled) setState(() => hover = true);
      },
      onExit: (_) {
        if (mounted) setState(() => hover = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: enabled
            ? (_) => setState(() => pressed = true)
            : null,
        onTapUp: enabled
            ? (_) => setState(() => pressed = false)
            : null,
        onTapCancel: enabled
            ? () => setState(() => pressed = false)
            : null,
        child: AnimatedScale(
          scale: pressed
              ? 0.992
              : hover
                  ? 1.006
                  : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled
                    ? const [
                        _primary,
                        _primary2,
                      ]
                    : [
                        _primary.withOpacity(0.55),
                        _primary2.withOpacity(0.55),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: _primary.withOpacity(
                          hover ? 0.27 : 0.20,
                        ),
                        blurRadius: hover ? 28 : 22,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: widget.loading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Publicando...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Publicar agora',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: darkMode
              ? Colors.white.withOpacity(0.055)
              : _primary.withOpacity(0.065),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: _primary,
          size: 21,
        ),
      ),
    );
  }
}