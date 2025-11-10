import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../services/progress_service.dart';

class RunnerGame extends FlameGame {
  late double worldWidth;
  late double worldHeight;

  late final CameraComponent _camera;
  late final World _world;
  late final PlayerRunner _player;
  final math.Random _rng = math.Random();
  late final List<double> lanePositions;
  late final double playerStartY;
  late final BackgroundRoad _background;

  double cameraCenterY = 0;
  bool started = false;
  bool gameOver = false;
  double score = 0;
  final ValueNotifier<double> scoreNotifier = ValueNotifier<double>(0);
  double _spawnAccumulator = 0;
  double speed = 140; // px/s baseline
  double timeSinceStart = 0;
  double _speedModifier = 0;
  double _speedModifierTimer = 0;
  final ProgressService _progress = ProgressService.instance;

  @override
  Color backgroundColor() => const Color(0xFF0D0B1E);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    worldWidth = size.x > 0 ? size.x : 480;
    worldHeight = size.y > 0 ? size.y : 840;
    _world = World();
    _camera = CameraComponent.withFixedResolution(world: _world, width: worldWidth, height: worldHeight);
    addAll([_world, _camera]);

    // Background road stripes
    _world.add(BackgroundRoad()..priority = -30);

    lanePositions = _computeLanePositions();
    playerStartY = worldHeight - math.max(120.0, worldHeight * 0.22);
    cameraCenterY = worldHeight / 2;

    _player = PlayerRunner()..priority = 10;
    _world.add(_player);
    _player.position.y = playerStartY;
    _player.snapToLane(1, snapInstant: true);

    _camera.viewfinder.position = Vector2(worldWidth / 2, cameraCenterY);

