// lib/providers/player_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// 基礎數值
final healthProvider = StateProvider<int>((ref) => 100);
final manaProvider = StateProvider<int>((ref) => 100);
final speedProvider = StateProvider<double>((ref) => 150.0);

// 新增：是否正在射擊
final isShootingProvider = StateProvider<bool>((ref) => false);

// 新增：武器熱值（用於機關槍等連射武器）
final weaponHeatProvider = StateProvider<double>((ref) => 0.0);

// 新增：武器切換冷卻
final weaponSwitchCooldownProvider = StateProvider<double>((ref) => 0.0);
