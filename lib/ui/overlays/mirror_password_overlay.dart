import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:night_and_rain_v2/main.dart';
import 'package:night_and_rain_v2/components/mirror_man_component.dart';
import 'package:night_and_rain_v2/ui/screens/puzzle_completed_screen.dart';

/// 鏡像人密碼鎖覆蓋層 - 專用於鏡像迴廊的密碼解謎
class MirrorPasswordOverlay extends ConsumerStatefulWidget {
  final FlameGame game;

  const MirrorPasswordOverlay({super.key, required this.game});

  @override
  ConsumerState<MirrorPasswordOverlay> createState() =>
      _MirrorPasswordOverlayState();
}

class _MirrorPasswordOverlayState extends ConsumerState<MirrorPasswordOverlay> {
  // 儲存輸入的密碼
  String _inputPassword = '';

  // 顯示的回饋訊息
  String _message = '';
  bool _showMessage = false;
  Color _messageColor = Colors.white;

  // 按鈕大小和間距
  final double _buttonSize = 70.0;
  final double _buttonSpacing = 10.0;

  // 最大密碼長度
  final int _maxPasswordLength = 4;

  // 是否正在進行動畫
  bool _isAnimating = false;

  // 焦點節點，用於捕獲鍵盤事件
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // 確保獲得焦點
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // 添加數字到密碼
  void _addDigit(int digit) {
    if (_inputPassword.length < _maxPasswordLength && !_isAnimating) {
      setState(() {
        _inputPassword += digit.toString();
      });

      // 如果達到最大長度，自動驗證
      if (_inputPassword.length == _maxPasswordLength) {
        _verifyPassword();
      }
    }
  }

  // 刪除最後一個數字
  void _deleteLastDigit() {
    if (_inputPassword.isNotEmpty && !_isAnimating) {
      setState(() {
        _inputPassword = _inputPassword.substring(0, _inputPassword.length - 1);
      });
    }
  }

  // 清空密碼
  void _clearPassword() {
    if (!_isAnimating) {
      setState(() {
        _inputPassword = '';
      });
    }
  }

  // 關閉覆蓋層
  void _closeOverlay() {
    if (widget.game.overlays.isActive('MirrorPasswordOverlay')) {
      widget.game.overlays.remove('MirrorPasswordOverlay');

      // 重新將焦點交還給遊戲
      gameFocusNode.requestFocus();
    }
  }

