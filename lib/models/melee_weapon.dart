import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../enum/item_rarity.dart';
import '../enum/item_type.dart';
import '../enum/weapon_type.dart';
import 'weapon.dart';

/// 不可變的近戰武器類別，繼承自 Weapon
class MeleeWeapon extends Weapon {
  final double swingAngle; // 揮舞角度，弧度制
  final bool canBlock; // 是否可以格擋

  MeleeWeapon({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price,
    required super.damage,
    this.swingAngle = 1.5, // 預設揮舞角度約85度
    this.canBlock = false,
    super.range,
    super.cooldown,
    super.quantity,
    super.manaCost,
  }) : super(weaponType: WeaponType.sword);

  @override
  bool performAttack(Vector2 direction) {
    // 近戰武器的攻擊邏輯，不再直接修改 Player 狀態
    // 魔力消耗已經由 PlayerNotifier 處理

    // 返回攻擊成功，攻擊效果會在 PlayerComponent 中處理
    return true;
  }

  // 獲取劍氣效果的參數
  Map<String, dynamic> getSlashParameters() {
    return {
      'damage': damage,
      'range': range,
      'swingAngle': swingAngle,
      'duration': 0.3, // 劍氣持續時間（秒）
    };
  }

  // 嘗試格擋
  bool tryBlock() {
    return canBlock;
  }

  @override
  MeleeWeapon copyWith({
    String? id,
    String? name,
    String? description,
    ItemType? type,
    ItemRarity? rarity,
    IconData? icon,
    int? price,
    Weapon? weaponItem,
    int? quantity,
    WeaponType? weaponType,
    double? damage,
    double? attackSpeed,
    double? range,
    double? cooldown,
    int? manaCost,
    double? swingAngle,
    bool? canBlock,
  }) {
    return MeleeWeapon(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      icon: icon ?? this.icon,
      price: price ?? this.price,
      damage: damage ?? this.damage,
      range: range ?? this.range,
      cooldown: cooldown ?? this.cooldown,
      manaCost: manaCost ?? this.manaCost,
      swingAngle: swingAngle ?? this.swingAngle,
      canBlock: canBlock ?? this.canBlock,
      quantity: quantity ?? this.quantity,
    );
  }
}
