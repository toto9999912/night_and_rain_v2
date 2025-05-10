import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// Boss光環效果組件
class BossAuraComponent extends PositionComponent implements OpacityProvider {
  final double radius;
  final Color color;
  double _lifespan = 1.0;
  double _opacity = 1.0;

  BossAuraComponent({
    required Vector2 position,
    required this.radius,
    required this.color,
  }) : super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

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
    // 繪製光環
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.6 * _lifespan * _opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * _lifespan;

    canvas.drawCircle(
      Offset.zero,
      radius * (1 + (1 - _lifespan) * 0.5), // 光環會慢慢擴大
      paint,
    );
  }

  // OpacityProvider 介面實現
  @override
  double get opacity => _opacity;
  @override
  set opacity(double value) {
    if (value < 0 || value > 1) {
      developer.log('警告: 光環效果設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }
    _opacity = value;
  }
}
