import 'package:flutter/material.dart';
import 'package:flame/cache.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import '../../main.dart';
import '../overlays/dialog_overlay.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/password_input_overlay.dart';
import '../overlays/player_dashboard_overlay.dart';
import '../overlays/shop_overlay.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  final bool isBirthdaySpecial;

  const LoadingScreen({super.key, this.isBirthdaySpecial = false});

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  double _loadingProgress = 0.0;
  bool _isLoadingComplete = false;
  final List<String> _loadingMessages = [
    '載入世界地圖...',
    '準備武器資料...',
    '喚醒睡著的NPC...',
    '計算宇宙常數...',
    '檢查地下城入口...',
    '餵養小米蟲...',
  ];
  String _currentMessage = '初始化資源...';
  final List<String> _preloadAssets = [
    'audio/bgm.mp3',
    'audio/menu.mp3',
    'AstrologerMumu.png',
    'ShopkeeperBug.png',
    'MenuTitle.png',
  ];

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    // 模擬載入過程
    int totalAssets = _preloadAssets.length;
    int loadedAssets = 0;

    // 預載每個資源
    for (var asset in _preloadAssets) {
      // 更新載入訊息
      setState(() {
        _currentMessage =
            _loadingMessages[loadedAssets % _loadingMessages.length];
      });

      // 實際預載資源
      try {
        if (asset.startsWith('audio/')) {
          await FlameAudio.audioCache.load(asset.replaceFirst('audio/', ''));
        } else if (asset.startsWith('images/')) {
          await Images().load(asset);
        }
      } catch (e) {
        debugPrint('預載資源失敗: $asset - $e');
      }

      // 更新進度
      loadedAssets++;
      setState(() {
        _loadingProgress = loadedAssets / totalAssets;
      });

      // 每次載入間隔一小段時間，模擬自然載入過程
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 確保總進度為100%
    setState(() {
      _loadingProgress = 1.0;
      _currentMessage = '載入完成！';
      _isLoadingComplete = true;
    });

    // 短暫延遲後進入遊戲
    await Future.delayed(const Duration(milliseconds: 800));

    // 轉到主遊戲畫面
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => RiverpodAwareGameWidget<NightAndRainGame>(
                game: gameInstance,
                key: gameWidgetKey,
                focusNode: gameFocusNode,
                autofocus: true,
                overlayBuilderMap: {
                  'HudOverlay': (context, game) => HudOverlay(game: game),
                  'InventoryOverlay':
                      (context, game) => PlayerDashboardOverlay(game: game),
                  'DialogOverlay':
                      (context, game) =>
                          DialogOverlay(game: game, npc: game.dialogNpc!),
                  'ShopOverlay':
                      (context, game) =>
                          ShopOverlay(game: game, shopkeeper: game.dialogNpc!),
                  'GameOverOverlay':
                      (context, game) => GameOverOverlay(game: game),
                  'PasswordInputOverlay':
                      (context, game) => PasswordInputOverlay(game: game),
                },
                initialActiveOverlays: const ['HudOverlay'],
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 獲取生日特別企劃模式的標題
    final String titleText =
        widget.isBirthdaySpecial ? '載入生日特別企劃...' : '載入遊戲資源...';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 顯示標題
            Text(
              titleText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),

            // 顯示載入進度條
            SizedBox(
              width: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.grey.shade900,
                  color:
                      widget.isBirthdaySpecial
                          ? Colors
                              .pink // 生日特別企劃用粉紅色
                          : Colors.blue, // 一般模式用藍色
                  minHeight: 20,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 顯示載入訊息
            Text(
              _currentMessage,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),

            const SizedBox(height: 40),

            // 如果是生日特別企劃，顯示特別提示
            if (widget.isBirthdaySpecial)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.pink.shade900.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.pink.shade300),
                ),
                child: const Text(
                  '生日特別企劃將包含獨特內容和限時獎勵！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // 提示按任意鍵繼續（僅在載入完成後顯示）
            if (_isLoadingComplete)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Text(
                  '按任意鍵繼續...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
