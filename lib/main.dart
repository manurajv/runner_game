import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'ui/main_menu.dart';
import 'ui/resume_screen.dart';
import 'ui/settings_screen.dart';
import 'game/runner_game.dart';
import 'ui/runner_overlays.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runner Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const MainMenuScreen(),
        '/play': (context) {
          final game = RunnerGame();
          return GameWidget(
            game: game,
            overlayBuilderMap: {
              'runner_start': (context, game) => RunnerStartOverlay(game: game as RunnerGame),
              'runner_hud': (context, game) => RunnerHudOverlay(game: game as RunnerGame),
              'runner_gameover': (context, game) => RunnerGameOverOverlay(game: game as RunnerGame),
              'runner_pause': (context, game) => RunnerPauseOverlay(game: game as RunnerGame),
              'runner_resume': (context, game) => RunnerResumeOverlay(game: game as RunnerGame),
            },
            initialActiveOverlays: const ['runner_start'],
          );
        },
        '/resume': (context) => const ResumeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
// Old counter app removed; routes now point to main menu and game
