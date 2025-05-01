import '../enum/item_type.dart';
import 'item.dart';

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
    if (items.length < capacity) {
      items.add(item);
      return true;
    }
    return false;
  }

  bool removeItem(Item item) {
    final result = items.remove(item);

    // 如果物品被移除，同時也要從快捷鍵綁定中移除
    if (result) {
      hotkeyBindings.removeWhere((key, value) => value.id == item.id);
    }

    return result;
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
