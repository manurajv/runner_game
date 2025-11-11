import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../services/progress_service.dart';

class RunnerSpriteFactory {
  static final Map<String, Future<Sprite>> _cache = {};

  static Future<Sprite> player() => _memo(
        'player',
        () => _roundedRectSprite(
          size: Vector2.all(160),
          gradient: const [Color(0xFF5EEAD4), Color(0xFF0EA5E9)],
          borderColor: const Color(0xAAFFFFFF),
          borderWidth: 6,
          cornerRadius: 48,
          glowColor: const Color(0x6638BDF8),
          glowSigma: 16,
          highlightOpacity: 0.18,
        ),
      );

  static Future<Sprite> obstacle() => _memo(
        'obstacle',
        () => _roundedRectSprite(
          size: Vector2.all(150),
          gradient: const [Color(0xFFFF6B6B), Color(0xFFEF4444)],
          borderColor: const Color(0xCCFFFFFF),
          borderWidth: 4,
          cornerRadius: 40,
          glowColor: const Color(0x55EF4444),
          glowSigma: 14,
          highlightOpacity: 0.12,
          stripeOpacity: 0.16,
        ),
      );

  static Future<Sprite> coin() => _memo(
        'coin',
        () => _circleSprite(
          diameter: 140,
          gradient: const [Color(0xFFFFF59D), Color(0xFFF59E0B)],
          borderColor: const Color(0xFFFFE082),
          borderWidth: 6,
          glowColor: const Color(0x80FCD34D),
          glowSigma: 18,
          highlightOpacity: 0.25,
          decorator: (canvas, rect) {
            final starPaint = Paint()
              ..shader = ui.Gradient.linear(
                rect.topCenter,
                rect.bottomCenter,
                [
                  Colors.white.withOpacity(0.65),
                  Colors.white.withOpacity(0.0),
                ],
              );
            final starPath = Path()
              ..moveTo(rect.center.dx, rect.top + rect.height * 0.15)
              ..lineTo(rect.center.dx + rect.width * 0.07, rect.center.dy)
              ..lineTo(rect.center.dx, rect.center.dy + rect.height * 0.1)
              ..lineTo(rect.center.dx - rect.width * 0.07, rect.center.dy)
              ..close();
            canvas.drawPath(starPath, starPaint);
          },
        ),
      );

  static Future<Sprite> speedPickup({required bool boost}) => _memo(
        boost ? 'speedBoost' : 'speedSlow',
        () => _circleSprite(
          diameter: 150,
          gradient: boost
              ? const [Color(0xFF34D399), Color(0xFF10B981)]
              : const [Color(0xFF60A5FA), Color(0xFF3B82F6)],
          borderColor: Colors.white.withOpacity(0.85),
          borderWidth: 5,
          glowColor: boost ? const Color(0x8034D399) : const Color(0x805DB3FF),
          glowSigma: 14,
          highlightOpacity: 0.18,
          decorator: (canvas, rect) {
            final path = Path();
            final center = rect.center;
            if (boost) {
              path.moveTo(center.dx - rect.width * 0.1, center.dy + rect.height * 0.18);
              path.lineTo(center.dx - rect.width * 0.1, center.dy - rect.height * 0.18);
              path.lineTo(center.dx + rect.width * 0.2, center.dy);
              path.close();
            } else {
              path.addRRect(
                RRect.fromRectAndRadius(
                  Rect.fromCenter(
                    center: center,
                    width: rect.width * 0.55,
                    height: rect.height * 0.28,
                  ),
                  Radius.circular(rect.width * 0.14),
                ),
              );
            }
            final arrowPaint = Paint()
              ..color = Colors.white.withOpacity(0.85)
              ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
            canvas.drawPath(path, arrowPaint);
          },
        ),
      );

  static Future<Sprite> _memo(String key, Future<Sprite> Function() builder) {
    return _cache.putIfAbsent(key, builder);
  }

