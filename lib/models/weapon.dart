import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../enum/item_rarity.dart';
import '../enum/item_type.dart';
import '../enum/weapon_type.dart';
import 'item.dart';
import 'player.dart';

/// 不可變的武器類別
class Weapon extends Item {
  final WeaponType weaponType;
  final double damage;
  final double attackSpeed;
  final double range;
  final double cooldown;
  final int manaCost; // 使用武器所需魔力值

  Weapon({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price,
    required this.weaponType,
    required this.damage,
    required this.attackSpeed,
    this.manaCost = 0,
    double? range,
    double? cooldown,
    super.quantity,
  }) : // 如果沒提供冷卻時間，則使用武器類型的預設值
       cooldown = cooldown ?? weaponType.defaultCooldown,
       // 如果沒提供範圍，則根據武器類型設定預設範圍
       range = range ?? (weaponType.isMelee ? 50 : 800),
       super(
         type: ItemType.weapon,
         weaponItem: null, // 武器類本身不需要關聯武器屬性
       );

  @override
  void applyEffects(Player player) {
    // 不再直接修改 player 狀態，只描述效果
    // 該邏輯會由 Notifier 調用並處理
  }

  /// 檢查是否可以攻擊
  bool canAttackWith(Player player) {
    return player.mana >= manaCost;
  }

  /// 玩家使用此武器的攻擊邏輯 - 不直接修改玩家狀態
  /// 由 PlayerNotifier 負責協調狀態更新
  bool performAttack(Vector2 direction) {
    // 根據不同武器類型實現不同的攻擊邏輯
    switch (weaponType) {
      case WeaponType.sword:
        // 劍的攻擊邏輯
        break;
      case WeaponType.pistol:
        // 手槍邏輯
        break;
      case WeaponType.machineGun:
        // 機關槍邏輯
        break;
      case WeaponType.shotgun:
        // 霰彈槍邏輯
        break;
      case WeaponType.sniper:
        // 狙擊槍邏輯
        break;
    }
    return true;
  }

  // 獲取武器描述
  String getStats() {
    String stats =
        '傷害: ${damage.toStringAsFixed(1)}\n'
        '攻速: ${attackSpeed.toStringAsFixed(1)}\n'
        '範圍: ${range.toStringAsFixed(1)}\n'
        '冷卻: ${cooldown.toStringAsFixed(1)}秒';

    if (manaCost > 0) {
      stats += '\n魔力消耗: $manaCost';
    }

    return stats;
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
    WeaponType? weaponType,
    double? damage,
    double? attackSpeed,
    double? range,
    double? cooldown,
    int? manaCost,
  }) {
    return Weapon(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      icon: icon ?? this.icon,
      price: price ?? this.price,
      weaponType: weaponType ?? this.weaponType,
      damage: damage ?? this.damage,
      attackSpeed: attackSpeed ?? this.attackSpeed,
      range: range ?? this.range,
      cooldown: cooldown ?? this.cooldown,
      manaCost: manaCost ?? this.manaCost,
      quantity: quantity ?? this.quantity,
    );
  }
}
