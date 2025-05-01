import 'package:flutter/material.dart';

import '../enum/item_rarity.dart';
import '../enum/item_type.dart';
import 'player.dart';

abstract class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final ItemRarity rarity;
  final IconData icon;
  final int price; // 物品價格

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.icon,
    required this.price,
  });

  // 使用物品的抽象方法
  void use(Player player);

  // 獲取物品描述
  String getDescription() {
    return '$description\n'
        '類型: ${_getItemTypeName()}\n'
        '稀有度: ${rarity.name}\n'
        '價格: $price';
  }

  // 獲取物品類型名稱
  String _getItemTypeName() {
    switch (type) {
      case ItemType.weapon:
        return '武器';
      case ItemType.consumable:
        return '消耗品';
      case ItemType.quest:
        return '任務道具';
      case ItemType.material:
        return '材料';
    }
  }
}
