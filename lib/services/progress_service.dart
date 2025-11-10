import 'dart:collection';
import '../constants/unlock_thresholds.dart';

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  int _highScore = 0;
  final Map<UnlockLevel, bool> _unlocks = {
    for (final level in UnlockLevel.values) level: false,
  };

  int get highScore => _highScore;
  UnmodifiableMapView<UnlockLevel, bool> get currentUnlocks => UnmodifiableMapView(_unlocks);

  void updateScore(int score) {
    if (score > _highScore) {
      _highScore = score;
    }
    _recomputeUnlocks();
  }

  void _recomputeUnlocks() {
    for (final entry in unlockThresholds.entries) {
      _unlocks[entry.key] = _highScore >= entry.value;
    }
  }

  void resetProgress() {
    _highScore = 0;
    for (final level in UnlockLevel.values) {
      _unlocks[level] = false;
    }
    _recomputeUnlocks();
  }

  // Firebase hooks to be implemented later:
  // Future<void> loadFromCloud();
  // Future<void> saveToCloud();
}


