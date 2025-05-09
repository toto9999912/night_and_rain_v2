import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'shopkeeper_npc.dart';

/// 米蟲奸商 - 販賣稀有但昂貴的物品(原價五倍)的商店NPC
class GreedyShopkeeperBug extends ShopkeeperNpc {
  // 儲存精靈圖元件
  SpriteComponent? _spriteComponent;

  // 閒置動畫計時器
  Timer? _idleAnimationTimer;

  // 用於呼吸效果的振幅和頻率
  final double _breathAmplitude = 0.05; // 比一般米蟲更誇張的呼吸
  final double _breathFrequency = 1.5; // 呼吸頻率更快

  // 記錄動畫時間
  double _animationTime = 0;

  // 米蟲奸商的對話內容
  static const List<String> _greedyBugConversations = [
    '我只招待有錢人哦',
    '我只賣給識貨的人，價格嘛...當然不便宜',
    '笑你買不起我店裡最高級的武器',
    '你付的不是價格，而是價值，懂嗎？',
    '想殺價？不存在的，要買就快點',
    '我這裡的東西，可是有錢也不一定買得到的',
  ];

  // 米蟲奸商的稀有商品列表
  static const List<String> _greedyBugShopItems = [
    // 稀有武器
    'pistol_gold', 'pistol_dragon',
    'shotgun_silver', 'shotgun_dragon',
    'machinegun_silver', 'machinegun_gold',
    'sniper_silver', 'sniper_gold',

    // 稀有消耗品
    'health_potion_legendary', 'mana_potion_legendary',
    'speed_potion_premium', 'invisibility_potion',
    'strength_potion', 'resistance_potion',
  ];

  // 價格倍數 - 比原價貴五倍
  static const double _priceMultiplier = 5.0;

  GreedyShopkeeperBug({required super.position})
    : super(
        name: '米蟲奸商',
        size: Vector2(64, 64),
        color: Colors.transparent, // 改為透明色，因為我們會使用精靈圖
        shopItems: _greedyBugShopItems,
        shopName: '米蟲稀品商店',
        greetings: _greedyBugConversations,
        // 將折扣率設為5.0，表示價格為原價的5倍
        discountRate: _priceMultiplier,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 載入精靈圖 - 使用GreedyShopkeeperBug.png
    final sprite = await Sprite.load('GreedyShopkeeperBug.png');

    // 創建精靈圖元件
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2(72, 72), // 設置精靈圖大小
      anchor: Anchor.center,
    );

    // 添加精靈圖
    add(_spriteComponent!);

    // 初始化閒置動畫計時器
    _idleAnimationTimer = Timer(
      0.08, // 每0.08秒更新一次，比普通米蟲更快
      onTick: _updateIdleAnimation,
      repeat: true,
    );
    _idleAnimationTimer!.start();
    // 添加文字標籤
    final textComponent = TextComponent(
      text: '商店',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: 'Cubic11', // 使用Cubic11字體
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(0, -size.y / 2 - 36),
    );
    add(textComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新閒置動畫計時器
    _idleAnimationTimer?.update(dt);

    // 更新動畫時間
    _animationTime += dt;
  }

  // 更新呼吸動畫 - 比普通米蟲更誇張
  void _updateIdleAnimation() {
    if (_spriteComponent == null) return;

    // 使用正弦波創造誇張的呼吸效果
    final breathCycle = sin(_animationTime * _breathFrequency);

    // 垂直方向的呼吸效果
    final verticalBreath = breathCycle * _breathAmplitude;

    // 呼吸時的輕微上移效果
    final verticalOffset = verticalBreath * 5; // 更大的移動幅度

    // 添加輕微的水平搖晃
    final horizontalWobble = sin(_animationTime * 3) * 1.5;

    // 應用搖晃和縮放效果
    _spriteComponent!.scale = Vector2(
      1.0 + verticalBreath * 0.5, // 水平方向輕微縮放
      1.0 + verticalBreath, // 垂直方向較大縮放
    );

    // 添加輕微的上下移動和左右搖晃
    _spriteComponent!.position = Vector2(horizontalWobble, -verticalOffset);
  }

  // 覆蓋父類的折扣率方法，確保物品價格為原價的五倍
  @override
  double get discountRate {
    return _priceMultiplier; // 返回5.0，即原價的五倍
  }
}
