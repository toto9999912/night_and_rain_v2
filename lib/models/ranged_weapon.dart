import 'package:flutter/material.dart';

import 'player.dart';
import 'weapon.dart';
import 'package:flame/components.dart';

import '../enum/weapon_type.dart';

class RangedWeapon extends Weapon {
  final bool hasAutoFire;
  final int manaCost; // 新增：魔力消耗

  RangedWeapon({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price, // 需要提供價格
    required super.weaponType,
    required super.damage,
    required super.attackSpeed,
    required super.range,
    super.cooldown,

    this.hasAutoFire = false,
    required this.manaCost, // 每次射擊消耗的魔力值
  }) : assert(weaponType != WeaponType.sword);

  @override
  bool attack(Vector2 direction, Player player) {
    // 檢查魔力是否足夠
    if (player.mana >= manaCost) {
      // 消耗魔力
      player.mana -= manaCost;

      // 返回攻擊成功，子彈會在 PlayerComponent 中生成
      return true;
    } else {
      // 魔力不足，無法發射
      return false;
    }
  }

  // 獲取子彈參數（可供擴展）
  Map<String, dynamic> getBulletParameters() {
    return {
      'damage': damage,
      'range': range,
      'speed': weaponType.defaultBulletSpeed, // 使用武器類型的預設子彈速度
      'color': _getBulletColorByType(),
    };
  }

  // 根據武器類型獲取子彈顏色
  Color _getBulletColorByType() {
    switch (weaponType.name) {
      case 'pistol':
        return Colors.yellow;
      case 'shotgun':
        return Colors.orange;
      case 'rifle':
        return Colors.blue;
      case 'machineGun':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  void reload() {
    // 實現彈藥重裝邏輯
  }
}
