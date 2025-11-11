import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/unlock_metadata.dart';
import '../constants/unlock_thresholds.dart';
import '../models/resume_section.dart';
import '../services/progress_service.dart';
import '../services/resume_service.dart';
import 'app_theme.dart';

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
  bool _refreshing = false;

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
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: FutureBuilder<Map<UnlockLevel, ResumeSection>>(
          future: _sectionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _sections.isEmpty) {
              return const _LoadingState();
            }
            if (snapshot.hasError && _sections.isEmpty) {
              return _ErrorState(
                message: _loadError ?? 'Something went wrong',
                onRetry: () {
                  setState(() => _sectionsFuture = _loadSections());
                },
              );
            }
            final unlocks = _progress.currentUnlocks;
            return RefreshIndicator(
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.secondary,
              onRefresh: () async {
                if (_refreshing) return;
                setState(() {
                  _refreshing = true;
                  _sectionsFuture = _loadSections();
                });
                await _sectionsFuture;
                if (mounted) {
                  setState(() => _refreshing = false);
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                children: [
                  _ResumeSummary(
                    highScore: _progress.highScore,
                    unlockedCount: unlocks.values
                        .where((value) => value == true)
                        .length,
                    totalSections: UnlockLevel.values.length,
                  ),
                  const SizedBox(height: 28),
                  ...UnlockLevel.values.map(
                    (level) => _sectionTile(
                      unlockLevelTitles[level]!,
                      level,
                      unlocks[level] == true,
                    ),
                  ),
                  const SizedBox(height: 28),
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
                      ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTile(String title, UnlockLevel level, bool unlocked) {
    final threshold = unlockThresholds[level]!;
    final section = _sections[level];
    final accent = unlockLevelColors[level]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: unlocked ? 1 : 0.45,
        child: GestureDetector(
          onTap: unlocked ? () => _showSection(level) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  gradient: unlocked
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent.withOpacity(0.32),
                            accent.withOpacity(0.12),
                          ],
                        )
                      : null,
                  color: unlocked ? null : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: unlocked
                        ? accent.withOpacity(0.35)
                        : Colors.white.withOpacity(0.12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.6)],
                        ),
                      ),
                      child: Icon(
                        unlocked ? Icons.verified_rounded : Icons.lock_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            unlocked
                                ? (section?.summary.isNotEmpty == true
                                      ? section!.summary
                                      : 'Unlocked — tap to view the details')
                                : 'Reach score $threshold to unlock',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.72),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      unlocked
                          ? Icons.arrow_forward_ios_rounded
                          : Icons.lock_outline_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      builder: (context) => ResumeSectionSheet(
        section: section,
        accent: unlockLevelColors[level]!,
      ),
    );
  }
}

class ResumeSectionSheet extends StatelessWidget {
  const ResumeSectionSheet({
    required this.section,
    required this.accent,
    super.key,
  });

  final ResumeSection section;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppDecorations.panel(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [accent, accent.withOpacity(0.6)],
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        section.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                if (section.summary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    section.summary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: 20),
                if (section.items.isNotEmpty)
                  ...section.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.brightness_1_rounded,
                            size: 10,
                            color: accent.withOpacity(0.9),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (section.items.isEmpty && section.summary.isEmpty)
                  Text(
                    'Content not provided yet. Check back soon!',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
              ],
            ),
          ),
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
        child: DecoratedBox(
          decoration: AppDecorations.glass(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 46,
                  color: Colors.white70,
                ),
                const SizedBox(height: 12),
                Text(
                  'Couldn\'t load resume data',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: AppDecorations.glass(
          borderRadius: BorderRadius.circular(28),
        ),
        child: const SizedBox(
          width: 160,
          height: 160,
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
    );
  }
}

class _ResumeSummary extends StatelessWidget {
  const _ResumeSummary({
    required this.highScore,
    required this.unlockedCount,
    required this.totalSections,
  });

  final int highScore;
  final int unlockedCount;
  final int totalSections;

  @override
  Widget build(BuildContext context) {
    final progress = totalSections == 0 ? 0.0 : unlockedCount / totalSections;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            color: Colors.white.withOpacity(0.06),
          ),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppGradients.highlight,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resume Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '$unlockedCount of $totalSections sections unlocked',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _SummaryStat(
                    label: 'High Score',
                    value: highScore.toString(),
                    icon: Icons.trending_up_rounded,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                        minHeight: 8,
                      ),
                    ),
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

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