  static Future<Sprite> _roundedRectSprite({
    required Vector2 size,
    required List<Color> gradient,
    Color? borderColor,
    double borderWidth = 0,
    double cornerRadius = 24,
    Color? glowColor,
    double glowSigma = 0,
    double highlightOpacity = 0,
    double stripeOpacity = 0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final width = size.x;
    final height = size.y;
    final rect = Rect.fromLTWH(0, 0, width, height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    if (glowColor != null && glowSigma > 0) {
      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, glowSigma);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.inflate(12), Radius.circular(cornerRadius + 12)),
        glowPaint,
      );
    }

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, gradient);
    canvas.drawRRect(rrect, fillPaint);

    if (stripeOpacity > 0) {
      final stripePaint = Paint()..color = Colors.white.withOpacity(stripeOpacity);
      const double stripeWidth = 22.0;
      canvas.save();
      canvas.translate(-height * 0.4, 0);
      canvas.rotate(-math.pi / 8);
      for (double x = -height; x < width + height * 1.5; x += stripeWidth * 2.6) {
        canvas.drawRect(
          Rect.fromLTWH(x, -height, stripeWidth, height * 3),
          stripePaint,
        );
      }
      canvas.restore();
    }

    if (highlightOpacity > 0) {
      final highlightRect = Rect.fromLTWH(
        rect.left + rect.width * 0.1,
        rect.top + rect.height * 0.08,
        rect.width * 0.8,
        rect.height * 0.4,
      );
      final highlightPaint = Paint()
        ..shader = ui.Gradient.radial(
          highlightRect.center,
          highlightRect.width,
          [
            Colors.white.withOpacity(highlightOpacity),
            Colors.white.withOpacity(0),
          ],
        );
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlightRect, Radius.circular(cornerRadius * 0.6)),
        highlightPaint,
      );
    }

    if (borderColor != null && borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawRRect(rrect.deflate(borderWidth / 2), borderPaint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      width.ceil().clamp(1, 2048).toInt(),
      height.ceil().clamp(1, 2048).toInt(),
    );
    return Sprite(image);
  }

  static Future<Sprite> _circleSprite({
    required double diameter,
    required List<Color> gradient,
    Color? borderColor,
    double borderWidth = 0,
    Color? glowColor,
    double glowSigma = 0,
    double highlightOpacity = 0,
    void Function(Canvas canvas, Rect rect)? decorator,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, diameter, diameter);
    final center = rect.center;
    final radius = diameter / 2;

    if (glowColor != null && glowSigma > 0) {
      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, glowSigma);
      canvas.drawCircle(center, radius, glowPaint);
    }

    final fillPaint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        gradient,
      );
    canvas.drawCircle(center, radius, fillPaint);

    if (highlightOpacity > 0) {
      final highlightPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(center.dx, center.dy - radius * 0.35),
          radius * 0.9,
          [
            Colors.white.withOpacity(highlightOpacity),
            Colors.white.withOpacity(0),
          ],
        );
      canvas.drawCircle(center, radius * 0.72, highlightPaint);
    }

    decorator?.call(canvas, rect);

    if (borderColor != null && borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawCircle(center, radius - borderWidth / 2, borderPaint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      diameter.ceil().clamp(1, 2048).toInt(),
      diameter.ceil().clamp(1, 2048).toInt(),
    );
    return Sprite(image);
  }
}

class RunnerGame extends FlameGame {
  double worldWidth = 0;
  double worldHeight = 0;
  late final CameraComponent _camera;
  late final World _world;
  late final PlayerRunner _player;
  final math.Random _rng = math.Random();
  List<double> lanePositions = const [];
  double playerStartY = 0;
  late final BackgroundRoad _background;
  final Map<int, double> _laneLastSpawnTime = {};
  double _lastGlobalSpawnTime = double.negativeInfinity;
  static const double _laneSpawnCooldown = 1.1;
  static const double _globalSpawnCooldown = 0.8;
  bool _resumeCountdownActive = false;

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
    _camera = CameraComponent.withFixedResolution(
      world: _world,
      width: worldWidth,
      height: worldHeight,
    );
    addAll([_world, _camera]);

