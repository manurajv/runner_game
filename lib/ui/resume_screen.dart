import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../constants/unlock_thresholds.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final ProgressService _progress = ProgressService.instance;

  @override
  Widget build(BuildContext context) {
    final unlocks = _progress.currentUnlocks;
    return Scaffold(
      appBar: AppBar(title: const Text('Resume')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTile('Profile', UnlockLevel.profile, unlocks[UnlockLevel.profile] == true),
          _sectionTile('Skills', UnlockLevel.skills, unlocks[UnlockLevel.skills] == true),
          _sectionTile('Education', UnlockLevel.education, unlocks[UnlockLevel.education] == true),
          _sectionTile('Experience', UnlockLevel.experience, unlocks[UnlockLevel.experience] == true),
          _sectionTile('Projects', UnlockLevel.projects, unlocks[UnlockLevel.projects] == true),
          _sectionTile('Achievements', UnlockLevel.achievements, unlocks[UnlockLevel.achievements] == true),
          const SizedBox(height: 24),
          Text('Highest Score: ${_progress.highScore}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _confirmReset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: const Text('Reset High Score'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTile(String title, UnlockLevel level, bool unlocked) {
    final threshold = unlockThresholds[level]!;
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(
          unlocked ? Icons.verified_rounded : Icons.lock_rounded,
          color: unlocked ? Colors.green : Colors.grey,
        ),
        title: Text(title),
        subtitle: Text(unlocked ? 'Unlocked' : 'Reach score $threshold to unlock'),
        onTap: unlocked
            ? () {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: Text('$title content goes here (from Firebase soon).'),
                  ),
                );
              }
            : null,
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text('This will clear your high score and lock resume sections until you unlock them again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _progress.resetProgress();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('High score reset. Unlocks will refresh as you play.')),
        );
      }
    }
  }
}


