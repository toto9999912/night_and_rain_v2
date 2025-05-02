import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class BulletComponent extends PositionComponent
    with HasGameReference, CollisionCallbacks {
  final Vector2 direction;
  final double speed;
  final double damage;
  final double range;
  final Color color;

  double _distanceTraveled = 0;
  final Paint _paint;

  BulletComponent({
    required Vector2 position,
    required this.direction,
    required this.speed,
    required this.damage,
    required this.range,
    this.color = Colors.yellow,
  }) : _paint = Paint()..color = color,
       super(position: position, size: Vector2.all(6));

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加碰撞形狀
    add(CircleHitbox(radius: 3));
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 移動子彈
    final movement = direction * speed * dt;
    position += movement;

    // 計算已移動距離
    _distanceTraveled += movement.length;

    // 超出射程移除子彈
    if (_distanceTraveled >= range) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(Offset.zero, 3, _paint);
  }

  // 碰撞檢測
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 如果碰到敵人，就對敵人造成傷害並移除子彈
    // TODO: 實現敵人碰撞邏輯
    // if (other is EnemyComponent) {
    //   other.takeDamage(damage);
    //   removeFromParent();
    // }
  }
}
