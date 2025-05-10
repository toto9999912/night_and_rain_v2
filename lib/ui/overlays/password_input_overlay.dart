import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:night_and_rain_v2/main.dart';
import 'package:night_and_rain_v2/providers/inventory_provider.dart';
import 'package:night_and_rain_v2/providers/items_data_provider.dart';
import 'package:night_and_rain_v2/providers/player_provider.dart';
import 'package:night_and_rain_v2/models/consumable.dart';
import 'package:night_and_rain_v2/models/ranged_weapon.dart';
import 'package:night_and_rain_v2/components/treasure_chest_component.dart';

/// 密碼輸入覆蓋層，允許玩家輸入密碼獲得特殊獎勵
class PasswordInputOverlay extends ConsumerStatefulWidget {
  final FlameGame game;

  const PasswordInputOverlay({super.key, required this.game});

  @override
  ConsumerState<PasswordInputOverlay> createState() =>
      _PasswordInputOverlayState();
}

class _PasswordInputOverlayState extends ConsumerState<PasswordInputOverlay> {
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';
  bool _showMessage = false;
  Color _messageColor = Colors.white;
  final FocusNode _focusNode = FocusNode();

  // 用於顯示提示信息
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // 確保清空原有輸入
    _passwordController.text = '';

    // 強制獲取焦點
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    // 清理焦點和控制器
    _focusNode.unfocus();
    _focusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 強制關閉覆蓋層並釋放焦點
  void _closeOverlay() {
    // 清空輸入
    _passwordController.clear();

    // 強制釋放焦點
    _focusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    // 延遲關閉，確保焦點釋放
    Future.delayed(const Duration(milliseconds: 50), () {
      if (widget.game.overlays.isActive('PasswordInputOverlay')) {
        widget.game.overlays.remove('PasswordInputOverlay');

        // 重新將焦點交還給遊戲
        gameFocusNode.requestFocus();
      }
    });
  }

  // 驗證密碼並給予獎勵
  void _verifyPassword() {
    final password = _passwordController.text.trim();

    // 清空輸入框
    _passwordController.clear();

    // 檢查是否是在神秘走廊中開啟寶箱
    if (widget.game is NightAndRainGame) {
      final game = widget.game as NightAndRainGame;

      // 如果在神秘走廊，尋找寶箱
      if (game.dungeonManager?.currentRoomId == 'secret_corridor') {
        // 尋找場景中的寶箱
        final treasureChests =
            game.gameWorld.children
                .whereType<TreasureChestComponent>()
                .toList();

        if (treasureChests.isNotEmpty) {
          // 嘗試用密碼開啟寶箱
          if (treasureChests.first.tryOpen(password)) {
            _showFeedbackMessage('寶箱開啟成功！', Colors.green);
            _closeOverlay();
            return;
          } else {
            _showFeedbackMessage('密碼錯誤，寶箱沒有反應...', Colors.red);
            return;
          }
        }
      }
    }

    // 獲取物品數據
    final itemsData = ref.read(itemsDataProvider);
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final playerNotifier = ref.read(playerProvider.notifier);

    // 根據不同的密碼給予不同的獎勵
    switch (password) {
      case '0510': // 頂級狙擊槍密碼
        // 檢查是否已有此武器
        if (inventoryNotifier.hasItem('sniper_gold')) {
          _showFeedbackMessage('你已經擁有頂級狙擊槍了！', Colors.yellow);
        } else {
          // 添加頂級狙擊槍
          final sniperGold = itemsData['sniper_gold'] as RangedWeapon;
          inventoryNotifier.addItem(sniperGold);
          _showFeedbackMessage('獲得了頂級狙擊槍！', Colors.green);
        }
        break;

      case '0124': // 大量藥水和金幣密碼
        // 添加高級紅藥水 x5
        for (int i = 0; i < 5; i++) {
          final healthPotionPremium =
              itemsData['health_potion_legendary'] as Consumable;
          inventoryNotifier.addItem(healthPotionPremium);
        }

        // 添加高級藍藥水 x5
        for (int i = 0; i < 5; i++) {
          final manaPotionPremium =
              itemsData['mana_potion_legendary'] as Consumable;
          inventoryNotifier.addItem(manaPotionPremium);
        }

        // 添加10000金幣
        playerNotifier.addMoney(10000);

        _showFeedbackMessage('獲得了5瓶高級紅藥水、5瓶高級藍藥水和10000金幣！', Colors.green);
        break;

      default:
        _showFeedbackMessage('無效的密碼，請再試一次', Colors.red);
        break;
    }

    // 處理完後立即請求焦點，維持輸入狀態
    FocusScope.of(context).requestFocus(_focusNode);
  }

  // 處理Enter按鍵提交
  void _handleSubmit([String? value]) {
    _verifyPassword();
  }

  // 顯示反饋信息
  void _showFeedbackMessage(String message, Color color) {
    setState(() {
      _message = message;
      _messageColor = color;
      _showMessage = true;
    });

    // 3秒後隱藏信息
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });
  }

  // 處理按鍵事件，特別是Escape鍵
  void _handleKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _closeOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: KeyboardListener(
        focusNode: FocusNode(), // 使用單獨的焦點節點來處理原始鍵盤事件
        onKeyEvent: _handleKeyEvent,
        child: Material(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: screenSize.width * 0.4,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade700, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade900.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 標題
                  const Text(
                    '夜的異次元包包',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 說明文字
                  const Text(
                    '輸入密碼獲取特殊物品',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),

                  // 密碼輸入框
                  Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        // 如果失去焦點，重新獲取焦點
                        Future.microtask(
                          () => FocusScope.of(context).requestFocus(_focusNode),
                        );
                      }
                    },
                    child: TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: '請輸入密碼...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.blue.shade900.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.blue.shade700),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.blue.shade400,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.key,
                          color: Colors.white70,
                        ),
                      ),
                      textAlign: TextAlign.center,
                      autofocus: true,
                      onSubmitted: _handleSubmit,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 反饋信息
                  if (_showMessage)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _messageColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _messageColor),
                      ),
                      child: Text(
                        _message,
                        style: TextStyle(
                          color: _messageColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 按鈕行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 確認按鈕
                      ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('確認'),
                      ),

                      // 取消按鈕
                      ElevatedButton(
                        onPressed: _closeOverlay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('關閉'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
