import 'package:flame/components.dart';
import '../enum/weapon_type.dart';
import '../models/player.dart';

import '../models/weapon.dart';

class WeaponManager {
  final Player player;
  final List<Weapon> availableWeapons;
  Weapon? currentWeapon;

  // 武器切換冷卻
  double switchCooldown = 0;
  final double maxSwitchCooldown = 0.5; // 武器切換冷卻時間（秒）

  WeaponManager({
    required this.player,
    this.availableWeapons = const [],
    this.currentWeapon,
  });

  void switchWeapon(Weapon weapon) {
    // 檢查是否在冷卻中
    if (switchCooldown <= 0) {
      currentWeapon = weapon;
      switchCooldown = maxSwitchCooldown;

      // 更新玩家裝備的武器
      player.equipWeapon(weapon);
    }
  }

  bool attack(Vector2 direction) {
    if (currentWeapon == null) return false;

    // 執行攻擊
    return currentWeapon!.attack(direction, player);
  }

  // 更新武器管理器狀態
  void update(double dt) {
    // 更新武器切換冷卻
    if (switchCooldown > 0) {
      switchCooldown -= dt;
    }

    // 其他可能的更新邏輯（如武器熱度、特殊效果等）
  }

  // 通過武器類型獲取武器
  Weapon? getWeaponByType(WeaponType type) {
    for (var weapon in availableWeapons) {
      if (weapon.weaponType == type) {
        return weapon;
      }
    }
    return null;
  }

  // 切換至下一個武器
  void switchToNextWeapon() {
    if (availableWeapons.isEmpty) return;

    // 找到當前武器在列表中的索引
    int currentIndex = -1;
    if (currentWeapon != null) {
      currentIndex = availableWeapons.indexWhere(
        (w) => w.id == currentWeapon!.id,
      );
    }

    // 切換到下一個武器
    int nextIndex = (currentIndex + 1) % availableWeapons.length;
    switchWeapon(availableWeapons[nextIndex]);
  }

  // 切換到特定索引的武器（用於快捷鍵1-5等）
  void switchToWeaponAt(int index) {
    if (index >= 0 && index < availableWeapons.length) {
      switchWeapon(availableWeapons[index]);
    }
  }
}
