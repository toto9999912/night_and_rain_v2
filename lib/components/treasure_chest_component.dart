import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/effects.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import 'player_component.dart';

/// 寶箱組件 - 需要密碼才能開啟
class TreasureChestComponent extends PositionComponent
    with TapCallbacks, CollisionCallbacks, HasGameReference<NightAndRainGame> {
  /// 寶箱名稱
  final String name;

  /// 寶箱顏色
  final Color color;

  /// 互動範圍
  final double interactionRange;

  /// 寶箱密碼
  final String password;

  /// 是否已開啟
  bool _isOpened = false;

  /// 是否顯示互動提示
  bool _shouldShowPrompt = false;

  /// 脈動效果值
  double _pulseValue = 0;

  /// 脈動方向
  int _pulseDirection = 1;

  /// 脈動計時器
  late Timer _pulseTimer;

  TreasureChestComponent({
    required Vector2 position,
    required this.name,
    required this.password,
    this.color = const Color(0xFFD4AF37), // 金色寶箱
    this.interactionRange = 60,
    Vector2? size,
  }) : super(
         position: position,
         size: size ?? Vector2(40, 40),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加碰撞檢測
    add(RectangleHitbox()..collisionType = CollisionType.passive);

    // 初始化脈動計時器
    _pulseTimer = Timer(0.05, onTick: _updatePulse, repeat: true);
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

    // 如果寶箱已開啟，則不做任何處理
    if (_isOpened) return;

    // 更新脈動計時器
    _pulseTimer.update(dt);

    // 檢查與玩家的距離
    final player = game.getPlayer();
    final distance = player.position.distanceTo(position);

    final shouldShowPrompt = distance <= interactionRange;

    // 如果狀態改變，則更新提示
    if (shouldShowPrompt != _shouldShowPrompt) {
      _shouldShowPrompt = shouldShowPrompt;

      if (_shouldShowPrompt) {
        game.showInteractionPrompt('按 E 打開寶箱');
      } else {
        game.hideInteractionPrompt();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 根據寶箱是否開啟來決定繪製不同的外觀
    if (_isOpened) {
      _renderOpenedChest(canvas);
    } else {
      _renderClosedChest(canvas);
    }
  }

  /// 繪製關閉的寶箱
  void _renderClosedChest(Canvas canvas) {
    // 繪製寶箱底部
    final basePaint = Paint()..color = color;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, basePaint);

    // 繪製寶箱邊框
    final borderPaint =
        Paint()
          ..color = Colors.brown.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

    // 繪製寶箱鎖
    final lockPaint = Paint()..color = Colors.grey.shade800;
    canvas.drawRect(
      Rect.fromLTWH(size.x / 2 - 5, size.y / 2 - 5, 10, 10),
      lockPaint,
    );

    // 添加閃爍效果
    if (!_isOpened) {
      final glowPaint =
          Paint()
            ..color = color.withOpacity(0.2 + _pulseValue * 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawRect(
        Rect.fromLTWH(-5, -5, size.x + 10, size.y + 10),
        glowPaint,
      );
    }

    // 繪製寶箱名稱
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
  }

  /// 繪製開啟的寶箱
  void _renderOpenedChest(Canvas canvas) {
    // 繪製寶箱底部
    final basePaint = Paint()..color = color;
    final baseRect = Rect.fromLTWH(0, size.y / 2, size.x, size.y / 2);
    canvas.drawRect(baseRect, basePaint);

    // 繪製寶箱蓋（打開狀態）
    final lidRect = Rect.fromLTWH(0, 0, size.x, size.y / 3);
    canvas.drawRect(lidRect, basePaint);

    // 繪製寶箱內部光芒
    final glowPaint =
        Paint()
          ..color = Colors.yellow.withOpacity(0.3 + _pulseValue * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(
      Rect.fromLTWH(5, size.y / 2 + 5, size.x - 10, size.y / 2 - 10),
      glowPaint,
    );

    // 繪製邊框
    final borderPaint =
        Paint()
          ..color = Colors.brown.shade800
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawRect(baseRect, borderPaint);
    canvas.drawRect(lidRect, borderPaint);

    // 繪製寶箱名稱
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
      ],
    );

    final textSpan = TextSpan(text: "$name (已開啟)", style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.x / 2 - textPainter.width / 2, -textPainter.height - 5),
    );
  }
  @override
  bool onTapDown(TapDownEvent event) {
    if (_shouldShowPrompt && !_isOpened) {
      // 開啟密碼輸入覆蓋層
      game.dialogNpc = null; // 清除對話NPC，避免衝突
      game.overlays.add('PasswordInputOverlay');
      game.hideInteractionPrompt();
      return true;
    }
    return false;
  }

  /// 嘗試用密碼開啟寶箱
  bool tryOpen(String inputPassword) {
    if (inputPassword == password) {
      _isOpened = true;

      // 添加開啟效果
      add(
        ScaleEffect.by(
          Vector2.all(1.2),
          EffectController(duration: 0.2, reverseDuration: 0.2),
        ),
      );

      // 添加獎勵（例如增加庫存物品）
      _giveRewards();

      return true;
    }
    return false;
  }

  /// 給予玩家獎勵
  void _giveRewards() {
    // 這裡可以根據遊戲邏輯給予玩家不同的獎勵
    // 例如：增加金幣、添加特殊武器等
    // 請根據具體需求自行實現

    // 提示玩家獲得獎勵
    game.showInteractionPrompt('獲得神秘寶物！');

    // 延遲隱藏提示
    add(
      TimerComponent(
        period: 3.0,
        removeOnFinish: true,
        onTick: () {
          game.hideInteractionPrompt();
        },
      ),
    );
  }
}
