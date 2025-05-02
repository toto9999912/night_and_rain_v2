import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/components.dart';

import '../models/armor.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../models/weapon.dart';

// 基本 Player Provider
final playerProvider = StateNotifierProvider<PlayerNotifier, Player>((ref) {
  return PlayerNotifier();
});

// 便於 UI 直接訪問當前武器的 Provider
final currentWeaponProvider = Provider<Weapon?>((ref) {
  final player = ref.watch(playerProvider);
  return player.equippedWeapon;
});

class PlayerNotifier extends StateNotifier<Player> {
  PlayerNotifier() : super(Player());

  // 生命值相關方法
  void heal(int amount) {
    state.heal(amount);
    state = state.copyWith(); // 觸發 UI 更新
  }

  void takeDamage(int amount) {
    state.takeDamage(amount);
    state = state.copyWith();
  }

  void setHealth(int value) {
    state = state.copyWith(health: value);
  }

  // 魔力相關方法
  void addMana(int amount) {
    state.addMana(amount);
    state = state.copyWith();
  }

  bool consumeMana(int amount) {
    final result = state.consumeMana(amount);
    if (result) {
      state = state.copyWith();
    }
    return result;
  }

  void setMana(int value) {
    state = state.copyWith(mana: value);
  }

  // 武器相關方法
  void equipWeapon(Weapon weapon) {
    state.equipWeapon(weapon);
    state = state.copyWith();
  }

  bool attack(Vector2 direction) {
    final result = state.attack(direction);

    // 使用 Future 延遲更新 UI，避免在渲染過程中修改狀態
    if (result) {
      Future(() {
        state = state.copyWith(); // 魔力可能變化，更新 UI
      });
    }

    return result;
  }

  void switchToNextWeapon() {
    state.switchToNextWeapon();
    state = state.copyWith();
  }

  // 護甲相關方法
  void equipArmor(Armor armor) {
    state.equipArmor(armor);
    state = state.copyWith();
  }

  // 物品相關方法
  void useItem(Item item) {
    state.useItem(item);
    state = state.copyWith();
  }

  // 金錢相關方法
  void addMoney(int amount) {
    state.addMoney(amount);
    state = state.copyWith();
  }

  bool spendMoney(int amount) {
    final result = state.spendMoney(amount);
    if (result) {
      state = state.copyWith();
    }
    return result;
  }

  // 背包相關方法
  bool addItemToInventory(Item item) {
    final result = state.inventory.addItem(item);
    if (result) {
      state = state.copyWith();
    }
    return result;
  }

  bool removeItemFromInventory(Item item) {
    final result = state.inventory.removeItem(item);
    if (result) {
      state = state.copyWith();
    }
    return result;
  }

  // 熱鍵相關方法
  void bindHotkey(int slot, Item item) {
    state.inventory.bindHotkey(slot, item);
    state = state.copyWith();
  }

  void unbindHotkey(int slot) {
    state.inventory.unbindHotkey(slot);
    state = state.copyWith();
  }

  void useHotkeyItem(int slot) {
    final item = state.inventory.hotkeyBindings[slot];
    if (item != null) {
      state.useItem(item);
      state = state.copyWith();
    }
  }
}
