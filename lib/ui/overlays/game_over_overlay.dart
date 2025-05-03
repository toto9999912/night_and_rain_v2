// filepath: d:\game\night_and_rain_v2\lib\ui\overlays\game_over_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:night_and_rain_v2/main.dart';
import 'package:night_and_rain_v2/providers/player_provider.dart';
import 'package:night_and_rain_v2/providers/inventory_provider.dart';

/// 遊戲結束覆蓋層
class GameOverOverlay extends ConsumerWidget {
  final FlameGame game;

  const GameOverOverlay({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          width: screenSize.width * 0.5,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade800, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade800.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 遊戲結束標題
              const Text(
                '你已經死亡',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 死亡描述
              const Text(
                '你在這個充滿危險的世界中結束了旅程...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 40),

              // 重新嘗試按鈕
              ElevatedButton(
                onPressed: () {
                  _restartGame(ref);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('重新嘗試', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 重新開始遊戲
  void _restartGame(WidgetRef ref) {
    // 重置玩家屬性
    final playerNotifier = ref.read(playerProvider.notifier);
    playerNotifier.setHealth(100); // 重置生命值
    playerNotifier.setMana(100); // 重置魔力值

    // 移除 GameOver 覆蓋層
    game.overlays.remove('GameOverOverlay');

    // 重新初始化玩家位置
    if (game is NightAndRainGame) {
      final nightAndRainGame = game as NightAndRainGame;
      // 將玩家移動回地圖中央
      nightAndRainGame.resetPlayerPosition();
    }
  }
}
