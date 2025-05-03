import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'shopkeeper_npc.dart';

/// 米蟲商店員 - 販賣多種物品的商店NPC
class ShopkeeperBug extends ShopkeeperNpc {
  static const List<String> _bugConversations = [
    '我的商店有最新鮮的商品！',
    '這把武器是我從龍窟帶回來的，絕對值這個價！',
    '別看我這樣，我可是很有眼光的收藏家。',
    '這些藥水都是用最純淨的材料釀造的，效果保證！',
    '如果你能找到更好的商品，我雙倍退款！',
    '不要猶豫了，這可是限量版！',
  ];

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
    double discountRate = 1.0, // 預設無折扣
  }) : super(
         name: '米蟲商人',
         color: Colors.orange,
         shopItems: _bugShopItems,
         shopName: '米蟲精品商店',
         discountRate: discountRate,
         greetings: const [
           '嘿，冒險者！過來看看我的商品吧！',
           '今天有特價喔，只對你！',
           '需要補給品嗎？我這裡應有盡有！',
         ],
         conversations: _bugConversations,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 隨機決定是否有特別折扣
    _hasSpecialDiscount = (DateTime.now().day % 3 == 0);

    // 添加商店員視覺效果
    add(RectangleComponent(size: size, paint: Paint()..color = color));

    // 添加文字標籤
    final textComponent = TextComponent(
      text: '商店',
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      anchor: Anchor.center,
      position: Vector2(size.x / 2, -10),
    );
    add(textComponent);
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