    _background = BackgroundRoad()..priority = -30;
    _world.add(_background);

    _player = PlayerRunner()..priority = 20;
    _world.add(_player);

    _applyViewportSizing(Vector2(worldWidth, worldHeight));
    _recalculateLayout(initial: true);

    // Seed a few obstacles starting off-screen above
    _seedInitialEntities();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    if (canvasSize.x <= 0 || canvasSize.y <= 0) {
      return;
    }
    worldWidth = canvasSize.x;
    worldHeight = canvasSize.y;
    if (!isLoaded) {
      return;
    }
    _applyViewportSizing(canvasSize);
    _recalculateLayout();
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
    final spawnInterval = (1.1 - timeSinceStart * 0.008).clamp(0.7, 1.1);
    if (_spawnAccumulator > spawnInterval) {
      _spawnAccumulator = 0;
      final spawnY = cameraCenterY - (worldHeight / 2) - 160;
      _spawnEntityAt(spawnY);
    }

    // Game over if obstacle overlaps player
    final removalThreshold = cameraCenterY + worldHeight / 2 + 160;

    for (final obstacle in _world.children.query<ObstacleRunner>()) {
      if (_componentsOverlap(_player, obstacle, padding: 12)) {
        triggerGameOver();
        break;
      }
      if (obstacle.position.y - obstacle.size.y / 2 > removalThreshold) {
        obstacle.removeFromParent();
      }
    }

    if (gameOver) {
      return;
    }

    for (final coin in _world.children.query<CoinRunner>()) {
      if (_componentsOverlap(_player, coin, padding: 18)) {
        score += 12;
        _updateScore();
        coin.collect();
        continue;
      }
      if (coin.position.y - coin.size.y / 2 > removalThreshold) {
        coin.removeFromParent();
      }
    }

