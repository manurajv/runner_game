import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundOn = true;
  bool _hapticsOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Text('Gameplay', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _SettingsCard(
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                title: const Text('Sound effects'),
                subtitle: const Text(
                  'Immerse yourself with lane change and pickup cues.',
                ),
                value: _soundOn,
                onChanged: (v) => setState(() => _soundOn = v),
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                title: const Text('Haptic feedback'),
                subtitle: const Text(
                  'Subtle vibration pulses when you dodge or collect items (coming soon).',
                ),
                value: _hapticsOn,
                onChanged: (v) => setState(() => _hapticsOn = v),
              ),
            ),
            const SizedBox(height: 28),
            Text('Tips', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const _InfoTile(
              icon: Icons.touch_app_rounded,
              title: 'Tap to pause',
              subtitle:
                  'Tap anywhere during a run to open the pause menu and resume or exit.',
            ),
            const SizedBox(height: 12),
            const _InfoTile(
              icon: Icons.bolt_rounded,
              title: 'Collectibles',
              subtitle:
                  'Coins add bonus points. Green pickups boost speed, blue pickups slow it down.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            color: Colors.white.withOpacity(0.05),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: AppDecorations.panel(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.highlight,
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
