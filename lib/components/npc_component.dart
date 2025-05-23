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

  // 更新變數，用於按鈕呼吸效果
  double _hintPulseValue = 0;
  bool _hintPulseIncreasing = true;

  NpcComponent({
    required this.name,
    required Vector2 position,
    required Vector2 size,
    this.color = Colors.blue,
    this.isInteractive = true,
    List<String>? greetings,
    this.bubbleDuration = 3.0,
    this.interactionRadius = 70, // 將默認互動半徑從 100 縮小到 70
    this.supportConversation = false, // 默認改為 false，只有明確指定的 NPC 才支持對話
    Map<String, Dialogue>? dialogueTree,
  }) : greetings = greetings ?? ['你好！', '嗨！', '有什麼我能幫你的嗎？'],

       dialogueTree = dialogueTree ?? {},
       super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加視覺效果
    add(RectangleComponent(size: size, paint: Paint()..color = color));

    // 添加名稱標籤 - 調整到NPC下方
    add(
      TextComponent(
        text: name,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cubic11', // 指定使用 Cubic11 字體
          ),
        ),
        position: Vector2(0, -size.y / 2 - 10), // 修改位置到NPC頭上方
        anchor: Anchor.bottomCenter, // 修改錨點以正確顯示
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
    const fontSize = 15.0; // 稍微增加字體大小
    const padding = 12.0; // 增加內邊距使氣泡更寬敞

    // 氣泡位置（在NPC頭頂）
    final bubblePosition = Vector2(0, -size.y / 2 - 100); // 大幅調高位置，避免遮擋NPC名字

    // 計算文字佈局以確定實際需要的高度
    final textStyle = TextStyle(
      color: Colors.black87, // 使用較深的黑色，不那麼刺眼
      fontSize: fontSize,
      fontFamily: 'Cubic11', // 使用 Cubic11 字體
      height: 1.2, // 增加行高使文字更易讀
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center, // 文字置中
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
      const Radius.circular(12), // 增加圓角半徑
    );

    // 使用漸變色彩增強視覺效果
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Colors.white, Colors.white.withOpacity(0.95)],
    );

    // 繪製陰影
    canvas.drawRRect(
      rrect.shift(const Offset(3, 3)), // 稍微增大陰影偏移
      Paint()
        ..color =
            Colors
                .black38 // 柔和的陰影顏色
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3), // 增加模糊效果
    );

    // 繪製氣泡
    final bubblePaint =
        Paint()
          ..shader = gradient.createShader(bubbleRect)
          ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, bubblePaint);

    // 為氣泡增加細邊框，增強立體感
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 繪製氣泡小尖角
    final path =
        Path()
          ..moveTo(bubblePosition.x - 10, bubblePosition.y + bubbleHeight / 2)
          ..lineTo(
            bubblePosition.x,
            bubblePosition.y + bubbleHeight / 2 + 15,
          ) // 墜大尖角
          ..lineTo(bubblePosition.x + 10, bubblePosition.y + bubbleHeight / 2)
          ..close();

    // 使用與氣泡相同的漸變色彩
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(
          bubbleRect.translate(0, bubbleHeight / 2),
        )
        ..style = PaintingStyle.fill,
    );

    // 為尖角增加細邊框
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.grey.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 繪製文字 (置中對齊)
    textPainter.paint(
      canvas,
      Offset(
        bubblePosition.x - textPainter.width / 2,
        bubblePosition.y - bubbleHeight / 2 + padding,
      ),
    );

    // 添加NPC名稱在氣泡頂部
    final nameStyle = TextStyle(
      color: Colors.deepPurple, // 使用較深的紫色突出名稱
      fontSize: fontSize - 3, // 名稱字體稍小
      fontFamily: 'Cubic11',
      fontWeight: FontWeight.bold,
    );

    final nameSpan = TextSpan(text: name, style: nameStyle);
    final namePainter = TextPainter(
      text: nameSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    namePainter.layout(minWidth: 0, maxWidth: bubbleWidth - (padding * 2));
  }

  // 繪製互動提示
  void _renderInteractionHint(Canvas canvas) {
    const hintWidth = 90.0; // 增加寬度
    const hintHeight = 28.0; // 增加高度
    const fontSize = 14.0; // 增加字體大小
    const iconSize = 16.0; // E 字符圖示大小

    // 提示位置（顯示在NPC下方）
    final hintPosition = Vector2(
      0, // 水平置中
      size.y / 2 + 20, // 垂直位置在NPC下方
    );

    // 計算呼吸效果值 (用於大小和透明度調整)
    final scale = 1.0 + (_hintPulseValue * 0.05);
    final opacity = 0.8 + (_hintPulseValue * 0.2);

    // 繪製提示背景 (帶有呼吸效果)
    final scaledWidth = hintWidth * scale;
    final scaledHeight = hintHeight * scale;

    final hintRect = Rect.fromCenter(
      center: Offset(hintPosition.x, hintPosition.y),
      width: scaledWidth,
      height: scaledHeight,
    );

    final rrect = RRect.fromRectAndRadius(
      hintRect,
      const Radius.circular(14), // 增大圓角
    );

    // 繪製外發光效果
    final glowPaint =
        Paint()
          ..color = Colors.white.withOpacity(0.3 * _hintPulseValue)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            4.0 * _hintPulseValue,
          );

    canvas.drawRRect(rrect.inflate(2 + _hintPulseValue * 2), glowPaint);

    // 繪製陰影
    canvas.drawRRect(
      rrect.shift(Offset(2, 2)),
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3),
    );

    // 繪製邊框
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white.withOpacity(0.3 + 0.2 * _hintPulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // 繪製 E 鍵圓形背景
    canvas.drawCircle(
      Offset(hintPosition.x - 25, hintPosition.y),
      iconSize / 2,
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    // 繪製 E 字符
    final keyStyle = TextStyle(
      color: Color(0xFF2A3C6E),
      fontSize: fontSize - 2,
      fontWeight: FontWeight.bold,
      fontFamily: 'Cubic11',
    );

    final keySpan = TextSpan(text: 'E', style: keyStyle);
    final keyPainter = TextPainter(
      text: keySpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    keyPainter.layout();
    keyPainter.paint(
      canvas,
      Offset(
        hintPosition.x - 25 - keyPainter.width / 2,
        hintPosition.y - keyPainter.height / 2,
      ),
    );

    // 繪製「對話」文字
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      fontFamily: 'Cubic11',
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          offset: Offset(1, 1),
          blurRadius: 1,
        ),
      ],
    );

    final textSpan = TextSpan(text: "對話", style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(minWidth: 0, maxWidth: hintWidth - 40);
    textPainter.paint(
      canvas,
      Offset(
        hintPosition.x - textPainter.width / 2 + 10,
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

    // 更新互動提示呼吸效果
    if (_showInteractionHint) {
      // 呼吸效果動畫 (0.0 ~ 1.0 循環)
      if (_hintPulseIncreasing) {
        _hintPulseValue += dt * 1.5; // 控制呼吸速度
        if (_hintPulseValue >= 1.0) {
          _hintPulseValue = 1.0;
          _hintPulseIncreasing = false;
        }
      } else {
        _hintPulseValue -= dt * 1.5;
        if (_hintPulseValue <= 0.0) {
          _hintPulseValue = 0.0;
          _hintPulseIncreasing = true;
        }
      }
    }
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
