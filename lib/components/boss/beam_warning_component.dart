import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// 光束警告組件 - 在發射光束前顯示警告線
class BeamWarningComponent extends PositionComponent {
  final Vector2 direction;
  final double length;
  final Color color;
  double _lifespan;
  final double duration;

  BeamWarningComponent({
    required Vector2 position,
    required this.direction,
    required this.length,
    required this.color,
    required this.duration,
  }) : _lifespan = duration,
       super(
         position: position,
         size: Vector2(length, 10),
         anchor: Anchor.centerLeft,
       ) {
    // 設置角度
    angle = direction.angleTo(Vector2(1, 0));
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
    // 繪製虛線警告
    final dashPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // 閃爍效果
    final blink = (_lifespan * 10).toInt() % 2 == 0;
    if (blink) {
      dashPaint.color = color.withValues(alpha: 0.8);
    } else {
      dashPaint.color = color.withValues(alpha: 0.4);
    }

    // 繪製虛線
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double currentX = 0;

    while (currentX < length) {
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX + dashWidth, 0),
        dashPaint,
      );
      currentX += dashWidth + dashSpace;
    }
  }
}
