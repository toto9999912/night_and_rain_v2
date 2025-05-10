import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'loading_screen.dart';

class IntroScreen extends StatefulWidget {
  final bool isBirthdaySpecial;

  const IntroScreen({super.key, this.isBirthdaySpecial = false});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with WidgetsBindingObserver {
  final List<String> _introMessages = [
    '哈囉！非雨',
    '我是福爾摩夜，因為蘋果怪客設下的蘋果力場使我無法進去協助你',
    '但我接下來說的話，請你務必要仔細聆聽！',
    '接下來，你即將探索神秘的Night and Rain世界',
    '尋找蘋果怪客、奪回被偷走的生日禮物，是我們的首要任務！',
    '在冒險開始前，這裡有一些重要的提示：',
    '• 你可以優先拆開二號禮物袋的黃色錦囊，裡面有我可以給你的相關協助',
    '• 在米蟲眷村收集可靠線索，了解蘋果怪客的情報',
    '• 米蟲商店提供各種武器和道具，別忘了準備充足再前往地下城',
    '• 按下WASD鍵可以上下左右移動',
    '• 按下C鍵可以打開背包，查看物品和裝備',
    '• 按下Q鍵可以快速切換武器，當然你也可以透過背包快速裝備武器到裝備欄',
    '• 滑鼠左鍵或是空白鍵可以進行射擊',
    '',
    '準備好了嗎？按下 E 鍵或 Enter 鍵開始你的冒險...',
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
  final int _typingSpeed = 200;

  FocusNode? _focusNode;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupKeyboardListening();
    _startTypewriterEffect();
  }

  void _startTypewriterEffect() {
    // 初始化空的顯示列表，大小與原始訊息列表相同
    _currentDisplayTexts = List.filled(_introMessages.length, '');

    // 開始第一條消息的打字效果
    _typeNextCharacter();
  }

  void _typeNextCharacter() {
    if (_currentMessageIndex >= _introMessages.length) {
      // 所有訊息都顯示完成
      setState(() {
        _isMessageCompleted = true;
      });
      return;
    }

    final currentMessage = _introMessages[_currentMessageIndex];

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
      for (int i = 0; i < _introMessages.length; i++) {
        _currentDisplayTexts[i] = _introMessages[i];
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

    // 確保在應用程式啟動時 HardwareKeyboard 已經初始化
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
          // 文字已完全顯示，進入遊戲
          _navigateToLoadingScreen();
        }
        return true; // 表示已處理此按鍵事件
      }
    }
    return false; // 未處理此按鍵事件，繼續傳遞給其他處理程序
  }

  void _navigateToLoadingScreen() {
    // 移除鍵盤處理程序
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);

    // 取消計時器
    _typewriterTimer?.cancel();

    // 解除焦點，但暫時不要釋放焦點節點
    _focusNode?.unfocus();

    // 導航到加載畫面，使用淡入效果
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                LoadingScreen(isBirthdaySpecial: widget.isBirthdaySpecial),
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

    // 不在此處調用 _focusNode?.dispose()，讓它在 dispose() 方法中處理
  }

  @override
  void dispose() {
    // 確保在組件釋放時移除處理程序和觀察者
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyPress);
    WidgetsBinding.instance.removeObserver(this);
    _typewriterTimer?.cancel(); // 取消文字打字效果計時器
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // 點擊屏幕可以加速文字顯示或進入遊戲
        onTap: () {
          if (!_isMessageCompleted) {
            _completeAllMessages();
          } else {
            _navigateToLoadingScreen();
          }
        },
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade800, width: 2),
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
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              message,
                              style: TextStyle(
                                color:
                                    message.startsWith('•')
                                        ? Colors.lightBlueAccent
                                        : (message.contains('按下 E 鍵')
                                            ? Colors.yellowAccent
                                            : Colors.white),
                                fontSize: message.contains('按下 E 鍵') ? 16 : 14,
                                fontWeight:
                                    message.contains('哈囉') ||
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
                const SizedBox(height: 30),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 當應用程式生命週期狀態改變時，確保焦點處理正確
    if (state == AppLifecycleState.resumed) {
      // 應用程式恢復時，重新請求焦點
      _focusNode?.requestFocus();
    }
  }
}
