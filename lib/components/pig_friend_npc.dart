// sage_roy_npc.dart - 智者羅伊NPC，展示新的對話系統功能
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'npc_component.dart';

/// 智者羅伊 - 一位擁有豐富知識的老者，可以與玩家進行深入對話
class PigFriendNpc extends NpcComponent {
  // 儲存精靈圖元件
  SpriteComponent? _spriteComponent;

  // 閒置動畫計時器
  Timer? _idleAnimationTimer;

  // 用於呼吸效果的振幅和頻率
  final double _breathAmplitude = 0.05;
  final double _breathFrequency = 1.5;

  // 記錄動畫時間
  double _animationTime = 0;

  PigFriendNpc({required super.position, Vector2? size})
    : super(
        name: '豬比',
        size: size ?? Vector2(64, 64), // 稍微大一點的NPC
        color: Colors.transparent, // 使用透明色，因為我們會使用精靈圖
        supportConversation: true, // 支持對話
        interactionRadius: 80, // 將互動範圍從 120 縮小到 80
        greetings: [
          '小非雨！！生日快樂！！',
          '因為夥伴功能還沒實踐ＱＱ，所以我還幫不上忙',
          '你是說蘋果怪客嗎？好像往地下城過去囉！',
        ],
      );
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 載入精靈圖
    final sprite = await Sprite.load('PigFriend.png');

    // 創建精靈圖元件
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2(72, 72), // 設定精靈圖大小
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

  @override
  void update(double dt) {
    super.update(dt);

    // 更新閒置動畫計時器
    _idleAnimationTimer?.update(dt);

    // 更新動畫時間
    _animationTime += dt;
  }

  void _updateIdleAnimation() {
    if (_spriteComponent == null) return;

    // 使用兩個不同頻率的正弦波來創造更自然的呼吸效果
    final breathCycle = sin(_animationTime * _breathFrequency);

    // 垂直方向的呼吸效果（較明顯）
    final verticalBreath = breathCycle * _breathAmplitude;

    // 水平方向的呼吸效果（較微弱）
    final horizontalBreath = breathCycle * (_breathAmplitude * 0.3);

    // 呼吸時的輕微上移效果（吸氣時身體微微上升）
    final verticalOffset = verticalBreath * 3;

    // 自然呼吸狀態
    // 非均勻縮放：垂直方向縮放大於水平方向
    _spriteComponent!.scale = Vector2(
      1.0 + horizontalBreath, // 水平方向輕微縮放
      1.0 + verticalBreath, // 垂直方向更明顯的縮放
    );

    // 添加輕微的上下移動
    _spriteComponent!.position = Vector2(0, -verticalOffset);

    // 呼吸時的輕微前傾/後仰（極其微小的角度）
    _spriteComponent!.angle = breathCycle * 0.01;
  }
}
