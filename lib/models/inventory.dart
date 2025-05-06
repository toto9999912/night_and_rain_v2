import '../enum/item_type.dart';
import '../enum/weapon_type.dart';
import 'item.dart';
import 'weapon.dart';

/// 不可變的 Inventory 模型
class Inventory {
  final List<Item> items;
  final int capacity;
  final Map<int, Item> hotkeyBindings; // 快捷鍵綁定

  // 構造函數 - 確保不可變性
  const Inventory({
    this.items = const [],
    this.capacity = 20,
    this.hotkeyBindings = const {},
  });

  /// 返回新增物品後的新 Inventory 實例
  (Inventory, bool) withItemAdded(Item item) {
    // 檢查是否為可堆疊物品
    if (item.isStackable) {
      // 尋找相同ID的物品
      final existingIndex = items.indexWhere((i) => i.id == item.id);

      if (existingIndex >= 0) {
        // 找到相同物品，堆疊數量
        final existingItem = items[existingIndex];
        final newQuantity = existingItem.quantity + item.quantity;

        // 複製一個新的物品但數量增加
        final updatedItem = existingItem.copyWith(quantity: newQuantity);

        // 創建新的物品列表，替換更新後的物品
        final newItems = List<Item>.from(items);
        newItems[existingIndex] = updatedItem;

        // 更新快捷鍵綁定
        final newBindings = Map<int, Item>.from(hotkeyBindings);
        hotkeyBindings.forEach((key, value) {
          if (value.id == item.id) {
            newBindings[key] = updatedItem;
          }
        });

        return (
          Inventory(
            items: newItems,
            capacity: capacity,
            hotkeyBindings: newBindings,
          ),
          true,
        );
      }
    }

    // 非堆疊物品或找不到相同ID的物品，則添加新物品
    if (items.length < capacity) {
      final newItems = List<Item>.from(items)..add(item);
      return (
        Inventory(
          items: newItems,
          capacity: capacity,
          hotkeyBindings: Map<int, Item>.from(hotkeyBindings),
        ),
        true,
      );
    }
    return (this, false);
  }

  /// 返回移除物品後的新 Inventory 實例
  (Inventory, bool) withItemRemoved(Item item, {int quantityToRemove = 1}) {
    // 查找物品索引
    final index = items.indexWhere((i) => i.id == item.id);
    if (index < 0) return (this, false);

    final existingItem = items[index];

    // 如果是可堆疊物品且數量大於要移除的數量
    if (existingItem.isStackable && existingItem.quantity > quantityToRemove) {
      // 減少數量但不移除物品
      final newQuantity = existingItem.quantity - quantityToRemove;
      final updatedItem = existingItem.copyWith(quantity: newQuantity);

      final newItems = List<Item>.from(items);
      newItems[index] = updatedItem;

      // 更新快捷鍵綁定
      final newBindings = Map<int, Item>.from(hotkeyBindings);
      hotkeyBindings.forEach((key, value) {
        if (value.id == item.id) {
          newBindings[key] = updatedItem;
        }
      });

      return (
        Inventory(
          items: newItems,
          capacity: capacity,
          hotkeyBindings: newBindings,
        ),
        true,
      );
    } else {
      // 完全移除物品
      final newItems = List<Item>.from(items);
      final removed = newItems.remove(existingItem);

      if (!removed) return (this, false);

      // 從快捷鍵綁定中移除
      final newBindings = Map<int, Item>.from(hotkeyBindings);
      newBindings.removeWhere((key, value) => value.id == item.id);

      return (
        Inventory(
          items: newItems,
          capacity: capacity,
          hotkeyBindings: newBindings,
        ),
        true,
      );
    }
  }

  /// 返回綁定熱鍵後的新 Inventory 實例
  Inventory withHotkeyBound(int slot, Item item) {
    // 確保物品在背包中
    if (!items.contains(item)) return this;

    final newBindings = Map<int, Item>.from(hotkeyBindings);
    newBindings[slot] = item;

    return Inventory(
      items: List<Item>.from(items),
      capacity: capacity,
      hotkeyBindings: newBindings,
    );
  }

  /// 返回解除熱鍵綁定後的新 Inventory 實例
  Inventory withHotkeyUnbound(int slot) {
    final newBindings = Map<int, Item>.from(hotkeyBindings);
    newBindings.remove(slot);

    return Inventory(
      items: List<Item>.from(items),
      capacity: capacity,
      hotkeyBindings: newBindings,
    );
  }

  /// 返回清空背包後的新 Inventory 實例
  Inventory withClearedItems() {
    return Inventory(capacity: capacity);
  }

  /// 返回新容量的 Inventory 實例
  Inventory withCapacity(int newCapacity) {
    if (newCapacity < items.length) return this;

    return Inventory(
      items: List<Item>.from(items),
      capacity: newCapacity,
      hotkeyBindings: Map<int, Item>.from(hotkeyBindings),
    );
  }

  // 以下是查詢方法，不修改狀態

  Item? getItemById(String id) {
    for (var item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  List<Item> getItemsByType(ItemType type) {
    return items.where((item) => item.type == type).toList();
  }

  // 獲取所有武器物品
  List<Weapon> getWeapons() {
    return items
        .where((item) => item.type == ItemType.weapon && item is Weapon)
        .cast<Weapon>()
        .toList();
  }

  // 根據武器類型獲取武器
  List<Weapon> getWeaponsByType(WeaponType weaponType) {
    return getWeapons()
        .where((weapon) => weapon.weaponType == weaponType)
        .toList();
  }

  // 排序武器 (根據傷害、稀有度等)
  List<Weapon> getSortedWeapons({
    required String sortBy,
    bool ascending = false,
  }) {
    final weapons = getWeapons();

    switch (sortBy) {
      case 'damage':
        weapons.sort(
          (a, b) =>
              ascending
                  ? a.damage.compareTo(b.damage)
                  : b.damage.compareTo(a.damage),
        );
        break;

      case 'rarity':
        weapons.sort(
          (a, b) =>
              ascending
                  ? a.rarity.index.compareTo(b.rarity.index)
                  : b.rarity.index.compareTo(a.rarity.index),
        );
        break;
      case 'price':
        weapons.sort(
          (a, b) =>
              ascending
                  ? a.price.compareTo(b.price)
                  : b.price.compareTo(a.price),
        );
        break;
      default:
        // 預設按稀有度排序
        weapons.sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
    }

    return weapons;
  }

  int countItems() {
    return items.length;
  }

  int getRemainingCapacity() {
    return capacity - items.length;
  }

  bool isFull() {
    return items.length >= capacity;
  }

  bool isEmpty() {
    return items.isEmpty;
  }

  bool hasItem(String itemId) {
    return getItemById(itemId) != null;
  }
}
