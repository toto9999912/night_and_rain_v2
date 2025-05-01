// lib/providers/player_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../models/weapon.dart';

final playerProvider = StateNotifierProvider<PlayerNotifier, Player>((ref) {
  return PlayerNotifier();
});

class PlayerNotifier extends StateNotifier<Player> {
  PlayerNotifier() : super(Player());

  void updateHealth(int value) {}
  void updateMana(int value) {}
  void equipWeapon(Weapon weapon) {}
  // 其他方法...
}
