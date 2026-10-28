import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

const Color _primary = Color(0xFF1769E8);
const Color _accent = Color(0xFFFFC928);
const Color _success = Color(0xFF2AA879);

class EvolucaoPage extends StatefulWidget {
  const EvolucaoPage({super.key});

  @override
  State<EvolucaoPage> createState() => _EvolucaoPageState();
}

class _EvolucaoPageState extends State<EvolucaoPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic> _user = {};
  List<Map<String, dynamic>> _metas = [];
  List<Map<String, dynamic>> _sessions = [];

  int _period = 7;
  bool _loading = true;
  bool _sidebarHovered = false;
  String? _sidebarItemHovered;

  bool get dark => Theme.of(context).brightness == Brightness.dark;
  Color get bg => dark ? const Color(0xFF06101F) : const Color(0xFFEAF3FB);
  Color get text => dark ? const Color(0xFFF2F6FF) : const Color(0xFF06152D);
  Color get soft => dark ? const Color(0xFFDCE5F4) : const Color(0xFF203B61);
  Color get muted => dark ? const Color(0xFF98A8BF) : const Color(0xFF61758F);

  @override
  void initState() {
    super.initState();
    _load();
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
      if (mounted) Navigator.of(context).pushReplacementNamed('/entrar');
      throw Exception('Sua sessão expirou.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map ? (data['detail'] ?? data['message']) : null;
      throw Exception(detail?.toString() ?? 'Não foi possível carregar os dados.');
    }
    return data;
  }

  Map<String, dynamic> _normalizeMeta(dynamic value) {
    final raw = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    final status = (raw['status'] ?? '').toString().trim().toLowerCase();
    final progressRaw = raw['progresso'] ?? raw['progress'] ?? 0;
    final progressNumber = progressRaw is num
        ? progressRaw.toDouble()
        : double.tryParse(progressRaw.toString().replaceAll(',', '.')) ?? 0.0;
    final progress = progressNumber.clamp(0.0, 100.0);

    return {
      'id': int.tryParse('${raw['id']}') ?? 0,
      'titulo': (raw['titulo'] ?? '').toString(),
      'descricao': (raw['descricao'] ?? '').toString(),
      'categoria': (raw['categoria'] ?? 'Outro').toString(),
      'prazo': raw['prazo']?.toString() ?? '',
      'progresso': progress,
      'status': status == 'concluida' || progress >= 100
          ? 'concluida'
          : 'em andamento',
    };
  }

  Map<String, dynamic> _normalizeSession(dynamic value, Map<String, dynamic> meta) {
    final raw = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    int duration = 0;

    for (final candidate in [raw['duracao'], raw['duration'], raw['duration_minutes'], raw['duracao_minutos'], raw['minutos']]) {
      if (candidate == null) continue;
      final number = candidate is num
          ? candidate.toDouble()
          : double.tryParse(candidate.toString().replaceAll(',', '.'));
      if (number != null && number > 0) {
        duration = number.round();
        break;
      }
    }

    if (duration == 0) {
      for (final candidate in [raw['durationSeconds'], raw['duration_seconds'], raw['duracao_segundos']]) {
        if (candidate == null) continue;
        final number = candidate is num
            ? candidate.toDouble()
            : double.tryParse(candidate.toString().replaceAll(',', '.'));
        if (number != null && number > 0) {
          duration = (number / 60).round();
          if (duration <= 0) duration = 1;
          break;
        }
      }
    }

    return {
      'id': int.tryParse('${raw['id'] ?? 0}') ?? 0,
      'meta_id': int.tryParse('${raw['meta_id'] ?? raw['id_meta'] ?? meta['id']}') ?? 0,
      'inicio': (raw['inicio'] ?? raw['started_at'] ?? raw['startedAt'] ?? '').toString(),
      'duracao': duration,
      'meta_titulo': meta['titulo']?.toString() ?? 'Meta',
      'categoria': meta['categoria']?.toString() ?? 'Outro',
    };
  }

  Future<void> _load() async {
    final token = await _token();
    if (token == null || token.isEmpty) {
      if (mounted) Navigator.of(context).pushReplacementNamed('/entrar');
      return;
    }

    try {
      final base = await Future.wait([
        http.get(ApiConfig.uri('/profile/me'), headers: _headers(token)),
        http.get(ApiConfig.uri('/metas/listar_metas'), headers: _headers(token)),
      ]);

      final userData = await _parse(base[0]);
      final metasData = await _parse(base[1]);
      final metas = metasData is List
          ? metasData.map(_normalizeMeta).toList()
          : <Map<String, dynamic>>[];

      final sessionLists = await Future.wait(
        metas.map((meta) async {
          try {
            final response = await http.get(
              ApiConfig.uri('/sessoes/meta/${meta['id']}'),
              headers: _headers(token),
            );
            if (response.statusCode < 200 || response.statusCode >= 300) {
              return <Map<String, dynamic>>[];
            }
            final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
            if (decoded is! List) return <Map<String, dynamic>>[];
            return decoded.map((e) => _normalizeSession(e, meta)).toList();
          } catch (_) {
            return <Map<String, dynamic>>[];
          }
        }),
      );

      final sessions = <Map<String, dynamic>>[];
      for (final list in sessionLists) {
        sessions.addAll(list);
      }
      sessions.sort((a, b) {
        final ad = _dateFromSession(a);
        final bd = _dateFromSession(b);
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

      if (!mounted) return;
      setState(() {
        _user = userData is Map ? Map<String, dynamic>.from(userData) : {};
        _metas = metas;
        _sessions = sessions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  DateTime? _dateFromSession(Map<String, dynamic> session) =>
      DateTime.tryParse(session['inicio']?.toString() ?? '');

  List<Map<String, dynamic>> get _periodSessions {
    final cutoff = DateTime.now().subtract(Duration(days: _period));
    return _sessions.where((s) {
      final d = _dateFromSession(s);
      return d != null && d.isAfter(cutoff);
    }).toList();
  }

  int get _focusMinutes => _periodSessions.fold<int>(
        0,
        (sum, s) => sum + (int.tryParse('${s['duracao'] ?? 0}') ?? 0),
      );

  int get _completedGoals => _metas.where((m) => m['status'] == 'concluida').length;
  int get _sessionCount => _periodSessions.length;

  int get _activeDays {
    final days = <String>{};
    for (final s in _periodSessions) {
      final d = _dateFromSession(s);
      if (d != null) {
        days.add('${d.year}-${d.month}-${d.day}');
      }
    }
    return days.length;
  }

  int get _streak {
    final days = <DateTime>{};
    for (final s in _sessions) {
      final d = _dateFromSession(s);
      if (d != null) days.add(DateTime(d.year, d.month, d.day));
    }
    if (days.isEmpty) return 0;
    var current = DateTime.now();
    current = DateTime(current.year, current.month, current.day);
    if (!days.contains(current)) {
      final yesterday = current.subtract(const Duration(days: 1));
      if (!days.contains(yesterday)) return 0;
      current = yesterday;
    }
    int count = 0;
    while (days.contains(current)) {
      count++;
      current = current.subtract(const Duration(days: 1));
    }
    return count;
  }

  int get _score {
    if (_metas.isEmpty && _periodSessions.isEmpty) {
      return 0;
    }

    final taxaMetas = _metas.isNotEmpty
        ? (_completedGoals / _metas.length) * 100
        : 0.0;

    final metasScore = taxaMetas * 0.30;
    final focoScore = (_focusMinutes / 12).clamp(0.0, 25.0);
    final sequenciaScore = (_streak * 3).clamp(0.0, 20.0);
    final constanciaScore = (_activeDays * 2).clamp(0.0, 15.0);
    final conclusoesScore = (_completedGoals * 2).clamp(0.0, 10.0);

    return (metasScore +
            focoScore +
            sequenciaScore +
            constanciaScore +
            conclusoesScore)
        .round()
        .clamp(0, 100);
  }

  Map<String, int> _weeklyTotals(int weeks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = today.subtract(Duration(days: weeks * 7 - 1));
    final result = <String, int>{};
    for (int i = 0; i < weeks; i++) {
      final start = first.add(Duration(days: i * 7));
      result[_weekKey(start)] = 0;
    }
    for (final s in _sessions) {
      final d = _dateFromSession(s);
      if (d == null || d.isBefore(first)) continue;
      final index = DateTime(d.year, d.month, d.day).difference(first).inDays ~/ 7;
      if (index < 0 || index >= weeks) continue;
      final key = _weekKey(first.add(Duration(days: index * 7)));
      result[key] = (result[key] ?? 0) + (int.tryParse('${s['duracao'] ?? 0}') ?? 0);
    }
    return result;
  }

  String _weekKey(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  Map<String, Map<String, int>> get _categoryStats {
    final result = <String, Map<String, int>>{};
    for (final meta in _metas) {
      final category = meta['categoria']?.toString().trim().isNotEmpty == true
          ? meta['categoria'].toString()
          : 'Outro';
      final bucket = result.putIfAbsent(category, () => {'total': 0, 'done': 0});
      bucket['total'] = (bucket['total'] ?? 0) + 1;
      if (meta['status'] == 'concluida') bucket['done'] = (bucket['done'] ?? 0) + 1;
    }
    return result;
  }

  List<Map<String, dynamic>> get _timeline {
    final events = <Map<String, dynamic>>[];
    for (final s in _sessions) {
      final d = _dateFromSession(s);
      if (d != null) {
        events.add({
          'date': d,
          'icon': Icons.psychology_outlined,
          'title': 'Foco em ${s['meta_titulo']}',
          'subtitle': '${s['duracao']} min de foco',
        });
      }
    }
    for (final m in _metas.where((m) => m['status'] == 'concluida')) {
      events.add({
        'date': DateTime.tryParse(m['prazo']?.toString() ?? '') ?? DateTime.now(),
        'icon': Icons.emoji_events_outlined,
        'title': 'Meta concluída: ${m['titulo']}',
        'subtitle': m['categoria']?.toString() ?? '',
      });
    }
    events.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return events.take(12).toList();
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final r = minutes % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}min';
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
                          ? const Center(child: CircularProgressIndicator(color: _primary))
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                mobile ? 18 : (tablet ? 28 : 38),
                                mobile ? 20 : 28,
                                mobile ? 18 : (tablet ? 28 : 38),
                                80,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1180),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _hero(mobile),
                                      const SizedBox(height: 20),
                                      _overview(mobile, tablet),
                                      const SizedBox(height: 14),
                                      _metrics(mobile),
                                      const SizedBox(height: 14),
                                      _mainGrid(mobile, tablet),
                                      const SizedBox(height: 14),
                                      _consistency(),
                                      const SizedBox(height: 14),
                                      _bottomGrid(mobile, tablet),
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

  Widget _background() => Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const [Color(0xFF081426), Color(0xFF06101F), Color(0xFF040B15)]
                    : const [Color(0xFFF4F8FD), Color(0xFFEAF1F9), Color(0xFFE4EDF8)],
              ),
            ),
          ),
        ),
      );

  Widget _hero(bool mobile) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  SizedBox(width: 18, child: Divider(thickness: 3, color: _accent)),
                  SizedBox(width: 8),
                  Text('DESENVOLVIMENTO', style: TextStyle(color: _primary, fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ]),
                const SizedBox(height: 7),
                Text('Evolução', style: TextStyle(color: text, fontSize: mobile ? 34 : 42, height: 1, fontWeight: FontWeight.w900, letterSpacing: -1.2)),
                const SizedBox(height: 7),
                Text('Veja como seus pequenos passos estão construindo resultados reais.', style: TextStyle(color: muted, fontSize: 14)),
              ],
            ),
          ),
          if (!mobile)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF0B1729) : Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: dark ? Colors.white.withOpacity(0.06) : const Color(0xFF06152D).withOpacity(0.08)),
              ),
              child: Row(children: [_periodButton(7, '7 dias'), _periodButton(30, '30 dias'), _periodButton(90, '90 dias')]),
            ),
        ],
      );

  Widget _periodButton(int value, String label) {
    final active = _period == value;
    return InkWell(
      onTap: () => setState(() => _period = value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(color: active ? _primary : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: TextStyle(color: active ? Colors.white : muted, fontSize: 10.5, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _overview(bool mobile, bool tablet) {
    final scoreCard = _panel(
      child: Row(
        children: [
          SizedBox(
            width: mobile ? 115 : 150,
            height: mobile ? 115 : 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: _score / 100,
                    strokeWidth: 12,
                    backgroundColor: dark ? const Color(0xFF203B61) : const Color(0xFFD8E7F5),
                    valueColor: const AlwaysStoppedAnimation(_primary),
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$_score', style: TextStyle(color: text, fontSize: mobile ? 30 : 40, fontWeight: FontWeight.w900)),
                  Text('ÍNDICE', style: TextStyle(color: muted, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SEU MOMENTO', style: TextStyle(color: _primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                const SizedBox(height: 6),
                Text(
                  _score >= 70 ? 'Seu ritmo está ganhando força.' : _score >= 40 ? 'Sua evolução está tomando forma.' : 'Seu histórico está começando.',
                  style: TextStyle(color: text, fontSize: mobile ? 18 : 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Text(
                  _score >= 70 ? 'Você está combinando foco, constância e objetivos concluídos.' : 'Continue registrando sessões e avançando nas metas para revelar padrões mais claros.',
                  style: TextStyle(color: muted, fontSize: 11.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final nextCard = _panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('PRÓXIMO PASSO', style: TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        const SizedBox(height: 10),
        const Icon(Icons.flag_outlined, color: _primary, size: 28),
        const SizedBox(height: 14),
        Text(_completedGoals < _metas.length ? 'Continue uma meta em andamento.' : 'Registre mais uma sessão de foco.', style: TextStyle(color: text, fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text(_completedGoals < _metas.length ? 'Finalizar o que você começou aumenta a clareza da sua evolução.' : 'Mais uma sessão ajuda a fortalecer seu histórico de constância.', style: TextStyle(color: muted, fontSize: 11, height: 1.45)),
      ]),
    );

    if (mobile || tablet) return Column(children: [scoreCard, const SizedBox(height: 12), nextCard]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: scoreCard), const SizedBox(width: 12), Expanded(flex: 2, child: nextCard)]);
  }

  Widget _metrics(bool mobile) {
    final cards = [
      _metric(Icons.timer_outlined, 'Tempo focado', _formatDuration(_focusMinutes), 'no período'),
      _metric(Icons.emoji_events_outlined, 'Metas concluídas', '$_completedGoals', 'de ${_metas.length}'),
      _metric(Icons.local_fire_department_outlined, 'Sequência', '$_streak', _streak == 1 ? 'dia' : 'dias'),
      _metric(Icons.check_circle_outline_rounded, 'Sessões', '$_sessionCount', 'concluídas'),
    ];
    if (mobile) return Column(children: [for (int i = 0; i < cards.length; i++) ...[cards[i], if (i < cards.length - 1) const SizedBox(height: 10)]]);
    return Row(children: [for (int i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i < cards.length - 1) const SizedBox(width: 10)]]);
  }

  Widget _metric(IconData icon, String label, String value, String helper) => _panel(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(width: 42, height: 42, alignment: Alignment.center, decoration: BoxDecoration(color: _primary.withOpacity(0.10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: _primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: muted, fontSize: 9.5)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: text, fontSize: 19, fontWeight: FontWeight.w900)),
            Text(helper, style: TextStyle(color: muted, fontSize: 8.5)),
          ])),
        ]),
      );

  Widget _mainGrid(bool mobile, bool tablet) {
    final left = _timelineCard();
    final right = _categoriesCard();
    if (mobile || tablet) return Column(children: [left, const SizedBox(height: 12), right]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: left), const SizedBox(width: 12), Expanded(flex: 2, child: right)]);
  }

  Widget _timelineCard() {
    final events = _timeline;
    return _panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardHeader('SUA HISTÓRIA', 'Momentos que construíram sua evolução', 'Linha do tempo real'),
        const SizedBox(height: 15),
        if (events.isEmpty)
          _empty(Icons.history_rounded, 'Sua história ainda será escrita aqui.', 'Metas concluídas e sessões de foco aparecerão nesta linha do tempo.')
        else
          ...events.map((event) {
            final d = event['date'] as DateTime;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: _primary.withOpacity(0.10), borderRadius: BorderRadius.circular(11)), child: Icon(event['icon'] as IconData, color: _primary, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: dark ? const Color(0xFF132238) : const Color(0xFFF7FBFF), borderRadius: BorderRadius.circular(13), border: Border.all(color: dark ? Colors.white.withOpacity(0.05) : const Color(0xFF06152D).withOpacity(0.06))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}', style: const TextStyle(color: _accent, fontSize: 8.5, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(event['title'].toString(), style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(event['subtitle'].toString(), style: TextStyle(color: muted, fontSize: 9.5)),
                  ]),
                )),
              ]),
            );
          }),
      ]),
    );
  }

  Widget _categoriesCard() {
    final stats = _categoryStats.entries.toList();
    return _panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardHeader('EQUILÍBRIO', 'Progresso por categoria', null),
        const SizedBox(height: 15),
        if (stats.isEmpty)
          _empty(Icons.sell_outlined, 'Nenhuma categoria ainda.', 'Crie metas para visualizar seu progresso em diferentes áreas.')
        else
          ...stats.map((entry) {
            final total = entry.value['total'] ?? 0;
            final done = entry.value['done'] ?? 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(entry.key, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.w800))), Text('$done/$total', style: TextStyle(color: muted, fontSize: 9.5))]),
                const SizedBox(height: 7),
                ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: total == 0 ? 0 : done / total, minHeight: 8, backgroundColor: dark ? Colors.white.withOpacity(0.06) : const Color(0xFFDCE8F5), valueColor: const AlwaysStoppedAnimation(_primary))),
              ]),
            );
          }),
      ]),
    );
  }

  Widget _consistency() {
    final weeks = _weeklyTotals(12);
    final vals = weeks.values.toList();
    final max = vals.isEmpty ? 0 : vals.reduce((a, b) => a > b ? a : b);
    return _panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardHeader('CONSTÂNCIA', 'Resumo por semana', 'Últimas 12 semanas'),
        const SizedBox(height: 15),
        SizedBox(
          height: 170,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeks.entries.map((e) {
              final ratio = max == 0 ? 0.0 : e.value / max;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(e.value == 0 ? '' : '${e.value}', style: TextStyle(color: muted, fontSize: 8)),
                  const SizedBox(height: 4),
                  Container(height: 18 + (105 * ratio), decoration: BoxDecoration(color: e.value == 0 ? (dark ? Colors.white.withOpacity(0.05) : const Color(0xFFDCE8F5)) : _primary.withOpacity(0.35 + 0.65 * ratio), borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 6),
                  Text(e.key, style: TextStyle(color: muted, fontSize: 7)),
                ]),
              ));
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _bottomGrid(bool mobile, bool tablet) {
    final insight = _insightCard();
    final achievements = _achievementsCard();
    if (mobile || tablet) return Column(children: [insight, const SizedBox(height: 12), achievements]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 2, child: insight), const SizedBox(width: 12), Expanded(flex: 3, child: achievements)]);
  }

  Widget _insightCard() {
    String title;
    String description;
    IconData icon;
    if (_focusMinutes >= 120) {
      title = 'Seu foco está criando volume.';
      description = 'Você acumulou uma boa quantidade de minutos no período. Continue protegendo esse ritmo.';
      icon = Icons.trending_up_rounded;
    } else if (_streak >= 3) {
      title = 'Sua constância está aparecendo.';
      description = 'Você manteve atividade em dias seguidos, um sinal forte de hábito em formação.';
      icon = Icons.local_fire_department_outlined;
    } else if (_completedGoals > 0) {
      title = 'Você já transformou intenção em resultado.';
      description = 'Metas concluídas mostram que seu progresso está saindo do planejamento e virando entrega.';
      icon = Icons.emoji_events_outlined;
    } else {
      title = 'Seu ritmo está começando a aparecer.';
      description = 'Continue registrando pequenas sessões e atualizando suas metas para enxergar padrões mais claros.';
      icon = Icons.lightbulb_outline_rounded;
    }
    return _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _cardHeader('LEITURA INTELIGENTE', 'Insight Pace', null),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: _accent.withOpacity(0.13), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: const Color(0xFFD89A00))),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(description, style: TextStyle(color: muted, fontSize: 10.5, height: 1.45))])),
      ]),
    ]));
  }

  Widget _achievementsCard() {
    final totalFocus = _sessions.fold<int>(0, (sum, s) => sum + (int.tryParse('${s['duracao'] ?? 0}') ?? 0));
    final items = [
      ('Primeiro passo', 'Conclua sua primeira sessão de foco.', Icons.directions_walk_outlined, _sessions.isNotEmpty),
      ('Objetivo alcançado', 'Conclua sua primeira meta.', Icons.emoji_events_outlined, _completedGoals >= 1),
      ('Uma hora de presença', 'Acumule uma hora de foco.', Icons.schedule_rounded, totalFocus >= 60),
      ('Constância', 'Mantenha três dias seguidos.', Icons.local_fire_department_outlined, _streak >= 3),
      ('Cinco metas', 'Conclua cinco metas.', Icons.checklist_rounded, _completedGoals >= 5),
      ('Foco profundo', 'Faça uma sessão de 60 minutos.', Icons.psychology_outlined, _sessions.any((s) => (int.tryParse('${s['duracao'] ?? 0}') ?? 0) >= 60)),
    ];
    final unlocked = items.where((e) => e.$4).length;
    return _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _cardHeader('MARCOS', 'Conquistas', '$unlocked de ${items.length}'),
      const SizedBox(height: 15),
      LayoutBuilder(builder: (context, constraints) {
        final cols = constraints.maxWidth >= 520 ? 2 : 1;
        const gap = 10.0;
        final w = (constraints.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(spacing: gap, runSpacing: gap, children: items.map((item) => SizedBox(
          width: w,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(color: item.$4 ? _success.withOpacity(0.08) : (dark ? const Color(0xFF132238) : const Color(0xFFF7FBFF)), borderRadius: BorderRadius.circular(13), border: Border.all(color: item.$4 ? _success.withOpacity(0.20) : (dark ? Colors.white.withOpacity(0.05) : const Color(0xFF06152D).withOpacity(0.06)))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(item.$4 ? item.$3 : Icons.lock_outline_rounded, color: item.$4 ? _success : muted, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$1, style: TextStyle(color: text, fontSize: 11.5, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(item.$2, style: TextStyle(color: muted, fontSize: 9, height: 1.35))])),
            ]),
          ),
        )).toList());
      }),
    ]));
  }

  Widget _panel({required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(20)}) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF0F1B2F) : Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dark ? Colors.white.withOpacity(0.055) : const Color(0xFF06152D).withOpacity(0.07)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(dark ? 0.14 : 0.06), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: child,
      );

  Widget _cardHeader(String kicker, String title, String? helper) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(kicker, style: const TextStyle(color: _primary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)), const SizedBox(height: 4), Text(title, style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w900))])),
          if (helper != null) Text(helper, style: TextStyle(color: muted, fontSize: 9.5)),
        ],
      );

  Widget _empty(IconData icon, String title, String desc) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(color: dark ? const Color(0xFF132238) : const Color(0xFFF7FBFF), borderRadius: BorderRadius.circular(14)),
        child: Column(children: [Icon(icon, color: _primary, size: 26), const SizedBox(height: 8), Text(title, textAlign: TextAlign.center, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(desc, textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 9.5))]),
      );

  Widget _sidebar() {
    const collapsed = 88.0;
    const expanded = 244.0;
    final width = _sidebarHovered ? expanded : collapsed;
    return MouseRegion(
      onEnter: (_) => setState(() => _sidebarHovered = true),
      onExit: (_) => setState(() { _sidebarHovered = false; _sidebarItemHovered = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: width,
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
        decoration: BoxDecoration(color: const Color(0xFF06152D), border: Border(right: BorderSide(color: _primary.withOpacity(0.09)))),
        child: Column(children: [
          SizedBox(height: 70, child: LayoutBuilder(builder: (context, c) {
            final show = c.maxWidth >= 150;
            return Row(children: [
              Padding(padding: const EdgeInsets.only(left: 9), child: Image.asset('assets/images/pace_icon.png', width: 46, height: 46)),
              if (show) ...[const SizedBox(width: 10), const Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pace', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)), Text('Evolução contínua', style: TextStyle(color: Color(0xFF8FA5C0), fontSize: 10))]))],
            ]);
          })),
          Divider(color: _primary.withOpacity(0.10)),
          const SizedBox(height: 8),
          Expanded(child: ListView(padding: EdgeInsets.zero, children: [
            _sectionLabel('COMUNIDADE'),
            _navItem(Icons.home_rounded, 'Feed', '/feed'),
            _navItem(Icons.explore_outlined, 'Explorar', '/explorar'),
            _navItem(Icons.edit_square, 'Postar', '/postar'),
            const SizedBox(height: 8),
            _sectionLabel('DESENVOLVIMENTO'),
            _navItem(Icons.track_changes_rounded, 'Metas', '/metas'),
            _navItem(Icons.psychology_outlined, 'Sala de foco', '/foco'),
            _navItem(Icons.trending_up_rounded, 'Evolução', '/evolucao', active: true),
          ])),
          Divider(color: Colors.white.withOpacity(0.08)),
          _navItem(Icons.settings_outlined, 'Configurações', '/config'),
          _profileItem(),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label) => SizedBox(
        height: 30,
        child: LayoutBuilder(builder: (context, c) {
          final show = c.maxWidth >= 150;
          return Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Align(alignment: Alignment.centerLeft, child: show ? Text(label, style: const TextStyle(color: Color(0xFF8FA5C0), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.1)) : const SizedBox.shrink()));
        }),
      );

  Widget _navItem(IconData icon, String label, String route, {bool active = false}) {
    final hovered = _sidebarItemHovered == route;
    final highlighted = active || hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _sidebarItemHovered = route),
      onExit: (_) { if (_sidebarItemHovered == route) setState(() => _sidebarItemHovered = null); },
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () { if (!active) Navigator.of(context).pushNamed(route); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 50,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: highlighted ? (active ? const Color(0xFF174A9B) : Colors.white.withOpacity(0.07)) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: highlighted ? Border.all(color: active ? _primary.withOpacity(0.55) : Colors.white.withOpacity(0.08)) : null),
          child: LayoutBuilder(builder: (context, c) {
            final show = c.maxWidth >= 150;
            return Row(children: [
              Stack(clipBehavior: Clip.none, children: [if (active) Positioned(left: -12, top: 1, bottom: 1, child: Container(width: 3, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(999)))), SizedBox(width: 24, child: Icon(icon, color: highlighted ? Colors.white : const Color(0xFFC7D5E8), size: 23))]),
              if (show) ...[const SizedBox(width: 16), Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: highlighted ? Colors.white : const Color(0xFFC7D5E8), fontSize: 15, fontWeight: FontWeight.w800)))],
            ]);
          }),
        ),
      ),
    );
  }

  Widget _profileItem() {
    final photo = (_user['foto_perfil'] ?? '').toString();
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/perfil'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: LayoutBuilder(builder: (context, c) {
          final show = c.maxWidth >= 150;
          return Row(children: [
            CircleAvatar(radius: 14, backgroundImage: photo.isNotEmpty ? ApiConfig.imageProvider(photo) : const AssetImage('assets/images/pace_icon.png')),
            if (show) ...[const SizedBox(width: 12), const Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Meu perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)), Text('Ver perfil', style: TextStyle(color: Color(0xFF8FA5C0), fontSize: 9.5))]))],
          ]);
        }),
      ),
    );
  }

  Widget _mobileTopBar() => Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: const Color(0xFF06152D),
        child: Row(children: [IconButton(onPressed: () => _scaffoldKey.currentState?.openDrawer(), icon: const Icon(Icons.menu_rounded, color: Colors.white)), const SizedBox(width: 8), Image.asset('assets/images/pace_icon.png', width: 34, height: 34)]),
      );

  Widget _mobileDrawer() => Drawer(
        backgroundColor: const Color(0xFF06152D),
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(14), children: [
            const SizedBox(height: 10),
            Image.asset('assets/images/pace_icon.png', width: 52, height: 52, alignment: Alignment.centerLeft),
            const SizedBox(height: 18),
            _drawerItem('Feed', '/feed', Icons.home_rounded),
            _drawerItem('Explorar', '/explorar', Icons.explore_outlined),
            _drawerItem('Postar', '/postar', Icons.edit_square),
            _drawerItem('Metas', '/metas', Icons.track_changes_rounded),
            _drawerItem('Sala de foco', '/foco', Icons.psychology_outlined),
            _drawerItem('Evolução', '/evolucao', Icons.trending_up_rounded, active: true),
          ]),
        ),
      );

  Widget _drawerItem(String label, String route, IconData icon, {bool active = false}) => ListTile(
        leading: Icon(icon, color: active ? Colors.white : const Color(0xFFC7D5E8)),
        title: Text(label, style: TextStyle(color: active ? Colors.white : const Color(0xFFC7D5E8), fontWeight: FontWeight.w700)),
        tileColor: active ? const Color(0xFF174A9B) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: active ? () => Navigator.pop(context) : () => Navigator.of(context).pushNamed(route),
      );
}