import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'pace_session.dart';
import 'pace_shell.dart';

class EvolucaoPage extends StatefulWidget {
  const EvolucaoPage({super.key});

  @override
  State<EvolucaoPage> createState() => _EvolucaoPageState();
}

class _EvolucaoPageState extends State<EvolucaoPage> {
  Map<String, dynamic> _user = {};

  List<Map<String, dynamic>> _metas = [];
  List<Map<String, dynamic>> _focus = [];

  int _period = 7;

  bool _loading = true;
  bool _refreshing = false;

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
    _load();
  }

  /* =========================================================
     API
  ========================================================= */

  Future<Map<String, String>> _headers() async {
    final token =
        await PaceSession.token();

    final headers =
        <String, String>{};

    if (token != null &&
        token.isNotEmpty) {
      headers['Authorization'] =
          'Bearer $token';
    }

    return headers;
  }

  Future<dynamic> _request(
    String endpoint,
  ) async {
    final headers =
        await _headers();

    final uri =
        ApiConfig.uri(
      endpoint,
    );

    late http.Response response;

    try {
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
          'Não foi possível carregar os dados.';

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
    };
  }

  /* =========================================================
     LOAD
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

      final focus =
          await _loadFocus(
        metas,
      );

      if (!mounted) return;

      setState(() {
        _user = user;
        _metas = metas;
        _focus = focus;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _handleError(
        error,
      );
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) {
      return;
    }

    setState(() {
      _refreshing = true;
    });

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

      final focus =
          await _loadFocus(
        metas,
      );

      if (!mounted) return;

      setState(() {
        _metas = metas;
        _focus = focus;
      });
    } catch (error) {
      if (!mounted) return;

      _handleError(
        error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>>
      _loadFocus(
    List<Map<String, dynamic>> metas,
  ) async {
    final focus =
        <Map<String, dynamic>>[];

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
            focus.add(
              session,
            );
          }
        }
      } on _PaceApiException catch (error) {
        if (error.statusCode == 401) {
          rethrow;
        }
      }
    }

    focus.sort(
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

    return focus;
  }

  /* =========================================================
     DADOS DO PERÍODO
  ========================================================= */

  List<Map<String, dynamic>>
      get _focusPeriod {
    final cutoff =
        DateTime.now().subtract(
      Duration(
        days: _period,
      ),
    );

    return _focus.where(
      (session) {
        final date =
            DateTime.tryParse(
          session['data']
                  ?.toString() ??
              '',
        );

        return date != null &&
            date.isAfter(
              cutoff,
            );
      },
    ).toList();
  }

  int get _minutes {
    return _focusPeriod.fold<int>(
      0,
      (
        total,
        session,
      ) {
        final minutes =
            (session['minutos'] as num?)
                    ?.toInt() ??
                0;

        return total +
            minutes;
      },
    );
  }

  int get _completedGoals {
    return _metas.where(
      (meta) =>
          meta['status']
              ?.toString()
              .toLowerCase() ==
          'concluida',
    ).length;
  }

  int get _ongoingGoals {
    return _metas.where(
      (meta) =>
          meta['status']
              ?.toString()
              .toLowerCase() ==
          'em andamento',
    ).length;
  }

  int get _activeDays {
    final days =
        <String>{};

    for (final session in _focusPeriod) {
      final date =
          DateTime.tryParse(
        session['data']
                ?.toString() ??
            '',
      );

      if (date == null) {
        continue;
      }

      days.add(
        '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
      );
    }

    return days.length;
  }

  int get _streak {
    final days =
        <DateTime>{};

    for (final session in _focus) {
      final date =
          DateTime.tryParse(
        session['data']
                ?.toString() ??
            '',
      );

      if (date == null) {
        continue;
      }

      days.add(
        DateTime(
          date.year,
          date.month,
          date.day,
        ),
      );
    }

    if (days.isEmpty) {
      return 0;
    }

    final sorted =
        days.toList()
          ..sort(
            (a, b) =>
                b.compareTo(
              a,
            ),
          );

    final today =
        DateTime.now();

    final todayOnly =
        DateTime(
      today.year,
      today.month,
      today.day,
    );

    final yesterday =
        todayOnly.subtract(
      const Duration(
        days: 1,
      ),
    );

    final first =
        sorted.first;

    if (first != todayOnly &&
        first != yesterday) {
      return 0;
    }

    var streak = 1;

    var previous =
        first;

    for (var i = 1;
        i < sorted.length;
        i++) {
      final current =
          sorted[i];

      final difference =
          previous
              .difference(
                current,
              )
              .inDays;

      if (difference == 1) {
        streak++;

        previous =
            current;
      } else if (difference > 1) {
        break;
      }
    }

    return streak;
  }

  /* =========================================================
     ÍNDICE PACE
  ========================================================= */

  int get _paceScore {
    if (_metas.isEmpty &&
        _focusPeriod.isEmpty) {
      return 0;
    }

    final taxaMetas =
        _metas.isEmpty
            ? 0.0
            : (
                _completedGoals /
                _metas.length
              ) *
              100;

    final metasScore =
        taxaMetas *
        0.30;

    final focoScore =
        (_minutes / 12)
            .clamp(
              0,
              25,
            );

    final sequenciaScore =
        (_streak * 3)
            .clamp(
              0,
              20,
            );

    final constanciaScore =
        (_activeDays * 2)
            .clamp(
              0,
              15,
            );

    final conclusoesScore =
        (_completedGoals * 2)
            .clamp(
              0,
              10,
            );

    final score =
        metasScore +
        focoScore +
        sequenciaScore +
        constanciaScore +
        conclusoesScore;

    return score
        .round()
        .clamp(
          0,
          100,
        );
  }

  String get _paceLabel {
    final score =
        _paceScore;

    if (score >= 75) {
      return 'Alta evolução';
    }

    if (score >= 50) {
      return 'Constância sólida';
    }

    if (score >= 25) {
      return 'Ritmo em construção';
    }

    return 'Sua jornada começa agora';
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

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(
            message,
          ),

          behavior:
              SnackBarBehavior.floating,

          backgroundColor:
              const Color(
            0xFFC94242,
          ),
        ),
      );

    if (error
            is _PaceApiException &&
        error.statusCode == 401) {
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

    final mobile =
        MediaQuery.sizeOf(
          context,
        ).width <
        760;

    return PaceShell(
      currentRoute:
          '/evolucao',

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
          Container(
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
                      1160,
                ),

                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    _hero(
                      mobile,
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    _paceIndex(),

                    const SizedBox(
                      height: 24,
                    ),

                    _periodSelector(),

                    if (_refreshing) ...[
                      const SizedBox(
                        height: 10,
                      ),

                      const LinearProgressIndicator(
                        minHeight:
                            2,
                        color:
                            pacePrimary,
                        backgroundColor:
                            Colors.transparent,
                      ),
                    ],

                    const SizedBox(
                      height: 18,
                    ),

                    _stats(),

                    const SizedBox(
                      height: 24,
                    ),

                    _timeline(),

                    const SizedBox(
                      height: 24,
                    ),

                    _insights(),
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

  Widget _hero(
    bool mobile,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        const _EvolutionBadge(
          text:
              'Sua jornada em movimento',
        ),

        const SizedBox(
          height: 14,
        ),

        Text.rich(
          TextSpan(
            text:
                'Você não está apenas avançando. ',

            children: [
              TextSpan(
                text:
                    'Está se transformando.',

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
                    ? 36
                    : 49,

            height:
                1.03,

            fontWeight:
                FontWeight.w900,

            letterSpacing:
                -1.6,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          'O Pace reúne suas metas, sessões de foco e constância para revelar como sua evolução está acontecendo de verdade.',

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
     ÍNDICE PACE
  ========================================================= */

  Widget _paceIndex() {
    return _EvolutionSurface(
      dark:
          dark,

      child:
          LayoutBuilder(
        builder:
            (
          _,
          constraints,
        ) {
          final compact =
              constraints.maxWidth <
              720;

          final scoreCard =
              Column(
            children: [
              Row(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Text(
                    'ÍNDICE PACE',

                    style:
                        TextStyle(
                      color:
                          paceAccent,

                      fontSize:
                          11,

                      fontWeight:
                          FontWeight.w900,

                      letterSpacing:
                          1.1,
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Tooltip(
                    message:
                        'Indicador geral de evolução baseado em metas concluídas, tempo de foco, sequência e constância.',

                    triggerMode:
                        TooltipTriggerMode.tap,

                    child:
                        Container(
                      width: 28,
                      height: 28,

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
                          9,
                        ),
                      ),

                      child:
                          const Icon(
                        Icons
                            .info_outline_rounded,

                        color:
                            pacePrimary,

                        size:
                            16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              TweenAnimationBuilder<double>(
                tween:
                    Tween(
                  begin:
                      0,

                  end:
                      _paceScore /
                      100,
                ),

                duration:
                    const Duration(
                  milliseconds:
                      750,
                ),

                curve:
                    Curves.easeOutCubic,

                builder:
                    (
                  context,
                  progress,
                  _,
                ) {
                  return SizedBox(
                    width:
                        190,

                    height:
                        190,

                    child:
                        Stack(
                      alignment:
                          Alignment.center,

                      children: [
                        SizedBox(
                          width:
                              190,

                          height:
                              190,

                          child:
                              CircularProgressIndicator(
                            value:
                                progress,

                            strokeWidth:
                                11,

                            backgroundColor:
                                pacePrimary
                                    .withOpacity(
                              0.09,
                            ),

                            valueColor:
                                const AlwaysStoppedAnimation(
                              pacePrimary,
                            ),
                          ),
                        ),

                        Column(
                          mainAxisSize:
                              MainAxisSize.min,

                          children: [
                            Text(
                              '$_paceScore',

                              style:
                                  TextStyle(
                                color:
                                    text,

                                fontSize:
                                    56,

                                height:
                                    1,

                                fontWeight:
                                    FontWeight.w900,

                                letterSpacing:
                                    -2,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              'DE 100',

                              style:
                                  TextStyle(
                                color:
                                    muted,

                                fontSize:
                                    11,

                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 14,
              ),

              Text(
                _paceLabel,

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      text,

                  fontSize:
                      18,

                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Seu indicador de consistência e evolução.',

                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  color:
                      muted,

                  fontSize:
                      12,
                ),
              ),
            ],
          );

          final explanation =
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'O que esse número representa?',

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
                height: 10,
              ),

              Text(
                'O Índice Pace não é a porcentagem de uma meta. Ele resume seu ritmo geral dentro do app, combinando diferentes sinais da sua evolução.',

                style:
                    TextStyle(
                  color:
                      muted,

                  height:
                      1.6,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              _IndexFactor(
                icon:
                    Icons
                        .task_alt_rounded,

                title:
                    'Metas concluídas',

                value:
                    '$_completedGoals',
              ),

              const SizedBox(
                height: 10,
              ),

              _IndexFactor(
                icon:
                    Icons
                        .bolt_rounded,

                title:
                    'Tempo de foco',

                value:
                    _formatMinutes(
                  _minutes,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              _IndexFactor(
                icon:
                    Icons
                        .local_fire_department_outlined,

                title:
                    'Sequência atual',

                value:
                    '$_streak ${_streak == 1 ? 'dia' : 'dias'}',
              ),

              const SizedBox(
                height: 10,
              ),

              _IndexFactor(
                icon:
                    Icons
                        .calendar_month_outlined,

                title:
                    'Dias ativos',

                value:
                    '$_activeDays',
              ),
            ],
          );

          if (compact) {
            return Column(
              children: [
                scoreCard,

                const SizedBox(
                  height: 28,
                ),

                explanation,
              ],
            );
          }

          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.center,

            children: [
              SizedBox(
                width: 280,
                child:
                    scoreCard,
              ),

              const SizedBox(
                width: 34,
              ),

              Expanded(
                child:
                    explanation,
              ),
            ],
          );
        },
      ),
    );
  }

  /* =========================================================
     PERIOD
  ========================================================= */

  Widget _periodSelector() {
    return Wrap(
      spacing:
          8,

      runSpacing:
          8,

      children: [
        7,
        30,
        90,
      ].map(
        (
          period,
        ) {
          final selected =
              _period ==
              period;

          return ChoiceChip(
            label:
                Text(
              '$period dias',
            ),

            selected:
                selected,

            onSelected:
                (_) {
              setState(() {
                _period =
                    period;
              });
            },

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
                    : Colors.white,

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
                    ? 0.24
                    : 0.10,
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  /* =========================================================
     STATS
  ========================================================= */

  Widget _stats() {
    final items = [
      _EvolutionStat(
        label:
            'Tempo em foco',

        value:
            _formatMinutes(
          _minutes,
        ),

        icon:
            Icons
                .bolt_rounded,

        dark:
            dark,
      ),

      _EvolutionStat(
        label:
            'Sessões',

        value:
            '${_focusPeriod.length}',

        icon:
            Icons
                .psychology_outlined,

        dark:
            dark,
      ),

      _EvolutionStat(
        label:
            'Metas concluídas',

        value:
            '$_completedGoals',

        icon:
            Icons
                .task_alt_rounded,

        dark:
            dark,
      ),

      _EvolutionStat(
        label:
            'Metas em andamento',

        value:
            '$_ongoingGoals',

        icon:
            Icons
                .route_rounded,

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
        final columns =
            constraints.maxWidth >=
                    900
                ? 4
                : constraints.maxWidth >=
                        560
                    ? 2
                    : 1;

        const gap =
            14.0;

        final width =
            (
              constraints.maxWidth -
              gap *
                  (
                    columns -
                    1
                  )
            ) /
            columns;

        return Wrap(
          spacing:
              gap,

          runSpacing:
              gap,

          children:
              items
                  .map(
                    (
                      item,
                    ) =>
                        SizedBox(
                      width:
                          width,

                      child:
                          item,
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  /* =========================================================
     TIMELINE
  ========================================================= */

  Widget _timeline() {
    final events =
        <_EvolutionEvent>[];

    for (final session in _focusPeriod) {
      events.add(
        _EvolutionEvent(
          icon:
              Icons
                  .bolt_rounded,

          title:
              session['intencao']
                      ?.toString() ??
                  'Sessão de foco',

          subtitle:
              '${session['minutos']} min de foco',

          date:
              DateTime.tryParse(
            session['data']
                    ?.toString() ??
                '',
          ),
        ),
      );
    }

    for (final meta in _metas.where(
      (meta) =>
          meta['status'] ==
          'concluida',
    )) {
      events.add(
        _EvolutionEvent(
          icon:
              Icons
                  .flag_rounded,

          title:
              meta['titulo']
                      ?.toString() ??
                  'Meta concluída',

          subtitle:
              'Meta concluída',

          date:
              null,
        ),
      );
    }

    events.sort(
      (a, b) {
        if (a.date == null &&
            b.date == null) {
          return 0;
        }

        if (a.date == null) {
          return 1;
        }

        if (b.date == null) {
          return -1;
        }

        return b.date!
            .compareTo(
          a.date!,
        );
      },
    );

    return _EvolutionSurface(
      dark:
          dark,

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            'Momentos que construíram sua evolução',

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
            height: 6,
          ),

          Text(
            'Sessões de foco e metas concluídas da sua jornada.',

            style:
                TextStyle(
              color:
                  muted,

              fontSize:
                  12.5,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          if (events.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical:
                    32,
              ),

              child:
                  Center(
                child:
                    Column(
                  children: [
                    const Icon(
                      Icons
                          .auto_graph_rounded,

                      color:
                          pacePrimary,

                      size:
                          40,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Text(
                      'Sua história ainda será escrita aqui.',

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
                      'Crie uma meta ou conclua uma sessão de foco.',

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
            ...events
                .take(
                  10,
                )
                .map(
                  (
                    event,
                  ) =>
                      _event(
                    event,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _event(
    _EvolutionEvent event,
  ) {
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
                0.10,
              ),

              borderRadius:
                  BorderRadius.circular(
                13,
              ),
            ),

            child:
                Icon(
              event.icon,

              color:
                  paceAccent,

              size:
                  20,
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
                  event.title,

                  style:
                      TextStyle(
                    color:
                        text,

                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  event.date == null
                      ? event.subtitle
                      : '${event.subtitle} • ${_formatDate(event.date!)}',

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
    );
  }

  /* =========================================================
     INSIGHT
  ========================================================= */

  Widget _insights() {
    String title;
    String body;
    IconData icon;

    if (_minutes == 0 &&
        _metas.isEmpty) {
      title =
          'Comece a gerar seu histórico.';

      body =
          'Sua evolução aparece quando você transforma intenção em pequenas ações registradas.';

      icon =
          Icons
              .auto_awesome_rounded;
    } else if (_streak >= 7) {
      title =
          'Sua constância já passou de uma semana.';

      body =
          'Você está construindo um padrão forte. Continue protegendo seu tempo de foco.';

      icon =
          Icons
              .local_fire_department_rounded;
    } else if (_minutes >= 120) {
      title =
          'Seu foco está virando consistência.';

      body =
          'Você acumulou ${_formatMinutes(_minutes)} de foco nos últimos $_period dias.';

      icon =
          Icons
              .psychology_rounded;
    } else if (_completedGoals > 0) {
      title =
          'Você está fechando ciclos.';

      body =
          'Já existem $_completedGoals ${_completedGoals == 1 ? 'meta concluída' : 'metas concluídas'}. Use essa energia para escolher o próximo passo.';

      icon =
          Icons
              .emoji_events_outlined;
    } else if (_activeDays >= 4) {
      title =
          'Seu esforço está bem distribuído.';

      body =
          'Você esteve ativo em $_activeDays dias neste período. A regularidade está começando a aparecer.';

      icon =
          Icons
              .calendar_month_outlined;
    } else {
      title =
          'O movimento já começou.';

      body =
          'Seu Índice Pace está em $_paceScore de 100. Agora, constância vale mais do que velocidade.';

      icon =
          Icons
              .trending_up_rounded;
    }

    return _EvolutionSurface(
      dark:
          dark,

      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            width: 52,
            height: 52,

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
                16,
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
            width: 16,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  'Insight Pace',

                  style:
                      TextStyle(
                    color:
                        paceAccent,

                    fontSize:
                        12,

                    fontWeight:
                        FontWeight.w900,

                    letterSpacing:
                        1.1,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  title,

                  style:
                      TextStyle(
                    color:
                        text,

                    fontSize:
                        20,

                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  body,

                  style:
                      TextStyle(
                    color:
                        muted,

                    height:
                        1.55,
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
     FORMATADORES
  ========================================================= */

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

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

/* =========================================================
   EVENT
========================================================= */

class _EvolutionEvent {
  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime? date;

  const _EvolutionEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
  });
}

/* =========================================================
   INDEX FACTOR
========================================================= */

class _IndexFactor
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _IndexFactor({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final dark =
        Theme.of(context).brightness ==
        Brightness.dark;

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

    return Container(
      padding:
          const EdgeInsets.all(
        12,
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
          14,
        ),
      ),

      child:
          Row(
        children: [
          Container(
            width: 38,
            height: 38,

            alignment:
                Alignment.center,

            decoration:
                BoxDecoration(
              color:
                  pacePrimary.withOpacity(
                0.09,
              ),

              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),

            child:
                Icon(
              icon,

              color:
                  pacePrimary,

              size:
                  19,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child:
                Text(
              title,

              style:
                  TextStyle(
                color:
                    muted,

                fontSize:
                    12.5,

                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Text(
            value,

            style:
                TextStyle(
              color:
                  text,

              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   BADGE
========================================================= */

class _EvolutionBadge
    extends StatelessWidget {
  final String text;

  const _EvolutionBadge({
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

/* =========================================================
   STAT
========================================================= */

class _EvolutionStat
    extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool dark;

  const _EvolutionStat({
    required this.label,
    required this.value,
    required this.icon,
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

    return _EvolutionSurface(
      dark:
          dark,

      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,

            color:
                pacePrimary,
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            value,

            style:
                TextStyle(
              color:
                  text,

              fontSize:
                  28,

              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 3,
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
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   SURFACE
========================================================= */

class _EvolutionSurface
    extends StatelessWidget {
  final bool dark;
  final Widget child;

  const _EvolutionSurface({
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
        21,
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

/* =========================================================
   API EXCEPTION
========================================================= */

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