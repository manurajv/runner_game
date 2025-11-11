import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../constants/unlock_thresholds.dart';
import '../models/resume_section.dart';
import '../services/resume_service.dart';

class ResumeScreen extends StatefulWidget {
  const ResumeScreen({super.key});

  @override
  State<ResumeScreen> createState() => _ResumeScreenState();
}

class _ResumeScreenState extends State<ResumeScreen> {
  final ProgressService _progress = ProgressService.instance;
  final ResumeService _resume = ResumeService.instance;
  late Future<Map<UnlockLevel, ResumeSection>> _sectionsFuture;
  Map<UnlockLevel, ResumeSection> _sections = {};
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _sectionsFuture = _loadSections();
  }

  Future<Map<UnlockLevel, ResumeSection>> _loadSections() async {
    try {
      final sections = await _resume.fetchSections();
      if (mounted) {
        setState(() {
          _sections = sections;
          _loadError = null;
        });
      }
      return sections;
    } catch (err) {
      final message = 'Unable to load resume data. ${err.toString()}';
      if (mounted) {
        setState(() {
          _loadError = message;
        });
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume')),
      body: FutureBuilder<Map<UnlockLevel, ResumeSection>>(
        future: _sectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _sections.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && _sections.isEmpty) {
            return _ErrorState(
              message: _loadError ?? 'Something went wrong',
              onRetry: () {
                setState(() {
                  _sectionsFuture = _loadSections();
                });
              },
            );
          }
          final unlocks = _progress.currentUnlocks;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _sectionsFuture = _loadSections();
              });
              await _sectionsFuture;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTile(
                  'Profile',
                  UnlockLevel.profile,
                  unlocks[UnlockLevel.profile] == true,
                ),
                _sectionTile(
                  'Skills',
                  UnlockLevel.skills,
                  unlocks[UnlockLevel.skills] == true,
                ),
                _sectionTile(
                  'Education',
                  UnlockLevel.education,
                  unlocks[UnlockLevel.education] == true,
                ),
                _sectionTile(
                  'Experience',
                  UnlockLevel.experience,
                  unlocks[UnlockLevel.experience] == true,
                ),
                _sectionTile(
                  'Projects',
                  UnlockLevel.projects,
                  unlocks[UnlockLevel.projects] == true,
                ),
                _sectionTile(
                  'Achievements',
                  UnlockLevel.achievements,
                  unlocks[UnlockLevel.achievements] == true,
                ),
                const SizedBox(height: 24),
                Text(
                  'Highest Score: ${_progress.highScore}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _confirmReset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset High Score'),
                ),
                if (_loadError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _loadError!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.red),
                  ),
                ],
              ],
            ),
          );
        },
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
        subtitle: Text(
          unlocked
              ? (_sections[level]?.summary.isNotEmpty == true
                    ? _sections[level]!.summary
                    : 'Unlocked — tap to view details')
              : 'Reach score $threshold to unlock',
        ),
        onTap: unlocked ? () => _showSection(level) : null,
      ),
    );
  }

  Future<void> _confirmReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This will clear your high score and lock resume sections until you unlock them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _progress.resetProgress();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'High score reset. Unlocks will refresh as you play.',
            ),
          ),
        );
      }
    }
  }

  void _showSection(UnlockLevel level) {
    final section = _sections[level];
    if (section == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No resume content found for ${level.name}.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => ResumeSectionSheet(section: section),
    );
  }
}

class ResumeSectionSheet extends StatelessWidget {
  const ResumeSectionSheet({required this.section, super.key});

  final ResumeSection section;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: Theme.of(context).textTheme.titleLarge),
            if (section.summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(section.summary),
            ],
            if (section.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...section.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              ),
            ],
            if (section.items.isEmpty && section.summary.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Content not provided yet.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Couldn\'t load resume data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
