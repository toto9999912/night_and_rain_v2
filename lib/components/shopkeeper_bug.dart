import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'npc_component.dart'; // 添加這行以導入 Dialogue 和 PlayerResponse 類別
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

  // 米蟲商店的商品列表 - 更新了藥水ID
  static const List<String> _bugShopItems = [
    // 武器
    'shotgun_ricebug', 'machinegun_ricebug', 'sniper_ricebug',
    'pistol_ricebug',
    // 消耗品 - 更新了藥水ID
    'health_potion_basic',
    'mana_potion_basic',
    'health_potion_medium',
    'mana_potion_medium',
  ];

  // 特別行銷活動 - 折扣
  bool _hasSpecialDiscount = false;

  ShopkeeperBug({required super.position})
    : super(
        name: '米蟲商人',
        discountRate: DateTime.now().month == 5 ? 0.1 : 1.0,
        size: Vector2(64, 64),
        color: Colors.transparent, // 改為透明色，因為我們會使用精靈圖
        shopItems: _bugShopItems,
        shopName: '米蟲精品商店',
        greetings: const [
          '最近很多冒險者都搶著購買我們特製的「鼾聲甜睡露」！一口下去，體力直接滿格！要不要來一瓶？',
          '嘿，冒險者！我們的「午休精神水」正在熱賣中，一瓶抵得上睡三天的效果！你看起來需要一些！',
          '「懶骨頭精華」剛到貨！這可是軌日記抄寫員收集懶洋洋的精華的，富含「不想動」的能量！',
          '想要輕鬆打怪？我們的「躺平能量水」讓你不費吹灰之力就能恢復大部分魔力！超值特價中！',
          '千萬不要找米蟲奸商購買東西，哼哼！他們的價格可是貴得離譜！',
        ],
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 判斷是否為5月，若是則啟動特殊折扣
    final now = DateTime.now();
    _hasSpecialDiscount = (now.month == 5);

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
    // 如果是五月，提供超級優惠的0.1折
    if (_hasSpecialDiscount) {
      return 0.1; // 0.1折，超級優惠！
    }
    return super.discountRate; // 使用建構時設定的折扣率
  }
}
