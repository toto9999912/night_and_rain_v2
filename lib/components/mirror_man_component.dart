import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import '../main.dart';
import 'npc_component.dart';
import 'treasure_chest_component.dart';

/// 藏鏡人NPC組件 - 只在鏡中迴廊中出現的特殊NPC
class MirrorManComponent extends NpcComponent {
  /// 脈動效果值
  double _pulseValue = 0;

  /// 脈動方向
  int _pulseDirection = 1;

  /// 互動提示計時器
  late Timer _interactionTimer;

  /// 儲存精靈圖元件
  SpriteComponent? _spriteComponent;

  /// 呼吸動畫計時器
  Timer? _idleAnimationTimer;

  /// 用於呼吸效果的振幅和頻率
  final double _breathAmplitude = 0.05;
  final double _breathFrequency = 1.0;

  /// 記錄動畫時間
  double _animationTime = 0;

  MirrorManComponent({
    required super.position,
    required super.name,
    required super.color,
    List<String> dialogues = const ['鏡子裡的你...或許知道通往寶藏的密碼...'],
    double interactionRange = 60,
    Vector2? size,
  }) : super(
         size: size ?? Vector2.all(64),
         greetings: dialogues,
         interactionRadius: interactionRange,
         supportConversation: true,
       );
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 設置對話樹
    dialogueTree.addAll({
      'start': Dialogue(
        npcText: '【藏鏡人】在這裡等你很久了...我是藏鏡人，來自鏡像世界',
        nextDialogueId: 'hint',
      ),
      'hint': Dialogue(
        npcText: '【藏鏡人】想要打開寶箱，你需要破譯最後的密碼，請記得，密碼不是你想的那麼簡單',
        nextDialogueId: 'final',
      ),
      'final': Dialogue(
        npcText: '【藏鏡人】這是你生命中最重要的日子之一',
        responses: [
          PlayerResponse(text: '我會找到答案的', action: () => onDialogueFinished()),
        ],
      ),
      'wrong_password': Dialogue(
        npcText: '【藏鏡人】很高興你記得這個日期，但它並不是正確答案。',
        responses: [
          PlayerResponse(text: '我會再試試', action: () => onDialogueFinished()),
        ],
      ),
      'success': Dialogue(
        npcText: '【藏鏡人】你找到了正確的密碼！寶箱已經出現...',
        responses: [PlayerResponse(text: '謝謝你', nextDialogueId: 'final')],
      ),
    });

    // 設置初始對話ID
    currentDialogueId = 'start';

    // 初始化互動計時器
    _interactionTimer = Timer(0.05, onTick: _updatePulse, repeat: true);

    // 載入精靈圖
    final sprite = await Sprite.load('MirrorMan.png');

    // 創建精靈圖元件
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2(64, 64), // 設定精靈圖大小
      anchor: Anchor.center,
    );

    // 添加精靈圖
    add(_spriteComponent!);

    // 初始化閒置動畫計時器
    _idleAnimationTimer = Timer(
      0.1, // 每0.1秒更新一次
      onTick: _updateIdleAnimation,
      repeat: true,
    );
    _idleAnimationTimer!.start();
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

  /// 更新呼吸動畫
  void _updateIdleAnimation() {
    if (_spriteComponent == null) return;

    // 使用正弦波來創造呼吸效果
    final breathCycle = sin(_animationTime * _breathFrequency);

    // 垂直方向的呼吸效果
    final verticalBreath = breathCycle * _breathAmplitude;

    // 水平方向的呼吸效果(較微弱)
    final horizontalBreath = breathCycle * (_breathAmplitude * 0.2);

    // 呼吸時的輕微上移效果
    final verticalOffset = verticalBreath * 2;

    // 設置縮放效果
    _spriteComponent!.scale = Vector2(
      1.0 + horizontalBreath,
      1.0 + verticalBreath,
    );

    // 設置輕微的上下移動
    _spriteComponent!.position = Vector2(0, -verticalOffset);

    // 添加輕微晃動，增加鏡像感
    _spriteComponent!.angle = breathCycle * 0.015;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新互動計時器
    _interactionTimer.update(dt);

    // 更新閒置動畫計時器
    _idleAnimationTimer?.update(dt);

    // 更新動畫時間
    _animationTime += dt;
  }

  @override
  void render(Canvas canvas) {
    // 繪製鏡像效果光暈
    _renderGlowEffect(canvas);

    // 呼叫父類的render方法(包括對話氣泡和互動提示)
    super.render(canvas);
  }

  /// 繪製光暈效果
  void _renderGlowEffect(Canvas canvas) {
    // 繪製半透明鏡像效果的外圈
    final glowPaint =
        Paint()
          ..color = color.withOpacity(0.2 + _pulseValue * 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 8 + _pulseValue * 4,
      glowPaint,
    );
  }

  // 自定義方法：處理對話完成後的操作
  void onDialogueFinished() {
    // 對話結束後打開鏡像密碼鎖界面
    if (game is NightAndRainGame) {
      (game as NightAndRainGame).overlays.add('MirrorPasswordOverlay');
    }
  }

  // 處理正確密碼輸入後的操作
  void onCorrectPasswordEntered() {
    // 設置對話ID為成功
    currentDialogueId = 'success';

    // 在玩家附近生成寶箱
    if (game is NightAndRainGame) {
      final gameRef = game as NightAndRainGame;
      final player = gameRef.getPlayer();

      // 在玩家前方生成寶箱
      final treasurePosition = player.position + Vector2(0, 60);

      // 創建並添加寶箱到遊戲世界
      final treasureChest = TreasureChestComponent(
        position: treasurePosition,
        name: '鏡像寶箱',
        password: '0120',
      );

      gameRef.gameWorld.add(treasureChest);
    }
  }

  // 處理不正確但特殊的密碼輸入
  void onSpecialPasswordEntered() {
    // 設置對話ID為特殊錯誤提示
    currentDialogueId = 'wrong_password';
  }
}
