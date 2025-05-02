import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'player_component.dart';

/// 基本NPC組件，所有NPC類型都繼承此類
class NpcComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  // NPC名稱
  final String name;
  // NPC顏色
  final Color color;
  // 是否可互動
  final bool isInteractive;
  // 對話列表
  final List<String> greetings;
  // 對話氣泡顯示時間
  final double bubbleDuration;
  // 互動距離
  final double interactionRadius;

  // 當前是否正在顯示對話
  bool _isShowingBubble = false;
  // 對話氣泡計時器
  Timer? _bubbleTimer;
  // 當前顯示的對話
  String _currentGreeting = '';
  // 隨機數生成器
  final Random _random = Random();

  NpcComponent({
    required this.name,
    required Vector2 position,
    required Vector2 size,
    this.color = Colors.blue,
    this.isInteractive = true,
    List<String>? greetings,
    this.bubbleDuration = 3.0,
    this.interactionRadius = 100,
  }) : greetings = greetings ?? ['你好！', '嗨！', '有什麼我能幫你的嗎？'],
       super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加視覺效果
    add(RectangleComponent(size: size, paint: Paint()..color = color));

    // 添加名稱標籤
    add(
      TextComponent(
        text: name,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(0, -size.y / 2 - 20),
        anchor: Anchor.bottomCenter,
      ),
    );

    // 添加碰撞檢測區域
    add(
      CircleHitbox(
        radius: interactionRadius,
        collisionType: CollisionType.passive,
        isSolid: false,
      ),
    );

    // 添加實體碰撞區域(較小)
    add(
      RectangleHitbox(
        size: size,
        collisionType: CollisionType.passive,
        isSolid: true,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_bubbleTimer != null) {
      _bubbleTimer!.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 繪製對話氣泡
    if (_isShowingBubble) {
      _renderSpeechBubble(canvas, _currentGreeting);
    }
  }

  void _renderSpeechBubble(Canvas canvas, String text) {
    const bubbleWidth = 150.0;
    const bubbleHeight = 60.0;
    const fontSize = 14.0;

    // 氣泡位置（在NPC頭頂）
    final bubblePosition = Vector2(0, -size.y / 2 - 50);

    // 繪製氣泡背景
    final bubbleRect = Rect.fromCenter(
      center: Offset(bubblePosition.x, bubblePosition.y),
      width: bubbleWidth,
      height: bubbleHeight,
    );

    final rrect = RRect.fromRectAndRadius(
      bubbleRect,
      const Radius.circular(10),
    );

    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // 繪製氣泡小尖角
    final path =
        Path()
          ..moveTo(bubblePosition.x - 10, bubblePosition.y + bubbleHeight / 2)
          ..lineTo(bubblePosition.x, bubblePosition.y + bubbleHeight / 2 + 10)
          ..lineTo(bubblePosition.x + 10, bubblePosition.y + bubbleHeight / 2)
          ..close();

    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.8));

    // 繪製文字
    final textStyle = TextStyle(color: Colors.black, fontSize: fontSize);

    final textSpan = TextSpan(text: text, style: textStyle);

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(minWidth: 0, maxWidth: bubbleWidth - 20);

    textPainter.paint(
      canvas,
      Offset(
        bubblePosition.x - textPainter.width / 2,
        bubblePosition.y - textPainter.height / 2,
      ),
    );
  }

  // 顯示隨機對話
  void showRandomGreeting() {
    if (greetings.isEmpty || _isShowingBubble) return;

    _currentGreeting = greetings[_random.nextInt(greetings.length)];
    _isShowingBubble = true;

    // 設置計時器，在一段時間後隱藏對話氣泡
    _bubbleTimer?.stop();
    _bubbleTimer = Timer(
      bubbleDuration,
      onTick: () {
        _isShowingBubble = false;
      },
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 檢測玩家是否靠近
    if (other is PlayerComponent && isInteractive) {
      showRandomGreeting();
    }
  }
}