    for (final pickup in _world.children.query<SpeedPickupRunner>()) {
      if (_componentsOverlap(_player, pickup, padding: 20)) {
        _applySpeedModifier(pickup.isSpeedBoost ? 90 : -70, duration: 5);
        pickup.consume();
        continue;
      }
      if (pickup.position.y - pickup.size.y / 2 > removalThreshold) {
        pickup.removeFromParent();
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
    _laneLastSpawnTime.clear();
    _lastGlobalSpawnTime = double.negativeInfinity;
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
      ..priority = 12
      ..position = Vector2(laneX, y);
    _world.add(o);
    _recordSpawn(laneIndex, timeSinceStart);
  }

  void spawnCoin({required double y, required int laneIndex}) {
    final laneX = lanePositions[laneIndex.clamp(0, lanePositions.length - 1)];
    final c = CoinRunner(laneIndex: laneIndex)
      ..priority = 10
      ..position = Vector2(laneX, y);
    _world.add(c);
    _recordSpawn(laneIndex, timeSinceStart);
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

  void beginResumeCountdown() {
    if (!paused || _resumeCountdownActive) return;
    _resumeCountdownActive = true;
    overlays.remove('runner_pause');
    if (!overlays.isActive('runner_resume')) {
      overlays.add('runner_resume');
    }
  }

  void completeResumeCountdown() {
    if (!_resumeCountdownActive) return;
    _resumeCountdownActive = false;
    overlays.remove('runner_resume');
    resumeEngine();
  }

  void _applySpeedModifier(double delta, {double duration = 4}) {
    _speedModifier = delta;
    _speedModifierTimer = duration;
  }

  void _seedInitialEntities() {
    _laneLastSpawnTime.clear();
    _lastGlobalSpawnTime = double.negativeInfinity;
    final topOfView = cameraCenterY - worldHeight / 2;
    for (int i = 1; i <= 6; i++) {
      final spawnY = topOfView - i * 200.0;
      _spawnEntityAt(spawnY, ignoreCooldown: true);
    }
    _laneLastSpawnTime.clear();
    _lastGlobalSpawnTime = double.negativeInfinity;
  }

  void _spawnEntityAt(double y, {bool ignoreCooldown = false}) {
    final lanes = List<int>.generate(lanePositions.length, (index) => index);
    lanes.shuffle(_rng);
    for (final laneIndex in lanes) {
      if (!_canSpawnAt(laneIndex, y, ignoreCooldown: ignoreCooldown)) continue;
      final roll = _rng.nextDouble();
      if (roll < 0.55) {
        spawnObstacle(y: y, laneIndex: laneIndex);
        break;
      } else if (roll < 0.78) {
        spawnCoin(y: y, laneIndex: laneIndex);
        break;
      } else if (roll < 0.9) {
        spawnSpeedPickup(y: y, laneIndex: laneIndex, isSpeedBoost: true);
        break;
      } else if (roll < 0.95) {
        spawnSpeedPickup(y: y, laneIndex: laneIndex, isSpeedBoost: false);
        break;
      } else {
        continue;
      }
    }
  }

  bool _canSpawnAt(int laneIndex, double y, {bool ignoreCooldown = false}) {
    const double minGap = 260;
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
    if (!ignoreCooldown) {
      final now = timeSinceStart;
      final laneTime = _laneLastSpawnTime[laneIndex];
      if (laneTime != null && (now - laneTime) < _laneSpawnCooldown) {
        return false;
      }
      if (_lastGlobalSpawnTime.isFinite && (now - _lastGlobalSpawnTime) < _globalSpawnCooldown) {
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
      ..priority = 9
      ..position = Vector2(laneX, y);
    _world.add(pickup);
    _recordSpawn(laneIndex, timeSinceStart);
  }

  void _updateScore() {
    final currentScore = score;
    if (scoreNotifier.value != currentScore) {
      scoreNotifier.value = currentScore;
      _progress.updateScore(currentScore.floor());
    }
  }

  void _applyViewportSizing(Vector2 resolution) {
    final viewport = _camera.viewport;
    if (viewport is FixedResolutionViewport) {
      viewport.resolution.setFrom(resolution);
    }
    _camera.viewfinder.visibleGameSize = resolution;
  }

  void _recalculateLayout({bool initial = false}) {
    if (worldWidth <= 0 || worldHeight <= 0) return;

    lanePositions = _computeLanePositions();
    playerStartY = worldHeight - math.max(140.0, worldHeight * 0.18);
    cameraCenterY = worldHeight / 2;

    if (_background.isMounted) {
      _background.syncSize();
    }

    if (_player.isMounted) {
      final clampBottom = worldHeight - _player.size.y * 0.6;
      if (!started || initial) {
        _player.position.y = playerStartY;
      } else {
        _player.position.y =
            _player.position.y.clamp(playerStartY * 0.35, clampBottom > 0 ? clampBottom : playerStartY);
      }
      _player.syncToLane(snapInstant: true);
    }

    _realignLaneEntities();
    _camera.viewfinder.position = Vector2(worldWidth / 2, cameraCenterY);
  }

  void _realignLaneEntities() {
    if (lanePositions.isEmpty) return;
    for (final entity in _world.children.whereType<LaneAttachable>()) {
      if (identical(entity, _player)) {
        continue;
      }
      entity.syncToLane(snapInstant: true);
    }
  }

  void _recordSpawn(int laneIndex, double timestamp) {
    _laneLastSpawnTime[laneIndex] = timestamp;
    _lastGlobalSpawnTime = timestamp;
  }

  bool _componentsOverlap(
    PositionComponent a,
    PositionComponent b, {
    double padding = 0,
  }) {
    final ax = a.size.x <= 0 ? 1 : a.size.x;
    final ay = a.size.y <= 0 ? 1 : a.size.y;
    final bx = b.size.x <= 0 ? 1 : b.size.x;
    final by = b.size.y <= 0 ? 1 : b.size.y;
    final dx = (a.position.x - b.position.x).abs();
    final dy = (a.position.y - b.position.y).abs();
    final limitX = ((ax + bx) * 0.5) - padding;
    final limitY = ((ay + by) * 0.5) - padding;
    return dx < limitX && dy < limitY;
  }
}

class BackgroundRoad extends PositionComponent with HasGameRef<RunnerGame> {
  double _offset = 0;

  BackgroundRoad() : super(anchor: Anchor.topLeft);

  void syncSize() {
    size = Vector2(gameRef.worldWidth, gameRef.worldHeight);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    syncSize();
  }

  @override
  void update(double dt) {
    super.update(dt);
    syncSize();
    position = Vector2.zero();
    final g = gameRef;
    if (!g.started || g.gameOver) return;
    _offset = (_offset + g.speed * dt * 0.5) % 5120;
  }

  @override
  void render(Canvas canvas) {
    final roadSize = size;
    final rect = Rect.fromLTWH(0, 0, roadSize.x, roadSize.y);
    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter,
        rect.bottomCenter,
        const [
          Color(0xFF080B1A),
          Color(0xFF10172A),
          Color(0xFF0B1120),
        ],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(rect, gradientPaint);

    final horizonPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, roadSize.y * 0.25),
        Offset(0, roadSize.y * 0.45),
        [
          const Color(0x4434D399),
          Colors.transparent,
        ],
      );
    canvas.drawRect(Rect.fromLTWH(0, roadSize.y * 0.2, roadSize.x, roadSize.y * 0.3), horizonPaint);

    final skylinePaint = Paint()..color = const Color(0x2210B981);
    final skylineGlow = Paint()
      ..color = const Color(0x3324D3FF)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18);

    for (double x = -80; x < roadSize.x + 80; x += 90) {
      final height = roadSize.y * 0.18 + (math.sin((x + _offset) * 0.01) + 1) * roadSize.y * 0.08;
      final buildingRect = Rect.fromLTWH(
        x,
        roadSize.y * 0.38 - height,
        70,
        height,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(buildingRect, topLeft: const Radius.circular(18), topRight: const Radius.circular(18)),
        skylineGlow,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(buildingRect, const Radius.circular(14)),
        skylinePaint,
      );
    }

    final g = gameRef;
    final lanes = g.lanePositions;
    const double spacing = 64;
    final double offset = _offset % spacing;

    final dividerPaint = Paint()
      ..color = const Color(0xFF172554)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, roadSize.y * 0.32, 14, roadSize.y * 0.68), dividerPaint);
    canvas.drawRect(
      Rect.fromLTWH(roadSize.x - 14, roadSize.y * 0.32, 14, roadSize.y * 0.68),
      dividerPaint,
    );

