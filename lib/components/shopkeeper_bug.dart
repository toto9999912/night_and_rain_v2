import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'shopkeeper_npc.dart';

/// 米蟲商店員 - 販賣多種物品的商店NPC
class ShopkeeperBug extends ShopkeeperNpc {
  // 儲存精靈圖元件
  SpriteComponent? _spriteComponent;

  // 閒置動畫計時器
  Timer? _idleAnimationTimer;

  // 用於呼吸效果的振幅和頻率
  final double _breathAmplitude = 0.03;
  final double _breathFrequency = 1.2;

  // 記錄動畫時間
  double _animationTime = 0;

  // static const List<String> _bugConversations = [
  //   '你要是買不起，就快滾',
  //   '',
  //   '笑你買不起我店裡最高級的武器',
  //   '這些藥水都是用最純淨的材料釀造的，效果保證！',
  //   '如果你能找到更好的商品，我雙倍退款！',
  //   '不要猶豫了，這可是限量版！',
  // ];

  // 米蟲商店的商品列表
  static const List<String> _bugShopItems = [
    // 武器
    'pistol_ricebug', 'pistol_copper', 'pistol_silver',
    'shotgun_ricebug', 'shotgun_copper',
    'machinegun_ricebug',
    'sniper_ricebug',

    // 消耗品
    'health_potion', 'health_potion_premium',
    'mana_potion', 'mana_potion_premium',
  ];

  // 特別行銷活動 - 折扣
  bool _hasSpecialDiscount = false;

  ShopkeeperBug({
    required super.position,
    super.discountRate, // 預設無折扣
  }) : super(
         name: '米蟲商人',
         size: Vector2(64, 64),
         color: Colors.transparent, // 改為透明色，因為我們會使用精靈圖
         shopItems: _bugShopItems,
         shopName: '米蟲精品商店',

         greetings: const [
           '嘿，冒險者！過來看看我的商品吧！',
           '聽說你要去地下城探險？我這裡有你需要的東西！',
           '這裡有最新的武器和藥水，保證讓你驚喜！',
         ],
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 隨機決定是否有特別折扣
    _hasSpecialDiscount = (DateTime.now().day % 3 == 0);

    // 載入精靈圖
    final sprite = await Sprite.load('ShopkeeperBug.png');

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

  // 更新呼吸動畫
  void _updateIdleAnimation() {
    if (_spriteComponent == null) return;

    // 使用正弦波創造簡單的呼吸效果
    final breathCycle = sin(_animationTime * _breathFrequency);

    // 垂直方向的呼吸效果
    final verticalBreath = breathCycle * _breathAmplitude;

    // 呼吸時的輕微上移效果
    final verticalOffset = verticalBreath * 3;

    // 應用簡單的上下移動和縮放效果
    _spriteComponent!.scale = Vector2(
      1.0, // 水平方向保持不變
      1.0 + verticalBreath, // 垂直方向輕微縮放
    );

    // 添加輕微的上下移動
    _spriteComponent!.position = Vector2(0, -verticalOffset);
  }

  // 覆蓋父類的折扣率方法，實現特別折扣
  @override
  double get discountRate {
    // 如果今天有特別折扣，提供8折
    if (_hasSpecialDiscount) {
      return 0.8; // 8折
    }
    return super.discountRate; // 使用建構時設定的折扣率
  }
}
