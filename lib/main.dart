import 'package:flame/game.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'game/runner_game.dart';
import 'ui/runner_overlays.dart';
import 'firebase_options.dart';
import 'ui/app_theme.dart';
import 'ui/main_menu.dart';
import 'ui/resume_screen.dart';
import 'ui/settings_screen.dart';
import 'services/audio_permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AudioPlayer.global.setAudioContext(
    AudioContext(
      android: AudioContextAndroid(
        usageType: AndroidUsageType.game,
        contentType: AndroidContentType.sonification,
        audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        isSpeakerphoneOn: true,
      ),
    ),
  );
  await AudioPermissionService.instance.ensureMicrophonePermission();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    Firebase.app();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Runner Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      routes: {
        '/': (context) => const MainMenuScreen(),
        '/play': (context) {
          final game = RunnerGame();
          return GameWidget(
            game: game,
            overlayBuilderMap: {
              'runner_start': (context, game) =>
                  RunnerStartOverlay(game: game as RunnerGame),
              'runner_hud': (context, game) =>
                  RunnerHudOverlay(game: game as RunnerGame),
              'runner_gameover': (context, game) =>
                  RunnerGameOverOverlay(game: game as RunnerGame),
              'runner_pause': (context, game) =>
                  RunnerPauseOverlay(game: game as RunnerGame),
              'runner_resume': (context, game) =>
                  RunnerResumeOverlay(game: game as RunnerGame),
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
