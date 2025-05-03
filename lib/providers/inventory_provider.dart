// 使用 Riverpod 管理庫存
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enum/weapon_type.dart';
import '../models/armor.dart';
import '../models/consumable.dart';
import '../models/inventory.dart';
import '../models/item.dart';
import '../models/weapon.dart';
import 'player_provider.dart';

// 全局單例 InventoryNotifier
final inventoryProvider = StateNotifierProvider<InventoryNotifier, Inventory>((
  ref,
) {
  // 創建 InventoryNotifier 的實例
  return InventoryNotifier(ref);
});

// 便於 UI 直接訪問所有武器的 Provider
final weaponsProvider = Provider<List<Weapon>>((ref) {
  final inventory = ref.watch(inventoryProvider);
  return inventory.getWeapons();
});

/// 統一管理 Inventory 狀態的 Notifier
/// 所有背包狀態更新都經過這個類別處理
class InventoryNotifier extends StateNotifier<Inventory> {
  final Ref _ref;

  InventoryNotifier(this._ref) : super(const Inventory(capacity: 20));

  // 基本物品操作
  bool addItem(Item item) {
    final (newInventory, success) = state.withItemAdded(item);
    if (success) {
      state = newInventory;
    }
    return success;
  }

  bool removeItem(Item item, {int quantityToRemove = 1}) {
    final (newInventory, success) = state.withItemRemoved(
      item,
      quantityToRemove: quantityToRemove,
    );
    if (success) {
      state = newInventory;
    }
    return success;
  }

  // 使用物品 - 會與 PlayerNotifier 互動
  void useItem(Item item) {
    debugPrint('開始使用物品: ${item.name} (ID: ${item.id})');

    final playerNotifier = _ref.read(playerProvider.notifier);
    final player = _ref.read(playerProvider);

    // 確保物品在背包中
    if (state.items.contains(item)) {
      // 根據物品類型進行處理
      if (item is Weapon) {
        // 裝備武器
        playerNotifier.equipWeapon(item);
      } else if (item is Armor) {
        // 裝備護甲
        playerNotifier.equipArmor(item);
      } else if (item is Consumable) {
        debugPrint(
          '使用消耗品: ${item.name}，健康恢復值: ${item.healthRestore}，魔法恢復值: ${item.manaRestore}',
        );

        try {
          // 處理消耗品的效果，避免直接依賴循環引用
          if (item.healthRestore > 0) {
            // 使用正確的healing方法恢復生命值，它會考慮最大生命值（含加成）
            playerNotifier.heal(item.healthRestore);
            debugPrint(
              '恢復${item.healthRestore}點生命值，當前生命值: ${_ref.read(playerProvider).health}',
            );
          }

          if (item.manaRestore > 0) {
            playerNotifier.addMana(item.manaRestore);
            debugPrint(
              '恢復${item.manaRestore}點魔力值，當前魔力值: ${_ref.read(playerProvider).mana}',
            );
          }

          // 如果是消耗品，使用後減少數量
          if (item.isStackable) {
            removeItem(item, quantityToRemove: 1);
            debugPrint('物品使用後數量減少1');
          }
        } catch (e) {
          debugPrint('使用消耗品時出錯: $e');
        }
      } else {
        // 其他類型物品的使用邏輯 - 用 applyEffects 獲取效果描述，但實際效果由 Provider 實現
        debugPrint('使用其他類型物品: ${item.name}');
        item.applyEffects(player);
      }
    } else {
      debugPrint('物品不在背包中，無法使用');
    }
  }

  // 熱鍵相關方法
  void bindHotkey(int slot, Item item) {
    state = state.withHotkeyBound(slot, item);
  }

  void unbindHotkey(int slot) {
    state = state.withHotkeyUnbound(slot);
  }

  void useHotkeyItem(int slot) {
    final item = state.hotkeyBindings[slot];
    if (item != null) {
      useItem(item);
    }
  }

  // 獲取特定類型的武器列表
  List<Weapon> getWeaponsByType(WeaponType type) {
    return state.getWeaponsByType(type);
  }

  // 獲取排序後的武器列表
  List<Weapon> getSortedWeapons({
    required String sortBy,
    bool ascending = false,
  }) {
    return state.getSortedWeapons(sortBy: sortBy, ascending: ascending);
  }

  // 修改背包容量
  void setCapacity(int newCapacity) {
    state = state.withCapacity(newCapacity);
  }

  // 清空背包
  void clear() {
    state = state.withClearedItems();
  }

  // 檢查是否有特定物品
  bool hasItem(String itemId) {
    return state.hasItem(itemId);
  }

  // 裝備最佳武器
  void equipBestWeaponOfType(WeaponType type) {
    final weapons = getWeaponsByType(type);
    if (weapons.isEmpty) return;

    // 按傷害排序
    weapons.sort((a, b) => b.damage.compareTo(a.damage));

    // 裝備最佳武器
    _ref.read(playerProvider.notifier).equipWeapon(weapons.first);
  }
}
