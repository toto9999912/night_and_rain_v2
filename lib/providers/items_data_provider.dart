// 物品數據提供者
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:night_and_rain_v2/models/item.dart';

import '../enum/item_rarity.dart';
import '../enum/weapon_type.dart';
import '../models/ranged_weapon.dart';
import '../models/weapon.dart';
import '../models/consumable.dart';

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
      manaCost: 5,
    ),
    'shotgun_1': RangedWeapon(
      id: 'shotgun_1',
      name: '標準霰彈槍',
      description: '標準配發的霰彈槍，性能可靠',
      rarity: ItemRarity.riceBug,
      icon: FontAwesomeIcons.gun,
      weaponType: WeaponType.shotgun,
      damage: 10,
      attackSpeed: 1.5,
      price: 200,
      range: 600,
      manaCost: 25,
    ),
    // 添加紅藥水
    'health_potion': Consumable(
      id: 'health_potion',
      name: '紅色藥水',
      description: '恢復少量生命值的藥水',
      rarity: ItemRarity.riceBug,
      icon: Icons.healing,
      price: 50,
      healthRestore: 30,
    ),
    // 添加藍藥水
    'mana_potion': Consumable(
      id: 'mana_potion',
      name: '藍色藥水',
      description: '恢復少量魔力值的藥水',
      rarity: ItemRarity.riceBug,
      icon: Icons.water_drop,
      price: 50,
      manaRestore: 30,
    ),
    // 其他物品...
  };
});
