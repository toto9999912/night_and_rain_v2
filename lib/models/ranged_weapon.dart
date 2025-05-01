import 'player.dart';
import 'weapon.dart';
import 'package:flame/components.dart';

import '../enum/weapon_type.dart';

class RangedWeapon extends Weapon {
  final int maxAmmo;
  final int currentAmmo;
  final double reloadTime;
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
    required super.cooldown,
    required this.maxAmmo,
    this.currentAmmo = 0,
    required this.reloadTime,
    this.hasAutoFire = false,
    required this.manaCost, // 每次射擊消耗的魔力值
  }) : assert(weaponType != WeaponType.sword);

  @override
  bool attack(Vector2 direction, Player player) {
    // 檢查魔力是否足夠
    if (player.mana >= manaCost) {
      // 實現遠程武器的攻擊邏輯
      player.mana -= manaCost; // 消耗魔力
      return true; // 攻擊成功
    } else {
      // 魔力不足，無法發射
      return false; // 攻擊失敗
    }
  }

  void reload() {
    // 實現彈藥重裝邏輯
  }
}
