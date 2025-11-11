import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../constants/unlock_thresholds.dart';

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  int _highScore = 0;
  final ValueNotifier<int> highScoreNotifier = ValueNotifier<int>(0);
  final Map<UnlockLevel, bool> _unlocks = {
    for (final level in UnlockLevel.values) level: false,
  };
  final StreamController<UnlockLevel> _unlockController =
      StreamController<UnlockLevel>.broadcast();

  int get highScore => _highScore;
  UnmodifiableMapView<UnlockLevel, bool> get currentUnlocks =>
      UnmodifiableMapView(_unlocks);
  Stream<UnlockLevel> get unlockStream => _unlockController.stream;

  void updateScore(int score) {
    if (score > _highScore) {
      _highScore = score;
      highScoreNotifier.value = _highScore;
    }
    _recomputeUnlocks();
  }

  void _recomputeUnlocks() {
    for (final entry in unlockThresholds.entries) {
      final level = entry.key;
      final threshold = entry.value;
      final wasUnlocked = _unlocks[level] ?? false;
      final isUnlocked = _highScore >= threshold;
      _unlocks[level] = isUnlocked;
      if (isUnlocked && !wasUnlocked) {
        _unlockController.add(level);
      }
    }
  }

  void resetProgress() {
    _highScore = 0;
    highScoreNotifier.value = _highScore;
    for (final level in UnlockLevel.values) {
      _unlocks[level] = false;
    }
    _recomputeUnlocks();
  }

  // Firebase hooks to be implemented later:
  // Future<void> loadFromCloud();
  // Future<void> saveToCloud();
}
