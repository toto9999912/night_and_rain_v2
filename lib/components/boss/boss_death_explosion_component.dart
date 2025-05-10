// 敵人元件，會主動檢測並攻擊玩家
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// Boss死亡爆炸效果
class BossDeathExplosionComponent extends PositionComponent
    implements OpacityProvider {
  final List<Color> colors = [Colors.red, Colors.orange, Colors.yellow];
  double _lifespan = 2.0;
  double _currentRadius = 0;
  final double _maxRadius;
  double _opacity = 1.0;

  BossDeathExplosionComponent({
    required Vector2 position,
    required Vector2 size,
  }) : _maxRadius = size.x / 2,
       super(position: position, size: size, anchor: Anchor.center);

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
    if (_lifespan > 1.0) {
      // 前半部分快速擴大
      _currentRadius = _maxRadius * (1 - _lifespan / 2) * 2;
    } else {
      // 保持最大半徑並慢慢消失
      _currentRadius = _maxRadius;
    }
  }

  @override
  void render(Canvas canvas) {
    // 根據生命週期選擇顏色
    final colorIndex = ((_lifespan * 5) % colors.length).floor().clamp(
      0,
      colors.length - 1,
    );
    final color = colors[colorIndex];

    // 計算有效透明度，結合生命週期和全局透明度設定
    final effectiveOpacity = (_lifespan / 2) * _opacity;

    // 外圈
    final outlinePaint =
        Paint()
          ..color = color.withValues(alpha: 0.9 * effectiveOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8;

    // 內圈
    final fillPaint =
        Paint()
          ..color = color.withValues(alpha: 0.4 * effectiveOpacity)
          ..style = PaintingStyle.fill;

    // 繪製主爆炸圓
    canvas.drawCircle(Offset.zero, _currentRadius, fillPaint);
    canvas.drawCircle(Offset.zero, _currentRadius, outlinePaint);

    // 添加碎片效果
    final random = math.Random();
    final debrisPaint =
        Paint()..color = Colors.white.withValues(alpha: 0.7 * effectiveOpacity);

    for (int i = 0; i < 50; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * _currentRadius;
      final debrisSize = 1 + random.nextDouble() * 4;

      canvas.drawCircle(
        Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        debrisSize,
        debrisPaint,
      );
    }

    // 添加光束效果
    final rayCount = 12;
    final rayPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6 * effectiveOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    for (int i = 0; i < rayCount; i++) {
      final angle = 2 * math.pi * i / rayCount;
      final rayLength = _currentRadius * 1.5;

      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle) * rayLength, math.sin(angle) * rayLength),
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
      developer.log('警告: 死亡爆炸效果設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }

    // 記錄顯著的透明度變化
    if ((value - _opacity).abs() > 0.1) {
      developer.log('死亡爆炸效果透明度從 $_opacity 變更到 $value', name: 'OpacityDebug');
    }

    _opacity = value;
  }
}
