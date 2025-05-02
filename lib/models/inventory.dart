import '../enum/item_type.dart';
import '../enum/weapon_type.dart';
import 'item.dart';
import 'weapon.dart';

class Inventory {
  final List<Item> items;
  final int capacity;
  final Map<int, Item> hotkeyBindings; // 快捷鍵綁定

  Inventory({
    List<Item>? startingItems,
    this.capacity = 20,
    Map<int, Item>? initialBindings,
  }) : items = startingItems ?? [],
       hotkeyBindings = initialBindings ?? {};

  bool addItem(Item item) {
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
        items[existingIndex] = updatedItem;

        // 更新快捷鍵綁定
        hotkeyBindings.forEach((key, value) {
          if (value.id == item.id) {
            hotkeyBindings[key] = updatedItem;
          }
        });

        return true;
      }
    }

    // 非堆疊物品或找不到相同ID的物品，則添加新物品
    if (items.length < capacity) {
      items.add(item);
      return true;
    }
    return false;
  }

  bool removeItem(Item item, {int quantityToRemove = 1}) {
    // 查找物品索引
    final index = items.indexWhere((i) => i.id == item.id);
    if (index < 0) return false;

    final existingItem = items[index];

    // 如果是可堆疊物品且數量大於要移除的數量
    if (existingItem.isStackable && existingItem.quantity > quantityToRemove) {
      // 減少數量但不移除物品
      final newQuantity = existingItem.quantity - quantityToRemove;
      final updatedItem = existingItem.copyWith(quantity: newQuantity);
      items[index] = updatedItem;

      // 更新快捷鍵綁定
      hotkeyBindings.forEach((key, value) {
        if (value.id == item.id) {
          hotkeyBindings[key] = updatedItem;
        }
      });

      return true;
    } else {
      // 完全移除物品
      final result = items.remove(item);

      // 如果物品被移除，同時也要從快捷鍵綁定中移除
      if (result) {
        hotkeyBindings.removeWhere((key, value) => value.id == item.id);
      }

      return result;
    }
  }

  void bindHotkey(int slot, Item item) {
    // 確保物品在背包中
    if (items.contains(item)) {
      hotkeyBindings[slot] = item;
    }
  }

  void unbindHotkey(int slot) {
    hotkeyBindings.remove(slot);
  }

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
      case 'attackSpeed':
        weapons.sort(
          (a, b) =>
              ascending
                  ? a.attackSpeed.compareTo(b.attackSpeed)
                  : b.attackSpeed.compareTo(a.attackSpeed),
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

  void clear() {
    items.clear();
    hotkeyBindings.clear();
  }
}