    // Seed a few obstacles starting off-screen above
    _seedInitialEntities();
  }

  List<double> _computeLanePositions() {
    const int laneCount = 3;
    final double lanePadding = worldWidth * 0.14;
    final double usableWidth = worldWidth - lanePadding * 2;
    return List<double>.generate(laneCount, (index) {
      if (laneCount == 1) return worldWidth / 2;
      final t = index / (laneCount - 1);
      return lanePadding + usableWidth * t;
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!started || gameOver) return;

    // Camera is fixed to player baseline (endless feel); obstacles move down
    _camera.viewfinder.position = Vector2(worldWidth / 2, cameraCenterY);

    timeSinceStart += dt;
    if (_speedModifierTimer > 0) {
      _speedModifierTimer -= dt;
      if (_speedModifierTimer <= 0) {
        _speedModifierTimer = 0;
        _speedModifier = 0;
      }
    }
    // Increase speed gradually
    final baseSpeed = 140 + timeSinceStart * 6; // +6 px/s each second
    speed = (baseSpeed + _speedModifier).clamp(120, 450).toDouble();
    // Score increases with distance/time
    final distanceScore = speed * dt / 100;
    score += distanceScore;
    _updateScore();

    // Spawn new obstacles over time
    _spawnAccumulator += dt;
    final spawnInterval = (0.9 - timeSinceStart * 0.01).clamp(0.4, 0.9);
    if (_spawnAccumulator > spawnInterval) {
      _spawnAccumulator = 0;
      final spawnY = cameraCenterY - (worldHeight / 2) - 160;
      _spawnEntityAt(spawnY);
    }

    // Game over if obstacle overlaps player
    final obstacles = _world.children.query<ObstacleRunner>();
    for (final o in obstacles) {
      if ((o.position.x - _player.position.x).abs() < 30 &&
          (_player.position.y - o.position.y).abs() < 36) {
        triggerGameOver();
        break;
      }
      // Recycle obstacle when below screen
      if (o.position.y > cameraCenterY + worldHeight / 2 + 80) {
        o.removeFromParent();
      }
    }

    // Coins collection
    for (final c in _world.children.query<CoinRunner>()) {
      if ((c.position.x - _player.position.x).abs() < 26 &&
          (_player.position.y - c.position.y).abs() < 30) {
        score += 10;
        _updateScore();
        c.removeFromParent();
      }
      if (c.position.y > cameraCenterY + worldHeight / 2 + 80) {
        c.removeFromParent();
      }
    }

    for (final p in _world.children.query<SpeedPickupRunner>()) {
      if ((p.position.x - _player.position.x).abs() < 26 &&
          (_player.position.y - p.position.y).abs() < 30) {
        _applySpeedModifier(p.isSpeedBoost ? 90 : -70, duration: 4);
        p.removeFromParent();
      }
      if (p.position.y > cameraCenterY + worldHeight / 2 + 80) {
        p.removeFromParent();
      }
    }
  }

  void moveLeft() {
    if (gameOver) return;
    _player.changeLane(-1);
  }

  void moveRight() {
    if (gameOver) return;
    _player.changeLane(1);
  }

  void start() {
    if (started) return;
    started = true;
    _spawnAccumulator = 0;
    overlays.remove('runner_pause');
    resumeEngine();
  }

  void triggerGameOver() {
    if (gameOver) return;
    gameOver = true;
    overlays.add('runner_gameover');
    pauseEngine();
  }

  void restart() {
    gameOver = false;
    started = false;
    score = 0;
    scoreNotifier.value = 0;
    timeSinceStart = 0;
    speed = 140;
    _speedModifier = 0;
    _speedModifierTimer = 0;
    _player
      ..position.y = playerStartY;
    _player.snapToLane(1, snapInstant: true);
    cameraCenterY = worldHeight / 2;
    _camera.viewfinder.position = Vector2(worldWidth / 2, cameraCenterY);
    // Remove all obstacles
    for (final o in _world.children.query<ObstacleRunner>().toList()) {
      o.removeFromParent();
    }
    for (final c in _world.children.query<CoinRunner>().toList()) {
      c.removeFromParent();
    }
    for (final p in _world.children.query<SpeedPickupRunner>().toList()) {
      p.removeFromParent();
    }
    // Seed again
    _seedInitialEntities();
    overlays.remove('runner_pause');
    overlays.remove('runner_gameover');
    overlays.add('runner_start');
    resumeEngine();
  }

  void spawnObstacle({required double y, required int laneIndex}) {
    final laneX = lanePositions[laneIndex.clamp(0, lanePositions.length - 1)];
    final o = ObstacleRunner(laneIndex: laneIndex)
      ..position = Vector2(laneX, y)
      ..priority = 5;
    _world.add(o);
  }

  void spawnCoin({required double y, required int laneIndex}) {
    final laneX = lanePositions[laneIndex.clamp(0, lanePositions.length - 1)];
    final c = CoinRunner(laneIndex: laneIndex)
      ..position = Vector2(laneX, y)
      ..priority = 4;
    _world.add(c);
  }

  void pauseGame() {
    if (paused || gameOver) return;
    pauseEngine();
    if (!overlays.isActive('runner_pause')) {
      overlays.add('runner_pause');
    }
  }

  void resumeGame() {
    if (!paused) return;
    overlays.remove('runner_pause');
    resumeEngine();
  }

  void _applySpeedModifier(double delta, {double duration = 4}) {
    _speedModifier = delta;
    _speedModifierTimer = duration;
  }

  void _seedInitialEntities() {
    final topOfView = cameraCenterY - worldHeight / 2;
    for (int i = 1; i <= 6; i++) {
      final spawnY = topOfView - i * 160.0;
      _spawnEntityAt(spawnY);
    }
  }

  void _spawnEntityAt(double y) {
    final lanes = List<int>.generate(lanePositions.length, (index) => index);
    lanes.shuffle(_rng);
    for (final laneIndex in lanes) {
      if (!_canSpawnAt(laneIndex, y)) continue;
      final roll = _rng.nextDouble();
      if (roll < 0.6) {
        spawnObstacle(y: y, laneIndex: laneIndex);
      } else if (roll < 0.88) {
        spawnCoin(y: y, laneIndex: laneIndex);
      } else if (roll < 0.92) {
        spawnSpeedPickup(y: y, laneIndex: laneIndex, isSpeedBoost: true);
      } else if (roll < 0.96) {
        spawnSpeedPickup(y: y, laneIndex: laneIndex, isSpeedBoost: false);
      } else {
        continue;
      }
      break;
    }
  }

  bool _canSpawnAt(int laneIndex, double y) {
    const double minGap = 140;
    for (final o in _world.children.query<ObstacleRunner>()) {
      if (o.laneIndex == laneIndex && (o.position.y - y).abs() < minGap) {
        return false;
      }
    }
    for (final c in _world.children.query<CoinRunner>()) {
      if (c.laneIndex == laneIndex && (c.position.y - y).abs() < minGap) {
        return false;
      }
    }
    for (final p in _world.children.query<SpeedPickupRunner>()) {
      if (p.laneIndex == laneIndex && (p.position.y - y).abs() < minGap) {
        return false;
      }
    }
    return true;
  }

  void spawnSpeedPickup({required double y, required int laneIndex, required bool isSpeedBoost}) {
    final laneX = lanePositions[laneIndex.clamp(0, lanePositions.length - 1)];
    final pickup = SpeedPickupRunner(
      laneIndex: laneIndex,
      isSpeedBoost: isSpeedBoost,
    )
      ..position = Vector2(laneX, y)
      ..priority = 4;
    _world.add(pickup);
  }

  void _updateScore() {
    final currentScore = score;
    if (scoreNotifier.value != currentScore) {
      scoreNotifier.value = currentScore;
      _progress.updateScore(currentScore.floor());
    }
  }
}

