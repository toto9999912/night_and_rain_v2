import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'player_component.dart';

/// 對話結構體 - 用於構建對話樹
class Dialogue {
  final String npcText; // NPC的對話內容
  final List<PlayerResponse> responses; // 玩家可選擇的回應
  final String? nextDialogueId; // 如果沒有回應選項，直接跳轉到下一個對話的ID

  Dialogue({
    required this.npcText,
    this.responses = const [],
    this.nextDialogueId,
  });
}

/// 玩家回應選項
class PlayerResponse {
  final String text; // 回應的文本內容
  final String? nextDialogueId; // 選擇此回應後跳轉到的對話ID
  final Function()? action; // 選擇此回應時可能觸發的額外動作

  PlayerResponse({required this.text, this.nextDialogueId, this.action});
}

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
  // 是否支持正式對話（按E鍵對話）
  final bool supportConversation;
  // 簡單對話內容 - 舊版的對話模式
  final List<String> conversations;

  // 新增：對話樹 - 用於構建複雜的交互式對話
  final Map<String, Dialogue> dialogueTree;
  // 新增：當前對話ID
  String? currentDialogueId;

  // 當前玩家是否在互動範圍內
  bool _playerInRange = false;
  // 當前是否正在顯示對話
  bool _isShowingBubble = false;
  // 是否顯示互動提示
  bool _showInteractionHint = false;
  // 當前顯示的對話
  String _currentGreeting = '';
  // 隨機數生成器
  final Random _random = Random();
  // 對話氣泡顯示時間計數器
  double _bubbleTimeLeft = 0;

  NpcComponent({
    required this.name,
    required Vector2 position,
    required Vector2 size,
    this.color = Colors.blue,
    this.isInteractive = true,
    List<String>? greetings,
    this.bubbleDuration = 3.0,
    this.interactionRadius = 100,
    this.supportConversation = false, // 默認改為 false，只有明確指定的 NPC 才支持對話
    List<String>? conversations,
    Map<String, Dialogue>? dialogueTree,
  }) : greetings = greetings ?? ['你好！', '嗨！', '有什麼我能幫你的嗎？'],
       conversations =
           conversations ?? ['歡迎來到夜雨世界，我是$name。', '今天天氣不錯，不是嗎？', '需要我幫忙嗎？'],
       dialogueTree = dialogueTree ?? {},
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
        position: Vector2(0, -size.y / 2 - 0),
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
  void render(Canvas canvas) {
    super.render(canvas);

    // 繪製對話氣泡
    if (_isShowingBubble) {
      _renderSpeechBubble(canvas, _currentGreeting);
    }

    // 繪製互動提示（當玩家在範圍內且NPC支持對話時）
    // 移除「!_isShowingBubble」條件，使互動提示可以與氣泡同時顯示
    if (_playerInRange && supportConversation && _showInteractionHint) {
      _renderInteractionHint(canvas);
    }
  }

  // 繪製對話氣泡
  void _renderSpeechBubble(Canvas canvas, String text) {
    const bubbleWidth = 180.0;
    const bubbleMinHeight = 60.0;
    const fontSize = 14.0;
    const padding = 10.0;

    // 氣泡位置（在NPC頭頂）
    final bubblePosition = Vector2(0, -size.y / 2 - 50);

    // 計算文字佈局以確定實際需要的高度
    final textStyle = TextStyle(color: Colors.black, fontSize: fontSize);
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // 計算文字所需的實際高度
    textPainter.layout(minWidth: 0, maxWidth: bubbleWidth - (padding * 2));
    final double textHeight = textPainter.height;
    final double bubbleHeight = max(
      bubbleMinHeight,
      textHeight + (padding * 2),
    );

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

    // 繪製陰影
    canvas.drawRRect(
      rrect.shift(const Offset(2, 2)),
      Paint()..color = Colors.black26,
    );

    // 繪製氣泡
    canvas.drawRRect(rrect, Paint()..color = Colors.white.withOpacity(0.9));

    // 繪製氣泡小尖角
    final path =
        Path()
          ..moveTo(bubblePosition.x - 10, bubblePosition.y + bubbleHeight / 2)
          ..lineTo(bubblePosition.x, bubblePosition.y + bubbleHeight / 2 + 10)
          ..lineTo(bubblePosition.x + 10, bubblePosition.y + bubbleHeight / 2)
          ..close();

    canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.9));

    // 繪製文字
    textPainter.paint(
      canvas,
      Offset(
        bubblePosition.x - bubbleWidth / 2 + padding,
        bubblePosition.y - bubbleHeight / 2 + padding,
      ),
    );
  }

  // 繪製互動提示
  void _renderInteractionHint(Canvas canvas) {
    const hintWidth = 80.0;
    const hintHeight = 24.0;
    const fontSize = 12.0;

    // 提示位置（修改為顯示在NPC名字的右側）
    final nameWidth = 20.0 + name.length * 8.0; // 估算名字的寬度
    final hintPosition = Vector2(
      nameWidth / 2 + hintWidth / 2 + 5,
      -size.y / 2 - 0,
    ); // 放在名字右側

    // 繪製提示背景
    final hintRect = Rect.fromCenter(
      center: Offset(hintPosition.x, hintPosition.y),
      width: hintWidth,
      height: hintHeight,
    );

    final rrect = RRect.fromRectAndRadius(hintRect, const Radius.circular(5));

    canvas.drawRRect(rrect, Paint()..color = Colors.black.withOpacity(0.7));

    // 繪製文字
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
    final textSpan = TextSpan(text: "按E對話", style: textStyle);

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(minWidth: 0, maxWidth: hintWidth - 10);

    textPainter.paint(
      canvas,
      Offset(
        hintPosition.x - textPainter.width / 2,
        hintPosition.y - textPainter.height / 2,
      ),
    );
  }

  // 顯示隨機問候語
  void showRandomGreeting() {
    if (greetings.isEmpty) return;

    // 如果已經在顯示氣泡，則不再觸發新的問候
    if (_isShowingBubble) return;

    // 隨機選擇一個問候語
    _currentGreeting = greetings[_random.nextInt(greetings.length)];
    _isShowingBubble = true;

    // 設置氣泡顯示時間
    _bubbleTimeLeft = bubbleDuration;
  }

  // 更新互動提示狀態 - 新增此方法來處理互動提示的顯示邏輯
  void updateInteractionHint() {
    // 只有玩家在範圍內且NPC支持對話時顯示互動提示
    _showInteractionHint = _playerInRange && supportConversation;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新氣泡倒數計時
    if (_isShowingBubble) {
      _bubbleTimeLeft -= dt;

      // 當計時結束，隱藏氣泡
      if (_bubbleTimeLeft <= 0) {
        _isShowingBubble = false;
        _currentGreeting = '';
      }
    }

    // 更新互動提示狀態
    updateInteractionHint();
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 檢測玩家是否靠近
    if (other is PlayerComponent && isInteractive) {
      _playerInRange = true;

      // 所有NPC都會顯示隨機問候語
      showRandomGreeting();

      // 如果支持對話，立即顯示互動提示（不再等待問候語結束）
      if (supportConversation) {
        _showInteractionHint = true;
        // 告訴玩家當前有可互動的NPC
        other.setInteractiveNpc(this);
      }
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (other is PlayerComponent && isInteractive) {
      _playerInRange = false;
      _showInteractionHint = false;

      // 告訴玩家已經離開互動範圍
      other.clearInteractiveNpc(this);
    }
  }

  // 新增：獲取當前對話
  Dialogue? getCurrentDialogue() {
    if (currentDialogueId == null) return null;
    return dialogueTree[currentDialogueId];
  }

  // 新增：設置對話ID並獲取對話
  Dialogue? setAndGetDialogue(String dialogueId) {
    currentDialogueId = dialogueId;
    return getCurrentDialogue();
  }

  // 新增：重置對話狀態
  void resetDialogue() {
    currentDialogueId = null;
  }

  // 更新開始對話方法，支持交互式對話
  void startDialogue() {
    if (!supportConversation) return;

    // 如果有對話樹，使用對話樹，否則使用簡單對話列表
    if (dialogueTree.isNotEmpty) {
      // 設置初始對話ID為"start"
      currentDialogueId = "start";
    }

    // 使用對話覆蓋層顯示對話
    game.overlays.add('DialogOverlay');
  }
}
