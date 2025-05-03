import 'package:flutter/material.dart';
import '../enum/item_rarity.dart';
import '../enum/item_type.dart';
import 'item.dart';
import 'player.dart';
import 'weapon.dart';

/// 不可變的護甲類別
class Armor extends Item {
  final int defense;

  const Armor({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price,
    required this.defense,
    super.quantity,
  }) : super(
         type: ItemType.material,
         weaponItem: null,
       ); // 暫時使用 material 類型，後續可增加專用類型

  @override
  void applyEffects(Player player) {
    // 不再直接修改 player 狀態，只描述效果
    // 該邏輯會由 InventoryNotifier 調用並處理
  }

  @override
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
    int? defense,
  }) {
    return Armor(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      icon: icon ?? this.icon,
      price: price ?? this.price,
      defense: defense ?? this.defense,
      quantity: quantity ?? this.quantity,
    );
  }
}
