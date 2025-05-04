import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:developer' as developer;

/// 確保透明度值在有效範圍內 (0.0-1.0)
double safeOpacity(double value) {
  if (value.isNaN) return 1.0; // 處理 NaN 情況
  if (value.isInfinite) return value.isNegative ? 0.0 : 1.0; // 處理無限值情況
  return value.clamp(0.0, 1.0);
}

class ExplosionEffect extends PositionComponent implements OpacityProvider {
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
            ..color = color.withOpacity(safeOpacity(1.0 - (i / particleCount)))
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
      final alphaValue = safeOpacity(
        (1.0 - progress) * (1.0 - (i / _paints.length)),
      );
      _paints[i].color = color.withOpacity(alphaValue);
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

      // 確保組合後的透明度仍在有效範圍內
      final combinedOpacity = safeOpacity(_paints[i].color.opacity * _opacity);

      // 套用整體透明度效果
      Paint effectivePaint =
          Paint()
            ..color = _paints[i].color.withOpacity(combinedOpacity)
            ..style = _paints[i].style
            ..strokeWidth = _paints[i].strokeWidth
            ..maskFilter = _paints[i].maskFilter;

      canvas.drawCircle(Offset.zero, radius, effectivePaint);

      // 添加一些隨機飛濺效果
      final sparkCount = 5;
      final sparkLength = radius * 0.6;

      // 同樣確保透明度值有效
      final sparkOpacity = safeOpacity(_paints[i].color.opacity * _opacity);

      final sparkPaint =
          Paint()
            ..color = _paints[i].color.withOpacity(sparkOpacity)
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

  // OpacityProvider 介面實現
  @override
  double get opacity => _opacity;
  double _opacity = 1.0;
  @override
  set opacity(double value) {
    // 使用全局函數確保透明度值有效
    final oldValue = value;
    _opacity = safeOpacity(value);

    // 只在值被修正時記錄
    if (oldValue != _opacity) {
      developer.log('修正爆炸效果透明度從 $oldValue 到 $_opacity', name: 'OpacityDebug');
    }
  }
}
