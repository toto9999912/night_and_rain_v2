import 'dart:math';
import 'package:flame/components.dart';
import 'npc_component.dart';

/// 會隨機走動的NPC
class WanderingNpc extends NpcComponent {
  // 移動狀態
  bool _isMoving = false;
  // 目標位置
  Vector2? _targetPosition;
  // 移動速度
  final double speed;
  // 移動間隔
  final double movementInterval;
  // 移動計時器
  Timer? _movementTimer;
  // 移動範圍（以起始位置為中心的半徑）
  final double wanderRadius;
  // 隨機數生成器
  final Random _random = Random();
  // 起始位置
  late final Vector2 _initialPosition;

  WanderingNpc({
    required super.name,
    required Vector2 position,
    required super.color,
    super.greetings,
    this.speed = 50.0,
    this.movementInterval = 3.0,
    this.wanderRadius = 150.0,
    bool enableConversation = false, // 將默認值改為 false
    List<String>? conversationTexts,
  }) : super(
         position: position,
         size: Vector2(35, 35),
         supportConversation: enableConversation,
       ) {
    _initialPosition = position.clone();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 初始化移動計時器
    _movementTimer = Timer(
      movementInterval,
      onTick: _decideMovement,
      repeat: true,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新移動計時器
    _movementTimer?.update(dt);

    // 處理移動邏輯
    if (_isMoving && _targetPosition != null) {
      // 計算移動方向
      final direction = _targetPosition! - position;

      // 如果已經非常接近目標，就停止移動
      if (direction.length < 5) {
        _isMoving = false;
        return;
      }

      // 正常化方向向量並移動
      direction.normalize();
      position += direction * speed * dt;
    }
  }

  // 決定下一次移動
  void _decideMovement() {
    // 隨機決定是否要移動
    if (_random.nextBool()) {
      _isMoving = true;

      // 計算隨機目標位置，在起始位置周圍的圓形範圍內
      final angle = _random.nextDouble() * 2 * pi;
      final distance = _random.nextDouble() * wanderRadius;

      _targetPosition = Vector2(
        _initialPosition.x + cos(angle) * distance,
        _initialPosition.y + sin(angle) * distance,
      );
    } else {
      // 暫時停下來
      _isMoving = false;
    }
  }

  @override
  void onRemove() {
    _movementTimer?.stop();
    super.onRemove();
  }
}
