// 物品數據提供者
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:night_and_rain_v2/models/item.dart';

import '../enum/item_rarity.dart';
import '../enum/weapon_type.dart';
import '../models/ranged_weapon.dart';
import '../models/consumable.dart';

final itemsDataProvider = Provider<Map<String, Item>>((ref) {
  // 返回遊戲中所有可用物品的數據
  return {
    // ==================== 手槍系列 ====================
    // 米蟲級手槍
    'pistol_ricebug': RangedWeapon(
      id: 'pistol_ricebug',
      name: '米蟲手槍',
      description: '專為最懶的你打造，扣動扳機的動作連夢境都懶得掙脫',
      rarity: ItemRarity.riceBug,
      icon: Icons.sports_handball,
      weaponType: WeaponType.pistol,
      damage: 8,

      price: 100,
      range: 250,
      manaCost: 5,
    ),
    // 銅牛級手槍
    'pistol_copper': RangedWeapon(
      id: 'pistol_copper',
      name: '銅牛哞槍',
      description: '每次開槍都伴隨低沉「哞──」聲響，可靠又威武，是進階懶蟲的標配',
      rarity: ItemRarity.copperBull,
      icon: Icons.sports_handball,
      weaponType: WeaponType.pistol,
      damage: 12,

      price: 300,
      range: 300,
      manaCost: 5,
    ),
    // 銀牛級手槍
    'pistol_silver': RangedWeapon(
      id: 'pistol_silver',
      name: '精良手槍',
      description: '由經驗豐富的工匠製作的手槍，精準且可靠',
      rarity: ItemRarity.silverBull,
      icon: Icons.sports_handball,
      weaponType: WeaponType.pistol,
      damage: 18,

      price: 800,
      range: 350,
      manaCost: 4,
    ),
    // 金牛級手槍
    'pistol_gold': RangedWeapon(
      id: 'pistol_gold',
      name: '傳說手槍',
      description: '曾屬於一位著名槍手的傳奇武器，威力非凡',
      rarity: ItemRarity.goldBull,
      icon: Icons.sports_handball,
      weaponType: WeaponType.pistol,
      damage: 25,

      price: 2000,
      range: 400,
      manaCost: 3,
      hasAutoFire: true,
    ),

    // ==================== 霰彈槍系列 ====================
    // 米蟲級霰彈槍
    'shotgun_ricebug': RangedWeapon(
      id: 'shotgun_ricebug',
      name: '老舊霰彈槍',
      description: '老舊的霰彈槍，用起來有些卡頓',
      rarity: ItemRarity.riceBug,
      icon: FontAwesomeIcons.gun,
      weaponType: WeaponType.shotgun,
      damage: 20,

      price: 150,
      range: 150,
      manaCost: 12,
    ),
    // 銅牛級霰彈槍
    'shotgun_copper': RangedWeapon(
      id: 'shotgun_copper',
      name: '標準霰彈槍',
      description: '標準配發的霰彈槍，近距離威力頗大',
      rarity: ItemRarity.copperBull,
      icon: FontAwesomeIcons.gun,
      weaponType: WeaponType.shotgun,
      damage: 28,

      price: 450,
      range: 180,
      manaCost: 15,
    ),
    // 銀牛級霰彈槍
    'shotgun_silver': RangedWeapon(
      id: 'shotgun_silver',
      name: '精良霰彈槍',
      description: '經過專業改裝的霰彈槍，射程與殺傷力都有提升',
      rarity: ItemRarity.silverBull,
      icon: FontAwesomeIcons.gun,
      weaponType: WeaponType.shotgun,
      damage: 35,

      price: 1200,
      range: 220,
      manaCost: 18,
    ),
    // 金牛級霰彈槍
    'shotgun_gold': RangedWeapon(
      id: 'shotgun_gold',
      name: '傳說霰彈槍',
      description: '散發著金色光芒的霰彈槍，擊中敵人時會產生強大的沖擊波',
      rarity: ItemRarity.goldBull,
      icon: FontAwesomeIcons.gun,
      weaponType: WeaponType.shotgun,
      damage: 45,

      price: 3000,
      range: 250,
      manaCost: 20,
    ),

    // ==================== 機關槍系列 ====================
    // 米蟲級機關槍
    'machinegun_ricebug': RangedWeapon(
      id: 'machinegun_ricebug',
      name: '簡易機關槍',
      description: '簡易組裝的機關槍，射速不穩定',
      rarity: ItemRarity.riceBug,
      icon: FontAwesomeIcons.bullseye,
      weaponType: WeaponType.machineGun,
      damage: 6,

      price: 200,
      range: 280,
      manaCost: 2,
      hasAutoFire: true,
    ),
    // 銅牛級機關槍
    'machinegun_copper': RangedWeapon(
      id: 'machinegun_copper',
      name: '標準機關槍',
      description: '量產型機關槍，彈藥充足',
      rarity: ItemRarity.copperBull,
      icon: FontAwesomeIcons.bullseye,
      weaponType: WeaponType.machineGun,
      damage: 8,

      price: 600,
      range: 320,
      manaCost: 2,
      hasAutoFire: true,
    ),
    // 銀牛級機關槍
    'machinegun_silver': RangedWeapon(
      id: 'machinegun_silver',
      name: '高級機關槍',
      description: '定制版機關槍，配備高品質彈藥和穩定系統',
      rarity: ItemRarity.silverBull,
      icon: FontAwesomeIcons.bullseye,
      weaponType: WeaponType.machineGun,
      damage: 10,

      price: 1500,
      range: 380,
      manaCost: 1,
      hasAutoFire: true,
    ),
    // 金牛級機關槍
    'machinegun_gold': RangedWeapon(
      id: 'machinegun_gold',
      name: '傳說機關槍',
      description: '據說是一位戰爭英雄使用過的機關槍，幾乎沒有後座力',
      rarity: ItemRarity.goldBull,
      icon: FontAwesomeIcons.bullseye,
      weaponType: WeaponType.machineGun,
      damage: 12,

      price: 4000,
      range: 450,
      manaCost: 1,
      hasAutoFire: true,
    ),

    // ==================== 狙擊槍系列 ====================
    // 米蟲級狙擊槍
    'sniper_ricebug': RangedWeapon(
      id: 'sniper_ricebug',
      name: '米蟲狙擊槍',
      description: '給米蟲新人使用的狙擊槍，在實戰的蠻坑爹的',
      rarity: ItemRarity.riceBug,
      icon: FontAwesomeIcons.crosshairs,
      weaponType: WeaponType.sniper,
      damage: 30,

      price: 300,
      range: 500,
      manaCost: 15,
    ),
    // 銅牛級狙擊槍
    'sniper_copper': RangedWeapon(
      id: 'sniper_copper',
      name: '軍用狙擊槍',
      description: '軍隊中使用的標準狙擊槍，射程遠',
      rarity: ItemRarity.copperBull,
      icon: FontAwesomeIcons.crosshairs,
      weaponType: WeaponType.sniper,
      damage: 45,

      price: 900,
      range: 650,
      manaCost: 18,
    ),
    // 銀牛級狙擊槍
    'sniper_silver': RangedWeapon(
      id: 'sniper_silver',
      name: '精密狙擊槍',
      description: '特種部隊專用狙擊槍，配有高精度瞄準鏡',
      rarity: ItemRarity.silverBull,
      icon: FontAwesomeIcons.crosshairs,
      weaponType: WeaponType.sniper,
      damage: 65,

      price: 2200,
      range: 800,
      manaCost: 20,
    ),
    // 金牛級狙擊槍
    'sniper_gold': RangedWeapon(
      id: 'sniper_gold',
      name: '喂～金牛座之眼',
      description:
          '傳說中的狙擊槍，是米蟲教的金牛星座使者專用的武器。據說是因為金牛使者的眼光非常好(?，能夠一眼看穿敵人的弱點，所以這把狙擊槍也被稱為「金牛座之眼」。',
      rarity: ItemRarity.goldBull,
      icon: FontAwesomeIcons.crosshairs,
      weaponType: WeaponType.sniper,
      damage: 180,

      price: 5000,
      range: 1000,
      manaCost: 25,
    ),

    // ==================== 藥水系列 ====================
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
    // 添加高級紅藥水
    'health_potion_premium': Consumable(
      id: 'health_potion_premium',
      name: '高級紅色藥水',
      description: '恢復大量生命值的藥水',
      rarity: ItemRarity.silverBull,
      icon: Icons.healing,
      price: 200,
      healthRestore: 100,
    ),
    // 添加高級藍藥水
    'mana_potion_premium': Consumable(
      id: 'mana_potion_premium',
      name: '高級藍色藥水',
      description: '恢復大量魔力值的藥水',
      rarity: ItemRarity.silverBull,
      icon: Icons.water_drop,
      price: 200,
      manaRestore: 100,
    ),
    // 其他物品...
  };
});
