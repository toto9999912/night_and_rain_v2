// filepath: d:\game\night_and_rain_v2\lib\ui\overlays\dialog_overlay.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/main.dart';
import 'package:night_and_rain_v2/components/npc_component.dart';

/// 對話覆蓋層 - 提供彈出式對話介面
class DialogOverlay extends ConsumerStatefulWidget {
  final NightAndRainGame game;
  final NpcComponent npc;

  const DialogOverlay({super.key, required this.game, required this.npc});

  @override
  ConsumerState<DialogOverlay> createState() => _DialogOverlayState();
}

class _DialogOverlayState extends ConsumerState<DialogOverlay>
    with WidgetsBindingObserver {
  // 當前對話索引
  int _currentDialogIndex = 0;
  // 是否顯示所有文本
  bool _showFullText = false;
  // 文本動畫計時器
  late Timer _textAnimationTimer;
  // 當前顯示的文本
  String _displayedText = '';
  // 當前對話內容
  String get _currentDialog =>
      widget.npc.conversations.isNotEmpty &&
              _currentDialogIndex < widget.npc.conversations.length
          ? widget.npc.conversations[_currentDialogIndex]
          : '...';
  // 是否已經到達對話結尾
  bool get _isLastDialog =>
      _currentDialogIndex >= widget.npc.conversations.length - 1;

  NightAndRainGame get game => widget.game;
  NpcComponent get npc => widget.npc;

  @override
  void initState() {
    super.initState();
    // 註冊為觀察者以接收鍵盤事件
    WidgetsBinding.instance.addObserver(this);
    // 設置硬件鍵盤事件回調
    ServicesBinding.instance.keyboard.addHandler(_handleKeyboardEvent);

    // 初始化文本動畫計時器
    _textAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 30),
      _animateText,
    );
    _displayedText = '';
    _showFullText = false;
  }

  @override
  void dispose() {
    // 移除鍵盤事件監聽
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyboardEvent);
    // 移除觀察者
    WidgetsBinding.instance.removeObserver(this);
    // 停止文本動畫計時器
    _textAnimationTimer.cancel();
    super.dispose();
  }

  // 文本動畫效果
  void _animateText(Timer timer) {
    if (!_showFullText && _displayedText.length < _currentDialog.length) {
      setState(() {
        _displayedText = _currentDialog.substring(0, _displayedText.length + 1);
      });
    }
  }

  // 使用新的 HardwareKeyboard API 處理鍵盤事件
  bool _handleKeyboardEvent(KeyEvent event) {
    // 處理空格鍵或E鍵按下事件
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.keyE)) {
      // 如果文本尚未完全顯示，則立即顯示完整文本
      if (!_showFullText && _displayedText.length < _currentDialog.length) {
        setState(() {
          _displayedText = _currentDialog;
          _showFullText = true;
        });
        return true;
      }

      // 如果已是最後一段對話，則關閉對話框
      if (_isLastDialog) {
        game.overlays.remove('DialogOverlay');
        return true;
      }

      // 否則顯示下一段對話
      setState(() {
        _currentDialogIndex++;
        _displayedText = '';
        _showFullText = false;
      });
      return true;
    }

    // 返回false表示我們沒有處理這個事件，允許其他處理器處理
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 半透明背景
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              // 點擊背景，如果文本尚未完全顯示，則立即顯示完整文本
              if (!_showFullText &&
                  _displayedText.length < _currentDialog.length) {
                setState(() {
                  _displayedText = _currentDialog;
                  _showFullText = true;
                });
              } else if (_isLastDialog) {
                // 如果已是最後一段對話，則關閉對話框
                game.overlays.remove('DialogOverlay');
              } else {
                // 否則顯示下一段對話
                setState(() {
                  _currentDialogIndex++;
                  _displayedText = '';
                  _showFullText = false;
                });
              }
            },
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),

        // 對話框
        Positioned(left: 80, right: 80, bottom: 100, child: _buildDialogBox()),
      ],
    );
  }

  // 構建對話框
  Widget _buildDialogBox() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white30, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // NPC名稱和頭像
          Row(
            children: [
              // NPC頭像
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: npc.color.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white60, width: 2),
                ),
                child: Center(
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 16),
              // NPC名稱
              Text(
                npc.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              Spacer(),
              // 關閉按鈕
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => game.overlays.remove('DialogOverlay'),
                splashRadius: 20,
                tooltip: '關閉對話',
              ),
            ],
          ),

          const Divider(color: Colors.white24, thickness: 1, height: 30),

          // 對話內容
          Container(
            constraints: const BoxConstraints(minHeight: 100),
            child: Text(
              _displayedText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 繼續提示或結束提示
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLastDialog
                        ? Icons.check_circle_outline
                        : Icons.arrow_forward,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isLastDialog ? '結束對話' : '繼續',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
