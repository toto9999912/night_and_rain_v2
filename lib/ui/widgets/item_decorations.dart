import 'package:flutter/material.dart';
import 'package:night_and_rain_v2/enum/item_rarity.dart';

/// 根據物品稀有度提供不同的裝飾效果
class ItemDecorations {
  /// 獲取物品的邊框裝飾
  static BoxDecoration getItemBorderDecoration(
    ItemRarity rarity, {
    bool isSelected = false,
  }) {
    switch (rarity) {
      case ItemRarity.riceBug:
        // 米蟲級 - 簡單的邊框
        return BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.yellow : rarity.color.withOpacity(0.6),
            width: isSelected ? 2 : 1,
          ),
        );

      case ItemRarity.copperBull:
        // 銅牛級 - 雙層邊框效果
        return BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: rarity.color.withOpacity(0.7),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: rarity.color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        );

      case ItemRarity.silverBull:
        // 銀牛級 - 優雅的雙層漸變邊框
        return BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(6),
          gradient: RadialGradient(
            colors: [Colors.black, Colors.grey.shade900],
            center: Alignment.center,
            radius: 0.8,
          ),
          border: Border.all(
            color: rarity.color.withOpacity(0.8),
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: rarity.color.withOpacity(0.4),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 0),
            ),
          ],
        );

      case ItemRarity.goldBull:
        // 金牛級 - 發光效果的邊框
        return BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(6),
          gradient: RadialGradient(
            colors: [Colors.brown.shade900.withOpacity(0.5), Colors.black],
            center: Alignment.center,
            radius: 0.7,
          ),
          border: Border.all(color: rarity.color, width: isSelected ? 3 : 2.5),
          boxShadow: [
            BoxShadow(
              color: rarity.color.withOpacity(0.6),
              spreadRadius: 2,
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
            BoxShadow(
              color: rarity.color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 0),
            ),
          ],
        );
    }
  }

  /// 獲取物品圖標裝飾
  static BoxDecoration getItemIconDecoration(ItemRarity rarity) {
    switch (rarity) {
      case ItemRarity.riceBug:
        // 米蟲級 - 基本容器
        return BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24),
        );

      case ItemRarity.copperBull:
        // 銅牛級 - 帶邊緣陰影
        return BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: rarity.color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: rarity.color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 0),
            ),
          ],
        );

      case ItemRarity.silverBull:
        // 銀牛級 - 漸層背景
        return BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black45, Colors.grey.shade800.withOpacity(0.5)],
          ),
          border: Border.all(color: rarity.color.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: rarity.color.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 0),
            ),
          ],
        );

      case ItemRarity.goldBull:
        // 金牛級 - 發光效果
        return BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: RadialGradient(
            colors: [rarity.color.withOpacity(0.2), Colors.black45],
            center: Alignment.center,
            radius: 0.8,
          ),
          border: Border.all(color: rarity.color.withOpacity(0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: rarity.color.withOpacity(0.4),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 0),
            ),
          ],
        );
    }
  }
}
