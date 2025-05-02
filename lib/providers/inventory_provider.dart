// 使用 Riverpod 管理庫存
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory.dart';
import '../models/item.dart';
import '../models/weapon.dart';
import '../models/consumable.dart';
import '../enum/weapon_type.dart';
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

class InventoryNotifier extends StateNotifier<Inventory> {
  final Ref _ref;

  InventoryNotifier(this._ref) : super(Inventory(capacity: 20));

  // 基本物品操作
  bool addItem(Item item) {
    final result = state.addItem(item);
    if (result) {
      state = Inventory(
        startingItems: [...state.items],
        capacity: state.capacity,
        initialBindings: Map.from(state.hotkeyBindings),
      );
    }
    return result;
  }

  bool removeItem(Item item, {int quantityToRemove = 1}) {
    final result = state.removeItem(item, quantityToRemove: quantityToRemove);
    if (result) {
      state = Inventory(
        startingItems: [...state.items],
        capacity: state.capacity,
        initialBindings: Map.from(state.hotkeyBindings),
      );
    }
    return result;
  }

  // 使用物品 - 會與 PlayerProvider 互動
  void useItem(Item item) {
    final playerNotifier = _ref.read(playerProvider.notifier);

    // 確保物品在背包中
    if (state.items.contains(item)) {
      // 根據物品類型進行處理
      if (item is Weapon) {
        // 裝備武器
        playerNotifier.equipWeapon(item);
      } else if (item is Consumable) {
        // 使用消耗品 - 對玩家產生效果
        item.use(_ref.read(playerProvider));
        playerNotifier.updateState();

        // 如果是消耗品，使用後減少數量
        if (item.isStackable) {
          removeItem(item, quantityToRemove: 1);
        }
      } else {
        // 其他類型物品的使用邏輯
        item.use(_ref.read(playerProvider));
        playerNotifier.updateState();
      }
    }
  }

  // 熱鍵相關方法
  void bindHotkey(int slot, Item item) {
    state.bindHotkey(slot, item);
    state = Inventory(
      startingItems: [...state.items],
      capacity: state.capacity,
      initialBindings: Map.from(state.hotkeyBindings),
    );
  }

  void unbindHotkey(int slot) {
    state.unbindHotkey(slot);
    state = Inventory(
      startingItems: [...state.items],
      capacity: state.capacity,
      initialBindings: Map.from(state.hotkeyBindings),
    );
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
    if (newCapacity >= state.items.length) {
      state = Inventory(
        startingItems: [...state.items],
        capacity: newCapacity,
        initialBindings: Map.from(state.hotkeyBindings),
      );
    }
  }

  // 清空背包
  void clear() {
    state = Inventory(
      capacity: state.capacity,
      startingItems: [],
      initialBindings: {},
    );
  }

  // 檢查是否有特定物品
  bool hasItem(String itemId) {
    return state.getItemById(itemId) != null;
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
