import 'dart:async';
import 'package:flutter/material.dart';
import '../game/runner_game.dart';

class RunnerStartOverlay extends StatefulWidget {
  final RunnerGame game;
  const RunnerStartOverlay({super.key, required this.game});

  @override
  State<RunnerStartOverlay> createState() => _RunnerStartOverlayState();
}

class _RunnerStartOverlayState extends State<RunnerStartOverlay> {
  bool _counting = false;
  int _sec = 3;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _go() {
    if (_counting) return;
    setState(() => _counting = true);
    _sec = 3;
    _t = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_sec <= 1) {
        timer.cancel();
        widget.game.start();
        widget.game.overlays
          ..remove('runner_start')
          ..add('runner_hud');
      } else {
        setState(() => _sec -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Runner Game', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Swipe lanes with buttons. Avoid obstacles. Get points!', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            if (!_counting)
              ElevatedButton.icon(
                onPressed: _go,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start'),
              )
            else
              Text('$_sec', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class RunnerHudOverlay extends StatefulWidget {
  final RunnerGame game;
  const RunnerHudOverlay({super.key, required this.game});

  @override
  State<RunnerHudOverlay> createState() => _RunnerHudOverlayState();
}

class _RunnerHudOverlayState extends State<RunnerHudOverlay> {
  RunnerGame get game => widget.game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full-screen swipe to change lanes
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (d) {
              final vx = d.primaryVelocity ?? 0;
              if (vx < -200) {
                game.moveLeft();
              } else if (vx > 200) {
                game.moveRight();
              }
            },
            onTapUp: (_) => game.pauseGame(),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                child: ValueListenableBuilder<double>(
                  valueListenable: game.scoreNotifier,
                  builder: (_, v, __) => Text(
                    'Score: ${v.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _circleButton(icon: Icons.arrow_left_rounded, onTap: game.moveLeft),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _circleButton(icon: Icons.arrow_right_rounded, onTap: game.moveRight),
          ),
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
        child: Icon(icon, size: 40, color: const Color(0xFF2E1A6F)),
      ),
    );
  }
}

class RunnerGameOverOverlay extends StatelessWidget {
  final RunnerGame game;
  const RunnerGameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Game Over', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ValueListenableBuilder<double>(
              valueListenable: game.scoreNotifier,
              builder: (_, v, __) => Text('Score: ${v.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(onPressed: game.restart, child: const Text('Retry')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    game.overlays.remove('runner_gameover');
                    game.resumeGame();
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  },
                  child: const Text('Main Menu'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class RunnerPauseOverlay extends StatelessWidget {
  final RunnerGame game;
  const RunnerPauseOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paused',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<double>(
                valueListenable: game.scoreNotifier,
                builder: (_, v, __) => Text(
                  'Score: ${v.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: game.beginResumeCountdown,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  game.resumeGame();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Main Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RunnerResumeOverlay extends StatefulWidget {
  final RunnerGame game;
  const RunnerResumeOverlay({super.key, required this.game});

  @override
  State<RunnerResumeOverlay> createState() => _RunnerResumeOverlayState();
}

class _RunnerResumeOverlayState extends State<RunnerResumeOverlay> {
  int _sec = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _sec = 3;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_sec <= 1) {
        timer.cancel();
        widget.game.completeResumeCountdown();
      } else {
        setState(() => _sec -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Resuming', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('$_sec', style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text('Get ready...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}


