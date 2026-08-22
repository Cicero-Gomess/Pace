import 'package:flutter/material.dart';

import 'pace_session.dart';
import 'pace_shell.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  Map<String, dynamic> user = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await PaceSession.currentUser();
    if (!mounted) return;
    setState(() {
      user = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF05070C) : const Color(0xFFF4F8FD);
    final text = dark ? Colors.white : const Color(0xFF172033);
    final muted = dark ? const Color(0xFF98A8BF) : const Color(0xFF6F7F96);

    if (loading) return Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator(color: pacePrimary)));

    return PaceShell(
      currentRoute: '/notificacoes',
      username: PaceSession.username(user),
      avatarValue: PaceSession.avatar(user),
      backgroundColor: bg,
      child: Container(
        color: bg,
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF0C1627) : Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: pacePrimary.withOpacity(0.10)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: pacePrimary, size: 44),
                  const SizedBox(height: 14),
                  Text('Notificações', style: TextStyle(color: text, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(
                    'Esta área já está preparada para receber as notificações do Pace quando o backend disponibilizar esse recurso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, height: 1.55),
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
