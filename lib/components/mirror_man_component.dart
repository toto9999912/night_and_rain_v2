import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'npc_component.dart';

/// 鏡像人NPC組件 - 只在神秘迴廊中出現的特殊NPC
class MirrorManComponent extends NpcComponent {
  /// 脈動效果值
  double _pulseValue = 0;

  /// 脈動方向
  int _pulseDirection = 1;

  /// 互動提示計時器
  late Timer _interactionTimer;

  MirrorManComponent({
    required super.position,
    required super.name,
    required super.color,
    List<String> dialogues = const ['鏡子裡的你...', '或許知道通往寶藏的密碼...'],
    double interactionRange = 60,
    Vector2? size,
  }) : super(
         size: size ?? Vector2.all(32),
         greetings: dialogues,
         interactionRadius: interactionRange,
         supportConversation: true,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 初始化互動計時器
    _interactionTimer = Timer(0.05, onTick: _updatePulse, repeat: true);
  }

  /// 更新脈動效果
  void _updatePulse() {
    _pulseValue += 0.05 * _pulseDirection;
    if (_pulseValue >= 1) {
      _pulseDirection = -1;
    } else if (_pulseValue <= 0) {
      _pulseDirection = 1;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新互動計時器
    _interactionTimer.update(dt);
  }

  @override
  void render(Canvas canvas) {
    // 繪製半透明鏡像效果的圓形
    final baseColor = color.withOpacity(0.6 + _pulseValue * 0.3);
    final paint = Paint()..color = baseColor;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);

    // 繪製光暈效果
    final glowPaint =
        Paint()
          ..color = color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 5 + _pulseValue * 3,
      glowPaint,
    );

    // 繪製鏡像線條效果
    final linePaint =
        Paint()
          ..color = Colors.white.withOpacity(0.5 + _pulseValue * 0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

    // 繪製交叉線條
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2 - 2;

    // 水平線
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      linePaint,
    );

    // 垂直線
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      linePaint,
    );

    // 對角線
    canvas.drawLine(
      Offset(center.dx - radius * 0.7, center.dy - radius * 0.7),
      Offset(center.dx + radius * 0.7, center.dy + radius * 0.7),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.7, center.dy + radius * 0.7),
      Offset(center.dx + radius * 0.7, center.dy - radius * 0.7),
      linePaint,
    );

    // 繪製NPC名稱
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
      ],
    );

    final textSpan = TextSpan(text: name, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.x / 2 - textPainter.width / 2, -textPainter.height - 5),
    );

    // 繪製對話氣泡和互動提示
    super.render(canvas);
  }

  // 自定義方法：處理對話完成後的操作
  void onDialogueFinished() {
    // 對話結束後打開密碼輸入界面
    if (game is NightAndRainGame) {
      (game as NightAndRainGame).overlays.add('PasswordInputOverlay');
    }
  }
}
