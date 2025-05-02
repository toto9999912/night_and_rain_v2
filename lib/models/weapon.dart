import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../enum/item_rarity.dart';
import '../enum/item_type.dart';
import '../enum/weapon_type.dart';
import 'item.dart';
import 'player.dart';

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
  void use(Player player) {
    player.equipWeapon(this);
  }

  // 更新攻擊方法簽名以匹配RangedWeapon
  bool attack(Vector2 direction, Player player) {
    // 檢查玩家的魔力是否足夠使用武器
    if (player.mana < manaCost) {
      return false; // 魔力不足，無法攻擊
    }

    // 近戰武器的攻擊邏輯
    if (weaponType.isMelee) {
      // 近戰武器可能不消耗魔力，或消耗較少魔力
      if (manaCost > 0) {
        player.consumeMana(manaCost);
      }
      _performAttack(direction);
      return true;
    } else {
      // 遠程武器消耗魔力
      player.consumeMana(manaCost);
      _performAttack(direction);
      return true;
    }
  }

  // 內部方法，執行實際攻擊動作
  void _performAttack(Vector2 direction) {
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
  }

  // 獲取武器描述
  @override
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
