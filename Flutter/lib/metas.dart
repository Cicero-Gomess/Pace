import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

const Color _primary = Color(0xFF1769E8);
const Color _primaryDark = Color(0xFF0B3D91);
const Color _accent = Color(0xFFFFC928);
const Color _success = Color(0xFF2AA879);
const Color _danger = Color(0xFFD8425C);

class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _metas = [];
  Map<String, dynamic> _user = {};

  String _filter = 'todas';
  bool _loading = true;
  bool _sidebarHovered = false;
  String? _sidebarItemHovered;

  bool get dark => Theme.of(context).brightness == Brightness.dark;

  Color get bg =>
      dark ? const Color(0xFF06101F) : const Color(0xFFEAF3FB);

  Color get text =>
      dark ? const Color(0xFFF2F6FF) : const Color(0xFF06152D);

  Color get soft =>
      dark ? const Color(0xFFDCE5F4) : const Color(0xFF203B61);

  Color get muted =>
      dark ? const Color(0xFF98A8BF) : const Color(0xFF61758F);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('access_token');
  }

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<dynamic> _parse(http.Response response) async {
    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode == 401) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/entrar');
      }
      throw Exception('Sua sessão expirou.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map
          ? (data['detail'] ?? data['message'])
          : null;

      throw Exception(
        detail?.toString() ?? 'Não foi possível concluir a operação.',
      );
    }

    return data;
  }

  Map<String, dynamic> _normalizeMeta(dynamic value) {
    final raw = value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};

    final status = (raw['status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return {
      'id': int.tryParse('${raw['id']}') ?? 0,
      'titulo': (raw['titulo'] ?? '').toString(),
      'descricao': (raw['descricao'] ?? '').toString(),
      'categoria': (raw['categoria'] ?? 'Outro').toString(),
      'prazo': raw['prazo']?.toString().split('T').first ?? '',
      'status': status == 'concluida' ? 'concluida' : 'em andamento',
    };
  }

  Future<void> _load() async {
    final token = await _token();

    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/entrar');
      }
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final responses = await Future.wait([
        http.get(
          ApiConfig.uri('/metas/listar_metas'),
          headers: _headers(token),
        ),
        http.get(
          ApiConfig.uri('/profile/me'),
          headers: _headers(token),
        ),
      ]);

      final metasData = await _parse(responses[0]);
      final userData = await _parse(responses[1]);

      if (!mounted) return;

      setState(() {
        _metas = metasData is List
            ? metasData.map(_normalizeMeta).toList()
            : [];
        _user = userData is Map
            ? Map<String, dynamic>.from(userData)
            : {};
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _metas = [];
      });

      _toast(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  int get _total => _metas.length;

  int get _concluidas =>
      _metas.where((m) => m['status'] == 'concluida').length;

  int get _andamento =>
      _metas.where((m) => m['status'] == 'em andamento').length;

  List<Map<String, dynamic>> get _filtered {
    final query = _searchController.text.trim().toLowerCase();

    return _metas.where((meta) {
      final matchesSearch = query.isEmpty ||
          meta['titulo']
              .toString()
              .toLowerCase()
              .contains(query) ||
          meta['descricao']
              .toString()
              .toLowerCase()
              .contains(query) ||
          meta['categoria']
              .toString()
              .toLowerCase()
              .contains(query);

      final matchesFilter = _filter == 'todas' ||
          (_filter == 'andamento' &&
              meta['status'] == 'em andamento') ||
          (_filter == 'concluidas' &&
              meta['status'] == 'concluida');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String _date(dynamic value) {
    final raw = value?.toString() ?? '';

    if (raw.isEmpty) return 'Sem prazo';

    final parts = raw.split('-');

    if (parts.length != 3) return 'Sem prazo';

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  Future<void> _createOrEdit([Map<String, dynamic>? meta]) async {
    final title = TextEditingController(
      text: meta?['titulo']?.toString() ?? '',
    );

    final description = TextEditingController(
      text: meta?['descricao']?.toString() ?? '',
    );

    String category =
        meta?['categoria']?.toString() ?? 'Pessoal';

    DateTime? deadline = meta?['prazo'] != null &&
            meta!['prazo'].toString().isNotEmpty
        ? DateTime.tryParse(meta['prazo'].toString())
        : null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.62),
      builder: (context) {
        final darkDialog =
            Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: darkDialog
                        ? const Color(0xFF0F1B2F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: darkDialog
                          ? Colors.white.withOpacity(0.07)
                          : const Color(0xFF06152D)
                              .withOpacity(0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 48,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PLANEJE SEU PRÓXIMO PASSO',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        meta == null ? 'Nova meta' : 'Editar meta',
                        style: TextStyle(
                          color: darkDialog
                              ? Colors.white
                              : const Color(0xFF06152D),
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Defina um objetivo real e acompanhe seu avanço.',
                        style: TextStyle(
                          color: darkDialog
                              ? const Color(0xFF98A8BF)
                              : const Color(0xFF61758F),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DialogField(
                        controller: title,
                        label: 'Título',
                        hint: 'Ex.: Finalizar meu projeto',
                        dark: darkDialog,
                      ),
                      const SizedBox(height: 13),
                      _DialogField(
                        controller: description,
                        label: 'Descrição',
                        hint: 'Descreva o que você deseja alcançar',
                        dark: darkDialog,
                        lines: 3,
                      ),
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: category,
                              dropdownColor: darkDialog
                                  ? const Color(0xFF0B1729)
                                  : Colors.white,
                              decoration: _dialogDecoration(
                                'Categoria',
                                darkDialog,
                              ),
                              style: TextStyle(
                                color: darkDialog
                                    ? Colors.white
                                    : const Color(0xFF06152D),
                                fontSize: 12.5,
                              ),
                              items: const [
                                'Pessoal',
                                'Estudos',
                                'Trabalho',
                                'Saúde',
                                'Projeto',
                                'Outro',
                              ]
                                  .map(
                                    (item) =>
                                        DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(
                                    () => category = value,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(13),
                              onTap: () async {
                                final picked =
                                    await showDatePicker(
                                  context: context,
                                  initialDate:
                                      deadline ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );

                                if (picked != null) {
                                  setDialogState(
                                    () => deadline = picked,
                                  );
                                }
                              },
                              child: InputDecorator(
                                decoration: _dialogDecoration(
                                  'Prazo',
                                  darkDialog,
                                ),
                                child: Text(
                                  deadline == null
                                      ? 'Selecionar'
                                      : '${deadline!.day.toString().padLeft(2, '0')}/'
                                          '${deadline!.month.toString().padLeft(2, '0')}/'
                                          '${deadline!.year}',
                                  style: TextStyle(
                                    color: deadline == null
                                        ? (darkDialog
                                            ? const Color(0xFF98A8BF)
                                            : const Color(0xFF61758F))
                                        : (darkDialog
                                            ? Colors.white
                                            : const Color(0xFF06152D)),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(13),
                              ),
                            ),
                            onPressed: () {
                              final titleText =
                                  title.text.trim();

                              if (titleText.isEmpty) return;

                              Navigator.pop(
                                context,
                                {
                                  'titulo': titleText,
                                  'descricao':
                                      description.text.trim(),
                                  'categoria': category,
                                  'prazo': deadline == null
                                      ? null
                                      : '${deadline!.year}-'
                                          '${deadline!.month.toString().padLeft(2, '0')}-'
                                          '${deadline!.day.toString().padLeft(2, '0')}',
                                },
                              );
                            },
                            icon: Icon(
                              meta == null
                                  ? Icons.add_rounded
                                  : Icons.save_outlined,
                              size: 18,
                            ),
                            label: Text(
                              meta == null
                                  ? 'Criar meta'
                                  : 'Salvar alterações',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    title.dispose();
    description.dispose();

    if (result == null) return;

    final token = await _token();
    if (token == null || token.isEmpty) return;

    try {
      final response = meta == null
          ? await http.post(
              ApiConfig.uri('/metas/criar_meta'),
              headers: _headers(token),
              body: jsonEncode(result),
            )
          : await http.put(
              ApiConfig.uri(
                '/metas/atualizar_meta/${meta['id']}',
              ),
              headers: _headers(token),
              body: jsonEncode(result),
            );

      await _parse(response);
      await _load();

      _toast(
        meta == null
            ? 'Meta criada com sucesso!'
            : 'Meta atualizada com sucesso!',
      );
    } catch (error) {
      _toast(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  InputDecoration _dialogDecoration(
    String label,
    bool darkDialog,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: darkDialog
            ? const Color(0xFF98A8BF)
            : const Color(0xFF61758F),
      ),
      filled: true,
      fillColor: darkDialog
          ? const Color(0xFF0B1729)
          : const Color(0xFFF7FBFF),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: darkDialog
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF06152D).withOpacity(0.08),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(
          color: darkDialog
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF06152D).withOpacity(0.08),
        ),
      ),
    );
  }

  Future<void> _toggleStatus(
    Map<String, dynamic> meta,
  ) async {
    final token = await _token();
    if (token == null || token.isEmpty) return;

    final concluded = meta['status'] == 'concluida';
    final nextStatus =
        concluded ? 'em andamento' : 'concluida';

    try {
      final response = await http.put(
        ApiConfig.uri(
          '/metas/atualizar_meta/${meta['id']}',
        ),
        headers: _headers(token),
        body: jsonEncode({'status': nextStatus}),
      );

      await _parse(response);
      await _load();

      _toast(
        concluded
            ? 'Meta reaberta.'
            : 'Meta concluída! 🎉',
      );
    } catch (error) {
      _toast(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _deleteMeta(
    Map<String, dynamic> meta,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.62),
      builder: (context) {
        final dialogDark =
            Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: dialogDark
              ? const Color(0xFF0F1B2F)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Excluir meta?'),
          content: Text(
            'Tem certeza que deseja excluir "${meta['titulo']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Excluir meta'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final token = await _token();
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.delete(
        ApiConfig.uri(
          '/metas/deletar_meta/${meta['id']}',
        ),
        headers: _headers(token),
      );

      await _parse(response);
      await _load();
      _toast('Meta excluída.');
    } catch (error) {
      _toast(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _shareConquest(
    Map<String, dynamic> meta,
  ) async {
    final controller = TextEditingController();

    final content = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.66),
      builder: (context) {
        final dialogDark =
            Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: dialogDark
                        ? const Color(0xFF0F1B2F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: dialogDark
                          ? Colors.white.withOpacity(0.07)
                          : const Color(0xFF06152D)
                              .withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.14),
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.emoji_events_outlined,
                          color: Color(0xFFD89A00),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'COMPARTILHE SEU PROGRESSO',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Compartilhar conquista',
                        style: TextStyle(
                          color: dialogDark
                              ? Colors.white
                              : const Color(0xFF06152D),
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _success.withOpacity(0.09),
                          borderRadius:
                              BorderRadius.circular(15),
                          border: Border.all(
                            color: _success.withOpacity(0.20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'META CONCLUÍDA',
                              style: TextStyle(
                                color: _success,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              meta['titulo'].toString(),
                              style: TextStyle(
                                color: dialogDark
                                    ? Colors.white
                                    : const Color(0xFF06152D),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              meta['categoria'].toString(),
                              style: TextStyle(
                                color: dialogDark
                                    ? const Color(0xFF98A8BF)
                                    : const Color(0xFF61758F),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller,
                        maxLength: 500,
                        maxLines: 5,
                        onChanged: (_) => setDialogState(() {}),
                        style: TextStyle(
                          color: dialogDark
                              ? Colors.white
                              : const Color(0xFF06152D),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Conte um pouco sobre essa conquista...',
                          filled: true,
                          fillColor: dialogDark
                              ? const Color(0xFF0B1729)
                              : const Color(0xFFF7FBFF),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed:
                                controller.text.trim().isEmpty
                                    ? null
                                    : () => Navigator.pop(
                                          context,
                                          controller.text.trim(),
                                        ),
                            icon: const Icon(
                              Icons.send_rounded,
                              size: 17,
                            ),
                            label: const Text(
                              'Publicar conquista',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();

    if (content == null || content.trim().isEmpty) return;

    final token = await _token();
    if (token == null || token.isEmpty) return;

    try {
      final response = await http.post(
        ApiConfig.uri('/post/criar_post'),
        headers: _headers(token),
        body: jsonEncode({
          'conteudo': content,
          'imagem': null,
          'comunidade_id': null,
          'tipo': 'conquista',
          'meta_id': meta['id'],
          'sessao_id': null,
        }),
      );

      await _parse(response);
      _toast('Conquista compartilhada! 🏆');
    } catch (error) {
      _toast(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  void _toast(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            error ? _danger : const Color(0xFF21855F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 760;
    final tablet = width >= 760 && width < 1080;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: mobile ? _mobileDrawer() : null,
      body: Row(
        children: [
          if (!mobile) _sidebar(),
          Expanded(
            child: Column(
              children: [
                if (mobile) _mobileTopBar(),
                Expanded(
                  child: Stack(
                    children: [
                      _background(),
                      _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: _primary,
                              ),
                            )
                          : SingleChildScrollView(
                              physics:
                                  const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                mobile ? 18 : (tablet ? 28 : 38),
                                mobile ? 20 : 28,
                                mobile ? 18 : (tablet ? 28 : 38),
                                80,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(
                                    maxWidth: 1180,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _hero(mobile),
                                      const SizedBox(height: 20),
                                      _dashboard(mobile, tablet),
                                      const SizedBox(height: 18),
                                      _workspace(mobile),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _background() {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero(bool mobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    child: Divider(
                      thickness: 3,
                      color: _accent,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'DESENVOLVIMENTO',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'Metas',
                style: TextStyle(
                  color: text,
                  fontSize: mobile ? 34 : 42,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Organize e acompanhe seus objetivos.',
                style: TextStyle(
                  color: muted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (!mobile)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: dark
                  ? const Color(0xFF071A36)
                  : const Color(0xFF06152D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            onPressed: () => _createOrEdit(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nova meta'),
          ),
      ],
    );
  }

  Widget _dashboard(bool mobile, bool tablet) {
    final mainCard = Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'VISÃO GERAL',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Seu progresso',
                      style: TextStyle(
                        color: text,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF0B2A58)
                  : const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _primary.withOpacity(0.14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: Color(0xFF06152D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _andamento == 1
                        ? '1 meta em andamento'
                        : '$_andamento metas em andamento',
                    style: TextStyle(
                      color: text,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final stats = Row(
      children: [
        Expanded(
          child: _statCard(
            Icons.checklist_rounded,
            _total,
            'metas criadas',
            _primary,
          ),
        ),
        Expanded(
          child: _statCard(
            Icons.check_circle_outline_rounded,
            _concluidas,
            'concluídas',
            _success,
          ),
        ),
        Expanded(
          child: _statCard(
            Icons.local_fire_department_outlined,
            _andamento,
            'em andamento',
            const Color(0xFFE09C20),
          ),
        ),
      ],
    );

    if (mobile || tablet) {
      return Column(
        children: [
          mainCard,
          const SizedBox(height: 12),
          stats,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: mainCard),
          const SizedBox(width: 14),
          Expanded(flex: 2, child: stats),
        ],
      ),
    );
  }

  Widget _statCard(
    IconData icon,
    int value,
    String label,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 136,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 17,
      ),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF0F1B2F)
            : Colors.white.withOpacity(0.88),
        border: Border(
          left: BorderSide(
            color: dark
                ? Colors.white.withOpacity(0.06)
                : const Color(0xFF06152D).withOpacity(0.07),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            '$value',
            style: TextStyle(
              color: text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspace(bool mobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(mobile ? 16 : 20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mobile) ...[
            _workspaceTitle(),
            const SizedBox(height: 13),
            _workspaceActions(),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _workspaceTitle()),
                _workspaceActions(),
              ],
            ),
          const SizedBox(height: 16),
          if (_filtered.isEmpty)
            _emptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns =
                    constraints.maxWidth >= 760;

                if (!twoColumns) {
                  return Column(
                    children: [
                      for (int i = 0;
                          i < _filtered.length;
                          i++) ...[
                        _metaCard(_filtered[i]),
                        if (i < _filtered.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                }

                final children = <Widget>[];

                for (int i = 0;
                    i < _filtered.length;
                    i += 2) {
                  children.add(
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _metaCard(_filtered[i]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: i + 1 < _filtered.length
                              ? _metaCard(_filtered[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );

                  if (i + 2 < _filtered.length) {
                    children.add(
                      const SizedBox(height: 12),
                    );
                  }
                }

                return Column(children: children);
              },
            ),
        ],
      ),
    );
  }

  Widget _workspaceTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLANEJAMENTO',
          style: TextStyle(
            color: _primary,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Minhas metas',
          style: TextStyle(
            color: text,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _workspaceActions() {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 230,
          height: 42,
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: text,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: 'Buscar meta...',
              hintStyle: TextStyle(color: muted),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: muted,
                size: 19,
              ),
              filled: true,
              fillColor: dark
                  ? const Color(0xFF0B1729)
                  : const Color(0xFFF7FBFF),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: dark
                      ? Colors.white.withOpacity(0.07)
                      : const Color(0xFF06152D)
                          .withOpacity(0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: dark
                      ? Colors.white.withOpacity(0.07)
                      : const Color(0xFF06152D)
                          .withOpacity(0.08),
                ),
              ),
            ),
          ),
        ),
        _filterButton('todas', 'Todas'),
        _filterButton('andamento', 'Em andamento'),
        _filterButton('concluidas', 'Concluídas'),
      ],
    );
  }

  Widget _filterButton(
    String value,
    String label,
  ) {
    final selected = _filter == value;

    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        padding:
            const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (dark
                  ? const Color(0xFF174A9B)
                  : const Color(0xFFEAF3FF))
              : (dark
                  ? Colors.white.withOpacity(0.04)
                  : const Color(0xFFF7FBFF)),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? _primary.withOpacity(0.32)
                : (dark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFF06152D)
                        .withOpacity(0.08)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _primary : muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _metaCard(
    Map<String, dynamic> meta,
  ) {
    final concluded = meta['status'] == 'concluida';
    final accent = concluded ? _success : _primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xFF0B1729)
              : const Color(0xFFF9FCFF),
          border: Border.all(
            color: accent.withOpacity(0.26),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                dark ? 0.12 : 0.05,
              ),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 3,
              color: accent,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _categoryPill(
                        meta['categoria'].toString(),
                      ),
                      const Spacer(),
                      _iconButton(
                        Icons.edit_outlined,
                        () => _createOrEdit(meta),
                      ),
                      const SizedBox(width: 6),
                      _iconButton(
                        Icons.delete_outline_rounded,
                        () => _deleteMeta(meta),
                        danger: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    meta['titulo'].toString(),
                    style: TextStyle(
                      color: text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meta['descricao'].toString().isEmpty
                        ? 'Sem descrição.'
                        : meta['descricao'].toString(),
                    style: TextStyle(
                      color: muted,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: _primary,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _date(meta['prazo']),
                        style: TextStyle(
                          color: soft,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(
                    height: 1,
                    color: dark
                        ? Colors.white.withOpacity(0.06)
                        : const Color(0xFF06152D)
                            .withOpacity(0.07),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      _statusPill(concluded),
                      const Spacer(),
                      if (concluded) ...[
                        _smallAction(
                          Icons.refresh_rounded,
                          'Reabrir meta',
                          () => _toggleStatus(meta),
                        ),
                        const SizedBox(width: 8),
                        _smallAction(
                          Icons.emoji_events_outlined,
                          'Compartilhar conquista',
                          () => _shareConquest(meta),
                          success: true,
                        ),
                      ] else
                        _smallAction(
                          Icons.check_circle_outline_rounded,
                          'Marcar como concluída',
                          () => _toggleStatus(meta),
                          success: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withOpacity(0.055)
            : const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sell_outlined,
            color: _primary,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: soft,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(bool concluded) {
    final color =
        concluded ? _success : const Color(0xFFE09C20);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        concluded ? 'Concluída' : 'Em andamento',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _iconButton(
    IconData icon,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 17,
          color: danger ? _danger : _primary,
        ),
      ),
    );
  }

  Widget _smallAction(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool success = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: success
              ? _success
              : (dark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFEAF3FF)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: success
                  ? Colors.white
                  : _primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: success
                    ? Colors.white
                    : _primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF0B1729)
            : const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFF06152D).withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.track_changes_rounded,
            color: _primary,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            _metas.isEmpty
                ? 'Sua primeira meta começa aqui.'
                : 'Nenhuma meta encontrada.',
            style: TextStyle(
              color: text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _metas.isEmpty
                ? 'Crie uma meta para começar a organizar seus objetivos.'
                : 'Tente outro termo ou filtro.',
            style: TextStyle(
              color: muted,
              fontSize: 11.5,
            ),
          ),
          if (_metas.isEmpty) ...[
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: () => _createOrEdit(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Criar primeira meta'),
            ),
          ],
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? const [
                Color(0xFF0C1627),
                Color(0xFF0A121F),
              ]
            : [
                Colors.white.withOpacity(0.96),
                const Color(0xFFF7FBFF),
              ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: dark
            ? Colors.white.withOpacity(0.055)
            : const Color(0xFF06152D).withOpacity(0.07),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            dark ? 0.18 : 0.06,
          ),
          blurRadius: 26,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  Widget _sidebar() {
    const collapsed = 88.0;
    const expanded = 244.0;
    final width =
        _sidebarHovered ? expanded : collapsed;

    return MouseRegion(
      onEnter: (_) =>
          setState(() => _sidebarHovered = true),
      onExit: (_) => setState(() {
        _sidebarHovered = false;
        _sidebarItemHovered = null;
      }),
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
              color: _primary.withOpacity(0.09),
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
            Divider(
              color: _primary.withOpacity(0.10),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _sectionLabel('COMUNIDADE'),
                  _navItem(
                    Icons.home_rounded,
                    'Feed',
                    '/feed',
                  ),
                  _navItem(
                    Icons.explore_outlined,
                    'Explorar',
                    '/explorar',
                  ),
                  _navItem(
                    Icons.edit_square,
                    'Postar',
                    '/postar',
                  ),
                  const SizedBox(height: 8),
                  _sectionLabel('DESENVOLVIMENTO'),
                  _navItem(
                    Icons.track_changes_rounded,
                    'Metas',
                    '/metas',
                    active: true,
                  ),
                  _navItem(
                    Icons.psychology_outlined,
                    'Sala de foco',
                    '/foco',
                  ),
                  _navItem(
                    Icons.trending_up_rounded,
                    'Evolução',
                    '/evolucao',
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.white.withOpacity(0.08),
            ),
            _navItem(
              Icons.settings_outlined,
              'Configurações',
              '/config',
            ),
            _profileItem(),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10),
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

  Widget _navItem(
    IconData icon,
    String label,
    String route, {
    bool active = false,
  }) {
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
        onTap: () {
          if (!active) {
            Navigator.of(context).pushNamed(route);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 50,
          margin: const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.symmetric(horizontal: 12),
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
                        ? _primary.withOpacity(0.55)
                        : Colors.white.withOpacity(0.08),
                  )
                : null,
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
                      if (active)
                        Positioned(
                          left: -12,
                          top: 1,
                          bottom: 1,
                          child: Container(
                            width: 3,
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius:
                                  BorderRadius.circular(999),
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
                          size: 23,
                        ),
                      ),
                    ],
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

  Widget _profileItem() {
    final photo = (_user['foto_perfil'] ?? '').toString();

    return InkWell(
      onTap: () =>
          Navigator.of(context).pushNamed('/perfil'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final show =
                _sidebarHovered && constraints.maxWidth > 90;

            return Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: photo.isNotEmpty
                      ? ApiConfig.imageProvider(photo)
                      : const AssetImage(
                          'assets/images/pace_icon.png',
                        ),
                ),
                if (show) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meu perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Ver perfil',
                          style: TextStyle(
                            color: Color(0xFF8FA5C0),
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
      ),
    );
  }

  Widget _mobileTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFF06152D),
      child: Row(
        children: [
          IconButton(
            onPressed: () =>
                _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Image.asset(
            'assets/images/pace_icon.png',
            width: 34,
            height: 34,
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _createOrEdit(),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Nova meta'),
          ),
        ],
      ),
    );
  }

  Widget _mobileDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF06152D),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const SizedBox(height: 10),
            Image.asset(
              'assets/images/pace_icon.png',
              width: 52,
              height: 52,
              alignment: Alignment.centerLeft,
            ),
            const SizedBox(height: 18),
            _drawerItem('Feed', '/feed', Icons.home_rounded),
            _drawerItem(
              'Explorar',
              '/explorar',
              Icons.explore_outlined,
            ),
            _drawerItem(
              'Postar',
              '/postar',
              Icons.edit_square,
            ),
            _drawerItem(
              'Metas',
              '/metas',
              Icons.track_changes_rounded,
              active: true,
            ),
            _drawerItem(
              'Sala de foco',
              '/foco',
              Icons.psychology_outlined,
            ),
            _drawerItem(
              'Evolução',
              '/evolucao',
              Icons.trending_up_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    String label,
    String route,
    IconData icon, {
    bool active = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: active ? Colors.white : const Color(0xFFC7D5E8),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFFC7D5E8),
          fontWeight: FontWeight.w700,
        ),
      ),
      tileColor:
          active ? const Color(0xFF174A9B) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: active
          ? () => Navigator.pop(context)
          : () => Navigator.of(context).pushNamed(route),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool dark;
  final int lines;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.dark,
    this.lines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      style: TextStyle(
        color: dark ? Colors.white : const Color(0xFF06152D),
        fontSize: 12.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: dark
            ? const Color(0xFF0B1729)
            : const Color(0xFFF7FBFF),
        labelStyle: TextStyle(
          color: dark
              ? const Color(0xFF98A8BF)
              : const Color(0xFF61758F),
        ),
        hintStyle: TextStyle(
          color: dark
              ? const Color(0xFF6F829C)
              : const Color(0xFF8091A7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );
  }
}