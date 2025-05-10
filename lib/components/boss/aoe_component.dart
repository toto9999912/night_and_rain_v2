// 敵人元件，會主動檢測並攻擊玩家
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../player_component.dart';

/// 持續範圍傷害組件
class AoeComponent extends PositionComponent
    with HasGameReference, CollisionCallbacks
    implements OpacityProvider {
  final double radius;
  final double damage;
  final Color color;
  double _lifespan;
  final double duration;
  final double tickInterval;
  double _tickTimer = 0;
  final List<PlayerComponent> _affectedPlayers = [];

  AoeComponent({
    required Vector2 position,
    required this.radius,
    required this.damage,
    required this.duration,
    required this.tickInterval,
    required this.color,
  }) : _lifespan = duration,
       super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加圓形碰撞區域
    add(CircleHitbox(radius: radius)..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
      return;
    }

    // 傷害計時器
    _tickTimer -= dt;
    if (_tickTimer <= 0) {
      _tickTimer = tickInterval;

      // 對所有在範圍內的玩家造成傷害
      for (final player in _affectedPlayers) {
        try {
          debugPrint('AOE嘗試對玩家造成 ${damage.toInt()} 點傷害');
          player.takeDamage(damage.toInt());
          debugPrint('AOE成功對玩家造成傷害');
        } catch (e) {
          debugPrint('AOE對玩家造成傷害時出錯: $e');
        }
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 只對玩家造成傷害，忽略Boss和其他敵人
    if (other is PlayerComponent && !_affectedPlayers.contains(other)) {
      debugPrint('玩家進入AOE攻擊範圍');
      _affectedPlayers.add(other);

      // 立即造成第一次傷害
      try {
        debugPrint('AOE立即對玩家造成 ${damage.toInt()} 點傷害');
        other.takeDamage(damage.toInt());
      } catch (e) {
        debugPrint('AOE初始傷害失敗: $e');
      }

      // 重置計時器，準備下一次傷害
      _tickTimer = tickInterval;
    }
  }

  // OpacityProvider 介面實現
  @override
  double get opacity => _opacityValue;
  double _opacityValue = 1.0;
  @override
  set opacity(double value) {
    if (value < 0 || value > 1) {
      developer.log('警告: AOE設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }
    _opacityValue = value;
  }

  @override
  void render(Canvas canvas) {
    // 計算基於剩餘生命的不透明度
    final lifespanOpacity = (_lifespan / duration).clamp(0.1, 0.6);

    // 結合全局透明度設定
    final effectiveOpacity = lifespanOpacity * _opacityValue;

    // 繪製外圈
    final outlinePaint =
        Paint()
          ..color = color.withValues(alpha: effectiveOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawCircle(Offset.zero, radius, outlinePaint);

    // 繪製填充區域
    final fillPaint =
        Paint()
          ..color = color.withValues(alpha: effectiveOpacity * 0.7)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius, fillPaint);

    // 添加流動效果 - 小圓點
    final random = math.Random();
    final particlePaint =
        Paint()..color = Colors.white.withValues(alpha: effectiveOpacity);

    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * radius;
      final particleSize = 1 + random.nextDouble() * 2;

      final x = math.cos(angle) * distance;
      final y = math.sin(angle) * distance;

      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    // 如果玩家離開範圍，從受影響列表移除
    if (other is PlayerComponent) {
      _affectedPlayers.remove(other);
    }
  }
}
