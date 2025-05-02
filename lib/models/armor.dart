import 'package:flutter/material.dart';
import 'package:night_and_rain_v2/enum/item_rarity.dart';

import 'package:night_and_rain_v2/models/weapon.dart';

import '../enum/item_type.dart';
import 'item.dart';
import 'player.dart';

class Armor extends Item {
  final int defense;

  Armor({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price,
    required this.defense,
    super.quantity,
  }) : super(type: ItemType.material); // 暫時使用material類型，後續可增加專用類型

  @override
  void use(Player player) {
    player.equipArmor(this);
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
