import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 玩家加成類型枚舉
enum PlayerBuffType {
  speedIncrease, // 移動速度加成
  maxHealthIncrease, // 最大生命值加成
}

// 加成效果數據模型
class PlayerBuff {
  final PlayerBuffType type;
  final double value; // 加成值
  final String description; // 描述
  final IconData icon; // 圖標
  final Color color; // 顏色
  final DateTime expireTime; // 過期時間，null表示永久

  PlayerBuff({
    required this.type,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
    DateTime? expireTime,
  }) : expireTime = expireTime ?? DateTime(9999); // 默認設置為一個很遠的未來日期

  // 檢查加成是否已過期
  bool get isExpired {
    return DateTime.now().isAfter(expireTime);
  }

  // 複製並修改加成對象
  PlayerBuff copyWith({
    PlayerBuffType? type,
    double? value,
    String? description,
    IconData? icon,
    Color? color,
    DateTime? expireTime,
  }) {
    return PlayerBuff(
      type: type ?? this.type,
      value: value ?? this.value,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      expireTime: expireTime ?? this.expireTime,
    );
  }
}

// 玩家加成狀態
class PlayerBuffsState {
  final List<PlayerBuff> buffs;

  const PlayerBuffsState({this.buffs = const []});

  // 獲取所有未過期的速度加成總和
  double get speedBuffValue {
    return buffs
        .where(
          (buff) =>
              buff.type == PlayerBuffType.speedIncrease && !buff.isExpired,
        )
        .fold(0.0, (sum, buff) => sum + buff.value);
  }

  // 獲取所有未過期的最大生命值加成總和
  double get maxHealthBuffValue {
    return buffs
        .where(
          (buff) =>
              buff.type == PlayerBuffType.maxHealthIncrease && !buff.isExpired,
        )
        .fold(0.0, (sum, buff) => sum + buff.value);
  }

  // 獲取所有未過期的加成
  List<PlayerBuff> get activeBuffs {
    return buffs.where((buff) => !buff.isExpired).toList();
  }

  // 清理過期的加成並返回新狀態
  PlayerBuffsState cleanExpiredBuffs() {
    final activeBuffs = this.activeBuffs;
    if (activeBuffs.length == buffs.length) return this;
    return PlayerBuffsState(buffs: activeBuffs);
  }

  // 添加加成並返回新狀態
  PlayerBuffsState addBuff(PlayerBuff newBuff) {
    // 首先清理過期加成
    final state = cleanExpiredBuffs();
    // 檢查是否已存在相同類型的加成，如果有則替換
    final existingIndex = state.buffs.indexWhere((b) => b.type == newBuff.type);

    if (existingIndex >= 0) {
      // 替換已存在的加成
      final newBuffs = List<PlayerBuff>.from(state.buffs);
      newBuffs[existingIndex] = newBuff;
      return PlayerBuffsState(buffs: newBuffs);
    } else {
      // 添加新加成
      return PlayerBuffsState(buffs: [...state.buffs, newBuff]);
    }
  }

  // 移除指定類型的加成並返回新狀態
  PlayerBuffsState removeBuff(PlayerBuffType type) {
    final newBuffs = buffs.where((b) => b.type != type).toList();
    return PlayerBuffsState(buffs: newBuffs);
  }
}

// 玩家加成Provider
final playerBuffsProvider =
    StateNotifierProvider<PlayerBuffsNotifier, PlayerBuffsState>((ref) {
      return PlayerBuffsNotifier();
    });

// 玩家加成Notifier
class PlayerBuffsNotifier extends StateNotifier<PlayerBuffsState> {
  PlayerBuffsNotifier() : super(const PlayerBuffsState());

  // 添加移動速度加成
  void addSpeedBuff(double value, {Duration? duration}) {
    final buff = PlayerBuff(
      type: PlayerBuffType.speedIncrease,
      value: value,
      description: '星象加成：移動速度+${value.toInt()}',
      icon: Icons.speed,
      color: Colors.orange,
      expireTime: duration != null ? DateTime.now().add(duration) : null,
    );
    state = state.addBuff(buff);
  }

  // 添加最大生命值加成
  void addMaxHealthBuff(double value, {Duration? duration}) {
    final buff = PlayerBuff(
      type: PlayerBuffType.maxHealthIncrease,
      value: value,
      description: '星象加成：最大生命值+${value.toInt()}',
      icon: Icons.favorite,
      color: Colors.red,
      expireTime: duration != null ? DateTime.now().add(duration) : null,
    );
    state = state.addBuff(buff);
  }

  // 清理已過期的加成
  void cleanExpiredBuffs() {
    state = state.cleanExpiredBuffs();
  }

  // 移除指定類型的加成
  void removeBuff(PlayerBuffType type) {
    state = state.removeBuff(type);
  }

  // 清除所有加成
  void clearAllBuffs() {
    state = const PlayerBuffsState();
  }
}
