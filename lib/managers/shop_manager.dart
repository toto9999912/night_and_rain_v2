import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item.dart';
import '../providers/items_data_provider.dart';

// 商店管理器提供者
final shopManagerProvider = Provider<ShopManager>((ref) {
  // 獲取物品數據
  final itemsData = ref.read(itemsDataProvider);
  return ShopManager(items: itemsData);
});

/// 管理商店物品和折扣的類
class ShopManager {
  final Map<String, Item> _allItems; // 所有可用的物品
  final Map<String, Item> _shopItems = {}; // 當前商店銷售的物品
  double _discountRate = 1.0; // 折扣率 (1.0表示原價，0.8表示8折)
  String _shopName = ""; // 商店名稱

  ShopManager({required Map<String, Item> items}) : _allItems = items {
    // 初始化默認商店物品
    _initializeDefaultShopItems();
  }

  // 初始化默認商店物品 - 從所有物品中選出一部分
  void _initializeDefaultShopItems() {
    // 篩選出想在默認商店提供的物品
    _allItems.forEach((id, item) {
      // 例如：只選擇價格在一定範圍內的物品，或特定類型的物品
      if (item.price > 0 && item.price <= 500) {
        _shopItems[id] = item;
      }
    });
  }

  // 獲取當前商店物品
  Map<String, Item> get shopItems => _shopItems;

  // 獲取折扣後的價格
  int getDiscountedPrice(Item item) {
    return (item.price * _discountRate).round();
  }

  // 設置商店名稱
  void setShopName(String name) {
    _shopName = name;
  }

  // 獲取商店名稱
  String get shopName => _shopName;

  // 設置折扣率
  void setDiscountRate(double rate) {
    _discountRate = rate;
  }

  // 獲取當前折扣率
  double get discountRate => _discountRate;

  // 獲取折扣百分比顯示文字 (例如："8折")
  String get discountText {
    if (_discountRate >= 1.0) return "無折扣";
    final percentage = (_discountRate * 100).round();
    return "$percentage折";
  }

  // 自定義商店物品 - 可用於不同NPC提供不同物品
  void customizeShopItems(List<String> itemIds) {
    _shopItems.clear();
    for (final id in itemIds) {
      if (_allItems.containsKey(id)) {
        _shopItems[id] = _allItems[id]!;
      }
    }
  }

  // 添加物品到商店
  void addItemToShop(String itemId) {
    if (_allItems.containsKey(itemId)) {
      _shopItems[itemId] = _allItems[itemId]!;
    }
  }

  // 從商店移除物品
  void removeItemFromShop(String itemId) {
    _shopItems.remove(itemId);
  }
}
