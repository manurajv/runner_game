import 'package:flutter/material.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F1147), Color(0xFF2E1A6F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Runner Game',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The Runner Game Adventure',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 48),
                  _MenuButton(
                    label: 'Play',
                    icon: Icons.play_arrow_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/play'),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    label: 'Resume',
                    icon: Icons.workspace_premium_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/resume'),
                  ),
                  const SizedBox(height: 16),
                  _MenuButton(
                    label: 'Settings',
                    icon: Icons.settings_rounded,
                    onTap: () => Navigator.of(context).pushNamed('/settings'),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => _showHowToPlay(context),
                    icon: const Icon(Icons.help_outline_rounded, color: Colors.white70),
                    label: const Text('How to Play', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('How to Play', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 12),
            Text('• Swipe or use the arrows to change lanes.'),
            Text('• Avoid red obstacles and stay on screen.'),
            Text('• Collect gold coins for bonus score.'),
            Text('• Green pickups speed you up; blue pickups slow you down.'),
            SizedBox(height: 12),
            Text('Controls'),
            Text('- Tap anywhere during a run to pause.'),
            Text('- From pause, resume or return to the main menu.'),
            SizedBox(height: 12),
            Text('Resume Unlocks'),
            Text('- Higher scores unlock resume sections in the Resume tab in real time.'),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E1A6F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}


