import 'package:flutter/material.dart';

import 'theme_controller.dart';
import 'sobre.dart';
import 'index.dart';
import 'entrar.dart';
import 'cadastro.dart';
import 'feed.dart';
import 'postar.dart';
import 'explorar.dart';
import 'configuracoes.dart';
import 'perfil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController();
  await themeController.loadTheme();

  runApp(PaceApp(themeController: themeController));
}

class PaceApp extends StatelessWidget {
  final ThemeController themeController;

  const PaceApp({
    super.key,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Pace',
          themeMode: themeController.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF4F7FB),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3059AA),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF05070C),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3059AA),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          initialRoute: '/',
          onGenerateRoute: (settings) {
            Widget page;

            switch (settings.name) {
              case '/':
                page = const HomePage();
                break;

              case '/entrar':
                page = const EntrarPage();
                break;

              case '/cadastro':
                page = const CadastroPage();
                break;

              case '/feed':
                page = const FeedPage();
                break;

              case '/postar':
                page = const PostarPage();
                break;

              case '/explorar':
                page = const ExplorarPage();
                break;

              case '/config':
                page = ConfigPage(themeController: themeController);
                break;

              case '/sobre':
                page = const SobrePage();
                break;

              case '/perfil':
                page = const PerfilPage();
                break;

              default:
                page = const HomePage();
            }

            return PageRouteBuilder(
              settings: settings,
              transitionDuration: const Duration(milliseconds: 650),
              reverseTransitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                );

                final fade = Tween<double>(
                  begin: 0,
                  end: 1,
                ).animate(curved);

                final slide = Tween<Offset>(
                  begin: const Offset(0.08, 0.02),
                  end: Offset.zero,
                ).animate(curved);

                final scale = Tween<double>(
                  begin: 0.985,
                  end: 1,
                ).animate(curved);

                return FadeTransition(
                  opacity: fade,
                  child: SlideTransition(
                    position: slide,
                    child: ScaleTransition(
                      scale: scale,
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}