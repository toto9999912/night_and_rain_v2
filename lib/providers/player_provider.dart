import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/components.dart';

import '../enum/weapon_type.dart';
import '../models/armor.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../models/weapon.dart';
import 'inventory_provider.dart';
import 'player_buffs_provider.dart';

// 基本 Player Provider
final playerProvider = StateNotifierProvider<PlayerNotifier, Player>((ref) {
  return PlayerNotifier(ref);
});

// 結合加成效果的玩家速度Provider
final playerSpeedProvider = Provider<double>((ref) {
  final player = ref.watch(playerProvider);
  final buffs = ref.watch(playerBuffsProvider);

  // 基礎速度加上所有未過期的速度加成
  return player.speed + buffs.speedBuffValue;
});

// 結合加成效果的玩家最大生命值Provider
final playerMaxHealthProvider = Provider<int>((ref) {
  final player = ref.watch(playerProvider);
  final buffs = ref.watch(playerBuffsProvider);

  // 基礎最大生命值加上所有未過期的最大生命值加成
  return player.maxHealth + buffs.maxHealthBuffValue.toInt();
});

// 當前玩家生命值Provider - 確保界面一致獲取相同的生命值
final playerHealthProvider = Provider<(int current, int max)>((ref) {
  final player = ref.watch(playerProvider);
  final maxHealth = ref.watch(playerMaxHealthProvider);

  return (player.health, maxHealth);
});

// 便於 UI 直接訪問當前武器的 Provider
final currentWeaponProvider = Provider<Weapon?>((ref) {
  final player = ref.watch(playerProvider);
  return player.equippedWeapon;
});

/// 統一管理 Player 狀態的 Notifier
/// 所有狀態更新都經過這個類別處理，不再直接修改 Player 對象
class PlayerNotifier extends StateNotifier<Player> {
  final Ref _ref;

  PlayerNotifier(this._ref) : super(Player());

  // 生命值相關方法
  void heal(int amount) {
    debugPrint('開始治療: 嘗試恢復 $amount 點生命值');
    try {
      // 獲取包含加成效果的最大生命值
      // 這裡直接使用 state.maxHealth 而不是 playerMaxHealthProvider
      // 避免產生循環依賴
      final maxHealthBase = state.maxHealth;
      final buffs = _ref.read(playerBuffsProvider);
      final maxHealthWithBuff =
          maxHealthBase + buffs.maxHealthBuffValue.toInt();

      debugPrint('基礎最大生命值: $maxHealthBase, 加成後最大生命值: $maxHealthWithBuff');

      // 計算新的生命值，使用帶加成的最大生命值作為上限
      final newHealth =
          state.health + amount > maxHealthWithBuff
              ? maxHealthWithBuff
              : state.health + amount;

      debugPrint('當前生命值: ${state.health}, 恢復後生命值: $newHealth');

      // 更新玩家狀態
      state = state.copyWith(health: newHealth);
    } catch (e) {
      debugPrint('治療過程中出錯: $e');
    }
  }

  void takeDamage(int amount) {
    state = state.withDamageTaken(amount);
  }

  void setHealth(int value) {
    state = state.copyWith(health: value);
  }

  // 魔力相關方法
  void addMana(int amount) {
    state = state.withAddedMana(amount);
  }

  bool consumeMana(int amount) {
    final (newState, success) = state.withManaConsumed(amount);
    if (success) {
      state = newState;
    }
    return success;
  }

  void setMana(int value) {
    state = state.copyWith(mana: value);
  }

  // 武器相關方法
  void equipWeapon(Weapon weapon) {
    // 確保武器在背包中
    final inventoryNotifier = _ref.read(inventoryProvider.notifier);
    if (!inventoryNotifier.hasItem(weapon.id)) {
      inventoryNotifier.addItem(weapon);
    }

    // 裝備武器
    state = state.withEquippedWeapon(weapon);
  }

  void unequipWeapon() {
    state = state.withoutWeapon();
  }

  bool attack(Vector2 direction) {
    // 檢查是否可以攻擊
    if (!state.canAttack()) return false;

    final weapon = state.equippedWeapon!;

    // 消耗魔力
    if (weapon.manaCost > 0) {
      final (newState, success) = state.withManaConsumed(weapon.manaCost);
      if (!success) return false;
      state = newState;
    }

    // 執行武器攻擊邏輯 - 使用重構後的 performAttack 方法
    return weapon.performAttack(direction);
  }

  void switchToNextWeapon() {
    final weapons = _ref.read(inventoryProvider).getWeapons();
    if (weapons.isEmpty) return;

    // 找到當前武器的索引
    int currentIndex = -1;
    if (state.equippedWeapon != null) {
      currentIndex = weapons.indexWhere(
        (w) => w.id == state.equippedWeapon!.id,
      );
    }

    // 切換到下一個武器
    int nextIndex = (currentIndex + 1) % weapons.length;
    equipWeapon(weapons[nextIndex]);
  }

  void switchToPreviousWeapon() {
    final weapons = _ref.read(inventoryProvider).getWeapons();
    if (weapons.isEmpty) return;

    // 找到當前武器的索引
    int currentIndex = -1;
    if (state.equippedWeapon != null) {
      currentIndex = weapons.indexWhere(
        (w) => w.id == state.equippedWeapon!.id,
      );
    }

    // 切換到上一個武器
    int prevIndex = currentIndex <= 0 ? weapons.length - 1 : currentIndex - 1;
    equipWeapon(weapons[prevIndex]);
  }

  // 裝備指定武器類型的最佳武器（根據傷害值）
  void equipBestWeaponOfType(WeaponType type) {
    _ref.read(inventoryProvider.notifier).equipBestWeaponOfType(type);
  }

  // 護甲相關方法
  void equipArmor(Armor armor) {
    // 確保護甲在背包中
    final inventoryNotifier = _ref.read(inventoryProvider.notifier);
    if (!inventoryNotifier.hasItem(armor.id)) {
      inventoryNotifier.addItem(armor);
    }

    // 裝備護甲
    state = state.withEquippedArmor(armor);
  }

  // 物品相關方法 - 現在僅是代理到 InventoryProvider
  void useItem(Item item) {
    _ref.read(inventoryProvider.notifier).useItem(item);
  }

  // 金錢相關方法
  void addMoney(int amount) {
    state = state.withAddedMoney(amount);
  }

  bool spendMoney(int amount) {
    final (newState, success) = state.withMoneySpent(amount);
    if (success) {
      state = newState;
    }
    return success;
  }

  // 使用熱鍵綁定的物品
  void useHotkeyItem(int slot) {
    _ref.read(inventoryProvider.notifier).useHotkeyItem(slot);
  }
}
