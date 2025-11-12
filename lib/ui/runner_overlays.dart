import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/runner_game.dart';
import 'app_theme.dart';

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
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _overlayBackground),
      child: Center(
        child: _OverlayPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Runner Game',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Swipe between lanes, dodge hazards, chase a higher score.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              if (!_counting)
                FilledButton.icon(
                  onPressed: _go,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Run'),
                )
              else
                Text(
                  '$_sec',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
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
        Positioned.fill(
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  game.moveLeft();
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  game.moveRight();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
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
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.black.withOpacity(0.35),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: ValueListenableBuilder<double>(
                    valueListenable: game.scoreNotifier,
                    builder: (_, v, __) => Text(
                      'Score ${v.toStringAsFixed(0)}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _circleButton(
              icon: Icons.arrow_left_rounded,
              onTap: game.moveLeft,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: _circleButton(
              icon: Icons.arrow_right_rounded,
              onTap: game.moveRight,
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: ValueListenableBuilder<List<AchievementUnlockEvent>>(
                valueListenable: game.unlockQueueNotifier,
                builder: (_, events, __) {
                  if (events.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: events
                        .map(
                          (event) => Padding(
                            key: ValueKey(event.id),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AchievementToast(
                              event: event,
                              onDismiss: () =>
                                  game.dismissAchievementToast(event.id),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.highlight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Icon(icon, size: 42, color: Colors.white),
      ),
    );
  }
}

class RunnerGameOverOverlay extends StatelessWidget {
  final RunnerGame game;
  const RunnerGameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _overlayBackground),
      child: Center(
        child: _OverlayPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Run Complete',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<double>(
                valueListenable: game.scoreNotifier,
                builder: (_, v, __) => Text(
                  'Final score: ${v.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: game.restart,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.35)),
                    ),
                    onPressed: () {
                      game.overlays.remove('runner_gameover');
                      game.resumeGame();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Main Menu'),
                  ),
                ],
              ),
            ],
          ),
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
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _overlayBackground),
      child: Center(
        child: _OverlayPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Paused',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<double>(
                valueListenable: game.scoreNotifier,
                builder: (_, v, __) => Text(
                  'Current score: ${v.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: game.beginResumeCountdown,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume run'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.35)),
                ),
                onPressed: () {
                  game.resumeGame();
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                icon: const Icon(Icons.home_rounded),
                label: const Text('Main menu'),
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
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _overlayBackground),
      child: Center(
        child: _OverlayPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Get ready',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                '$_sec',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Resume in a moment...',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementToast extends StatefulWidget {
  const _AchievementToast({required this.event, required this.onDismiss});

  final AchievementUnlockEvent event;
  final VoidCallback onDismiss;

  @override
  State<_AchievementToast> createState() => _AchievementToastState();
}

class _AchievementToastState extends State<_AchievementToast> {
  static const _slideDuration = Duration(milliseconds: 260);
  static const _fadeDuration = Duration(milliseconds: 240);
  static const _visibleDuration = Duration(milliseconds: 2100);

  bool _visible = false;
  Timer? _hideTimer;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 20), () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
    _hideTimer = Timer(_visibleDuration, _startDismiss);
  }

  void _startDismiss() {
    if (!mounted) return;
    setState(() => _visible = false);
    _dismissTimer = Timer(_slideDuration, widget.onDismiss);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.event.color;
    final title = widget.event.title;
    final subtitle = 'Reached ${widget.event.threshold} pts';
    return AnimatedSlide(
      duration: _slideDuration,
      curve: Curves.easeOut,
      offset: _visible ? Offset.zero : const Offset(0.2, 0),
      child: AnimatedOpacity(
        duration: _fadeDuration,
        opacity: _visible ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent.withOpacity(0.92), accent.withOpacity(0.65)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Resume unlock!',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayPanel extends StatelessWidget {
  const _OverlayPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            color: Colors.white.withOpacity(0.08),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: child,
        ),
      ),
    );
  }
}

const LinearGradient _overlayBackground = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xCC0A0F1F), Color(0xCC1C1F3A)],
);