  // 驗證密碼
  void _verifyPassword() {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    // 檢查密碼
    if (widget.game is NightAndRainGame) {
      final game = widget.game as NightAndRainGame;
      final mirrorManComponents =
          game.gameWorld.children.whereType<MirrorManComponent>().toList();

      if (mirrorManComponents.isNotEmpty) {
        final mirrorMan = mirrorManComponents.first;

        // 根據密碼處理不同結果
        switch (_inputPassword) {
          case '0120': // 正確密碼
            _showFeedbackMessage('密碼正確！寶箱已出現...', Colors.green);
            Future.delayed(const Duration(milliseconds: 800), () {
              mirrorMan.onCorrectPasswordEntered();
              _closeOverlay();

              // 導航到解謎成功畫面
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (context, animation, secondaryAnimation) =>
                          const PuzzleCompletedScreen(),
                  transitionsBuilder: (
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ) {
                    const begin = 0.0;
                    const end = 1.0;
                    var tween = Tween(begin: begin, end: end);
                    var fadeAnimation = animation.drive(tween);

                    return FadeTransition(opacity: fadeAnimation, child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 800),
                ),
              );
            });
            break;
          case '0124': // 特殊日期1
            _showFeedbackMessage(
              '鏡中人顯得很開心，貌似很高興你始終記得這個日期，但它並不是正確答案。',
              Colors.amber,
            );
            // 幾秒後清空輸入
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() {
                  _inputPassword = '';
                  _isAnimating = false;
                });
              }
            });
            // 更新鏡中人對話
            mirrorMan.onSpecialPasswordEntered();
            break;

          case '0510': // 特殊日期2
            _showFeedbackMessage(
              '鏡中人淡然一笑，顯然早已知道你會使用這個日期。但它並不是正確答案',
              Colors.amber,
            );
            // 幾秒後清空輸入
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() {
                  _inputPassword = '';
                  _isAnimating = false;
                });
              }
            });
            // 更新鏡中人對話
            mirrorMan.onSpecialPasswordEntered();
            break;

          default:
            _showFeedbackMessage('密碼錯誤，請再試一次...', Colors.red);
            Future.delayed(const Duration(milliseconds: 800), () {
              setState(() {
                _inputPassword = '';
                _isAnimating = false;
              });
            });
        }
      }
    }
  }

  // 顯示反饋訊息
  void _showFeedbackMessage(String message, Color color) {
    setState(() {
      _message = message;
      _messageColor = color;
      _showMessage = true;
    });

    // 對於錯誤訊息，3秒後隱藏
    if (color == Colors.red) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showMessage = false;
            _isAnimating = false;
          });
        }
      });
    }
  }

  // 處理實體鍵盤輸入
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _closeOverlay();
      return;
    } // 處理數字鍵
    if (event.logicalKey == LogicalKeyboardKey.digit0 ||
        event.logicalKey == LogicalKeyboardKey.numpad0) {
      _addDigit(0);
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.digit1 ||
        event.logicalKey == LogicalKeyboardKey.numpad1) {
      _addDigit(1);
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.digit2 ||
        event.logicalKey == LogicalKeyboardKey.numpad2) {
      _addDigit(2);
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.digit3 ||
        event.logicalKey == LogicalKeyboardKey.numpad3) {
      _addDigit(3);
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.digit4 ||
        event.logicalKey == LogicalKeyboardKey.numpad4) {
      _addDigit(4);
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.digit5 ||
        event.logicalKey == LogicalKeyboardKey.numpad5) {
      _addDigit(5);
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.digit6 ||
        event.logicalKey == LogicalKeyboardKey.numpad6) {
      _addDigit(6);
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.digit7 ||
        event.logicalKey == LogicalKeyboardKey.numpad7) {
      _addDigit(7);
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.digit8 ||
        event.logicalKey == LogicalKeyboardKey.numpad8) {
      _addDigit(8);
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.digit9 ||
        event.logicalKey == LogicalKeyboardKey.numpad9) {
      _addDigit(9);
      return;
    }

    // 處理退格鍵
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _deleteLastDigit();
    }

    // 處理回車鍵
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_inputPassword.length == _maxPasswordLength) {
        _verifyPassword();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            width: screenSize.width * 0.35,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.cyan.shade400, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyan.shade700.withOpacity(0.5),
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
                  '鏡像世界的密碼鎖',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // 說明文字
                const Text(
                  '輸入四位數密碼以解開謎題',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 24),

                // 密碼顯示區域
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyan.shade700),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_maxPasswordLength, (index) {
                      // 決定是否顯示數字
                      final hasDigit = index < _inputPassword.length;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: 40,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                hasDigit
                                    ? Colors.cyan.shade900.withOpacity(0.7)
                                    : Colors.grey.shade800.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  hasDigit
                                      ? Colors.cyan.shade400
                                      : Colors.grey.shade600,
                              width: 1.5,
                            ),
                          ),
                          child:
                              hasDigit
                                  ? Text(
                                    _inputPassword[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                  : null,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 20),

                // 顯示回饋訊息
                if (_showMessage)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 20),
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
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // 數字鍵盤
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: _buttonSpacing,
                  runSpacing: _buttonSpacing,
                  children: [
                    // 數字1-9
                    for (int i = 1; i <= 9; i++) _buildNumberButton(i),

                    // 清除按鈕
                    _buildActionButton(
                      icon: Icons.clear_all,
                      color: Colors.orange,
                      onPressed: _clearPassword,
                    ),

                    // 數字0
                    _buildNumberButton(0),

                    // 退格按鈕
                    _buildActionButton(
                      icon: Icons.backspace,
                      color: Colors.red,
                      onPressed: _deleteLastDigit,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 底部按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 確認按鈕
                    ElevatedButton(
                      onPressed:
                          _inputPassword.length == _maxPasswordLength
                              ? _verifyPassword
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        disabledBackgroundColor: Colors.cyan.shade900
                            .withOpacity(0.3),
                      ),
                      child: const Text(
                        '確認',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // 取消按鈕
                    ElevatedButton(
                      onPressed: _closeOverlay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        '關閉',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 建立數字按鈕
  Widget _buildNumberButton(int number) {
    return SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: ElevatedButton(
        onPressed: _isAnimating ? null : () => _addDigit(number),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.cyan.shade800,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.cyan.shade600),
          ),
          disabledBackgroundColor: Colors.cyan.shade900.withOpacity(0.3),
        ),
        child: Text(
          number.toString(),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // 建立功能按鈕
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: ElevatedButton(
        onPressed: _isAnimating ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: color.withOpacity(0.8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color),
          ),
          disabledBackgroundColor: color.withOpacity(0.3),
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }
}
