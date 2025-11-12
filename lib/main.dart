import 'package:flame/game.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          return _KeyboardGameWrapper(
            game: game,
            child: GameWidget(
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
            ),
          );
        },
        '/resume': (context) => const ResumeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

// Old counter app removed; routes now point to main menu and game

// Intent classes for keyboard shortcuts
class MoveLeftIntent extends Intent {
  const MoveLeftIntent();
}

class MoveRightIntent extends Intent {
  const MoveRightIntent();
}

// Wrapper widget to handle keyboard input for the game
class _KeyboardGameWrapper extends StatefulWidget {
  final RunnerGame game;
  final Widget child;

  const _KeyboardGameWrapper({
    required this.game,
    required this.child,
  });

  @override
  State<_KeyboardGameWrapper> createState() => _KeyboardGameWrapperState();
}

class _KeyboardGameWrapperState extends State<_KeyboardGameWrapper> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const MoveLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const MoveRightIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          MoveLeftIntent: CallbackAction<MoveLeftIntent>(
            onInvoke: (intent) {
              widget.game.moveLeft();
              return null;
            },
          ),
          MoveRightIntent: CallbackAction<MoveRightIntent>(
            onInvoke: (intent) {
              widget.game.moveRight();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: GestureDetector(
            onTap: () {
              // Re-request focus when user taps on the game
              _focusNode.requestFocus();
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
