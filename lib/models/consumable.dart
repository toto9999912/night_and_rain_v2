import 'package:flutter/material.dart';
import 'package:night_and_rain_v2/enum/item_rarity.dart';
import 'package:night_and_rain_v2/models/weapon.dart';
import '../enum/item_type.dart';
import 'item.dart';
import 'player.dart';

/// 不可變的消耗品類別
class Consumable extends Item {
  final int healthRestore;
  final int manaRestore;
  // 如果需要效果系統，可以使用以下註釋行
  // final List<PlayerEffect> effects;

  const Consumable({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price,
    this.healthRestore = 0,
    this.manaRestore = 0,
    super.quantity,
    // this.effects = const [],
  }) : super(type: ItemType.consumable, weaponItem: null);

  @override
  void applyEffects(Player player) {
    // 不再直接修改 player 狀態，只描述效果
    // 返回應用效果的描述，由 Provider 負責實際執行狀態變更
  }

  @override
  String getDescription() {
    String desc = '${super.getDescription()}\n';

    if (healthRestore > 0) {
      desc += '恢復生命值: +$healthRestore\n';
    }

    if (manaRestore > 0) {
      desc += '恢復魔力值: +$manaRestore\n';
    }

    return desc;
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
    int? healthRestore,
    int? manaRestore,
  }) {
    return Consumable(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      icon: icon ?? this.icon,
      price: price ?? this.price,
      healthRestore: healthRestore ?? this.healthRestore,
      manaRestore: manaRestore ?? this.manaRestore,
      quantity: quantity ?? this.quantity,
    );
  }
}
