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
      name: '周公解夢手槍',
      description: '米蟲教新手入門配槍，據說扣動扳機的那一刻，還能聽見周公在耳邊低語：「再睡五分鐘...」',
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
      name: '午睡使者',
      description: '米蟲教中午茶禮儀官御用手槍，每次開槍都會發出一聲「哞～」，彷彿在催促教徒該躺平休息了。',
      rarity: ItemRarity.copperBull,
      icon: Icons.sports_handball,
      weaponType: WeaponType.pistol,
      damage: 15,
      price: 300,
      range: 300,
      manaCost: 5,
    ),
    // 銀牛級手槍
    'pistol_silver': RangedWeapon(
      id: 'pistol_silver',
      name: '夢境守衛者',
      description: '四大象限護教法王共同開發的精良手槍，據說能射穿現實與夢境的界限，讓敵人在兩個世界都感受痛楚。',
      rarity: ItemRarity.silverBull,
      icon: Icons.sports_handball,
      weaponType: WeaponType.pistol,
      damage: 25,
      price: 800,
      range: 350,
      manaCost: 4,
    ),
    // 金牛級手槍
    'pistol_gold': RangedWeapon(
      id: 'pistol_gold',
      name: '「乾躺」太虛手槍',
      description:
          '米蟲教主親自持有的傳奇手槍，據說教主用它擊倒了試圖強迫教徒工作的「996惡魔」。持有此槍的人，連扣扳機這種小事都能用意念完成，達到究極躺平境界。',
      rarity: ItemRarity.goldBull,
      icon: Icons.sports_handball,
      weaponType: WeaponType.pistol,
      damage: 40,
      price: 2000,
      range: 400,
      manaCost: 3,
      hasAutoFire: true,
    ),

    // ==================== 霰彈槍系列 ====================
    // 米蟲級霰彈槍
    'shotgun_ricebug': RangedWeapon(
      id: 'shotgun_ricebug',
      name: '早餐驚魂',
      description: '米蟲教新手必備的第一把霰彈槍，據說是由那些拒絕起床吃早餐的教徒們的怨念所鑄造。',
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
      name: '午餐超時',
      description: '米蟲教「午餐必須睡覺」教義的執行者，能散射出一片睡意，讓敵人昏昏欲睡。',
      rarity: ItemRarity.copperBull,
      icon: FontAwesomeIcons.gun,
      weaponType: WeaponType.shotgun,
      damage: 30,
      price: 450,
      range: 180,
      manaCost: 14,
    ),
    // 銀牛級霰彈槍
    'shotgun_silver': RangedWeapon(
      id: 'shotgun_silver',
      name: '晚霞星塵散',
      description: '星軌日記抄寫員特製的霰彈槍，能將星辰的碎片作為彈藥，每次開火都像是灑下一片星光。',
      rarity: ItemRarity.silverBull,
      icon: FontAwesomeIcons.gun,
      weaponType: WeaponType.shotgun,
      damage: 45,
      price: 1200,
      range: 220,
      manaCost: 16,
    ),
    // 金牛級霰彈槍
    'shotgun_gold': RangedWeapon(
      id: 'shotgun_gold',
      name: '極致「躺平」霰彈槍',
      description:
          '米蟲教的至高儀式武器，據說在滿月之夜持此槍對著月亮開火，能召喚出躺平之神的化身。一擊之下，連最勤勞的工蜂都會放下工作，立刻躺平。',
      rarity: ItemRarity.goldBull,
      icon: FontAwesomeIcons.gun,
      weaponType: WeaponType.shotgun,
      damage: 100,
      price: 3000,
      range: 250,
      manaCost: 18,
    ),

    // ==================== 機關槍系列 ====================
    // 米蟲級機關槍
    'machinegun_ricebug': RangedWeapon(
      id: 'machinegun_ricebug',
      name: '唸經小鈴',
      description: '米蟲教新進教徒用來背誦教義的輔助武器，槍聲如同催眠曲，有助於進入躺平冥想狀態。',
      rarity: ItemRarity.riceBug,
      icon: FontAwesomeIcons.bullseye,
      weaponType: WeaponType.machineGun,
      damage: 7,
      price: 200,
      range: 280,
      manaCost: 2,
      hasAutoFire: true,
    ),
    // 銅牛級機關槍
    'machinegun_copper': RangedWeapon(
      id: 'machinegun_copper',
      name: '說教連珠',
      description: '星軌日記抄寫員用來朗誦教義的機關槍，子彈如同串珠般連綿不絕，聽久了會讓人不由自主地想要躺下。',
      rarity: ItemRarity.copperBull,
      icon: FontAwesomeIcons.bullseye,
      weaponType: WeaponType.machineGun,
      damage: 18,
      price: 600,
      range: 320,
      manaCost: 2,
      hasAutoFire: true,
    ),
    // 銀牛級機關槍
    'machinegun_silver': RangedWeapon(
      id: 'machinegun_silver',
      name: '思想滔滔',
      description:
          '四大象限護教法王向教眾傳達米蟲教理念時使用的武器，能夠把米蟲思想以子彈的形式植入目標腦中。中彈者會突然理解「人生苦短，何必勞碌」的真諦。',
      rarity: ItemRarity.silverBull,
      icon: FontAwesomeIcons.bullseye,
      weaponType: WeaponType.machineGun,
      damage: 29,
      price: 1500,
      range: 380,
      manaCost: 2,
      hasAutoFire: true,
    ),
    // 金牛級機關槍
    'machinegun_gold': RangedWeapon(
      id: 'machinegun_gold',
      name: '「嘴砲」共鳴機關槍',
      description:
          '水瓶使者的標誌性武器，傳說水瓶使者只需坐在躺椅上，讓這把武器替他說話。槍口能釋放出如洪水般的言論，讓敵人在思想的洪流中迷失自我，最終加入米蟲教的行列。',
      rarity: ItemRarity.goldBull,
      icon: FontAwesomeIcons.bullseye,
      weaponType: WeaponType.machineGun,
      damage: 40,
      price: 4000,
      range: 450,
      manaCost: 3,
      hasAutoFire: true,
    ),

    // ==================== 狙擊槍系列 ====================
    // 米蟲級狙擊槍
    'sniper_ricebug': RangedWeapon(
      id: 'sniper_ricebug',
      name: '遠望偷懶鏡',
      description: '米蟲教徒用來觀察遠處是否有工作需要避開的偵察武器，精度不高但勝在能讓你提前規劃躺平路線。',
      rarity: ItemRarity.riceBug,
      icon: FontAwesomeIcons.crosshairs,
      weaponType: WeaponType.sniper,
      damage: 70,
      price: 200,
      range: 500,
      manaCost: 18,
    ),
    // 銅牛級狙擊槍
    'sniper_copper': RangedWeapon(
      id: 'sniper_copper',
      name: '懶人凝視',
      description: '星軌日記抄寫員用來遠距離記錄星象的狙擊槍，透過它望向星空時，仿佛能看見宇宙也在懶洋洋地躺著。',
      rarity: ItemRarity.copperBull,
      icon: FontAwesomeIcons.crosshairs,
      weaponType: WeaponType.sniper,
      damage: 180,
      price: 600,
      range: 650,
      manaCost: 22,
    ),
    // 銀牛級狙擊槍
    'sniper_silver': RangedWeapon(
      id: 'sniper_silver',
      name: '四象限望遠鏡',
      description: '四大象限護教法王共同打造的狙擊槍，能夠透視到四個不同時空的懶惰能量，並將其凝聚為一擊。',
      rarity: ItemRarity.silverBull,
      icon: FontAwesomeIcons.crosshairs,
      weaponType: WeaponType.sniper,
      damage: 290,
      price: 1800,
      range: 800,
      manaCost: 30,
    ),
    // 金牛級狙擊槍
    'sniper_gold': RangedWeapon(
      id: 'sniper_gold',
      name: '喂～金牛座之眼',
      description:
          '傳說中的狙擊槍，是米蟲教的金牛星座使者專用的武器，據說是因為金牛使者的眼光非常好，持有者可以躺在任何地方，通過槍的瞄準鏡觀測宇宙的奧秘，並將宇宙能量化為彈藥。',
      rarity: ItemRarity.goldBull,
      icon: FontAwesomeIcons.crosshairs,
      weaponType: WeaponType.sniper,
      damage: 400,
      price: 4500,
      range: 1000,
      manaCost: 40,
    ),

    // ==================== 藥水系列 ====================
    // 添加紅藥水
    // ==================== 藥水系列 ====================
    // 添加基礎紅藥水
    // ==================== 優化後的藥水系統 ====================
    // 基礎生命藥水
    'health_potion_basic': Consumable(
      id: 'health_potion_basic',
      name: '鼾聲甜睡露',
      description: '米蟲教新手入門級藥水，據說是用熟睡時的鼾聲精華提煉而成，喝下去有助於小憩片刻恢復元氣。',
      rarity: ItemRarity.riceBug,
      icon: Icons.healing,
      price: 20,
      healthRestore: 30,
    ),

    // 基礎魔力藥水
    'mana_potion_basic': Consumable(
      id: 'mana_potion_basic',
      name: '午休精神水',
      description: '每個米蟲教徒午休時的床邊必備品，讓你在短暫的午睡後精神煥發，魔力小幅恢復。',
      rarity: ItemRarity.riceBug,
      icon: Icons.water_drop,
      price: 30,
      manaRestore: 30,
    ),

    // 中級生命藥水
    'health_potion_medium': Consumable(
      id: 'health_potion_medium',
      name: '懶骨頭精華',
      description: '由星軌日記抄寫員收集懶洋洋的精華所調配，富含「不想動」的能量，能快速修復身體損傷。',
      rarity: ItemRarity.copperBull,
      icon: Icons.healing,
      price: 40,
      healthRestore: 50,
    ),

    // 中級魔力藥水
    'mana_potion_medium': Consumable(
      id: 'mana_potion_medium',
      name: '躺平能量水',
      description: '四大象限護教法王共同開發的魔力飲品，採集了最純淨的「躺平」意念，飲用後魔力恢復顯著。',
      rarity: ItemRarity.copperBull,
      icon: Icons.water_drop,
      price: 60,
      manaRestore: 50,
    ),

    // 高級生命藥水
    'health_potion_advanced': Consumable(
      id: 'health_potion_advanced',
      name: '米蟲之淚',
      description: '傳說是由米蟲教徒看見完美躺平景象時流下的感動淚水所釀造，具有超凡的治癒力量。',
      rarity: ItemRarity.silverBull,
      icon: Icons.healing,
      price: 80,
      healthRestore: 75,
    ),

    // 高級魔力藥水
    'mana_potion_advanced': Consumable(
      id: 'mana_potion_advanced',
      name: '周公會面券',
      description: '飲用後能在夢中與周公直接對話，獲取宇宙級的懶惰智慧，大幅恢復魔力。',
      rarity: ItemRarity.silverBull,
      icon: Icons.water_drop,
      price: 120,
      manaRestore: 75,
    ),

    // 神級生命藥水
    'health_potion_legendary': Consumable(
      id: 'health_potion_legendary',
      name: '「長眠」不朽仙露',
      description: '米蟲教主熬夜(?)三天三夜精心調配的傳說藥水，據說飲用者能體驗「死亡」的終極安寧，然後滿血復活。',
      rarity: ItemRarity.goldBull,
      icon: Icons.healing,
      price: 160,
      healthRestore: 150,
    ),

    // 神級魔力藥水
    'mana_potion_legendary': Consumable(
      id: 'mana_potion_legendary',
      name: '星座祝福液',
      description: '金牛使者與水瓶使者聯手創造的星座精華，融合了十二星座的能量，喝下後能使魔力瞬間衝至頂峰。',
      rarity: ItemRarity.goldBull,
      icon: Icons.water_drop,
      price: 240,
      manaRestore: 150,
    ),

    // 其他物品...
  };
});
