import 'package:flutter/material.dart';

import '../enum/item_rarity.dart';
import '../enum/item_type.dart';
import 'player.dart';
import 'weapon.dart';

abstract class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final ItemRarity rarity;
  final IconData icon;
  final int price; // 物品價格
  final Weapon? weaponItem; // 武器物品關聯
  final int quantity; // 新增：物品數量

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rarity,
    required this.icon,
    required this.price,
    this.weaponItem,
    this.quantity = 1, // 預設數量為1
  });

  // 使用物品的抽象方法
  void use(Player player);

  // 獲取物品描述
  String getDescription() {
    String desc =
        '$description\n'
        '類型: ${_getItemTypeName()}\n'
        '稀有度: ${rarity.name}\n'
        '價格: $price';

    // 如果是武器物品，添加武器屬性
    if (weaponItem != null) {
      desc += '\n\n${weaponItem!.getStats()}';
    }

    return desc;
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

  // 檢查物品是否可堆疊
  bool get isStackable =>
      type == ItemType.consumable || type == ItemType.material;

  // 複製物品但可以修改部分屬性的方法
  Item copyWith({
    String? id,
    String? name,
    String? description,
    ItemType? type,
    ItemRarity? rarity,
    IconData? icon,
    int? price,
    Weapon? weaponItem,
    int? quantity,
  });
}
