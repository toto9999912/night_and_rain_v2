import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ExplosionEffect extends PositionComponent {
  final Color color;
  final double explosionSize; // 改名為 explosionSize 避免與 PositionComponent.size 衝突
  final double duration;

  double _timer = 0;
  late final List<Paint> _paints;
  late final List<double> _radiuses;

  ExplosionEffect({
    required Vector2 position,
    this.color = Colors.orange,
    this.explosionSize = 20, // 改名為 explosionSize
    this.duration = 0.5,
  }) : super(position: position, anchor: Anchor.center) {
    // 準備多層爆炸效果
    final particleCount = 3;
    _paints = List.generate(
      particleCount,
      (i) =>
          Paint()
            ..color = color.withOpacity(1.0 - (i / particleCount))
            ..style = PaintingStyle.fill,
    );

    // 爆炸粒子的不同大小
    _radiuses = List.generate(
      particleCount,
      (i) => explosionSize * (1.0 - (i * 0.3)), // 使用改名後的 explosionSize
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _timer += dt;
    if (_timer >= duration) {
      removeFromParent();
      return;
    }

    // 更新顏色透明度
    final progress = _timer / duration;
    for (int i = 0; i < _paints.length; i++) {
      final opacity = (1.0 - progress) * (1.0 - (i / _paints.length));
      _paints[i].color = color.withOpacity(opacity);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = _timer / duration;
    final expansion = 1.0 + progress;

    // 繪製爆炸粒子
    for (int i = 0; i < _paints.length; i++) {
      final radius = _radiuses[i] * expansion;
      canvas.drawCircle(Offset.zero, radius, _paints[i]);

      // 添加一些隨機飛濺效果
      final sparkCount = 5;
      final sparkLength = radius * 0.6;
      final sparkPaint =
          Paint()
            ..color = _paints[i].color
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;

      for (int j = 0; j < sparkCount; j++) {
        final angle = j * (math.pi * 2 / sparkCount);
        final innerRadius = radius * 0.8;
        final outerRadius = radius + sparkLength * (1 - progress);

        canvas.drawLine(
          Offset(innerRadius * math.cos(angle), innerRadius * math.sin(angle)),
          Offset(outerRadius * math.cos(angle), outerRadius * math.sin(angle)),
          sparkPaint,
        );
      }
    }
  }
}
