// lib/providers/player_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../models/weapon.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../effects/player_effect.dart';
import '../models/armor.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../models/weapon.dart';

final playerProvider = StateNotifierProvider<PlayerNotifier, Player>((ref) {
  return PlayerNotifier();
});

class PlayerNotifier extends StateNotifier<Player> {
  PlayerNotifier() : super(Player());

  // 更新生命值
  void updateHealth(int value) {
    state.updateHealth(value);
    // 通知 UI 更新
    state = state.copyWith();
  }

  // 直接設置生命值
  void setHealth(int value) {
    state = state.copyWith(health: value);
  }

  // 增加/減少生命值
  void changeHealth(int amount) {
    if (amount > 0) {
      state.heal(amount);
    } else if (amount < 0) {
      state.takeDamage(-amount);
    }
    // 通知 UI 更新
    state = state.copyWith();
  }

  // 更新魔力值
  void updateMana(int value) {
    state.updateMana(value);
    // 通知 UI 更新
    state = state.copyWith();
  }

  // 直接設置魔力值
  void setMana(int value) {
    state = state.copyWith(mana: value);
  }

  // 增加/減少魔力值
  void changeMana(int amount) {
    if (amount > 0) {
      state.addMana(amount);
    } else if (amount < 0) {
      state.consumeMana(-amount);
    }
    // 通知 UI 更新
    state = state.copyWith();
  }

  // 消耗魔力
  bool consumeMana(int amount) {
    final success = state.consumeMana(amount);
    if (success) {
      // 通知 UI 更新
      state = state.copyWith();
    }
    return success;
  }

  // 裝備武器
  void equipWeapon(Weapon weapon) {
    state.equipWeapon(weapon);
    // 通知 UI 更新
    state = state.copyWith();
  }

  // 裝備護甲
  void equipArmor(Armor armor) {
    state.equipArmor(armor);
    // 通知 UI 更新
    state = state.copyWith();
  }

  // 設置速度
  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
  }

  // 增加金錢
  void addMoney(int amount) {
    state.addMoney(amount);
    // 通知 UI 更新
    state = state.copyWith();
  }

  // 消費金錢
  bool spendMoney(int amount) {
    final success = state.spendMoney(amount);
    if (success) {
      // 通知 UI 更新
      state = state.copyWith();
    }
    return success;
  }

  // 使用物品
  void useItem(Item item) {
    state.useItem(item);
    // 通知 UI 更新
    state = state.copyWith();
  }

  // 添加效果
  void addEffect(PlayerEffect effect) {
    state.effectManager.addEffect(effect);
    // 通知 UI 更新
    state = state.copyWith();
  }

  // 更新所有效果
  void updateEffects(double dt) {
    state.update(dt);
    // 如果有需要更新UI的效果變化
    state = state.copyWith();
  }

  // 清除所有效果
  void clearEffects() {
    state.effectManager.clearEffects();
    // 通知 UI 更新
    state = state.copyWith();
  }
}
