import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'pace_session.dart';
import 'pace_shell.dart';

class FocoPage extends StatefulWidget {
  const FocoPage({super.key});

  @override
  State<FocoPage> createState() => _FocoPageState();
}

class _FocoPageState extends State<FocoPage> {
  final TextEditingController _intention =
      TextEditingController();

  Map<String, dynamic> _user = {};

  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _metas = [];

  Timer? _timer;

  int _durationMinutes = 25;
  int _remainingSeconds = 25 * 60;

  bool _running = false;
  bool _paused = false;
  bool _immersive = false;
  bool _loading = true;
  bool _finishing = false;
  bool _clearingHistory = false;

  int? _linkedMetaId;

  DateTime? _startedAt;

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

  List<Map<String, dynamic>> get _activeMetas {
    return _metas
        .where(
          (meta) =>
              meta['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ==
              'em andamento',
        )
        .toList();
  }

  Map<String, dynamic>? get _selectedMeta {
    if (_linkedMetaId == null) {
      return null;
    }

    for (final meta in _metas) {
      if (meta['id'] == _linkedMetaId) {
        return meta;
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();

    _intention.addListener(
      _onIntentionChanged,
    );

    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();

    _intention.removeListener(
      _onIntentionChanged,
    );

    _intention.dispose();

    super.dispose();
  }

  void _onIntentionChanged() {
    if (!mounted || _running) {
      return;
    }

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

    final headers =
        <String, String>{};

    if (token != null &&
        token.isNotEmpty) {
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

    final uri =
        ApiConfig.uri(
      endpoint,
    );

    late http.Response response;

    try {
      switch (method) {
        case 'POST':
          response = await http
              .post(
                uri,
                headers: headers,
                body: body == null
                    ? null
                    : jsonEncode(
                        body,
                      ),
              )
              .timeout(
                const Duration(
                  seconds: 10,
                ),
              );

          break;

        case 'DELETE':
          response = await http
              .delete(
                uri,
                headers: headers,
              )
              .timeout(
                const Duration(
                  seconds: 10,
                ),
              );

          break;

        default:
          response = await http
              .get(
                uri,
                headers: headers,
              )
              .timeout(
                const Duration(
                  seconds: 10,
                ),
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
        statusCode:
            response.statusCode,
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
              'Meta',

      'descricao':
          map['descricao']
                  ?.toString() ??
              '',

      'categoria':
          map['categoria']
                  ?.toString() ??
              'Outro',

      'status':
          status == 'concluida'
              ? 'concluida'
              : 'em andamento',

      'prazo':
          map['prazo']
              ?.toString(),
    };
  }

  Map<String, dynamic> _normalizeSession(
    dynamic value,
    Map<String, dynamic> meta,
  ) {
    if (value is! Map) {
      return {};
    }

    final map =
        Map<String, dynamic>.from(
      value,
    );

    /*
      O BACKEND TRABALHA EM MINUTOS.
    */

    final minutes =
        (map['duracao'] as num?)
                ?.toInt() ??
            0;

    return {
      'id':
          (map['id'] as num?)
              ?.toInt(),

      'metaId':
          (map['id_meta'] as num?)
                  ?.toInt() ??
              meta['id'],

      'metaTitulo':
          meta['titulo']
                  ?.toString() ??
              'Meta',

      'intencao':
          'Foco em ${meta['titulo'] ?? 'Meta'}',

      'minutos':
          minutes,

      'data':
          map['inicio']
              ?.toString(),

      'concluida':
          true,
    };
  }

  /* =========================================================
     CARREGAMENTO
  ========================================================= */

  Future<void> _load() async {
    try {
      final user =
          await PaceSession.currentUser();

      final metasResponse =
          await _request(
        '/metas/listar_metas',
      );

      final metas =
          metasResponse is List
              ? metasResponse
                  .map(_normalizeMeta)
                  .where(
                    (item) =>
                        item.isNotEmpty,
                  )
                  .toList()
              : <Map<String, dynamic>>[];

      final history =
          await _loadHistoryForMetas(
        metas,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _metas = metas;
        _history = history;

        /*
          Caso uma meta selecionada anteriormente
          tenha sido concluída ou removida.
        */

        if (_linkedMetaId != null &&
            !_activeMetas.any(
              (meta) =>
                  meta['id'] ==
                  _linkedMetaId,
            )) {
          _linkedMetaId = null;
        }

        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      _handleError(
        error,
      );
    }
  }

  Future<List<Map<String, dynamic>>>
      _loadHistoryForMetas(
    List<Map<String, dynamic>> metas,
  ) async {
    final history =
        <Map<String, dynamic>>[];

    /*
      A API atual lista sessões por meta.

      Portanto buscamos as sessões de cada meta
      e depois juntamos tudo em uma única lista.
    */

    for (final meta in metas) {
      final id =
          (meta['id'] as num?)
              ?.toInt();

      if (id == null) {
        continue;
      }

      try {
        final response =
            await _request(
          '/sessoes/meta/$id',
        );

        if (response is! List) {
          continue;
        }

        for (final item in response) {
          final session =
              _normalizeSession(
            item,
            meta,
          );

          if (session.isNotEmpty) {
            history.add(
              session,
            );
          }
        }
      } on _PaceApiException catch (error) {
        if (error.statusCode == 401) {
          rethrow;
        }

        /*
          Se uma meta específica falhar,
          não derruba toda a Sala de Foco.
        */
      }
    }

    history.sort(
      (a, b) {
        final dateA =
            DateTime.tryParse(
                  a['data']
                          ?.toString() ??
                      '',
                ) ??
                DateTime.fromMillisecondsSinceEpoch(
                  0,
                );

        final dateB =
            DateTime.tryParse(
                  b['data']
                          ?.toString() ??
                      '',
                ) ??
                DateTime.fromMillisecondsSinceEpoch(
                  0,
                );

        return dateB.compareTo(
          dateA,
        );
      },
    );

    return history;
  }

  Future<void> _refreshData() async {
    try {
      final metasResponse =
          await _request(
        '/metas/listar_metas',
      );

      final metas =
          metasResponse is List
              ? metasResponse
                  .map(_normalizeMeta)
                  .where(
                    (item) =>
                        item.isNotEmpty,
                  )
                  .toList()
              : <Map<String, dynamic>>[];

      final history =
          await _loadHistoryForMetas(
        metas,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _metas = metas;
        _history = history;

        final selectedStillValid =
            _linkedMetaId == null ||
                metas.any(
                  (meta) =>
                      meta['id'] ==
                          _linkedMetaId &&
                      meta['status'] ==
                          'em andamento',
                );

        if (!selectedStillValid) {
          _linkedMetaId = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      _handleError(
        error,
      );
    }
  }

  /* =========================================================
     TIMER
  ========================================================= */

  void _setDuration(
    int minutes,
  ) {
    if (_running) {
      return;
    }

    setState(() {
      _durationMinutes =
          minutes;

      _remainingSeconds =
          minutes * 60;
    });
  }

  void _start() {
    if (_running) {
      if (_paused) {
        setState(() {
          _paused = false;
        });

        _startTicker();
      }

      return;
    }

    /*
      O BACKEND EXIGE UMA META.
    */

    if (_linkedMetaId == null) {
      _snack(
        'Escolha uma meta em andamento antes de iniciar.',
        error: true,
      );

      return;
    }

    final selected =
        _selectedMeta;

    if (selected == null ||
        selected['status'] !=
            'em andamento') {
      _snack(
        'A meta selecionada não está mais disponível.',
        error: true,
      );

      return;
    }

    setState(() {
      _running = true;
      _paused = false;

      _startedAt =
          DateTime.now();
    });

    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();

    _timer =
        Timer.periodic(
      const Duration(
        seconds: 1,
      ),
      (_) {
        if (!mounted ||
            _paused) {
          return;
        }

        if (_remainingSeconds <= 1) {
          setState(() {
            _remainingSeconds = 0;
          });

          _finish(
            completed: true,
          );

          return;
        }

        setState(() {
          _remainingSeconds--;
        });
      },
    );
  }

  void _pause() {
    if (!_running) {
      return;
    }

    _timer?.cancel();

    setState(() {
      _paused = true;
    });
  }

  void _reset() {
    _timer?.cancel();

    setState(() {
      _running = false;
      _paused = false;
      _immersive = false;

      _startedAt = null;

      _remainingSeconds =
          _durationMinutes *
          60;
    });
  }

  /* =========================================================
     FINALIZAR + API
  ========================================================= */

  Future<void> _finish({
    bool completed = false,
  }) async {
    if (_finishing) {
      return;
    }

    if (!_running &&
        _startedAt == null) {
      return;
    }

    if (_linkedMetaId == null) {
      _snack(
        'Nenhuma meta vinculada à sessão.',
        error: true,
      );

      return;
    }

    _timer?.cancel();

    /*
      O TIMER TRABALHA EM SEGUNDOS.
    */

    final totalSeconds =
        _durationMinutes *
        60;

    final elapsedSeconds =
        completed
            ? totalSeconds
            : (
                totalSeconds -
                _remainingSeconds
              ).clamp(
                0,
                totalSeconds,
              );

    /*
      BACKEND TRABALHA EM MINUTOS.

      1500 segundos -> 25 minutos.
    */

    final minutes =
        completed
            ? _durationMinutes
            : (elapsedSeconds / 60)
                .ceil()
                .clamp(
                  1,
                  _durationMinutes,
                );

    if (elapsedSeconds < 10 &&
        !completed) {
      _snack(
        'A sessão foi curta demais para ser registrada.',
        error: true,
      );

      _reset();

      return;
    }

    final metaId =
        _linkedMetaId!;

    final meta =
        _selectedMeta;

    if (meta == null) {
      _snack(
        'A meta vinculada não foi encontrada.',
        error: true,
      );

      return;
    }

    final startedAt =
        _startedAt ??
        DateTime.now();

    setState(() {
      _finishing = true;
    });

    try {
      final response =
          await _request(
        '/sessoes/criar_sessao',

        method: 'POST',

        body: {
          'id_meta':
              metaId,

          'inicio':
              startedAt
                  .toIso8601String(),

          /*
            IMPORTANTE:
            É MINUTOS.
          */
          'duracao':
              minutes,
        },
      );

      final session =
          _normalizeSession(
        response,
        meta,
      );

      /*
        A intenção não existe no modelo do backend.

        Para a sessão recém-concluída,
        podemos mostrar a intenção digitada
        enquanto a tela estiver aberta.
      */

      session['intencao'] =
          _intention.text
                  .trim()
                  .isEmpty
              ? 'Foco em ${meta['titulo']}'
              : _intention.text
                  .trim();

      if (!mounted) {
        return;
      }

      setState(() {
        _history.insert(
          0,
          session,
        );

        _running = false;
        _paused = false;
        _immersive = false;
        _startedAt = null;

        _remainingSeconds =
            _durationMinutes *
            60;
      });

      _snack(
        'Sessão registrada: $minutes min de foco. 🔥',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      /*
        Se a API falhar, a sessão não é apagada.
        O usuário pode tentar finalizar novamente.
      */

      setState(() {
        _running = true;
        _paused = true;
      });

      _handleError(
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _finishing = false;
        });
      }
    }
  }

  /* =========================================================
     HISTÓRICO
  ========================================================= */

  Future<void> _clearHistory() async {
    if (_history.isEmpty ||
        _clearingHistory) {
      return;
    }

    final confirmed =
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
                .delete_sweep_outlined,
            color:
                Color(
              0xFFE45454,
            ),
            size: 34,
          ),

          title:
              Text(
            'Limpar histórico?',
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
            'Todas as sessões de foco registradas serão removidas da sua conta.',
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

            FilledButton(
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

              child:
                  const Text(
                'Limpar histórico',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _clearingHistory =
          true;
    });

    try {
      final sessions =
          List<Map<String, dynamic>>.from(
        _history,
      );

      var failures = 0;

      for (final session in sessions) {
        final id =
            (session['id'] as num?)
                ?.toInt();

        if (id == null) {
          continue;
        }

        try {
          await _request(
            '/sessoes/deletar_sessao/$id',
            method: 'DELETE',
          );
        } catch (_) {
          failures++;
        }
      }

      await _refreshData();

      if (!mounted) {
        return;
      }

      if (failures == 0) {
        _snack(
          'Histórico removido.',
        );
      } else {
        _snack(
          '$failures sessão(ões) não puderam ser removidas.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _clearingHistory =
              false;
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
          if (!mounted) {
            return;
          }

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
    if (!mounted) {
      return;
    }

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

          backgroundColor:
              error
                  ? const Color(
                      0xFFC94242,
                    )
                  : const Color(
                      0xFF21855F,
                    ),

          behavior:
              SnackBarBehavior.floating,

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
     CLOCK
  ========================================================= */

  String get _clock {
    final minutes =
        _remainingSeconds ~/
        60;

    final seconds =
        _remainingSeconds %
        60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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
        backgroundColor:
            bg,

        body:
            const Center(
          child:
              CircularProgressIndicator(
            color:
                pacePrimary,
          ),
        ),
      );
    }

    final page =
        _immersive
            ? _immersiveView()
            : _normalView();

    return PaceShell(
      currentRoute:
          '/foco',

      username:
          PaceSession.username(
        _user,
      ),

      avatarValue:
          PaceSession.avatar(
        _user,
      ),

      backgroundColor:
          bg,

      child:
          page,
    );
  }

  /* =========================================================
     NORMAL VIEW
  ========================================================= */

  Widget _normalView() {
    final mobile =
        MediaQuery.sizeOf(
          context,
        ).width <
        760;

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
          RefreshIndicator(
        color:
            pacePrimary,

        onRefresh:
            _refreshData,

        child:
            SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(
            parent:
                BouncingScrollPhysics(),
          ),

          padding:
              EdgeInsets.fromLTRB(
            mobile
                ? 18
                : 38,

            mobile
                ? 28
                : 42,

            mobile
                ? 18
                : 38,

            80,
          ),

          child:
              Center(
            child:
                ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth:
                    1120,
              ),

              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  _hero(
                    mobile,
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  _focusPanel(
                    mobile,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  _configuration(),

                  const SizedBox(
                    height: 24,
                  ),

                  _summary(),

                  const SizedBox(
                    height: 24,
                  ),

                  _historyPanel(),
                ],
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

  Widget _hero(
    bool mobile,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const _FocusBadge(
          text:
              'Entre no seu ritmo',
        ),

        const SizedBox(
          height: 14,
        ),

        Text.rich(
          TextSpan(
            text:
                'Silencie o ruído. ',

            children: [
              TextSpan(
                text:
                    'Faça acontecer.',

                style:
                    const TextStyle(
                  color:
                      pacePrimary,
                ),
              ),
            ],
          ),

          style:
              TextStyle(
            color:
                text,

            fontSize:
                mobile
                    ? 38
                    : 50,

            height:
                1.02,

            fontWeight:
                FontWeight.w900,

            letterSpacing:
                -1.7,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          'Escolha uma meta, defina seu tempo e transforme alguns minutos de presença em progresso real.',

          style:
              TextStyle(
            color:
                muted,

            fontSize:
                16,

            height:
                1.65,
          ),
        ),
      ],
    );
  }

  /* =========================================================
     TIMER PRINCIPAL
  ========================================================= */

  Widget _focusPanel(
    bool mobile,
  ) {
    final meta =
        _selectedMeta;

    final intention =
        _intention.text
            .trim();

    return _FocusSurface(
      dark:
          dark,

      child:
          Column(
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,

            children: [
              Container(
                width: 8,
                height: 8,

                decoration:
                    BoxDecoration(
                  color:
                      _running &&
                              !_paused
                          ? const Color(
                              0xFF2AA879,
                            )
                          : paceAccent,

                  shape:
                      BoxShape.circle,
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                _running
                    ? (
                        _paused
                            ? 'SESSÃO PAUSADA'
                            : 'FOCO ATIVO'
                      )
                    : 'PREPARAÇÃO',

                style:
                    TextStyle(
                  color:
                      _running &&
                              !_paused
                          ? const Color(
                              0xFF2AA879,
                            )
                          : muted,

                  fontSize:
                      11,

                  letterSpacing:
                      1.1,

                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            _running
                ? (
                    _paused
                        ? 'Pausado. Seu foco continua aqui.'
                        : 'Agora é só você e a sua intenção.'
                  )
                : 'Pronto para começar?',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  text,

              fontSize:
                  22,

              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 22,
          ),

          Text(
            _clock,

            style:
                TextStyle(
              color:
                  text,

              fontSize:
                  mobile
                      ? 66
                      : 88,

              height:
                  1,

              fontWeight:
                  FontWeight.w900,

              letterSpacing:
                  -3,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          if (intention.isNotEmpty)
            Text(
              intention,

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    muted,

                fontWeight:
                    FontWeight.w700,
              ),
            )
          else if (meta != null)
            Text(
              'Foco em ${meta['titulo']}',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    muted,

                fontWeight:
                    FontWeight.w700,
              ),
            )
          else
            Text(
              'Escolha uma meta para iniciar.',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    muted,

                fontWeight:
                    FontWeight.w700,
              ),
            ),

          if (meta != null) ...[
            const SizedBox(
              height: 14,
            ),

            _SelectedGoalPill(
              title:
                  meta['titulo']
                          ?.toString() ??
                      'Meta',

              dark:
                  dark,
            ),
          ],

          const SizedBox(
            height: 26,
          ),

          Wrap(
            spacing:
                10,

            runSpacing:
                10,

            alignment:
                WrapAlignment.center,

            children: [
              OutlinedButton.icon(
                onPressed:
                    _finishing
                        ? null
                        : _reset,

                icon:
                    const Icon(
                  Icons
                      .restart_alt_rounded,
                ),

                label:
                    const Text(
                  'Resetar',
                ),
              ),

              FilledButton.icon(
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      pacePrimary,

                  foregroundColor:
                      Colors.white,

                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        18,
                    vertical:
                        14,
                  ),
                ),

                onPressed:
                    _finishing
                        ? null
                        : (
                            _running
                                ? (
                                    _paused
                                        ? _start
                                        : _pause
                                  )
                                : _start
                          ),

                icon:
                    Icon(
                  _running &&
                          !_paused
                      ? Icons
                          .pause_rounded
                      : Icons
                          .play_arrow_rounded,
                ),

                label:
                    Text(
                  _running
                      ? (
                          _paused
                              ? 'Continuar'
                              : 'Pausar'
                        )
                      : 'Iniciar foco',
                ),
              ),

              if (_running)
                OutlinedButton.icon(
                  onPressed:
                      _finishing
                          ? null
                          : () =>
                              _confirmFinish(),

                  icon:
                      _finishing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    pacePrimary,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .stop_circle_outlined,
                            ),

                  label:
                      const Text(
                    'Finalizar',
                  ),
                ),

              if (_running)
                OutlinedButton.icon(
                  onPressed:
                      () {
                    setState(() {
                      _immersive =
                          true;
                    });
                  },

                  icon:
                      const Icon(
                    Icons
                        .fullscreen_rounded,
                  ),

                  label:
                      const Text(
                    'Modo imersivo',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /* =========================================================
     CONFIRMAR FINALIZAÇÃO
  ========================================================= */

  Future<void> _confirmFinish() async {
    final confirmed =
        await showDialog<bool>(
      context:
          context,

      barrierColor:
          Colors.black54,

      builder:
          (
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
                .timer_outlined,
            color:
                pacePrimary,
            size: 36,
          ),

          title:
              Text(
            'Finalizar sessão?',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  text,

              fontWeight:
                  FontWeight.w900,
            ),
          ),

          content:
              Text(
            'O tempo focado até agora será salvo no Pace.',

            textAlign:
                TextAlign.center,

            style:
                TextStyle(
              color:
                  muted,

              height:
                  1.5,
            ),
          ),

          actionsAlignment:
              MainAxisAlignment.center,

          actions: [
            TextButton(
              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child:
                  const Text(
                'Continuar focando',
              ),
            ),

            FilledButton(
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    pacePrimary,
              ),

              onPressed:
                  () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child:
                  const Text(
                'Finalizar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _finish();
    }
  }

  /* =========================================================
     CONFIGURAÇÃO
  ========================================================= */

  Widget _configuration() {
    return _FocusSurface(
      dark:
          dark,

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,

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
                    14,
                  ),
                ),

                child:
                    const Icon(
                  Icons
                      .tune_rounded,

                  color:
                      pacePrimary,
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Configure sua sessão',

                      style:
                          TextStyle(
                        color:
                            text,

                        fontSize:
                            24,

                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Defina onde sua atenção vai estar.',

                      style:
                          TextStyle(
                        color:
                            muted,

                        fontSize:
                            12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          TextField(
            controller:
                _intention,

            enabled:
                !_running,

            style:
                TextStyle(
              color:
                  text,
            ),

            decoration:
                _input(
              'Intenção da sessão',
              'Ex.: Revisar a matéria da prova',
            ).copyWith(
              prefixIcon:
                  const Icon(
                Icons
                    .auto_awesome_outlined,
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            'Meta da sessão',

            style:
                TextStyle(
              color:
                  muted,

              fontSize:
                  12.5,

              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          _goalPicker(),

          const SizedBox(
            height: 20,
          ),

          Row(
            children: [
              Text(
                'Duração',

                style:
                    TextStyle(
                  color:
                      muted,

                  fontWeight:
                      FontWeight.w800,
                ),
              ),

              const Spacer(),

              Text(
                '$_durationMinutes min',

                style:
                    const TextStyle(
                  color:
                      pacePrimary,

                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Wrap(
            spacing: 9,
            runSpacing: 9,

            children: [
              15,
              25,
              45,
              60,
            ].map(
              (minutes) {
                final selected =
                    _durationMinutes ==
                    minutes;

                return ChoiceChip(
                  selected:
                      selected,

                  label:
                      Text(
                    '$minutes min',
                  ),

                  onSelected:
                      _running
                          ? null
                          : (_) =>
                              _setDuration(
                                minutes,
                              ),

                  selectedColor:
                      pacePrimary
                          .withOpacity(
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
                                0.65,
                              ),

                  labelStyle:
                      TextStyle(
                    color:
                        selected
                            ? pacePrimary
                            : muted,

                    fontWeight:
                        FontWeight.w800,
                  ),

                  side:
                      BorderSide(
                    color:
                        pacePrimary
                            .withOpacity(
                      selected
                          ? 0.25
                          : 0.10,
                    ),
                  ),
                );
              },
            ).toList(),
          ),

          const SizedBox(
            height: 18,
          ),

          Container(
            width:
                double.infinity,

            padding:
                const EdgeInsets.all(
              14,
            ),

            decoration:
                BoxDecoration(
              color:
                  pacePrimary
                      .withOpacity(
                dark
                    ? 0.08
                    : 0.05,
              ),

              borderRadius:
                  BorderRadius.circular(
                16,
              ),

              border:
                  Border.all(
                color:
                    pacePrimary
                        .withOpacity(
                  0.08,
                ),
              ),
            ),

            child:
                Row(
              children: [
                const Icon(
                  Icons
                      .shield_outlined,

                  color:
                      pacePrimary,

                  size:
                      21,
                ),

                const SizedBox(
                  width: 11,
                ),

                Expanded(
                  child:
                      Text(
                    'A sessão será registrada na meta escolhida quando você finalizar o foco.',

                    style:
                        TextStyle(
                      color:
                          muted,

                      fontSize:
                          12,

                      height:
                          1.45,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     SELETOR BONITO DE META
  ========================================================= */

  Widget _goalPicker() {
    final selected =
        _selectedMeta;

    return InkWell(
      onTap:
          _running
              ? null
              : _openGoalPicker,

      borderRadius:
          BorderRadius.circular(
        16,
      ),

      child:
          Container(
        width:
            double.infinity,

        padding:
            const EdgeInsets.symmetric(
          horizontal:
              14,

          vertical:
              13,
        ),

        decoration:
            BoxDecoration(
          color:
              dark
                  ? Colors.white
                      .withOpacity(
                        0.035,
                      )
                  : Colors.white
                      .withOpacity(
                        0.88,
                      ),

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border:
              Border.all(
            color:
                selected != null
                    ? pacePrimary
                        .withOpacity(
                          0.28,
                        )
                    : pacePrimary
                        .withOpacity(
                          0.10,
                        ),
          ),
        ),

        child:
            Row(
          children: [
            Container(
              width: 44,
              height: 44,

              alignment:
                  Alignment.center,

              decoration:
                  BoxDecoration(
                color:
                    pacePrimary
                        .withOpacity(
                  0.09,
                ),

                borderRadius:
                    BorderRadius.circular(
                  13,
                ),
              ),

              child:
                  const Icon(
                Icons
                    .track_changes_rounded,

                color:
                    pacePrimary,

                size:
                    22,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    selected == null
                        ? 'Selecione uma meta em andamento'
                        : selected['titulo']
                                ?.toString() ??
                            'Meta',

                    maxLines:
                        1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        TextStyle(
                      color:
                          selected == null
                              ? muted
                              : text,

                      fontSize:
                          14,

                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    selected == null
                        ? '${_activeMetas.length} disponível(is)'
                        : 'Meta em andamento',

                    style:
                        TextStyle(
                      color:
                          selected == null
                              ? muted.withOpacity(
                                  0.8,
                                )
                              : const Color(
                                  0xFFD99035,
                                ),

                      fontSize:
                          11.5,

                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            Icon(
              Icons
                  .keyboard_arrow_down_rounded,

              color:
                  _running
                      ? muted.withOpacity(
                          0.45,
                        )
                      : pacePrimary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoalPicker() async {
    if (_running) {
      return;
    }

    if (_activeMetas.isEmpty) {
      final goToMetas =
          await showDialog<bool>(
        context:
            context,

        builder:
            (
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
                  .track_changes_rounded,
              color:
                  pacePrimary,
              size:
                  38,
            ),

            title:
                Text(
              'Nenhuma meta em andamento',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    text,

                fontWeight:
                    FontWeight.w900,
              ),
            ),

            content:
                Text(
              'Crie ou reabra uma meta antes de iniciar uma sessão de foco.',

              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                color:
                    muted,

                height:
                    1.5,
              ),
            ),

            actionsAlignment:
                MainAxisAlignment.center,

            actions: [
              TextButton(
                onPressed:
                    () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },

                child:
                    const Text(
                  'Agora não',
                ),
              ),

              FilledButton(
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      pacePrimary,
                ),

                onPressed:
                    () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },

                child:
                    const Text(
                  'Ir para Metas',
                ),
              ),
            ],
          );
        },
      );

      if (goToMetas == true &&
          mounted) {
        Navigator.of(context)
            .pushNamed(
          '/metas',
        );
      }

      return;
    }

    final selected =
        await showModalBottomSheet<int>(
      context:
          context,

      isScrollControlled:
          true,

      backgroundColor:
          Colors.transparent,

      builder:
          (
        sheetContext,
      ) {
        return _GoalPickerSheet(
          metas:
              _activeMetas,

          selectedId:
              _linkedMetaId,

          dark:
              dark,
        );
      },
    );

    if (selected == null ||
        !mounted) {
      return;
    }

    setState(() {
      _linkedMetaId =
          selected;
    });
  }

  /* =========================================================
     RESUMO
  ========================================================= */

  Widget _summary() {
    final now =
        DateTime.now();

   final todayMinutes =
    _history
        .where((session) {
          final date = DateTime.tryParse(
            session['data']?.toString() ?? '',
          );

          if (date == null) {
            return false;
          }

          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold<int>(
          0,
          (total, session) {
            final sessionMinutes =
                (session['minutos'] as num?)?.toInt() ?? 0;

            return total + sessionMinutes;
          },
        );

    final bestDay =
        _bestDayMinutes();

    final cards = [
      _FocusStat(
        icon:
            Icons
                .timer_outlined,

        title:
            _formatMinutes(
          todayMinutes,
        ),

        subtitle:
            'Foco hoje',

        dark:
            dark,
      ),

      _FocusStat(
        icon:
            Icons
                .task_alt_rounded,

        title:
            '${_history.length}',

        subtitle:
            'Sessões concluídas',

        dark:
            dark,
      ),

      _FocusStat(
        icon:
            Icons
                .calendar_month_outlined,

        title:
            bestDay > 0
                ? _formatMinutes(
                    bestDay,
                  )
                : '—',

        subtitle:
            'Melhor dia',

        dark:
            dark,
      ),
    ];

    return LayoutBuilder(
      builder:
          (
        _,
        constraints,
      ) {
        if (constraints.maxWidth <
            680) {
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

  int _bestDayMinutes() {
    final days =
        <String, int>{};

    for (final session in _history) {
      final date =
          DateTime.tryParse(
        session['data']
                ?.toString() ??
            '',
      );

      if (date == null) {
        continue;
      }

      final key =
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      final sessionMinutes =
    (session['minutos'] as num?)?.toInt() ?? 0;

days[key] = (days[key] ?? 0) + sessionMinutes;
    }

    if (days.isEmpty) {
      return 0;
    }

    return days.values.reduce(
      (
        a,
        b,
      ) =>
          a > b
              ? a
              : b,
    );
  }

  String _formatMinutes(
    int minutes,
  ) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours =
        minutes ~/
        60;

    final remaining =
        minutes %
        60;

    if (remaining == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remaining}min';
  }

  /* =========================================================
     HISTÓRICO
  ========================================================= */

  Widget _historyPanel() {
    return _FocusSurface(
      dark:
          dark,

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      'Suas sessões recentes',

                      style:
                          TextStyle(
                        color:
                            text,

                        fontSize:
                            24,

                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Histórico sincronizado com sua conta.',

                      style:
                          TextStyle(
                        color:
                            muted,

                        fontSize:
                            12,
                      ),
                    ),
                  ],
                ),
              ),

              if (_history.isNotEmpty)
                TextButton.icon(
                  onPressed:
                      _clearingHistory
                          ? null
                          : _clearHistory,

                  icon:
                      _clearingHistory
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .delete_sweep_outlined,
                              size:
                                  18,
                            ),

                  label:
                      const Text(
                    'Limpar',
                  ),
                ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          if (_history.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical:
                    30,
              ),

              child:
                  Center(
                child:
                    Column(
                  children: [
                    Container(
                      width:
                          64,
                      height:
                          64,

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
                            .psychology_outlined,

                        color:
                            pacePrimary,

                        size:
                            34,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    Text(
                      'Seu foco ainda vai deixar marcas aqui.',

                      textAlign:
                          TextAlign.center,

                      style:
                          TextStyle(
                        color:
                            text,

                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Conclua uma sessão para começar seu histórico.',

                      textAlign:
                          TextAlign.center,

                      style:
                          TextStyle(
                        color:
                            muted,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._history
                .take(
                  8,
                )
                .map(
                  _historyItem,
                ),
        ],
      ),
    );
  }

  Widget _historyItem(
    Map<String, dynamic> session,
  ) {
    final date =
        DateTime.tryParse(
      session['data']
              ?.toString() ??
          '',
    );

    final minutes =
        (session['minutos'] as num?)
                ?.toInt() ??
            0;

    final goal =
        session['metaTitulo']
                ?.toString() ??
            '';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(
        14,
      ),

      decoration:
          BoxDecoration(
        color:
            pacePrimary.withOpacity(
          dark
              ? 0.08
              : 0.045,
        ),

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child:
          Row(
        children: [
          Container(
            width: 42,
            height: 42,

            alignment:
                Alignment.center,

            decoration:
                BoxDecoration(
              color:
                  paceAccent.withOpacity(
                0.12,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child:
                const Icon(
              Icons
                  .bolt_rounded,

              color:
                  paceAccent,

              size:
                  21,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  session['intencao']
                          ?.toString() ??
                      'Sessão de foco',

                  maxLines:
                      1,

                  overflow:
                      TextOverflow.ellipsis,

                  style:
                      TextStyle(
                    color:
                        text,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Wrap(
                  spacing:
                      6,

                  runSpacing:
                      2,

                  children: [
                    if (date != null)
                      Text(
                        '${date.day.toString().padLeft(2, '0')}/'
                        '${date.month.toString().padLeft(2, '0')}'
                        ' • '
                        '${date.hour.toString().padLeft(2, '0')}:'
                        '${date.minute.toString().padLeft(2, '0')}',

                        style:
                            TextStyle(
                          color:
                              muted,

                          fontSize:
                              11.5,
                        ),
                      ),

                    if (goal.isNotEmpty)
                      Text(
                        '• $goal',

                        maxLines:
                            1,

                        overflow:
                            TextOverflow.ellipsis,

                        style:
                            TextStyle(
                          color:
                              muted,

                          fontSize:
                              11.5,

                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  10,

              vertical:
                  7,
            ),

            decoration:
                BoxDecoration(
              color:
                  pacePrimary.withOpacity(
                0.09,
              ),

              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),

            child:
                Text(
              '$minutes min',

              style:
                  const TextStyle(
                color:
                    pacePrimary,

                fontSize:
                    12,

                fontWeight:
                    FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* =========================================================
     MODO IMERSIVO
  ========================================================= */

  Widget _immersiveView() {
    final meta =
        _selectedMeta;

    final intention =
        _intention.text
            .trim();

    return Container(
      color:
          dark
              ? const Color(
                  0xFF05070C,
                )
              : const Color(
                  0xFFF4F8FD,
                ),

      alignment:
          Alignment.center,

      child:
          SafeArea(
        child:
            Padding(
          padding:
              const EdgeInsets.all(
            24,
          ),

          child:
              Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const _FocusBadge(
                text:
                    'Modo imersivo',
              ),

              const SizedBox(
                height: 26,
              ),

              if (meta != null)
                _SelectedGoalPill(
                  title:
                      meta['titulo']
                              ?.toString() ??
                          'Meta',

                  dark:
                      dark,
                ),

              if (meta != null)
                const SizedBox(
                  height: 18,
                ),

              if (intention.isNotEmpty)
                Text(
                  intention,

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        muted,

                    fontSize:
                        18,

                    fontWeight:
                        FontWeight.w800,
                  ),
                )
              else if (meta != null)
                Text(
                  'Foco em ${meta['titulo']}',

                  textAlign:
                      TextAlign.center,

                  style:
                      TextStyle(
                    color:
                        muted,

                    fontSize:
                        18,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

              const SizedBox(
                height: 20,
              ),

              FittedBox(
                fit:
                    BoxFit.scaleDown,

                child:
                    Text(
                  _clock,

                  style:
                      TextStyle(
                    color:
                        text,

                    fontSize:
                        96,

                    fontWeight:
                        FontWeight.w900,

                    letterSpacing:
                        -4,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                _paused
                    ? 'Sessão pausada'
                    : 'Continue. O próximo minuto também conta.',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      muted,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              Wrap(
                spacing:
                    10,

                runSpacing:
                    10,

                alignment:
                    WrapAlignment.center,

                children: [
                  FilledButton.icon(
                    style:
                        FilledButton.styleFrom(
                      backgroundColor:
                          pacePrimary,

                      foregroundColor:
                          Colors.white,

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal:
                            18,

                        vertical:
                            14,
                      ),
                    ),

                    onPressed:
                        _finishing
                            ? null
                            : (
                                _paused
                                    ? _start
                                    : _pause
                              ),

                    icon:
                        Icon(
                      _paused
                          ? Icons
                              .play_arrow_rounded
                          : Icons
                              .pause_rounded,
                    ),

                    label:
                        Text(
                      _paused
                          ? 'Continuar'
                          : 'Pausar',
                    ),
                  ),

                  OutlinedButton.icon(
                    onPressed:
                        _finishing
                            ? null
                            : () async {
                                setState(() {
                                  _immersive =
                                      false;
                                });

                                await _confirmFinish();
                              },

                    icon:
                        const Icon(
                      Icons
                          .stop_circle_outlined,
                    ),

                    label:
                        const Text(
                      'Finalizar',
                    ),
                  ),

                  TextButton.icon(
                    onPressed:
                        () {
                      setState(() {
                        _immersive =
                            false;
                      });
                    },

                    icon:
                        const Icon(
                      Icons
                          .fullscreen_exit_rounded,
                    ),

                    label:
                        const Text(
                      'Sair do imersivo',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* =========================================================
     INPUT
  ========================================================= */

  InputDecoration _input(
    String label,
    String hint,
  ) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      labelStyle:
          TextStyle(
        color:
            muted,
      ),

      hintStyle:
          TextStyle(
        color:
            muted.withOpacity(
          0.7,
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
        ),
      ),
    );
  }
}

/* =========================================================
   META PICKER SHEET
========================================================= */

class _GoalPickerSheet
    extends StatelessWidget {
  final List<Map<String, dynamic>> metas;
  final int? selectedId;
  final bool dark;

  const _GoalPickerSheet({
    required this.metas,
    required this.selectedId,
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

    return SafeArea(
      child:
          Container(
        constraints:
            BoxConstraints(
          maxHeight:
              MediaQuery.sizeOf(
                    context,
                  ).height *
                  0.72,
        ),

        padding:
            const EdgeInsets.fromLTRB(
          18,
          12,
          18,
          22,
        ),

        decoration:
            BoxDecoration(
          color:
              dark
                  ? const Color(
                      0xFF0C1627,
                    )
                  : const Color(
                      0xFFF9FBFE,
                    ),

          borderRadius:
              const BorderRadius.vertical(
            top:
                Radius.circular(
              28,
            ),
          ),

          border:
              Border.all(
            color:
                dark
                    ? Colors.white
                        .withOpacity(
                          0.06,
                        )
                    : pacePrimary
                        .withOpacity(
                          0.10,
                        ),
          ),
        ),

        child:
            Column(
          mainAxisSize:
              MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Center(
              child:
                  Container(
                width:
                    42,

                height:
                    4,

                decoration:
                    BoxDecoration(
                  color:
                      muted.withOpacity(
                    0.28,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    99,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Row(
              children: [
                Container(
                  width:
                      44,

                  height:
                      44,

                  alignment:
                      Alignment.center,

                  decoration:
                      BoxDecoration(
                    color:
                        pacePrimary
                            .withOpacity(
                      0.10,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),

                  child:
                      const Icon(
                    Icons
                        .track_changes_rounded,

                    color:
                        pacePrimary,
                  ),
                ),

                const SizedBox(
                  width:
                      12,
                ),

                Expanded(
                  child:
                      Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Escolha sua meta',

                        style:
                            TextStyle(
                          color:
                              text,

                          fontSize:
                              21,

                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(
                        height:
                            2,
                      ),

                      Text(
                        'Onde você quer avançar nesta sessão?',

                        style:
                            TextStyle(
                          color:
                              muted,

                          fontSize:
                              12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            Flexible(
              child:
                  ListView.separated(
                shrinkWrap:
                    true,

                physics:
                    const BouncingScrollPhysics(),

                itemCount:
                    metas.length,

                separatorBuilder:
                    (
                  _,
                  __,
                ) =>
                        const SizedBox(
                  height:
                      8,
                ),

                itemBuilder:
                    (
                  context,
                  index,
                ) {
                  final meta =
                      metas[index];

                  final id =
                      (meta['id']
                              as num?)
                          ?.toInt();

                  final selected =
                      id ==
                      selectedId;

                  return InkWell(
                    onTap:
                        id == null
                            ? null
                            : () {
                                Navigator.pop(
                                  context,
                                  id,
                                );
                              },

                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),

                    child:
                        AnimatedContainer(
                      duration:
                          const Duration(
                        milliseconds:
                            170,
                      ),

                      padding:
                          const EdgeInsets.all(
                        14,
                      ),

                      decoration:
                          BoxDecoration(
                        color:
                            selected
                                ? pacePrimary
                                    .withOpacity(
                                      0.12,
                                    )
                                : (
                                    dark
                                        ? Colors.white
                                            .withOpacity(
                                              0.035,
                                            )
                                        : Colors.white
                                  ),

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),

                        border:
                            Border.all(
                          color:
                              selected
                                  ? pacePrimary
                                      .withOpacity(
                                        0.40,
                                      )
                                  : pacePrimary
                                      .withOpacity(
                                        0.08,
                                      ),
                        ),
                      ),

                      child:
                          Row(
                        children: [
                          Container(
                            width:
                                42,

                            height:
                                42,

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
                                13,
                              ),
                            ),

                            child:
                                const Icon(
                              Icons
                                  .flag_outlined,

                              color:
                                  pacePrimary,

                              size:
                                  20,
                            ),
                          ),

                          const SizedBox(
                            width:
                                12,
                          ),

                          Expanded(
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                Text(
                                  meta['titulo']
                                          ?.toString() ??
                                      'Meta',

                                  maxLines:
                                      1,

                                  overflow:
                                      TextOverflow.ellipsis,

                                  style:
                                      TextStyle(
                                    color:
                                        text,

                                    fontWeight:
                                        FontWeight.w900,
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                      4,
                                ),

                                Text(
                                  '${meta['categoria'] ?? 'Outro'} • Em andamento',

                                  style:
                                      TextStyle(
                                    color:
                                        muted,

                                    fontSize:
                                        11.5,

                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            width:
                                10,
                          ),

                          Container(
                            width:
                                30,

                            height:
                                30,

                            alignment:
                                Alignment.center,

                            decoration:
                                BoxDecoration(
                              color:
                                  selected
                                      ? pacePrimary
                                      : Colors.transparent,

                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),

                              border:
                                  Border.all(
                                color:
                                    selected
                                        ? pacePrimary
                                        : pacePrimary
                                            .withOpacity(
                                              0.12,
                                            ),
                              ),
                            ),

                            child:
                                Icon(
                              selected
                                  ? Icons
                                      .check_rounded
                                  : Icons
                                      .arrow_forward_ios_rounded,

                              color:
                                  selected
                                      ? Colors.white
                                      : pacePrimary,

                              size:
                                  selected
                                      ? 17
                                      : 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   COMPONENTES
========================================================= */

class _FocusBadge
    extends StatelessWidget {
  final String text;

  const _FocusBadge({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            14,

        vertical:
            9,
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
            width:
                7,

            height:
                7,

            decoration:
                const BoxDecoration(
              color:
                  paceAccent,

              shape:
                  BoxShape.circle,
            ),
          ),

          const SizedBox(
            width:
                9,
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

class _FocusSurface
    extends StatelessWidget {
  final bool dark;
  final Widget child;

  const _FocusSurface({
    required this.dark,
    required this.child,
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
        22,
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
          26,
        ),

        border:
            Border.all(
          color:
              dark
                  ? Colors.white
                      .withOpacity(
                        0.055,
                      )
                  : pacePrimary
                      .withOpacity(
                        0.10,
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
                32,

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

class _SelectedGoalPill
    extends StatelessWidget {
  final String title;
  final bool dark;

  const _SelectedGoalPill({
    required this.title,
    required this.dark,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth:
            360,
      ),

      padding:
          const EdgeInsets.symmetric(
        horizontal:
            12,

        vertical:
            8,
      ),

      decoration:
          BoxDecoration(
        color:
            pacePrimary.withOpacity(
          dark
              ? 0.12
              : 0.07,
        ),

        borderRadius:
            BorderRadius.circular(
          999,
        ),

        border:
            Border.all(
          color:
              pacePrimary.withOpacity(
            0.12,
          ),
        ),
      ),

      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          const Icon(
            Icons
                .track_changes_rounded,

            color:
                pacePrimary,

            size:
                16,
          ),

          const SizedBox(
            width:
                7,
          ),

          Flexible(
            child:
                Text(
              title,

              maxLines:
                  1,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                color:
                    pacePrimary,

                fontSize:
                    12,

                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusStat
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool dark;

  const _FocusStat({
    required this.icon,
    required this.title,
    required this.subtitle,
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

    return _FocusSurface(
      dark:
          dark,

      child:
          Row(
        children: [
          Container(
            width:
                48,

            height:
                48,

            alignment:
                Alignment.center,

            decoration:
                BoxDecoration(
              color:
                  pacePrimary.withOpacity(
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
            width:
                13,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style:
                      TextStyle(
                    color:
                        text,

                    fontSize:
                        22,

                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height:
                      2,
                ),

                Text(
                  subtitle,

                  style:
                      TextStyle(
                    color:
                        muted,

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w700,
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