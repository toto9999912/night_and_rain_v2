import 'package:flutter/material.dart';

import '../enum/item_rarity.dart';
import '../enum/item_type.dart';
import 'player.dart';
import 'weapon.dart';

/// 基礎物品類別 - 設計為不可變的模型
abstract class Item {
  final String id;
  final String name;
  final String description;
  final ItemType type;
  final ItemRarity rarity;
  final IconData icon;
  final int price; // 物品價格
  final Weapon? weaponItem; // 物品數量
  final int quantity; // 物品數量

  const Item({
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

  /// 不再直接修改 Player 狀態，而是提供一個方法描述如何使用此物品
  /// 由 Provider 負責處理實際的狀態變更
  void applyEffects(Player player);

  /// 獲取物品描述
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

  /// 獲取物品類型名稱
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

  /// 檢查物品是否可堆疊
  bool get isStackable =>
      type == ItemType.consumable || type == ItemType.material;

  /// 增加物品數量 - 返回新的物品實例
  Item withQuantity(int newQuantity) {
    return copyWith(quantity: newQuantity);
  }

  /// 複製物品但可以修改部分屬性的方法
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
