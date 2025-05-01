import 'package:flame/components.dart';

import '../enum/weapon_type.dart';
import 'player.dart';
import 'weapon.dart';

class MeleeWeapon extends Weapon {
  final double swingAngle;

  MeleeWeapon({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.damage,
    required super.attackSpeed,
    required super.range,
    required super.cooldown,
    required this.swingAngle,
    required super.price,
  }) : super(weaponType: WeaponType.sword);

  @override
  bool attack(Vector2 direction, Player player) {
    return true;
    // 實現近戰武器的攻擊邏輯
  }
}
