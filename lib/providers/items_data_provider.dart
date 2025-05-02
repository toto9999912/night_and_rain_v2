// 物品數據提供者
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/models/item.dart';

import '../enum/item_rarity.dart';
import '../enum/weapon_type.dart';
import '../models/weapon.dart';

final itemsDataProvider = Provider<Map<String, Item>>((ref) {
  // 返回遊戲中所有可用物品的數據
  return {
    'pistol_1': Weapon(
      id: 'pistol_1',
      name: '標準手槍',
      description: '標準配發的手槍，性能可靠',
      rarity: ItemRarity.riceBug,
      icon: Icons.sports_handball,
      weaponType: WeaponType.pistol,
      damage: 10,
      attackSpeed: 1.5,
      price: 200,
      range: 300,
      cooldown: 0.5,
    ),
    'shotgun_1': Weapon(
      id: 'pistol_1',
      name: '標準霰彈槍',
      description: '標準配發的霰彈槍，性能可靠',
      rarity: ItemRarity.riceBug,
      icon: Icons.sports_handball,
      weaponType: WeaponType.shotgun,
      damage: 10,
      attackSpeed: 1.5,
      price: 200,
      range: 600,
      cooldown: 0.5,
    ),
    // 其他物品...
  };
});
