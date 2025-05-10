import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'main_menu_screen.dart';
import '../../main.dart'; // 導入main.dart以獲取遊戲實例
import '../../components/portal_component.dart'; // 導入PortalType枚舉

class PuzzleCompletedScreen extends StatefulWidget {
  const PuzzleCompletedScreen({super.key});

  @override
  State<PuzzleCompletedScreen> createState() => _PuzzleCompletedScreenState();
}

class _PuzzleCompletedScreenState extends State<PuzzleCompletedScreen> {
  final List<String> _messages = [
    '恭喜非雨解開了藏鏡人的謎題啦XD',
    '藏鏡人湮沒在迷霧中，你已經獲得打開寶箱的權利',
    '接下來請你跟著主持人(夜)的指引，打開第三個禮物吧～',
    '按下 E 鍵或 Enter 鍵返回主選單...',
  ];

  // 目前顯示的文字
  List<String> _currentDisplayTexts = [];
  // 正在執行的計時器
  Timer? _typewriterTimer;
  // 目前處理到的訊息索引
  int _currentMessageIndex = 0;
  // 目前訊息顯示的字符數
  int _currentCharIndex = 0;
  // 是否完成了所有訊息的顯示
  bool _isMessageCompleted = false;
  // 文字打字速度 (毫秒/字)
  final int _typingSpeed = 70;

  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _setupKeyboardListening();
    _startTypewriterEffect();
  }

  void _startTypewriterEffect() {
    // 初始化空的顯示列表
    _currentDisplayTexts = List.filled(_messages.length, '');

    // 開始第一條消息的打字效果
    _typeNextCharacter();
  }

  void _typeNextCharacter() {
    if (_currentMessageIndex >= _messages.length) {
      // 所有訊息都顯示完成
      setState(() {
        _isMessageCompleted = true;
      });
      return;
    }

    final currentMessage = _messages[_currentMessageIndex];

    // 如果是空行，直接完成並轉到下一行
    if (currentMessage.isEmpty) {
      setState(() {
        _currentDisplayTexts[_currentMessageIndex] = '';
        _currentMessageIndex++;
        _currentCharIndex = 0;
      });
      _typeNextCharacter();
      return;
    }

    if (_currentCharIndex < currentMessage.length) {
      // 添加下一個字符
      setState(() {
        _currentDisplayTexts[_currentMessageIndex] = currentMessage.substring(
          0,
          _currentCharIndex + 1,
        );
        _currentCharIndex++;
      });

      // 計時器設置下一個字符的顯示
      _typewriterTimer = Timer(
        Duration(milliseconds: _typingSpeed),
        _typeNextCharacter,
      );
    } else {
      // 當前行顯示完成，移至下一行
      setState(() {
        _currentMessageIndex++;
        _currentCharIndex = 0;
      });

      // 短暫停頓後繼續下一行
      _typewriterTimer = Timer(
        Duration(milliseconds: _typingSpeed * 3),
        _typeNextCharacter,
      );
    }
  }

  void _completeAllMessages() {
    // 取消計時器
    _typewriterTimer?.cancel();

    // 立即顯示所有訊息
    setState(() {
      for (int i = 0; i < _messages.length; i++) {
        _currentDisplayTexts[i] = _messages[i];
      }
      _isMessageCompleted = true;
    });
  }

  void _setupKeyboardListening() {
    // 創建焦點節點並請求焦點
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode?.requestFocus();
    });

    // 設置鍵盤監聽
    ServicesBinding.instance.keyboard.addHandler(_handleKeyPress);
  }

  bool _handleKeyPress(KeyEvent event) {
    // 只處理按下事件
    if (event is KeyDownEvent) {
      // 檢查是否按下 E 鍵或 Enter 鍵
      if (event.logicalKey == LogicalKeyboardKey.keyE ||
          event.logicalKey == LogicalKeyboardKey.enter) {
        if (!_isMessageCompleted) {
          // 如果文字尚未完全顯示，則顯示所有文字
          _completeAllMessages();
        } else {
          // 文字已完全顯示，返回主選單
          _navigateToMainMenu();
        }
        return true; // 表示已處理此按鍵事件
      }
    }
    return false; // 未處理此按鍵事件，繼續傳遞給其他處理程序
  }

  void _navigateToMainMenu() {
    // 移除鍵盤處理程序
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);

    // 取消計時器
    _typewriterTimer?.cancel();

    // 解除焦點
    _focusNode?.unfocus(); // 重置遊戲實例
    if (gameInstance.dungeonManager != null) {
      // 使用特殊標識符調用傳送門返回主世界
      if (gameInstance.dungeonManager!.currentRoomId != null) {
        gameInstance.triggerPortalTransport(
          'puzzle_completed',
          PortalType.returnToMainWorld,
        );
      }

      // 清空地下城管理器
      gameInstance.dungeonManager = null;

      debugPrint('重置遊戲實例完成');
    }

    // 導航到主選單，使用淡入效果
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => const MainMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          var tween = Tween(begin: begin, end: end);
          var fadeAnimation = animation.drive(tween);

          return FadeTransition(opacity: fadeAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    // 確保在組件釋放時移除處理程序
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    _typewriterTimer?.cancel();
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // 點擊屏幕可以加速文字顯示或跳到主選單
        onTap: () {
          if (!_isMessageCompleted) {
            _completeAllMessages();
          } else {
            _navigateToMainMenu();
          }
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Stack(
            children: [
              // 背景效果 - 發光粒子
              CustomPaint(
                painter: StarfieldPainter(),
                size: MediaQuery.of(context).size,
              ),

              // 中央文字內容
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 成功圖標
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green.shade400,
                    ),
                    const SizedBox(height: 30),

                    // 文字訊息容器
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.cyan.shade800,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black.withOpacity(0.8),
                      ),
                      child: Column(
                        children:
                            _currentDisplayTexts.map((message) {
                              // 空行使用SizedBox
                              if (message.isEmpty) {
                                return const SizedBox(height: 10);
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Text(
                                  message,
                                  style: TextStyle(
                                    color:
                                        message.contains('恭喜')
                                            ? Colors.green.shade300
                                            : (message.contains('按下 E 鍵')
                                                ? Colors.cyan.shade300
                                                : Colors.white),
                                    fontSize: message.contains('恭喜') ? 20 : 16,
                                    fontWeight:
                                        message.contains('恭喜') ||
                                                message.contains('按下 E 鍵')
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 星空背景效果
class StarfieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final paint = Paint()..color = Colors.white;

    // 繪製一些發光的星星
    for (int i = 0; i < 150; i++) {
      final x = (random * (i + 1) * 0.0001) % size.width;
      final y = (random * (i + 2) * 0.0001) % size.height;
      final radius = ((random * (i + 3) * 0.0001) % 3) + 0.5;

      // 特殊顏色的星星
      if (i % 15 == 0) {
        paint.color = Colors.cyan.withOpacity(0.8);
      } else if (i % 23 == 0) {
        paint.color = Colors.purple.withOpacity(0.7);
      } else {
        paint.color = Colors.white.withOpacity(
          0.6 + (random * i * 0.0001) % 0.4,
        );
      }

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
