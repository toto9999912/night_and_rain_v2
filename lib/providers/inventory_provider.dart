// 使用 Riverpod 管理庫存
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory.dart';
import '../models/item.dart';

final inventoryProvider = StateNotifierProvider<InventoryNotifier, Inventory>((
  ref,
) {
  return InventoryNotifier();
});

class InventoryNotifier extends StateNotifier<Inventory> {
  InventoryNotifier() : super(Inventory());

  void addItem(Item item) {}
  void removeItem(Item item) {}
  void bindHotkey(int slot, Item item) {}
  // 其他方法...
}