    final edgeGlow = Paint()
      ..color = const Color(0x5538BDF8)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);
    canvas.drawRect(Rect.fromLTWH(0, roadSize.y * 0.32, 28, roadSize.y * 0.68), edgeGlow);
    canvas.drawRect(
      Rect.fromLTWH(roadSize.x - 28, roadSize.y * 0.32, 28, roadSize.y * 0.68),
      edgeGlow,
    );

    final lanePaint = Paint()..color = const Color(0xAAFFFFFF);
    for (final laneX in lanes) {
      for (double y = -spacing; y < roadSize.y + spacing; y += spacing) {
        final centerY = y + offset;
        final laneRect = Rect.fromCenter(
          center: Offset(laneX, centerY),
          width: 6,
          height: 32,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(laneRect, const Radius.circular(6)),
          lanePaint,
        );
      }
    }

    final ambientOverlay = Paint()
      ..shader = ui.Gradient.radial(
        Offset(roadSize.x / 2, roadSize.y * 0.6),
        roadSize.y,
        [
          Colors.transparent,
          const Color(0x220EA5E9),
        ],
      );
    canvas.drawRect(rect, ambientOverlay);
  }
}

abstract class LaneAttachable extends SpriteComponent with HasGameRef<RunnerGame> {
  LaneAttachable({
    required this.laneIndex,
    required Vector2 size,
    Anchor? anchor,
  }) : super(size: size, anchor: anchor ?? Anchor.center);

