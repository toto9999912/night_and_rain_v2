import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/components.dart';

import '../enum/weapon_type.dart';
import '../models/armor.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../models/weapon.dart';
import 'inventory_provider.dart';

// 基本 Player Provider
final playerProvider = StateNotifierProvider<PlayerNotifier, Player>((ref) {
  return PlayerNotifier(ref);
});

// 便於 UI 直接訪問當前武器的 Provider
final currentWeaponProvider = Provider<Weapon?>((ref) {
  final player = ref.watch(playerProvider);
  return player.equippedWeapon;
});

class PlayerNotifier extends StateNotifier<Player> {
  final Ref _ref;

  PlayerNotifier(this._ref) : super(Player());

  // 生命值相關方法
  void heal(int amount) {
    state.heal(amount);
    updateState();
  }

  void takeDamage(int amount) {
    state.takeDamage(amount);
    updateState();
  }

  void setHealth(int value) {
    state = state.copyWith(health: value);
  }

  // 魔力相關方法
  void addMana(int amount) {
    state.addMana(amount);
    updateState();
  }

  bool consumeMana(int amount) {
    final result = state.consumeMana(amount);
    if (result) {
      updateState();
    }
    return result;
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
    state.equipWeapon(weapon);
    updateState();
  }

  void unequipWeapon() {
    state.unequipWeapon();
    updateState();
  }

  bool attack(Vector2 direction) {
    final result = state.attack(direction);

    // 使用 Future 延遲更新 UI，避免在渲染過程中修改狀態
    if (result) {
      Future(() {
        updateState(); // 魔力可能變化，更新 UI
      });
    }

    return result;
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
    state.equipArmor(armor);
    updateState();
  }

  // 物品相關方法 - 現在僅是代理到 InventoryProvider
  void useItem(Item item) {
    _ref.read(inventoryProvider.notifier).useItem(item);
  }

  // 金錢相關方法
  void addMoney(int amount) {
    state.addMoney(amount);
    updateState();
  }

  bool spendMoney(int amount) {
    final result = state.spendMoney(amount);
    if (result) {
      updateState();
    }
    return result;
  }

  // 使用熱鍵綁定的物品
  void useHotkeyItem(int slot) {
    _ref.read(inventoryProvider.notifier).useHotkeyItem(slot);
  }

  // 用於強制更新狀態以觸發UI重繪
  void updateState() {
    state = state.copyWith();
  }
}
