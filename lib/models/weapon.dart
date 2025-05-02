import 'package:flame/components.dart';

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
    double? range,
    double? cooldown,
  }) : // 如果沒提供冷卻時間，則使用武器類型的預設值
       cooldown = cooldown ?? weaponType.defaultCooldown,
       // 如果沒提供範圍，則根據武器類型設定預設範圍
       range = range ?? (weaponType.isMelee ? 50 : 800),
       super(type: ItemType.weapon);

  @override
  void use(Player player) {
    player.equipWeapon(this);
  }

  // 更新攻擊方法簽名以匹配RangedWeapon
  bool attack(Vector2 direction, Player player) {
    // 近戰武器的攻擊邏輯
    if (weaponType == WeaponType.sword) {
      // 近戰武器不消耗魔力，直接攻擊
      _performAttack(direction);
      return true;
    } else {
      // 對於遠程武器，此方法會在子類中被覆蓋
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
  String getStats() {
    return '傷害: ${damage.toStringAsFixed(1)}\n'
        '攻速: ${attackSpeed.toStringAsFixed(1)}\n'
        '範圍: ${range.toStringAsFixed(1)}\n'
        '冷卻: ${cooldown.toStringAsFixed(1)}秒';
  }
}
