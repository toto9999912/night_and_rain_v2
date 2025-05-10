import 'package:flame/components.dart';

import 'package:flutter/material.dart';

/// 範圍攻擊指示器組件
class AoeIndicatorComponent extends PositionComponent {
  final double radius;
  final Color color;
  double _lifespan;
  final double duration;

  AoeIndicatorComponent({
    required Vector2 position,
    required this.radius,
    required this.color,
    required this.duration,
  }) : _lifespan = duration,
       super(
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
    // 閃爍效果
    final blink = (_lifespan * 10).toInt() % 2 == 0;
    final opacity = blink ? 0.6 : 0.3;

    // 繪製外圈
    final outlinePaint =
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, radius, outlinePaint);

    // 繪製填充區域
    final fillPaint =
        Paint()
          ..color = color.withValues(alpha: opacity * 0.3)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius, fillPaint);

    // 添加警告標記
    final warningPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    const warningSize = 20.0;

    // 繪製感嘆號
    canvas.drawLine(
      Offset(0, -warningSize / 2),
      Offset(0, warningSize / 2 - 5),
      warningPaint,
    );

    canvas.drawCircle(Offset(0, warningSize / 2 + 2), 2, warningPaint);
  }
}
