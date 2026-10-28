import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

const Color _primary = Color(0xFF1769E8);
const Color _accent = Color(0xFFFFC928);
const Color _success = Color(0xFF2AA879);
const Color _danger = Color(0xFFD8425C);

class FocoPage extends StatefulWidget {
  const FocoPage({super.key});

  @override
  State<FocoPage> createState() => _FocoPageState();
}

class _FocoPageState extends State<FocoPage> {
  static const _activeSessionKey = 'pace_flutter_focus_active';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _intentionController = TextEditingController();

  List<Map<String, dynamic>> _metas = [];
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic> _user = {};

  Timer? _timer;

  int _durationMinutes = 25;
  int _remainingSeconds = 25 * 60;
  int _customMinutes = 25;

  int? _selectedMetaId;
  DateTime? _startedAt;
  int _elapsedBeforeStart = 0;

  bool _running = false;
  bool _paused = false;
  bool _loading = true;
  bool _saving = false;
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
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intentionController.dispose();
    super.dispose();
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

    final status = (raw['status'] ?? '').toString().trim().toLowerCase();

    return {
      'id': int.tryParse('${raw['id']}') ?? 0,
      'titulo': (raw['titulo'] ?? '').toString(),
      'descricao': (raw['descricao'] ?? '').toString(),
      'categoria': (raw['categoria'] ?? 'Outro').toString(),
      'status': status == 'concluida' ? 'concluida' : 'em andamento',
    };
  }

  Map<String, dynamic> _normalizeSession(
    dynamic value, {
    Map<String, dynamic>? meta,
  }) {
    Map<String, dynamic> raw = {};

    if (value is Map) {
      raw = Map<String, dynamic>.from(value);
    } else if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          raw = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    final durationCandidates = [
      raw['duracao'],
      raw['duration'],
      raw['duration_minutes'],
      raw['duracao_minutos'],
      raw['minutos'],
    ];

    int duracao = 0;

    for (final candidate in durationCandidates) {
      if (candidate == null) continue;

      final parsed = candidate is num
          ? candidate.toDouble()
          : double.tryParse(candidate.toString().replaceAll(',', '.'));

      if (parsed != null && parsed > 0) {
        duracao = parsed.round();
        break;
      }
    }

    if (duracao == 0) {
      final secondsCandidates = [
        raw['durationSeconds'],
        raw['duration_seconds'],
        raw['duracao_segundos'],
      ];

      for (final candidate in secondsCandidates) {
        if (candidate == null) continue;

        final parsed = candidate is num
            ? candidate.toDouble()
            : double.tryParse(candidate.toString().replaceAll(',', '.'));

        if (parsed != null && parsed > 0) {
          duracao = (parsed / 60).round();
          if (duracao <= 0) duracao = 1;
          break;
        }
      }
    }

    final inicio = (
      raw['inicio'] ??
      raw['startedAt'] ??
      raw['started_at'] ??
      ''
    ).toString();

    return {
      'id': int.tryParse('${raw['id'] ?? 0}') ?? 0,
      'meta_id': int.tryParse(
            '${raw['meta_id'] ?? raw['id_meta'] ?? meta?['id'] ?? 0}',
          ) ??
          0,
      'inicio': inicio,
      'duracao': duracao,
      'meta_titulo': meta?['titulo']?.toString() ?? 'Sessão de foco',
      'meta_categoria': meta?['categoria']?.toString() ?? '',
      'meta': meta == null ? null : Map<String, dynamic>.from(meta),
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

    try {
      final responses = await Future.wait([
        http.get(
          ApiConfig.uri('/profile/me'),
          headers: _headers(token),
        ),
        http.get(
          ApiConfig.uri('/metas/listar_metas'),
          headers: _headers(token),
        ),
      ]);

      final userData = await _parse(responses[0]);
      final metasData = await _parse(responses[1]);

      final metas = metasData is List
          ? metasData.map(_normalizeMeta).toList()
          : <Map<String, dynamic>>[];

      final history = <Map<String, dynamic>>[];

      final sessionResponses = await Future.wait(
        metas.map(
          (meta) async {
            try {
              final response = await http.get(
                ApiConfig.uri('/sessoes/meta/${meta['id']}'),
                headers: _headers(token),
              );

              if (response.statusCode < 200 || response.statusCode >= 300) {
                return <Map<String, dynamic>>[];
              }

              final decoded = response.body.isNotEmpty
                  ? jsonDecode(response.body)
                  : null;

              if (decoded is! List) {
                return <Map<String, dynamic>>[];
              }

              return decoded
                  .map(
                    (item) => _normalizeSession(
                      item,
                      meta: meta,
                    ),
                  )
                  .toList();
            } catch (_) {
              return <Map<String, dynamic>>[];
            }
          },
        ),
      );

      for (final sessions in sessionResponses) {
        history.addAll(sessions);
      }

      history.sort((a, b) {
        final ad = DateTime.tryParse(a['inicio']?.toString() ?? '');
        final bd = DateTime.tryParse(b['inicio']?.toString() ?? '');

        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;

        return bd.compareTo(ad);
      });

      if (!mounted) return;

      setState(() {
        _user = userData is Map
            ? Map<String, dynamic>.from(userData)
            : {};
        _metas = metas;
        _history = history;
        _loading = false;
      });

      await _restoreActiveSession();
    } catch (error) {
      if (!mounted) return;

      setState(() => _loading = false);

      _toast(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  List<Map<String, dynamic>> get _openMetas => _metas
      .where((meta) => meta['status'] == 'em andamento')
      .toList();

  Map<String, dynamic>? get _selectedMeta {
    if (_selectedMetaId == null) return null;

    for (final meta in _metas) {
      if (meta['id'] == _selectedMetaId) {
        return meta;
      }
    }

    return null;
  }

  Future<void> _saveActiveSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (!_running && !_paused) {
      await prefs.remove(_activeSessionKey);
      return;
    }

    final data = {
      'durationMinutes': _durationMinutes,
      'selectedMetaId': _selectedMetaId,
      'intention': _intentionController.text,
      'startedAt': _startedAt?.toIso8601String(),
      'elapsedBeforeStart': _elapsedBeforeStart,
      'running': _running,
      'paused': _paused,
    };

    await prefs.setString(
      _activeSessionKey,
      jsonEncode(data),
    );
  }

  Future<void> _restoreActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeSessionKey);

    if (raw == null || raw.isEmpty) return;

    try {
      final data = jsonDecode(raw);

      if (data is! Map) return;

      final duration = int.tryParse('${data['durationMinutes']}') ?? 25;
      final selectedMetaId =
          int.tryParse('${data['selectedMetaId']}');
      final startedAt =
          DateTime.tryParse('${data['startedAt'] ?? ''}');
      final elapsed =
          int.tryParse('${data['elapsedBeforeStart']}') ?? 0;
      final running = data['running'] == true;
      final paused = data['paused'] == true;

      if (!mounted) return;

      setState(() {
        _durationMinutes = duration;
        _customMinutes = duration;
        _selectedMetaId = selectedMetaId;
        _intentionController.text =
            (data['intention'] ?? '').toString();
        _startedAt = startedAt;
        _elapsedBeforeStart = elapsed;
        _running = running;
        _paused = paused;
        _remainingSeconds = _computeRemaining();
      });

      if (_running && !_paused) {
        _startTicker();
      }
    } catch (_) {}
  }

  int _computeElapsed() {
    if (!_running && !_paused) return 0;

    if (_paused || _startedAt == null) {
      return _elapsedBeforeStart;
    }

    final delta =
        DateTime.now().difference(_startedAt!).inSeconds;

    return _elapsedBeforeStart + delta;
  }

  int _computeRemaining() {
    final total = _durationMinutes * 60;
    return (total - _computeElapsed()).clamp(0, total);
  }

  void _setDuration(int minutes) {
    if (_running || _paused) return;

    final value = minutes.clamp(1, 240);

    setState(() {
      _durationMinutes = value;
      _customMinutes = value;
      _remainingSeconds = value * 60;
    });
  }

  void _incrementCustom(int delta) {
    if (_running || _paused) return;

    setState(() {
      _customMinutes = (_customMinutes + delta).clamp(1, 240);
    });
  }

  void _applyCustom() {
    _setDuration(_customMinutes);
  }

  void _startOrPause() {
    if (_selectedMetaId == null) {
      _toast(
        'Escolha uma meta antes de iniciar.',
        error: true,
      );
      return;
    }

    if (!_running && !_paused) {
      setState(() {
        _running = true;
        _paused = false;
        _startedAt = DateTime.now();
        _elapsedBeforeStart = 0;
        _remainingSeconds = _durationMinutes * 60;
      });

      _saveActiveSession();
      _startTicker();
      return;
    }

    if (_running && !_paused) {
      _timer?.cancel();

      setState(() {
        _elapsedBeforeStart = _computeElapsed();
        _startedAt = null;
        _paused = true;
        _running = true;
        _remainingSeconds = _computeRemaining();
      });

      _saveActiveSession();
      return;
    }

    if (_running && _paused) {
      setState(() {
        _startedAt = DateTime.now();
        _paused = false;
      });

      _saveActiveSession();
      _startTicker();
    }
  }

  void _startTicker() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) async {
        if (!mounted || _paused) return;

        final remaining = _computeRemaining();

        if (remaining <= 0) {
          setState(() => _remainingSeconds = 0);
          _timer?.cancel();
          await _finishSession(automatic: true);
          return;
        }

        setState(() => _remainingSeconds = remaining);
      },
    );
  }

  Future<void> _resetSession() async {
    _timer?.cancel();

    setState(() {
      _running = false;
      _paused = false;
      _startedAt = null;
      _elapsedBeforeStart = 0;
      _remainingSeconds = _durationMinutes * 60;
    });

    await _saveActiveSession();
  }

  Future<void> _finishSession({
    bool automatic = false,
  }) async {
    if (_saving || (!_running && !_paused)) return;

    final meta = _selectedMeta;

    if (meta == null) {
      await _resetSession();
      return;
    }

    final elapsed = _computeElapsed();
    final seconds = elapsed.clamp(0, _durationMinutes * 60);

    if (seconds < 10) {
      await _resetSession();

      if (!automatic) {
        _toast(
          'A sessão foi curta demais para ser registrada.',
          error: true,
        );
      }

      return;
    }

    final minutes = (seconds / 60).round().clamp(1, 240);

    final token = await _token();
    if (token == null || token.isEmpty) return;

    setState(() => _saving = true);

    try {
      final response = await http.post(
        ApiConfig.uri('/sessoes/criar_sessao'),
        headers: _headers(token),
        body: jsonEncode({
          'id_meta': meta['id'],
          'inicio': (_startedAt ??
                  DateTime.now().subtract(
                    Duration(seconds: seconds),
                  ))
              .toIso8601String(),
          'duracao': minutes,
        }),
      );

      final data = await _parse(response);
      final saved = _normalizeSession(
        data,
        meta: meta,
      );

      await _resetSession();
      await _load();

      if (!mounted) return;

      await _showConclusion(saved);
    } catch (error) {
      _toast(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _showConclusion(
    Map<String, dynamic> session,
  ) async {
    final meta = session['meta'] as Map<String, dynamic>?;

    final action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.68),
      builder: (context) {
        final dialogDark =
            Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
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
                      : const Color(0xFF06152D).withOpacity(0.08),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(
                      Icons.emoji_events_outlined,
                      color: Color(0xFFD89A00),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SESSÃO CONCLUÍDA',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Você fez acontecer.',
                    style: TextStyle(
                      color: dialogDark
                          ? Colors.white
                          : const Color(0xFF06152D),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${session['duracao']} min focados'
                    '${meta != null ? ' em "${meta['titulo']}"' : ''}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dialogDark
                          ? const Color(0xFF98A8BF)
                          : const Color(0xFF61758F),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(context, 'continue'),
                          child: const Text('Continuar evoluindo'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              Navigator.pop(context, 'share'),
                          icon: const Icon(
                            Icons.send_rounded,
                            size: 17,
                          ),
                          label: const Text('Compartilhar foco'),
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

    if (action == 'share') {
      await _shareFocus(session);
    }
  }

  Future<void> _shareFocus(
    Map<String, dynamic> session,
  ) async {
    final controller = TextEditingController();

    final meta = session['meta'] as Map<String, dynamic>?;

    final content = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.68),
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
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COMPARTILHE SEU RITMO',
                        style: TextStyle(
                          color: _primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Compartilhar sessão de foco',
                        style: TextStyle(
                          color: dialogDark
                              ? Colors.white
                              : const Color(0xFF06152D),
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryBox(
                              dialogDark,
                              'Meta',
                              meta?['titulo']?.toString() ?? '—',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _summaryBox(
                              dialogDark,
                              'Tempo focado',
                              '${session['duracao']} min',
                            ),
                          ),
                        ],
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
                              'Conte como foi essa sessão...',
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
                            label: const Text('Publicar foco'),
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
          'tipo': 'foco',
          'meta_id': null,
          'sessao_id': session['id'],
        }),
      );

      await _parse(response);
      _toast('Sessão de foco compartilhada! ⚡');
    } catch (error) {
      _toast(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Widget _summaryBox(
    bool dialogDark,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dialogDark
            ? const Color(0xFF0B1729)
            : const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: dialogDark
              ? Colors.white.withOpacity(0.07)
              : const Color(0xFF06152D).withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dialogDark
                  ? const Color(0xFF98A8BF)
                  : const Color(0xFF61758F),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dialogDark
                  ? Colors.white
                  : const Color(0xFF06152D),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  int get _todayMinutes {
    final now = DateTime.now();

    return _history.fold<int>(0, (sum, session) {
      final dt =
          DateTime.tryParse(session['inicio']?.toString() ?? '');

      if (dt == null) return sum;

      final sameDay = dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day;

      return sameDay
          ? sum + (int.tryParse('${session['duracao']}') ?? 0)
          : sum;
    });
  }

  int get _bestDayMinutes {
    final totals = <String, int>{};

    for (final session in _history) {
      final dt =
          DateTime.tryParse(session['inicio']?.toString() ?? '');

      if (dt == null) continue;

      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

      totals[key] = (totals[key] ?? 0) +
          (int.tryParse('${session['duracao']}') ?? 0);
    }

    if (totals.isEmpty) return 0;

    return totals.values.reduce(
      (a, b) => a > b ? a : b,
    );
  }

  int get _streak {
    final days = <DateTime>{};

    for (final session in _history) {
      final dt =
          DateTime.tryParse(session['inicio']?.toString() ?? '');

      if (dt != null) {
        days.add(DateTime(dt.year, dt.month, dt.day));
      }
    }

    if (days.isEmpty) return 0;

    var current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);

    int streak = 0;

    while (days.contains(current)) {
      streak++;
      current = current.subtract(const Duration(days: 1));
    }

    return streak;
  }

  String _timeText() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String _sessionTitle() {
    if (_running && !_paused) return 'Você está em foco.';
    if (_running && _paused) return 'Sessão pausada.';
    return 'Pronto para começar?';
  }

  String _sessionState() {
    if (_running && !_paused) return 'FOCO ATIVO';
    if (_running && _paused) return 'PAUSADO';
    return 'PREPARAÇÃO';
  }

  String _intentionText() {
    final typed = _intentionController.text.trim();

    if (_running || _paused) {
      return typed.isEmpty
          ? 'Foco em ${_selectedMeta?['titulo'] ?? 'sua meta'}'
          : typed;
    }

    return typed.isEmpty
        ? 'Defina uma intenção para sua sessão'
        : typed;
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
                                      const SizedBox(height: 22),
                                      _focusWorkspace(
                                        mobile,
                                        tablet,
                                      ),
                                      const SizedBox(height: 14),
                                      _insights(mobile),
                                      const SizedBox(height: 14),
                                      _historyCard(),
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
                'Sala de Foco',
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
                'Timer, metas e histórico das suas sessões.',
                style: TextStyle(
                  color: muted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        if (!mobile)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF0F1B2F)
                  : Colors.white.withOpacity(0.86),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFF06152D)
                        .withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_outlined,
                    color: Color(0xFFD89A00),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sequência',
                      style: TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$_streak ${_streak == 1 ? 'dia' : 'dias'}',
                      style: TextStyle(
                        color: text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _focusWorkspace(
    bool mobile,
    bool tablet,
  ) {
    final timerCard = _timerCard();
    final configCard = _configCard();

    if (mobile || tablet) {
      return Column(
        children: [
          timerCard,
          const SizedBox(height: 14),
          configCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: timerCard),
        const SizedBox(width: 14),
        SizedBox(width: 410, child: configCard),
      ],
    );
  }

  Widget _timerCard() {
    final total = _durationMinutes * 60;
    final progress = total <= 0
        ? 0.0
        : (1 - (_remainingSeconds / total)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SESSÃO ATUAL',
            style: TextStyle(
              color: _primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _sessionTitle(),
            style: TextStyle(
              color: text,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF17345C)
                  : const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primary.withOpacity(0.12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _sessionState(),
                    style: const TextStyle(
                      color: Color(0xFF06152D),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _intentionText(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: soft,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 310,
              height: 310,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: dark
                          ? const Color(0xFF203B61)
                          : const Color(0xFFD8E7F5),
                      valueColor: const AlwaysStoppedAnimation(
                        _primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TEMPO RESTANTE',
                        style: TextStyle(
                          color: muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _timeText(),
                        style: TextStyle(
                          color: text,
                          fontSize: 61,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'minutos',
                        style: TextStyle(
                          color: muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: (_running || _paused)
                    ? _resetSession
                    : null,
                child: const Icon(
                  Icons.restart_alt_rounded,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: const Color(0xFF06152D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 15,
                  ),
                ),
                onPressed: _saving ? null : _startOrPause,
                icon: Icon(
                  _running && !_paused
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 19,
                ),
                label: Text(
                  _running && !_paused
                      ? 'Pausar'
                      : (_running && _paused
                          ? 'Continuar'
                          : 'Iniciar foco'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: (_running || _paused) && !_saving
                    ? () => _finishSession()
                    : null,
                child: const Icon(
                  Icons.stop_rounded,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Sua sessão continua contando mesmo se a página for atualizada.',
              style: TextStyle(
                color: muted,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _configCard() {
    final disabled = _running || _paused;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONFIGURAÇÃO',
            style: TextStyle(
              color: _primary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Preparar sessão',
            style: TextStyle(
              color: text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Intenção',
            style: TextStyle(
              color: muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: _intentionController,
            enabled: !disabled,
            onChanged: (_) {
              setState(() {});
              _saveActiveSession();
            },
            style: TextStyle(
              color: text,
              fontSize: 12,
            ),
            decoration: InputDecoration(
              hintText: 'Ex.: Revisar a matéria da prova',
              prefixIcon: const Icon(
                Icons.edit_outlined,
                color: _primary,
                size: 18,
              ),
              filled: true,
              fillColor: dark
                  ? const Color(0xFF0B1729)
                  : const Color(0xFFF7FBFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Meta vinculada',
            style: TextStyle(
              color: muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          DropdownButtonFormField<int>(
            value: _selectedMetaId,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
            ),
            onChanged: disabled
                ? null
                : (value) {
                    setState(() => _selectedMetaId = value);
                    _saveActiveSession();
                  },
            dropdownColor: dark
                ? const Color(0xFF0B1729)
                : Colors.white,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.track_changes_rounded,
                color: _primary,
              ),
              filled: true,
              fillColor: dark
                  ? const Color(0xFF0B1729)
                  : const Color(0xFFF7FBFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            hint: Text(
              'Selecione uma meta em andamento',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: muted,
                fontSize: 11.5,
              ),
            ),
            selectedItemBuilder: (context) {
              return _openMetas.map((meta) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    meta['titulo'].toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: text,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList();
            },
            items: _openMetas
                .map(
                  (meta) => DropdownMenuItem<int>(
                    value: meta['id'] as int,
                    child: Text(
                      meta['titulo'].toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Duração',
                style: TextStyle(
                  color: muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$_durationMinutes min',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final minutes in [15, 25, 45, 60]) ...[
                Expanded(
                  child: _durationButton(
                    minutes,
                    disabled,
                  ),
                ),
                if (minutes != 60)
                  const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Tempo personalizado',
            style: TextStyle(
              color: muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF0B1729)
                        : const Color(0xFFF7FBFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFF06152D)
                              .withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      _customStep(
                        Icons.remove_rounded,
                        disabled ? null : () => _incrementCustom(-1),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '$_customMinutes min',
                            style: TextStyle(
                              color: text,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      _customStep(
                        Icons.add_rounded,
                        disabled ? null : () => _incrementCustom(1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: dark
                      ? const Color(0xFF06152D)
                      : _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(82, 44),
                ),
                onPressed: disabled ? null : _applyCustom,
                child: const Text(
                  'Aplicar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dark
                  ? const Color(0xFF0B2A58).withOpacity(0.52)
                  : const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fullscreen_rounded,
                  color: _primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Você pode abrir a sessão em modo imersivo durante o foco.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 10.5,
                      height: 1.35,
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

  Widget _durationButton(
    int minutes,
    bool disabled,
  ) {
    final selected = _durationMinutes == minutes;

    return InkWell(
      onTap: disabled ? null : () => _setDuration(minutes),
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (dark
                  ? const Color(0xFF174A9B)
                  : const Color(0xFFEAF3FF))
              : (dark
                  ? const Color(0xFF0B1729)
                  : const Color(0xFFF7FBFF)),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected
                ? _primary.withOpacity(0.34)
                : (dark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFF06152D)
                        .withOpacity(0.08)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                color: selected ? Colors.white : text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'min',
              style: TextStyle(
                color: selected
                    ? Colors.white70
                    : muted,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _customStep(
    IconData icon,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 50,
        height: 44,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? muted : text,
        ),
      ),
    );
  }

  Widget _insights(bool mobile) {
    final cards = [
      _insightCard(
        Icons.timer_outlined,
        'Foco hoje',
        '$_todayMinutes min',
      ),
      _insightCard(
        Icons.check_circle_outline_rounded,
        'Sessões concluídas',
        '${_history.length}',
      ),
      _insightCard(
        Icons.calendar_month_outlined,
        'Melhor dia',
        '$_bestDayMinutes min',
      ),
    ];

    if (mobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1)
            const SizedBox(width: 10),
        ],
      ],
    );
  }

  Widget _insightCard(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: _primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: text,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                      'HISTÓRICO',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sessões recentes',
                      style: TextStyle(
                        color: text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 34,
              ),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF0B1729)
                    : const Color(0xFFF7FBFF),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.hourglass_empty_rounded,
                    color: _primary,
                    size: 28,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Seu foco ainda vai deixar marcas aqui.',
                    style: TextStyle(
                      color: text,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Conclua sua primeira sessão para começar a construir seu histórico.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _history.take(8).map((session) {
                final metaTitle =
                    session['meta_titulo']?.toString() ?? 'Sessão de foco';
                final start =
                    DateTime.tryParse(session['inicio']?.toString() ?? '');

                final dateText = start == null
                    ? 'Sessão registrada'
                    : '${start.day.toString().padLeft(2, '0')}/'
                        '${start.month.toString().padLeft(2, '0')}/'
                        '${start.year}';

                return Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF0B1729)
                        : const Color(0xFFF7FBFF),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFF06152D)
                              .withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.psychology_outlined,
                          color: _primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              metaTitle,
                              style: TextStyle(
                                color: text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateText,
                              style: TextStyle(
                                color: muted,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${session['duracao'] ?? 0} min',
                        style: TextStyle(
                          color: text,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: dark
          ? const Color(0xFF0F1B2F)
          : Colors.white.withOpacity(0.94),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: dark
            ? Colors.white.withOpacity(0.055)
            : const Color(0xFF06152D).withOpacity(0.07),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            dark ? 0.16 : 0.06,
          ),
          blurRadius: 24,
          offset: const Offset(0, 10),
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
            Divider(color: _primary.withOpacity(0.10)),
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
                  ),
                  _navItem(
                    Icons.psychology_outlined,
                    'Sala de foco',
                    '/foco',
                    active: true,
                  ),
                  _navItem(
                    Icons.trending_up_rounded,
                    'Evolução',
                    '/evolucao',
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08)),
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
            _drawerItem(
              'Feed',
              '/feed',
              Icons.home_rounded,
            ),
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
            ),
            _drawerItem(
              'Sala de foco',
              '/foco',
              Icons.psychology_outlined,
              active: true,
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