class PlayerRunner extends RectangleComponent with HasGameRef<RunnerGame> {
  int laneIndex = 1;
  double _targetX = 0;
  double _laneLerpSpeed = 12; // higher is snappier

  PlayerRunner() : super(size: Vector2(34, 34), anchor: Anchor.center);

  @override
  void onMount() {
    super.onMount();
    snapToLane(laneIndex, snapInstant: true);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)), paint);
  }

  void changeLane(int delta) {
    snapToLane(laneIndex + delta);
  }

  void snapToLane(int lane, {bool snapInstant = false}) {
    final lanes = gameRef.lanePositions;
    if (lanes.isEmpty) return;
    laneIndex = lane.clamp(0, lanes.length - 1);
    _targetX = lanes[laneIndex];
    if (snapInstant) {
      position.x = _targetX;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.started || gameRef.gameOver) {
      position.x = _targetX;
      return;
    }
    // Smoothly move toward target lane x
    position.x = position.x + (_targetX - position.x) * (_laneLerpSpeed * dt);
  }
}

class ObstacleRunner extends RectangleComponent with HasGameRef<RunnerGame> {
  final int laneIndex;

  ObstacleRunner({required this.laneIndex}) : super(size: Vector2(36, 36), anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);
    final g = gameRef;
    if (!g.started || g.gameOver) {
      return;
    }
    // Move downward
    position.y += g.speed * dt;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFE53935);
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)), paint);
    final border = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)), border);
  }
}

class CoinRunner extends CircleComponent with HasGameRef<RunnerGame> {
  final int laneIndex;

  CoinRunner({required this.laneIndex}) : super(radius: 10, anchor: Anchor.center, paint: Paint()..color = const Color(0xFFFFD54F));

  @override
  void update(double dt) {
    super.update(dt);
    final g = gameRef;
    if (!g.started || g.gameOver) {
      return;
    }
    position.y += g.speed * dt;
  }
}

class SpeedPickupRunner extends CircleComponent with HasGameRef<RunnerGame> {
  final int laneIndex;
  final bool isSpeedBoost;

  SpeedPickupRunner({
    required this.laneIndex,
    required this.isSpeedBoost,
  }) : super(
          radius: 12,
          anchor: Anchor.center,
          paint: Paint()..color = isSpeedBoost ? const Color(0xFF66FF99) : const Color(0xFF81D4FA),
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final iconPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (isSpeedBoost) {
      canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), iconPaint);
      canvas.drawLine(const Offset(2, -6), const Offset(6, 0), iconPaint);
      canvas.drawLine(const Offset(2, 6), const Offset(6, 0), iconPaint);
    } else {
      canvas.drawLine(const Offset(-6, 0), const Offset(6, 0), iconPaint);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final g = gameRef;
    if (!g.started || g.gameOver) {
      return;
    }
    position.y += g.speed * dt;
  }
}

class BackgroundRoad extends PositionComponent with HasGameRef<RunnerGame> {
  double _offset = 0;

  BackgroundRoad()
      : super(
          anchor: Anchor.topLeft,
        );

  void _syncSize() {
    size = gameRef.camera.viewport.size;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _syncSize();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncSize();
    final g = gameRef;
    position = Vector2.zero();
    if (!g.started || g.gameOver) return;
    _offset += g.speed * dt * 0.5; // slower than obstacles for parallax feel
  }

  @override
  void render(Canvas canvas) {
    final roadSize = size;
    // Road background centered on this component
    final bg = Paint()..color = const Color(0xFF1B2533);
    canvas.drawRect(Rect.fromLTWH(0, 0, roadSize.x, roadSize.y), bg);
    // Lane markers
    final linePaint = Paint()..color = const Color(0x66FFFFFF);
    final g = gameRef;
    final lanes = g.lanePositions;
    const double spacing = 60;
    final double offset = _offset % spacing;
    for (final x in lanes) {
      final laneX = (x / g.worldWidth) * roadSize.x;
      // dashed vertical lines
      for (double y = -spacing; y < roadSize.y + spacing; y += spacing) {
        final centerY = y + offset;
        canvas.drawRect(Rect.fromCenter(center: Offset(laneX, centerY), width: 4, height: 24), linePaint);
      }
    }
    final edgePaint = Paint()..color = const Color(0x99FFFFFF);
    canvas.drawRect(Rect.fromLTWH(12, 0, 6, roadSize.y), edgePaint);
    canvas.drawRect(Rect.fromLTWH(roadSize.x - 18, 0, 6, roadSize.y), edgePaint);
  }
}


