import 'package:flutter/material.dart';

import '../enum/item_type.dart';
import 'weapon.dart';
import 'package:flame/components.dart';

import '../enum/weapon_type.dart';
import '../enum/item_rarity.dart';

/// 不可變的遠程武器類別，繼承自 Weapon
class RangedWeapon extends Weapon {
  final bool hasAutoFire;

  RangedWeapon({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price,
    required super.weaponType,
    required super.damage,
    required super.range,
    super.cooldown,
    required super.manaCost,
    this.hasAutoFire = false,
    super.quantity,
  }) : assert(weaponType != WeaponType.sword);

  @override
  bool performAttack(Vector2 direction) {
    // 遠程武器的攻擊邏輯，不再直接修改 Player 狀態
    // 魔力消耗已經由 PlayerNotifier 處理

    // 返回攻擊成功，子彈會在 PlayerComponent 中生成
    return true;
  }

  // 獲取子彈參數（可供擴展）
  Map<String, dynamic> getBulletParameters() {
    return {
      'damage': damage,
      'range': range,
      'speed': weaponType.defaultBulletSpeed, // 使用武器類型的預設子彈速度
      'color': rarity.color, // 統一所有遠程武器的子彈顏色
      'rarity': rarity, // 傳遞武器稀有度
      'size': _getBulletSizeByRarity(), // 根據稀有度調整子彈大小
      'weaponType': weaponType, // 傳遞武器類型，以便特殊處理
      'trailEffect': _getTrailEffectByRarity(), // 根據稀有度設置尾隨效果
    };
  }

  // 根據稀有度獲取子彈大小
  double _getBulletSizeByRarity() {
    switch (weaponType) {
      case WeaponType.pistol:
        return 10.0;
      case WeaponType.machineGun:
        return 8.0;
      case WeaponType.shotgun:
        return 8.0;
      case WeaponType.sniper:
        return 12.0;
      default:
        return 5.0; // 預設大小
    }
  }

  // 根據稀有度獲取適當的尾隨效果
  String _getTrailEffectByRarity() {
    switch (rarity) {
      case ItemRarity.riceBug:
        return 'none';
      case ItemRarity.copperBull:
        return 'simple';
      case ItemRarity.silverBull:
        return 'shine';
      case ItemRarity.goldBull:
        return 'particles';
    }
  }

  @override
  RangedWeapon copyWith({
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
    bool? hasAutoFire,
  }) {
    return RangedWeapon(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      icon: icon ?? this.icon,
      price: price ?? this.price,
      weaponType: weaponType ?? this.weaponType,
      damage: damage ?? this.damage,

      range: range ?? this.range,
      cooldown: cooldown ?? this.cooldown,
      manaCost: manaCost ?? this.manaCost,
      hasAutoFire: hasAutoFire ?? this.hasAutoFire,
      quantity: quantity ?? this.quantity,
    );
  }
}
