import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import 'app_theme.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Stack(
            children: [
              const _AnimatedBlurOrbs(),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _HeroHeader(),
                      const SizedBox(height: 32),
                      _MenuButton(
                        label: 'Play',
                        icon: Icons.play_arrow_rounded,
                        gradient: AppGradients.highlight,
                        onTap: () => Navigator.of(context).pushNamed('/play'),
                      ),
                      const SizedBox(height: 18),
                      _MenuButton(
                        label: 'Resume',
                        icon: Icons.workspace_premium_rounded,
                        gradient: AppGradients.success,
                        onTap: () => Navigator.of(context).pushNamed('/resume'),
                      ),
                      const SizedBox(height: 18),
                      _MenuButton(
                        label: 'Settings',
                        icon: Icons.settings_rounded,
                        gradient: AppGradients.caution,
                        onTap: () =>
                            Navigator.of(context).pushNamed('/settings'),
                      ),
                      const SizedBox(height: 28),
                      TextButton.icon(
                        onPressed: () => _showHowToPlay(context),
                        icon: const Icon(Icons.help_outline_rounded),
                        label: const Text('How to Play'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DecoratedBox(
        decoration: AppDecorations.panel(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to Play',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const _BulletRow(
                icon: Icons.swipe_rounded,
                text: 'Swipe or use the arrows to change lanes quickly.',
              ),
              const _BulletRow(
                icon: Icons.shield_rounded,
                text:
                    'Avoid obstacles and stay in motion to keep your run alive.',
              ),
              const _BulletRow(
                icon: Icons.attach_money_rounded,
                text: 'Collect coins for bonus score multipliers.',
              ),
              const _BulletRow(
                icon: Icons.flash_on_rounded,
                text:
                    'Green pickups speed you up, blue pickups slow the world down.',
              ),
              const SizedBox(height: 16),
              Text('Controls', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const _BulletRow(
                icon: Icons.touch_app_rounded,
                text: 'Tap anywhere during a run to pause instantly.',
              ),
              const _BulletRow(
                icon: Icons.workspace_premium_rounded,
                text:
                    'Resume menu shows unlocked resume sections in real time.',
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return ValueListenableBuilder<int>(
      valueListenable: progress.highScoreNotifier,
      builder: (context, highScore, _) {
        return Column(
          children: [
            Text(
              'Runner Game',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Dash between lanes, chase the score, and unlock your resume.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 28),
            DecoratedBox(
              decoration: AppDecorations.glass(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.military_tech_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Personal Best',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      highScore.toString(),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: const [
                        _TagChip(
                          icon: Icons.auto_awesome_rounded,
                          label: 'Dynamic resume unlocks',
                        ),
                        _TagChip(
                          icon: Icons.sports_esports_rounded,
                          label: 'Reactive controls',
                        ),
                        _TagChip(
                          icon: Icons.cloud_sync_rounded,
                          label: 'Firebase-powered',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBlurOrbs extends StatefulWidget {
  const _AnimatedBlurOrbs();

  @override
  State<_AnimatedBlurOrbs> createState() => _AnimatedBlurOrbsState();
}

class _AnimatedBlurOrbsState extends State<_AnimatedBlurOrbs>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        return IgnorePointer(
          ignoring: true,
          child: Stack(
            children: [
              _Orb(
                top: 40 + math.sin(t) * 20,
                left: 20 + math.cos(t) * 50,
                diameter: 160,
                colors: const [Color(0xFF6C63FF), Color(0xFFB287FF)],
              ),
              _Orb(
                bottom: 60 + math.cos(t * 0.7) * 30,
                right: 18 + math.sin(t * 0.6) * 40,
                diameter: 140,
                colors: const [Color(0xFF13C4A3), Color(0xFF62FBD7)],
              ),
              _Orb(
                bottom: 180 + math.sin(t * 0.4) * 40,
                left: 0,
                diameter: 220,
                colors: const [Color(0xFFF0648B), Color(0xFFFFB3C1)],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.diameter,
    required this.colors,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double diameter;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.35),
              blurRadius: 80,
              spreadRadius: 30,
            ),
          ],
        ),
      ),
    );
  }
}
