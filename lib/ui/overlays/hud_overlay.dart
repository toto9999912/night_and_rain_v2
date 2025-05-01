import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import '../../providers/player_provider.dart';

import '../widgets/hotkey_bar.dart';
import '../widgets/status_group.dart';

class HudOverlay extends ConsumerWidget {
  final FlameGame game;
  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);

    // final weapon = ref.watch(currentWeaponProvider);
    final screenSize = MediaQuery.of(context).size;

    // 使用透明Material解決文字警告問題
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand, // 確保Stack填滿整個安全區域
          children: [
            // 左上狀態條組
            Positioned(
              top: 16,
              left: 16,
              child: StatusGroup(health: player.health, mana: player.mana),
            ),

            // 左下角武器展示
            // Positioned(
            //   left: 16,
            //   bottom: 16,
            //   child: CurrentWeaponDisplay(
            //     weaponName: weapon.name,
            //     weaponType: weapon.weaponType,
            //   ),
            // ),

            // 底部中間數字熱鍵
            Positioned(
              bottom: 16,
              width: screenSize.width, // 明確設置寬度以防止跑版
              child: Center(child: HotkeyBar()),
            ),
          ],
        ),
      ),
    );
  }
}
