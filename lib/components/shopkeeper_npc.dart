import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../managers/shop_manager.dart';
import 'npc_component.dart';

/// 商店NPC基礎類，提供商店功能
class ShopkeeperNpc extends NpcComponent with RiverpodComponentMixin {
  final List<String> _shopItems; // 銷售的物品ID列表
  final double _discountRate; // 折扣率 (1.0表示原價，0.8表示8折)
  final String _shopName; // 商店名稱

  ShopkeeperNpc({
    required super.name,
    required super.position,
    required super.color,
    required List<String> shopItems,
    String shopName = "",
    double discountRate = 1.0,
    List<String> greetings = const ['歡迎光臨！', '需要什麼東西嗎？', '我的貨品都是最好的！'],
    List<String> conversations = const [],
    Vector2? size,
    double interactionRadius = 40,
  }) : _shopItems = shopItems,
       _discountRate = discountRate,
       _shopName = shopName,
       super(
         greetings: greetings,
         conversations: conversations,
         size: size ?? Vector2(32, 32), // 提供默認大小而不是null
         interactionRadius: interactionRadius,
         supportConversation: true, // 商店NPC支持對話
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  // 初始化商店設置
  void _initializeShop() {
    final shopManager = ref.read(shopManagerProvider);

    // 設定商店名稱
    if (_shopName.isNotEmpty) {
      shopManager.setShopName(_shopName);
    } else {
      shopManager.setShopName('$name的商店');
    }

    // 設定折扣率
    shopManager.setDiscountRate(_discountRate);

    // 設定商店物品
    if (_shopItems.isNotEmpty) {
      shopManager.customizeShopItems(_shopItems);
    }
  }

  // 打開商店
  void openShop() {
    // 初始化商店設置
    _initializeShop();

    // 啟動商店覆蓋層
    game.overlays.add('ShopOverlay');
  }

  // 覆蓋基類的開始對話方法，為了能夠顯示"查看商店"選項
  @override
  void startDialogue() {
    // 確保沒有重複添加對話覆蓋層
    if (game.overlays.isActive('DialogOverlay')) return;

    // 設置當前對話NPC
    if (game is NightAndRainGame) {
      (game as NightAndRainGame).dialogNpc = this;
    }

    // 添加對話覆蓋層
    game.overlays.add('DialogOverlay');
  }

  // 獲取商店物品列表，讓子類可以覆蓋
  List<String> get shopItems => _shopItems;

  // 獲取折扣率，讓子類可以覆蓋
  double get discountRate => _discountRate;

  // 獲取商店名稱，讓子類可以覆蓋
  String get shopName => _shopName;
}