  int laneIndex;

  double get laneX {
    final lanes = gameRef.lanePositions;
    if (lanes.isEmpty) return 0;
    final idx = laneIndex.clamp(0, lanes.length - 1);
    return lanes[idx];
  }

  void syncToLane({bool snapInstant = false}) {
    final lanes = gameRef.lanePositions;
    if (lanes.isEmpty) return;
    final clamped = laneIndex.clamp(0, lanes.length - 1);
    laneIndex = clamped is int ? clamped : clamped.toInt();
    final x = lanes[laneIndex];
    position.x = x;
  }
}

class PlayerRunner extends LaneAttachable {
  double _targetX = 0;
  final double _laneLerpSpeed = 12;

  PlayerRunner() : super(laneIndex: 1, size: Vector2(64, 72));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await gameRef.loadSprite('yellow_car.png');
    position.y = gameRef.playerStartY;
    syncToLane(snapInstant: true);
    add(
      ScaleEffect.by(
        Vector2.all(1.045),
        EffectController(
          duration: 1.6,
          reverseDuration: 1.6,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  void changeLane(int delta) {
    final lanes = gameRef.lanePositions;
    if (lanes.isEmpty) return;
    final next = (laneIndex + delta).clamp(0, lanes.length - 1);
    laneIndex = next is int ? next : next.toInt();
    syncToLane(snapInstant: false);
  }

  void snapToLane(int lane, {bool snapInstant = false}) {
    laneIndex = lane;
    syncToLane(snapInstant: snapInstant);
  }

  @override
  void syncToLane({bool snapInstant = false}) {
    final lanes = gameRef.lanePositions;
    if (lanes.isEmpty) return;
    laneIndex = laneIndex.clamp(0, lanes.length - 1);
    _targetX = laneX;
    if (snapInstant) {
      position.x = _targetX;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!gameRef.started || gameRef.gameOver) {
      position.x = _targetX;
      angle = angle * 0.6;
      return;
    }
    position.x = position.x + (_targetX - position.x) * (_laneLerpSpeed * dt);
    final targetAngle = ((_targetX - position.x) / gameRef.worldWidth) * 2.6;
    angle = angle + (targetAngle - angle) * math.min(1, dt * 8);
  }
}

class ObstacleRunner extends LaneAttachable {
  ObstacleRunner({required int laneIndex}) : super(laneIndex: laneIndex, size: Vector2.all(64));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await RunnerSpriteFactory.obstacle();
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

class CoinRunner extends LaneAttachable {
  CoinRunner({required int laneIndex}) : super(laneIndex: laneIndex, size: Vector2.all(52));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await RunnerSpriteFactory.coin();
    add(
      RotateEffect.by(
        math.pi * 2,
        EffectController(
          duration: 2.2,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
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

  void collect() {
    removeFromParent();
  }
}

class SpeedPickupRunner extends LaneAttachable {
  final bool isSpeedBoost;

  SpeedPickupRunner({
    required int laneIndex,
    required this.isSpeedBoost,
  }) : super(laneIndex: laneIndex, size: Vector2.all(56));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await RunnerSpriteFactory.speedPickup(boost: isSpeedBoost);
    add(
      ScaleEffect.by(
        Vector2.all(1.1),
        EffectController(
          duration: 1.2,
          reverseDuration: 1.2,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
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

  void consume() {
    removeFromParent();
  }
}

