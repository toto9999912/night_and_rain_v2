// 使用 Riverpod 管理武器
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/managers/weapon_manager.dart';

import '../models/weapon.dart';
import 'player_provider.dart';

final weaponManagerProvider = Provider<WeaponManager>((ref) {
  final player = ref.watch(playerProvider);
  return WeaponManager(player: player);
});

final currentWeaponProvider = Provider<Weapon?>((ref) {
  final weaponManager = ref.watch(weaponManagerProvider);
  return weaponManager.currentWeapon;
});
