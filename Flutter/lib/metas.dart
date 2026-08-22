import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'pace_session.dart';
import 'pace_shell.dart';

class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  final TextEditingController _search = TextEditingController();

  Map<String, dynamic> _user = {};

  List<Map<String, dynamic>> _metas = [];

  String _filter = 'todas';

  bool _loading = true;
  bool _reloading = false;

  int? _busyMetaId;

  bool get dark =>
      Theme.of(context).brightness == Brightness.dark;

  Color get bg =>
      dark
          ? const Color(0xFF05070C)
          : const Color(0xFFF4F8FD);

  Color get text =>
      dark
          ? const Color(0xFFF2F6FF)
          : const Color(0xFF172033);

  Color get muted =>
      dark
          ? const Color(0xFF98A8BF)
          : const Color(0xFF6F7F96);

  @override
  void initState() {
    super.initState();

    _search.addListener(_onSearchChanged);

    _load();
  }

  @override
  void dispose() {
    _search.removeListener(_onSearchChanged);
    _search.dispose();

    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {});
  }

  /* =========================================================
     API
  ========================================================= */

  Future<Map<String, String>> _headers({
    bool json = false,
  }) async {
    final token =
        await PaceSession.token();

    final headers = <String, String>{};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] =
          'Bearer $token';
    }

    if (json) {
      headers['Content-Type'] =
          'application/json';
    }

    return headers;
  }

  Future<dynamic> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final headers =
        await _headers(
      json: body != null,
    );

    late http.Response response;

    final uri =
        ApiConfig.uri(endpoint);

    try {
      switch (method) {
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body == null
                    ? null
                    : jsonEncode(body),
              )
              .timeout(
                const Duration(seconds: 10),
              );

          break;

        case 'PUT':
          response = await http
              .put(
                uri,
                headers: headers,
                body: body == null
                    ? null
                    : jsonEncode(body),
              )
              .timeout(
                const Duration(seconds: 10),
              );

          break;

        case 'DELETE':
          response = await http
              .delete(
                uri,
                headers: headers,
              )
              .timeout(
                const Duration(seconds: 10),
              );

          break;

        default:
          response = await http
              .get(
                uri,
                headers: headers,
              )
              .timeout(
                const Duration(seconds: 10),
              );
      }
    } catch (_) {
      throw Exception(
        'Não foi possível conectar à API do Pace.',
      );
    }

    dynamic data;

    if (response.body.isNotEmpty) {
      try {
        data =
            jsonDecode(
          utf8.decode(
            response.bodyBytes,
          ),
        );
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode == 401) {
      throw const _PaceApiException(
        'Sua sessão expirou. Entre novamente.',
        statusCode: 401,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      String message =
          'Não foi possível concluir a operação.';

      if (data is Map) {
        final detail =
            data['detail'] ??
                data['message'];

        if (detail != null) {
          message =
              detail.toString();
        }
      }

      throw _PaceApiException(
        message,
        statusCode: response.statusCode,
      );
    }

    return data;
  }

  /* =========================================================
     NORMALIZAÇÃO
  ========================================================= */

  Map<String, dynamic> _normalizeMeta(
    dynamic value,
  ) {
    if (value is! Map) {
      return {};
    }

    final map =
        Map<String, dynamic>.from(
      value,
    );

    final status =
        map['status']
            ?.toString()
            .trim()
            .toLowerCase();

    return {
      'id':
          (map['id'] as num?)
              ?.toInt(),

      'titulo':
          map['titulo']
                  ?.toString() ??
              '',

      'descricao':
          map['descricao']
                  ?.toString() ??
              '',

      'categoria':
          map['categoria']
                  ?.toString() ??
              'Outro',

      'prazo':
          map['prazo']
              ?.toString(),

      'status':
          status == 'concluida'
              ? 'concluida'
              : 'em andamento',
    };
  }

  bool _isCompleted(
    Map<String, dynamic> meta,
  ) {
    return meta['status']
            ?.toString()
            .toLowerCase() ==
        'concluida';
  }

  /* =========================================================
     CARREGAR
  ========================================================= */

  Future<void> _load() async {
    try {
      final user =
          await PaceSession.currentUser();

      final response =
          await _request(
        '/metas/listar_metas',
      );

      final items =
          response is List
              ? response
                  .map(_normalizeMeta)
                  .where(
                    (item) =>
                        item.isNotEmpty,
                  )
                  .toList()
              : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _user = user;
        _metas = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _handleError(error);
    }
  }

  Future<void> _refresh() async {
    if (_reloading) return;

    setState(() {
      _reloading = true;
    });

    try {
      final response =
          await _request(
        '/metas/listar_metas',
      );

      final items =
          response is List
              ? response
                  .map(_normalizeMeta)
                  .where(
                    (item) =>
                        item.isNotEmpty,
                  )
                  .toList()
              : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _metas = items;
      });
    } catch (error) {
      if (!mounted) return;

      _handleError(error);
    } finally {
      if (mounted) {
        setState(() {
          _reloading = false;
        });
      }
    }
  }

  /* =========================================================
     FILTROS
  ========================================================= */

  List<Map<String, dynamic>>
      get _filtered {
    final query =
        _search.text
            .trim()
            .toLowerCase();

    return _metas.where(
      (meta) {
        final completed =
            _isCompleted(meta);

        final statusOk =
            _filter == 'todas' ||
                (
                  _filter ==
                      'andamento' &&
                  !completed
                ) ||
                (
                  _filter ==
                      'concluidas' &&
                  completed
                );

        final title =
            meta['titulo']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final description =
            meta['descricao']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final category =
            meta['categoria']
                    ?.toString()
                    .toLowerCase() ??
                '';

        final searchOk =
            query.isEmpty ||
                title.contains(query) ||
                description.contains(query) ||
                category.contains(query);

        return statusOk &&
            searchOk;
      },
    ).toList();
  }

  int get _concluidas =>
      _metas
          .where(_isCompleted)
          .length;

  int get _andamento =>
      _metas.length -
      _concluidas;

  /* =========================================================
     CRIAR / EDITAR
  ========================================================= */

  Future<void> _openEditor([
    Map<String, dynamic>? current,
  ]) async {
    final title =
        TextEditingController(
      text:
          current?['titulo']
                  ?.toString() ??
              '',
    );

    final description =
        TextEditingController(
      text:
          current?['descricao']
                  ?.toString() ??
              '',
    );

    String category =
        current?['categoria']
                ?.toString() ??
            'Pessoal';

    final rawDeadline =
        current?['prazo']
            ?.toString();

    DateTime? deadline =
        rawDeadline == null ||
                rawDeadline.isEmpty
            ? null
            : DateTime.tryParse(
                rawDeadline,
              );

    final result =
        await showDialog<
            Map<String, dynamic>>(
      context: context,
      barrierColor:
          Colors.black54,
      builder: (
        dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            context,
            setLocal,
          ) {
            return AlertDialog(
              backgroundColor:
                  dark
                      ? const Color(
                          0xFF0D1727,
                        )
                      : Colors.white,

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  26,
                ),
              ),

              title: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Text(
                    current == null
                        ? 'Nova meta'
                        : 'Editar meta',
                    style: TextStyle(
                      color: text,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    current == null
                        ? 'Defina um objetivo claro para começar.'
                        : 'Atualize os dados da sua meta.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12.5,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),

              content: SizedBox(
                width: 520,
                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      _field(
                        title,
                        'Título',
                        'Ex.: Finalizar meu projeto',
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _field(
                        description,
                        'Descrição',
                        'Descreva o que deseja alcançar',
                        lines: 3,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      DropdownButtonFormField<
                          String>(
                        value: category,

                        dropdownColor:
                            dark
                                ? const Color(
                                    0xFF0D1727,
                                  )
                                : Colors.white,

                        style: TextStyle(
                          color: text,
                          fontWeight:
                              FontWeight.w600,
                        ),

                        decoration:
                            _input(
                          'Categoria',
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
                              (value) =>
                                  DropdownMenuItem(
                                value:
                                    value,
                                child:
                                    Text(
                                  value,
                                ),
                              ),
                            )
                            .toList(),

                        onChanged: (
                          value,
                        ) {
                          if (value ==
                              null) {
                            return;
                          }

                          setLocal(
                            () {
                              category =
                                  value;
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      SizedBox(
                        width:
                            double.infinity,
                        child:
                            OutlinedButton.icon(
                          onPressed:
                              () async {
                            final picked =
                                await showDatePicker(
                              context:
                                  context,

                              initialDate:
                                  deadline ??
                                      DateTime
                                          .now(),

                              firstDate:
                                  DateTime
                                          .now()
                                      .subtract(
                                const Duration(
                                  days: 1,
                                ),
                              ),

                              lastDate:
                                  DateTime
                                          .now()
                                      .add(
                                const Duration(
                                  days:
                                      3650,
                                ),
                              ),
                            );

                            if (picked !=
                                null) {
                              setLocal(
                                () {
                                  deadline =
                                      picked;
                                },
                              );
                            }
                          },

                          icon: const Icon(
                            Icons
                                .calendar_month_rounded,
                          ),

                          label: Text(
                            deadline == null
                                ? 'Escolher prazo'
                                : _formatDate(
                                    deadline!,
                                  ),
                          ),

                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                pacePrimary,

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal:
                                  16,
                              vertical:
                                  15,
                            ),

                            side: BorderSide(
                              color:
                                  pacePrimary
                                      .withOpacity(
                                0.14,
                              ),
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                15,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      Container(
                        width:
                            double.infinity,

                        padding:
                            const EdgeInsets
                                .all(
                          14,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              pacePrimary
                                  .withOpacity(
                            dark
                                ? 0.10
                                : 0.06,
                          ),

                          borderRadius:
                              BorderRadius
                                  .circular(
                            15,
                          ),
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,

                              alignment:
                                  Alignment
                                      .center,

                              decoration:
                                  BoxDecoration(
                                color:
                                    pacePrimary
                                        .withOpacity(
                                  0.12,
                                ),

                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                              ),

                              child:
                                  const Icon(
                                Icons
                                    .route_rounded,
                                color:
                                    pacePrimary,
                                size: 20,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    current ==
                                            null
                                        ? 'A meta começa em andamento'
                                        : 'O status é alterado diretamente no card',
                                    style:
                                        TextStyle(
                                      color:
                                          text,
                                      fontSize:
                                          12.5,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 2,
                                  ),

                                  Text(
                                    'Quando terminar, basta marcar como concluída.',
                                    style:
                                        TextStyle(
                                      color:
                                          muted,
                                      fontSize:
                                          11.5,
                                      height:
                                          1.4,
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
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child:
                      const Text(
                    'Cancelar',
                  ),
                ),

                FilledButton.icon(
                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        pacePrimary,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                  ),

                  onPressed: () {
                    if (title.text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    Navigator.pop(
                      dialogContext,
                      {
                        'titulo':
                            title.text
                                .trim(),

                        'descricao':
                            description
                                .text
                                .trim(),

                        'categoria':
                            category,

                        'prazo':
                            deadline ==
                                    null
                                ? null
                                : _apiDate(
                                    deadline!,
                                  ),
                      },
                    );
                  },

                  icon: Icon(
                    current == null
                        ? Icons.add_rounded
                        : Icons
                            .save_outlined,
                    size: 19,
                  ),

                  label: Text(
                    current == null
                        ? 'Criar meta'
                        : 'Salvar alterações',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    title.dispose();
    description.dispose();

    if (result == null) {
      return;
    }

    if (current == null) {
      await _createMeta(
        result,
      );
    } else {
      await _updateMeta(
        current,
        result,
      );
    }
  }

  Future<void> _createMeta(
    Map<String, dynamic> values,
  ) async {
    try {
      final response =
          await _request(
        '/metas/criar_meta',
        method: 'POST',
        body: values,
      );

      final meta =
          _normalizeMeta(
        response,
      );

      if (!mounted) return;

      setState(() {
        _metas.insert(
          0,
          meta,
        );
      });

      _snack(
        'Meta criada com sucesso!',
      );
    } catch (error) {
      if (!mounted) return;

      _handleError(error);
    }
  }

  Future<void> _updateMeta(
    Map<String, dynamic> current,
    Map<String, dynamic> values,
  ) async {
    final id =
        (current['id'] as num?)
            ?.toInt();

    if (id == null) return;

    setState(() {
      _busyMetaId = id;
    });

    try {
      final response =
          await _request(
        '/metas/atualizar_meta/$id',
        method: 'PUT',
        body: values,
      );

      final updated =
          _normalizeMeta(
        response,
      );

      if (!mounted) return;

      setState(() {
        final index =
            _metas.indexWhere(
          (meta) =>
              meta['id'] == id,
        );

        if (index >= 0) {
          _metas[index] =
              updated;
        }
      });

      _snack(
        'Meta atualizada com sucesso!',
      );
    } catch (error) {
      if (!mounted) return;

      _handleError(error);
    } finally {
      if (mounted) {
        setState(() {
          _busyMetaId = null;
        });
      }
    }
  }

  /* =========================================================
     CONCLUIR / REABRIR
  ========================================================= */

  Future<void> _toggleStatus(
    Map<String, dynamic> meta,
  ) async {
    final id =
        (meta['id'] as num?)
            ?.toInt();

    if (id == null) return;

    final completed =
        _isCompleted(meta);

    final newStatus =
        completed
            ? 'em andamento'
            : 'concluida';

    setState(() {
      _busyMetaId = id;
    });

    try {
      final response =
          await _request(
        '/metas/atualizar_meta/$id',
        method: 'PUT',
        body: {
          'status':
              newStatus,
        },
      );

      final updated =
          _normalizeMeta(
        response,
      );

      if (!mounted) return;

      setState(() {
        final index =
            _metas.indexWhere(
          (item) =>
              item['id'] == id,
        );

        if (index >= 0) {
          _metas[index] =
              updated;
        }
      });

      _snack(
        newStatus == 'concluida'
            ? 'Meta concluída! 🔥'
            : 'Meta marcada como em andamento.',
      );
    } catch (error) {
      if (!mounted) return;

      _handleError(error);
    } finally {
      if (mounted) {
        setState(() {
          _busyMetaId = null;
        });
      }
    }
  }

  /* =========================================================
     EXCLUIR
  ========================================================= */

  Future<void> _delete(
    Map<String, dynamic> meta,
  ) async {
    final id =
        (meta['id'] as num?)
            ?.toInt();

    if (id == null) return;

    final ok =
        await showDialog<bool>(
      context: context,
      barrierColor:
          Colors.black54,
      builder: (
        dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              dark
                  ? const Color(
                      0xFF0D1727,
                    )
                  : Colors.white,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              24,
            ),
          ),

          icon:
              const Icon(
            Icons
                .delete_outline_rounded,
            color:
                Color(0xFFE45454),
            size: 34,
          ),

          title:
              Text(
            'Excluir meta?',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color: text,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          content:
              Text(
            'A meta "${meta['titulo']}" será removida permanentemente da sua conta.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color: muted,
              height: 1.5,
            ),
          ),

          actionsAlignment:
              MainAxisAlignment.center,

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child:
                  const Text(
                'Cancelar',
              ),
            ),

            FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFFE45454,
                ),
              ),

              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              icon:
                  const Icon(
                Icons
                    .delete_outline_rounded,
                size: 18,
              ),

              label:
                  const Text(
                'Excluir',
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() {
      _busyMetaId = id;
    });

    try {
      await _request(
        '/metas/deletar_meta/$id',
        method: 'DELETE',
      );

      if (!mounted) return;

      setState(() {
        _metas.removeWhere(
          (item) =>
              item['id'] == id,
        );
      });

      _snack(
        'Meta excluída.',
      );
    } catch (error) {
      if (!mounted) return;

      _handleError(error);
    } finally {
      if (mounted) {
        setState(() {
          _busyMetaId = null;
        });
      }
    }
  }

  /* =========================================================
     FEEDBACK
  ========================================================= */

  void _handleError(
    Object error,
  ) {
    final message =
        error is _PaceApiException
            ? error.message
            : error
                .toString()
                .replaceFirst(
                  'Exception: ',
                  '',
                );

    _snack(
      message,
      error: true,
    );

    if (error
            is _PaceApiException &&
        error.statusCode ==
            401) {
      Future.delayed(
        const Duration(
          milliseconds: 700,
        ),
        () {
          if (!mounted) return;

          Navigator.of(context)
              .pushNamedAndRemoveUntil(
            '/entrar',
            (route) => false,
          );
        },
      );
    }
  }

  void _snack(
    String message, {
    bool error = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Row(
            children: [
              Icon(
                error
                    ? Icons
                        .error_outline_rounded
                    : Icons
                        .check_circle_outline_rounded,
                color:
                    Colors.white,
                size: 20,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                    Text(
                  message,
                ),
              ),
            ],
          ),

          behavior:
              SnackBarBehavior.floating,

          backgroundColor:
              error
                  ? const Color(
                      0xFFC94242,
                    )
                  : const Color(
                      0xFF21855F,
                    ),

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      );
  }

  /* =========================================================
     FORMATADORES
  ========================================================= */

  String _apiDate(
    DateTime value,
  ) {
    final year =
        value.year
            .toString()
            .padLeft(
              4,
              '0',
            );

    final month =
        value.month
            .toString()
            .padLeft(
              2,
              '0',
            );

    final day =
        value.day
            .toString()
            .padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }

  String _formatDate(
    DateTime value,
  ) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _formatMetaDeadline(
    dynamic value,
  ) {
    if (value == null) {
      return 'Sem prazo';
    }

    final raw =
        value.toString();

    if (raw.isEmpty) {
      return 'Sem prazo';
    }

    final date =
        DateTime.tryParse(
      raw,
    );

    if (date == null) {
      return 'Sem prazo';
    }

    return _formatDate(
      date,
    );
  }

  /* =========================================================
     BUILD
  ========================================================= */

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        body:
            const Center(
          child:
              CircularProgressIndicator(
            color: pacePrimary,
          ),
        ),
      );
    }

    return PaceShell(
      currentRoute: '/metas',

      username:
          PaceSession.username(
        _user,
      ),

      avatarValue:
          PaceSession.avatar(
        _user,
      ),

      backgroundColor: bg,

      child:
          _PageBackground(
        dark: dark,

        child:
            RefreshIndicator(
          color: pacePrimary,

          onRefresh:
              _refresh,

          child:
              SingleChildScrollView(
            physics:
                const AlwaysScrollableScrollPhysics(
              parent:
                  BouncingScrollPhysics(),
            ),

            padding:
                EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(
                            context,
                          ).width <
                      760
                  ? 18
                  : 38,

              MediaQuery.sizeOf(
                            context,
                          ).width <
                      760
                  ? 28
                  : 42,

              MediaQuery.sizeOf(
                            context,
                          ).width <
                      760
                  ? 18
                  : 38,

              80,
            ),

            child: Center(
              child:
                  ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 1120,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    _hero(),

                    const SizedBox(
                      height: 28,
                    ),

                    _summary(),

                    const SizedBox(
                      height: 26,
                    ),

                    _controls(),

                    if (_reloading) ...[
                      const SizedBox(
                        height: 12,
                      ),

                      const LinearProgressIndicator(
                        minHeight: 2,
                        color:
                            pacePrimary,
                        backgroundColor:
                            Colors
                                .transparent,
                      ),
                    ],

                    const SizedBox(
                      height: 18,
                    ),

                    _list(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /* =========================================================
     HERO
  ========================================================= */

  Widget _hero() {
    final mobile =
        MediaQuery.sizeOf(
          context,
        ).width <
        760;

    final copy =
        Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const _Badge(
          text:
              'Seu espaço de evolução',
        ),

        const SizedBox(
          height: 14,
        ),

        Text(
          'Metas que viram progresso.',

          style:
              TextStyle(
            color: text,

            fontSize:
                mobile
                    ? 38
                    : 50,

            height: 1.02,

            fontWeight:
                FontWeight.w900,

            letterSpacing:
                -1.8,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          'Organize o que importa, avance no seu ritmo e transforme objetivos em resultados.',

          style:
              TextStyle(
            color: muted,

            fontSize: 16,

            height: 1.65,
          ),
        ),
      ],
    );

    if (mobile) {
      return Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          copy,

          const SizedBox(
            height: 20,
          ),

          _newButton(),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end,

      children: [
        Expanded(
          child: copy,
        ),

        const SizedBox(
          width: 24,
        ),

        _newButton(),
      ],
    );
  }

  Widget _newButton() {
    return FilledButton.icon(
      style:
          FilledButton.styleFrom(
        backgroundColor:
            pacePrimary,

        foregroundColor:
            Colors.white,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),

        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            16,
          ),
        ),
      ),

      onPressed:
          () => _openEditor(),

      icon:
          const Icon(
        Icons.add_rounded,
      ),

      label:
          const Text(
        'Nova meta',

        style:
            TextStyle(
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  /* =========================================================
     RESUMO
  ========================================================= */

  Widget _summary() {
    final total =
        _metas.length;

    return LayoutBuilder(
      builder: (
        _,
        constraints,
      ) {
        final compact =
            constraints.maxWidth <
            680;

        final cards = [
          _StatCard(
            icon:
                Icons
                    .flag_outlined,

            label:
                'Metas criadas',

            value:
                '$total',

            dark:
                dark,
          ),

          _StatCard(
            icon:
                Icons
                    .route_rounded,

            label:
                'Em andamento',

            value:
                '$_andamento',

            dark:
                dark,
          ),

          _StatCard(
            icon:
                Icons
                    .task_alt_rounded,

            label:
                'Concluídas',

            value:
                '$_concluidas',

            dark:
                dark,
          ),
        ];

        if (compact) {
          return Column(
            children:
                cards
                    .map(
                      (card) =>
                          Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          bottom:
                              12,
                        ),
                        child:
                            card,
                      ),
                    )
                    .toList(),
          );
        }

        return Row(
          children: [
            Expanded(
              child:
                  cards[0],
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child:
                  cards[1],
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child:
                  cards[2],
            ),
          ],
        );
      },
    );
  }

  /* =========================================================
     CONTROLES
  ========================================================= */

  Widget _controls() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          'Minhas metas',

          style:
              TextStyle(
            color: text,

            fontSize: 28,

            fontWeight:
                FontWeight.w900,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        LayoutBuilder(
          builder: (
            _,
            constraints,
          ) {
            final search =
                TextField(
              controller:
                  _search,

              style:
                  TextStyle(
                color:
                    text,
              ),

              decoration:
                  _input(
                'Buscar meta...',
              ).copyWith(
                prefixIcon:
                    const Icon(
                  Icons
                      .search_rounded,
                ),

                suffixIcon:
                    _search.text
                            .isNotEmpty
                        ? IconButton(
                            onPressed:
                                () {
                              _search
                                  .clear();
                            },
                            icon:
                                const Icon(
                              Icons
                                  .close_rounded,
                            ),
                          )
                        : null,
              ),
            );

            final filters =
                Wrap(
              spacing: 8,
              runSpacing: 8,

              children: [
                _filterChip(
                  'todas',
                  'Todas',
                ),

                _filterChip(
                  'andamento',
                  'Em andamento',
                ),

                _filterChip(
                  'concluidas',
                  'Concluídas',
                ),
              ],
            );

            if (constraints
                    .maxWidth <
                760) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  search,

                  const SizedBox(
                    height: 12,
                  ),

                  filters,
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child:
                      search,
                ),

                const SizedBox(
                  width: 14,
                ),

                filters,
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _filterChip(
    String value,
    String label,
  ) {
    final active =
        _filter == value;

    return ChoiceChip(
      label:
          Text(
        label,
      ),

      selected:
          active,

      onSelected:
          (_) {
        setState(() {
          _filter =
              value;
        });
      },

      selectedColor:
          pacePrimary.withOpacity(
        0.14,
      ),

      backgroundColor:
          dark
              ? Colors.white
                  .withOpacity(
                    0.035,
                  )
              : Colors.white
                  .withOpacity(
                    0.75,
                  ),

      labelStyle:
          TextStyle(
        color:
            active
                ? pacePrimary
                : muted,

        fontWeight:
            FontWeight.w800,
      ),

      side:
          BorderSide(
        color:
            pacePrimary.withOpacity(
          active
              ? 0.24
              : 0.10,
        ),
      ),
    );
  }

  /* =========================================================
     LISTA
  ========================================================= */

  Widget _list() {
    final items =
        _filtered;

    if (items.isEmpty) {
      return _Surface(
        dark: dark,

        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 38,
            horizontal: 16,
          ),

          child:
              Center(
            child:
                Column(
              children: [
                Container(
                  width: 66,
                  height: 66,

                  alignment:
                      Alignment.center,

                  decoration:
                      BoxDecoration(
                    color:
                        pacePrimary
                            .withOpacity(
                      0.08,
                    ),

                    shape:
                        BoxShape.circle,
                  ),

                  child:
                      const Icon(
                    Icons
                        .track_changes_rounded,

                    color:
                        pacePrimary,

                    size: 34,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Text(
                  _metas.isEmpty
                      ? 'Sua primeira meta começa aqui.'
                      : 'Nenhuma meta encontrada.',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color: text,

                    fontSize: 22,

                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  _metas.isEmpty
                      ? 'Crie uma meta simples e transforme intenção em resultado.'
                      : 'Tente outro termo de busca ou selecione outro filtro.',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color: muted,

                    height: 1.5,
                  ),
                ),

                if (_metas.isEmpty) ...[
                  const SizedBox(
                    height: 18,
                  ),

                  _newButton(),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children:
          items.map(
        _metaCard,
      ).toList(),
    );
  }

  Widget _metaCard(
    Map<String, dynamic> meta,
  ) {
    final id =
        (meta['id'] as num?)
            ?.toInt();

    final completed =
        _isCompleted(meta);

    final busy =
        _busyMetaId ==
        id;

    final category =
        meta['categoria']
                ?.toString() ??
            'Outro';

    final description =
        meta['descricao']
                ?.toString() ??
            '';

    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),

      child:
          _Surface(
        dark: dark,

        borderColor:
            completed
                ? const Color(
                        0xFF2AA879,
                      )
                    .withOpacity(
                      0.20,
                    )
                : null,

        child:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Container(
                  width: 48,
                  height: 48,

                  alignment:
                      Alignment.center,

                  decoration:
                      BoxDecoration(
                    color:
                        completed
                            ? const Color(
                                    0xFF2AA879,
                                  )
                                .withOpacity(
                                  0.10,
                                )
                            : pacePrimary
                                .withOpacity(
                                  0.08,
                                ),

                    borderRadius:
                        BorderRadius
                            .circular(
                      15,
                    ),
                  ),

                  child:
                      Icon(
                    completed
                        ? Icons
                            .task_alt_rounded
                        : Icons
                            .flag_outlined,

                    color:
                        completed
                            ? const Color(
                                0xFF2AA879,
                              )
                            : pacePrimary,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 7,
                        crossAxisAlignment:
                            WrapCrossAlignment
                                .center,

                        children: [
                          Text(
                            meta['titulo']
                                    ?.toString() ??
                                '',

                            style:
                                TextStyle(
                              color:
                                  completed
                                      ? text.withOpacity(
                                          0.86,
                                        )
                                      : text,

                              fontSize:
                                  18,

                              fontWeight:
                                  FontWeight
                                      .w900,
                            ),
                          ),

                          _StatusBadge(
                            completed:
                                completed,

                            dark:
                                dark,
                          ),
                        ],
                      ),

                      if (description
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          description,

                          style:
                              TextStyle(
                            color:
                                muted,

                            height:
                                1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                PopupMenuButton<String>(
                  enabled:
                      !busy,

                  tooltip:
                      'Opções',

                  color:
                      dark
                          ? const Color(
                              0xFF101B2D,
                            )
                          : Colors.white,

                  icon:
                      busy
                          ? const SizedBox(
                              width:
                                  22,
                              height:
                                  22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2.3,
                                color:
                                    pacePrimary,
                              ),
                            )
                          : Icon(
                              Icons
                                  .more_horiz_rounded,
                              color:
                                  muted,
                            ),

                  onSelected:
                      (value) {
                    if (value ==
                        'edit') {
                      _openEditor(
                        meta,
                      );
                    }

                    if (value ==
                        'delete') {
                      _delete(
                        meta,
                      );
                    }
                  },

                  itemBuilder:
                      (_) => [
                    const PopupMenuItem(
                      value:
                          'edit',
                      child:
                          Row(
                        children: [
                          Icon(
                            Icons
                                .edit_outlined,
                            size: 19,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Editar',
                          ),
                        ],
                      ),
                    ),

                    const PopupMenuItem(
                      value:
                          'delete',
                      child:
                          Row(
                        children: [
                          Icon(
                            Icons
                                .delete_outline_rounded,
                            size: 19,
                            color:
                                Color(
                              0xFFE45454,
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            'Excluir',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            Wrap(
              spacing: 8,
              runSpacing: 8,

              children: [
                _MetaInfoChip(
                  icon:
                      Icons
                          .sell_outlined,

                  text:
                      category,

                  dark:
                      dark,
                ),

                _MetaInfoChip(
                  icon:
                      Icons
                          .calendar_month_outlined,

                  text:
                      _formatMetaDeadline(
                    meta['prazo'],
                  ),

                  dark:
                      dark,
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            Container(
              height: 1,
              color:
                  pacePrimary.withOpacity(
                0.07,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            SizedBox(
              width:
                  double.infinity,

              child:
                  completed
                      ? OutlinedButton.icon(
                          onPressed:
                              busy
                                  ? null
                                  : () =>
                                      _toggleStatus(
                                        meta,
                                      ),

                          icon:
                              const Icon(
                            Icons
                                .restart_alt_rounded,
                          ),

                          label:
                              const Text(
                            'Reabrir meta',
                          ),

                          style:
                              OutlinedButton
                                  .styleFrom(
                            foregroundColor:
                                pacePrimary,

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical:
                                  14,
                            ),

                            side:
                                BorderSide(
                              color:
                                  pacePrimary
                                      .withOpacity(
                                0.18,
                              ),
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed:
                              busy
                                  ? null
                                  : () =>
                                      _toggleStatus(
                                        meta,
                                      ),

                          icon:
                              const Icon(
                            Icons
                                .check_circle_outline_rounded,
                          ),

                          label:
                              const Text(
                            'Marcar como concluída',
                          ),

                          style:
                              FilledButton
                                  .styleFrom(
                            backgroundColor:
                                const Color(
                              0xFF2AA879,
                            ),

                            foregroundColor:
                                Colors.white,

                            padding:
                                const EdgeInsets
                                    .symmetric(
                              vertical:
                                  14,
                            ),

                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /* =========================================================
     INPUTS
  ========================================================= */

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    int lines = 1,
  }) {
    return TextField(
      controller:
          controller,

      maxLines:
          lines,

      style:
          TextStyle(
        color:
            text,
      ),

      decoration:
          _input(
        label,
      ).copyWith(
        hintText:
            hint,
      ),
    );
  }

  InputDecoration _input(
    String label,
  ) {
    return InputDecoration(
      labelText:
          label,

      labelStyle:
          TextStyle(
        color:
            muted,
      ),

      hintStyle:
          TextStyle(
        color:
            muted.withOpacity(
          0.75,
        ),
      ),

      filled:
          true,

      fillColor:
          dark
              ? Colors.white
                  .withOpacity(
                    0.035,
                  )
              : Colors.white
                  .withOpacity(
                    0.88,
                  ),

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),

        borderSide:
            BorderSide.none,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),

        borderSide:
            BorderSide(
          color:
              pacePrimary.withOpacity(
            0.10,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          16,
        ),

        borderSide:
            const BorderSide(
          color:
              pacePrimary,

          width:
              1.4,
        ),
      ),
    );
  }
}

/* =========================================================
   COMPONENTES
========================================================= */

class _PageBackground
    extends StatelessWidget {
  final bool dark;
  final Widget child;

  const _PageBackground({
    required this.dark,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration:
          BoxDecoration(
        gradient:
            LinearGradient(
          begin:
              Alignment.topCenter,

          end:
              Alignment.bottomCenter,

          colors:
              dark
                  ? const [
                      Color(
                        0xFF081120,
                      ),
                      Color(
                        0xFF050B15,
                      ),
                    ]
                  : const [
                      Color(
                        0xFFF4F8FD,
                      ),
                      Color(
                        0xFFEAF1F9,
                      ),
                      Color(
                        0xFFE4EDF8,
                      ),
                    ],
        ),
      ),

      child:
          child,
    );
  }
}

class _Badge
    extends StatelessWidget {
  final String text;

  const _Badge({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),

      decoration:
          BoxDecoration(
        color:
            pacePrimary.withOpacity(
          0.09,
        ),

        borderRadius:
            BorderRadius.circular(
          999,
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width: 7,
            height: 7,

            decoration:
                const BoxDecoration(
              color:
                  paceAccent,

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          Text(
            text,

            style:
                const TextStyle(
              color:
                  pacePrimary,

              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Surface
    extends StatelessWidget {
  final bool dark;
  final Widget child;
  final Color? borderColor;

  const _Surface({
    required this.dark,
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,

      padding:
          const EdgeInsets.all(
        20,
      ),

      decoration:
          BoxDecoration(
        color:
            dark
                ? const Color(
                    0xFF0C1627,
                  )
                : Colors.white
                    .withOpacity(
                      0.94,
                    ),

        borderRadius:
            BorderRadius.circular(
          24,
        ),

        border:
            Border.all(
          color:
              borderColor ??
                  (
                    dark
                        ? Colors.white
                            .withOpacity(
                              0.055,
                            )
                        : pacePrimary
                            .withOpacity(
                              0.10,
                            )
                  ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                const Color(
                  0xFF15284D,
                ).withOpacity(
              dark
                  ? 0.18
                  : 0.08,
            ),

            blurRadius:
                30,

            offset:
                const Offset(
              0,
              14,
            ),
          ),
        ],
      ),

      child:
          child,
    );
  }
}

class _StatCard
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool dark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.dark,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final text =
        dark
            ? const Color(
                0xFFF2F6FF,
              )
            : const Color(
                0xFF172033,
              );

    final muted =
        dark
            ? const Color(
                0xFF98A8BF,
              )
            : const Color(
                0xFF6F7F96,
              );

    return _Surface(
      dark:
          dark,

      child:
          Row(
        children: [
          Container(
            width: 48,
            height: 48,

            alignment:
                Alignment.center,

            decoration:
                BoxDecoration(
              color:
                  pacePrimary
                      .withOpacity(
                0.08,
              ),

              borderRadius:
                  BorderRadius.circular(
                15,
              ),
            ),

            child:
                Icon(
              icon,
              color:
                  pacePrimary,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  value,

                  style:
                      TextStyle(
                    color:
                        text,

                    fontSize:
                        24,

                    fontWeight:
                        FontWeight
                            .w900,
                  ),
                ),

                Text(
                  label,

                  style:
                      TextStyle(
                    color:
                        muted,

                    fontSize:
                        12.5,

                    fontWeight:
                        FontWeight
                            .w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge
    extends StatelessWidget {
  final bool completed;
  final bool dark;

  const _StatusBadge({
    required this.completed,
    required this.dark,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final color =
        completed
            ? const Color(
                0xFF2AA879,
              )
            : const Color(
                0xFFD99035,
              );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration:
          BoxDecoration(
        color:
            color.withOpacity(
          dark
              ? 0.15
              : 0.10,
        ),

        borderRadius:
            BorderRadius.circular(
          999,
        ),

        border:
            Border.all(
          color:
              color.withOpacity(
            0.16,
          ),
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Container(
            width: 7,
            height: 7,

            decoration:
                BoxDecoration(
              color:
                  color,

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            completed
                ? 'Concluída'
                : 'Em andamento',

            style:
                TextStyle(
              color:
                  color,

              fontSize:
                  11.5,

              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaInfoChip
    extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool dark;

  const _MetaInfoChip({
    required this.icon,
    required this.text,
    required this.dark,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final textColor =
        dark
            ? const Color(
                0xFF98A8BF,
              )
            : const Color(
                0xFF66768D,
              );

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),

      decoration:
          BoxDecoration(
        color:
            pacePrimary.withOpacity(
          dark
              ? 0.075
              : 0.055,
        ),

        borderRadius:
            BorderRadius.circular(
          11,
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 15,
            color:
                pacePrimary,
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            text,

            style:
                TextStyle(
              color:
                  textColor,

              fontSize:
                  11.5,

              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaceApiException
    implements Exception {
  final String message;
  final int? statusCode;

  const _PaceApiException(
    this.message, {
    this.statusCode,
  });

  @override
  String toString() =>
      message;
}