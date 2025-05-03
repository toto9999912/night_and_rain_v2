import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../enum/item_rarity.dart';
import 'map_component.dart';
import '../effects/explosion_effect.dart';

class BulletComponent extends PositionComponent
    with HasGameReference, CollisionCallbacks {
  final Vector2 direction;
  final double speed;
  final double damage;
  final double range;
  final Color color;
  final ItemRarity? rarity; // 新增：子彈稀有度屬性

  double _distanceTraveled = 0;
  final Paint _paint;
  bool _hasCollided = false;
  Timer? _trailTimer; // 用於控制尾隨效果生成頻率

  BulletComponent({
    required Vector2 position,
    required this.direction,
    required this.speed,
    required this.damage,
    required this.range,
    this.color = Colors.yellow,
    this.rarity, // 稀有度參數
    double size = 6.0, // 可自定義大小
  }) : _paint = Paint()..color = color,
       super(
         position: position,
         size: Vector2.all(size),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加碰撞形狀，使用動態大小
    add(CircleHitbox(radius: size.x / 2)..collisionType = CollisionType.active);

    // 根據稀有度添加視覺效果
    _addRarityVisualEffects();
  }

  void _addRarityVisualEffects() {
    if (rarity == null) return;

    // 根據稀有度添加不同的視覺效果
    switch (rarity!) {
      case ItemRarity.riceBug:
        // 米蟲級：無特殊效果
        break;
      case ItemRarity.copperBull:
        // 銅牛級：添加簡單的旋轉效果
        add(
          RotateEffect.by(
            2 * 3.14159, // 旋轉一圈
            EffectController(duration: 0.5, infinite: true),
          ),
        );
        break;
      case ItemRarity.silverBull:
        // 銀牛級：添加顏色變化效果
        add(
          ColorEffect(
            Colors.white,
            EffectController(
              duration: 0.5,
              reverseDuration: 0.5,
              infinite: true,
            ),
            opacityFrom: 0.0,
            opacityTo: 0.8, // 透明度脈動
          ),
        );
        break;
      case ItemRarity.goldBull:
        // 金牛級：添加縮放和顏色效果
        add(
          SequenceEffect([
            ScaleEffect.by(Vector2.all(1.2), EffectController(duration: 0.3)),
            ScaleEffect.by(
              Vector2.all(1 / 1.2),
              EffectController(duration: 0.3),
            ),
          ], infinite: true),
        );
        // 添加發光效果 (通過設置 paint)
        _paint
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0)
          ..color = color.withOpacity(0.8);
        break;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新尾隨效果定時器
    _trailTimer?.update(dt);

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
    canvas.drawCircle(Offset.zero, size.x / 2, _paint);
  }

  void _createExplosion(Color explosionColor, double explosionSize) {
    // 根據稀有度調整爆炸效果
    Color finalColor = explosionColor;
    double finalSize = explosionSize;

    if (rarity != null) {
      switch (rarity!) {
        case ItemRarity.riceBug:
          // 普通爆炸
          break;
        case ItemRarity.copperBull:
          // 稍大一些的爆炸，帶銅色調
          finalColor = const Color(0xFFB87333).withOpacity(0.8);
          finalSize *= 1.2;
          break;
        case ItemRarity.silverBull:
          // 更大的爆炸，銀白色調
          finalColor = const Color(0xFFCED4DA).withOpacity(0.8);
          finalSize *= 1.5;
          break;
        case ItemRarity.goldBull:
          // 最大的爆炸，金色調
          finalColor = const Color(0xFFFFB627).withOpacity(0.8);
          finalSize *= 2.0;
          break;
      }
    }

    // 創建爆炸特效
    final explosion = ExplosionEffect(
      position: position.clone(),
      color: finalColor,
      explosionSize: finalSize,
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
