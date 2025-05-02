import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'map_component.dart';
import 'explosion_effect.dart';

class BulletComponent extends PositionComponent
    with HasGameReference, CollisionCallbacks {
  final Vector2 direction;
  final double speed;
  final double damage;
  final double range;
  final Color color;

  double _distanceTraveled = 0;
  final Paint _paint;
  bool _hasCollided = false;

  BulletComponent({
    required Vector2 position,
    required this.direction,
    required this.speed,
    required this.damage,
    required this.range,
    this.color = Colors.yellow,
  }) : _paint = Paint()..color = color,
       super(position: position, size: Vector2.all(6), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加碰撞形狀
    add(CircleHitbox(radius: 3)..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 如果已經碰撞則不再移動
    if (_hasCollided) return;

    // 移動子彈
    final movement = direction * speed * dt;
    position += movement;

    // 計算已移動距離
    _distanceTraveled += movement.length;

    // 超出射程移除子彈，並產生小型爆炸效果
    if (_distanceTraveled >= range) {
      // 產生爆炸效果，但較小且淡色
      _createExplosion(Colors.grey, 10);
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset.zero, 3, _paint);
  }

  void _createExplosion(Color explosionColor, double size) {
    // 創建爆炸特效
    final explosion = ExplosionEffect(
      position: position.clone(),
      color: explosionColor,
      explosionSize: size, // 使用正確的參數名稱 explosionSize
    );

    // 添加到遊戲世界
    parent?.add(explosion);
  }

  // 碰撞檢測
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 避免重複處理碰撞
    if (_hasCollided) return;

    // 處理與障礙物和邊界的碰撞
    if (other is Obstacle || other is BoundaryWall) {
      _hasCollided = true;

      // 產生爆炸效果
      _createExplosion(color, 20);

      // 移除子彈
      removeFromParent();
    }

    // 如果碰到敵人，就對敵人造成傷害並移除子彈
    // TODO: 實現敵人碰撞邏輯
    // if (other is EnemyComponent) {
    //   _hasCollided = true;
    //   other.takeDamage(damage);
    //   _createExplosion(Colors.red, 15);
    //   removeFromParent();
    // }
  }
}
