// 敵人元件，會主動檢測並攻擊玩家
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// Boss階段轉換效果
class BossPhaseTransitionEffect extends PositionComponent
    implements OpacityProvider {
  final Color color;
  double _lifespan = 1.5;
  double _scale = 0;
  final double _maxScale = 1.0;
  double _opacity = 1.0;

  BossPhaseTransitionEffect({
    required Vector2 position,
    required this.color,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    // 更新生命週期
    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
      return;
    }

    // 擴散效果
    if (_lifespan > 0.75) {
      // 前半部分擴大
      _scale = (_maxScale * (1.5 - _lifespan) / 0.75).clamp(0.0, _maxScale);
    } else {
      // 後半部分保持最大並漸漸消失
      _scale = _maxScale;
    }
  }

  @override
  void render(Canvas canvas) {
    // 確保半徑至少為1，避免繪製尺寸為0的形狀
    final radius = math.max(size.x / 2 * _scale, 1.0);

    // 確保顏色的透明度在有效範圍內，並應用全局透明度設定
    final outlineOpacity = (0.8 * (_lifespan / 1.5) * _opacity).clamp(0.0, 1.0);
    final fillOpacity = (0.3 * (_lifespan / 1.5) * _opacity).clamp(0.0, 1.0);
    final rayOpacity = (0.5 * (_lifespan / 1.5) * _opacity).clamp(0.0, 1.0);

    // 外圈
    final outlinePaint =
        Paint()
          ..color = color.withValues(alpha: outlineOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5;

    // 內圈
    final fillPaint =
        Paint()
          ..color = color.withValues(alpha: fillOpacity)
          ..style = PaintingStyle.fill;

    // 繪製圓形
    canvas.drawCircle(Offset.zero, radius, fillPaint);
    canvas.drawCircle(Offset.zero, radius, outlinePaint);

    // 添加光線效果
    final rayCount = 8;
    final rayPaint =
        Paint()
          ..color = color.withValues(alpha: rayOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    for (int i = 0; i < rayCount; i++) {
      final angle = 2 * math.pi * i / rayCount;
      final innerRadius = radius * 0.8;
      final outerRadius = radius * 1.5;

      canvas.drawLine(
        Offset(math.cos(angle) * innerRadius, math.sin(angle) * innerRadius),
        Offset(math.cos(angle) * outerRadius, math.sin(angle) * outerRadius),
        rayPaint,
      );
    }
  }

  // OpacityProvider 介面實現
  @override
  double get opacity => _opacity;
  @override
  set opacity(double value) {
    if (value < 0 || value > 1) {
      developer.log('警告: 階段轉換效果設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }
    _opacity = value;
  }
}
