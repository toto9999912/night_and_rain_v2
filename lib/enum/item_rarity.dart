import 'package:flutter/material.dart';

/// 物品稀有度列舉
enum ItemRarity {
  riceBug(Color(0xFF8A8A8F), '米蟲級'), // 冷灰色，帶點藍調，呈現基礎感
  copperBull(Color(0xFFB87333), '銅牛級'), // 溫暖的紅銅色，豐富的金屬質感
  silverBull(Color(0xFFCED4DA), '銀牛級'), // 亮銀色，帶微藍光澤，突顯高級感
  goldBull(Color(0xFFFFB627), '金牛級'); // 明亮溫暖的金色，彰顯稀有和價值

  final Color color;
  final String name;

  const ItemRarity(this.color, this.name);
}
