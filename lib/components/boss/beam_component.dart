// 敵人元件，會主動檢測並攻擊玩家
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../player_component.dart';

/// 光束組件 - 用於Boss的光束攻擊
class BeamComponent extends PositionComponent
    with HasGameReference, CollisionCallbacks
    implements OpacityProvider {
  final Vector2 direction;
  final double length;
  final double width;
  final double damage;
  final Color color;
  double _lifespan;
  final double duration;
  final bool isEnemyAttack;

  BeamComponent({
    required Vector2 position,
    required this.direction,
    required this.length,
    required this.damage,
    required this.duration,
    this.width = 20,
    this.color = Colors.red,
    this.isEnemyAttack = false,
  }) : _lifespan = duration,
       super(
         position: position,
         size: Vector2(length, width),
         anchor: Anchor.centerLeft,
       ) {
    // 設置角度
    angle = direction.angleTo(Vector2(1, 0));
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加碰撞區域
    add(RectangleHitbox()..collisionType = CollisionType.passive);

    try {
      // 添加透明度效果前進行日誌記錄
      developer.log('光束組件添加淡出效果', name: 'OpacityDebug');

      // 添加視覺效果 - 由亮到暗的漸變
      add(
        OpacityEffect.fadeOut(
          EffectController(duration: duration),
          onComplete: () {
            developer.log('光束淡出完成，準備移除', name: 'OpacityDebug');
            removeFromParent();
          },
        ),
      );

      developer.log('光束組件淡出效果已添加', name: 'OpacityDebug');
    } catch (e) {
      developer.log('添加光束淡出效果時發生錯誤: $e', name: 'OpacityDebug');
      // 如果效果添加失敗，還是設置一個定時器來移除光束
      add(
        TimerComponent(
          period: duration,
          removeOnFinish: true,
          onTick: () => removeFromParent(),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

    // 繪製主體光束
    canvas.drawRect(Rect.fromLTWH(0, -width / 2, length, width), paint);

    // 繪製光束邊緣（更亮的部分）
    final edgePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(0, -width / 2, length, width), edgePaint);

    // 添加一些小粒子效果
    final random = math.Random();
    for (int i = 0; i < 10; i++) {
      final particleX = random.nextDouble() * length;
      final particleY = (random.nextDouble() - 0.5) * width;
      final particleSize = 1 + random.nextDouble() * 3;

      canvas.drawCircle(
        Offset(particleX, particleY),
        particleSize,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 只有敵人攻擊才會對玩家造成傷害
    if (isEnemyAttack && other is PlayerComponent) {
      debugPrint('光束攻擊命中玩家，嘗試造成 ${damage.toInt()} 點傷害');
      try {
        other.takeDamage(damage.toInt());
        debugPrint('光束成功對玩家造成傷害');
      } catch (e) {
        debugPrint('光束對玩家造成傷害時出錯: $e');
      }
    }
  }

  @override
  double get opacity => _opacity;
  double _opacity = 1.0;
  @override
  set opacity(double value) {
    // 添加調試日誌來追蹤透明度變更
    if (value < 0 || value > 1) {
      developer.log('警告: 光束設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }

    // 只記錄明顯的變化
    if ((value - _opacity).abs() > 0.1) {
      developer.log('光束透明度從 $_opacity 變更到 $value', name: 'OpacityDebug');
    }

    _opacity = value;
  }
}
