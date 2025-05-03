// filepath: d:\game\night_and_rain_v2\lib\ui\overlays\dialog_overlay.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/main.dart';
import 'package:night_and_rain_v2/components/npc_component.dart';
import 'package:flame/game.dart';

import '../../components/npc_component.dart';
import '../../components/shopkeeper_npc.dart';

/// 與NPC對話的覆蓋層
class DialogOverlay extends ConsumerStatefulWidget {
  final FlameGame game;
  final NpcComponent npc;

  const DialogOverlay({Key? key, required this.game, required this.npc})
    : super(key: key);

  @override
  ConsumerState<DialogOverlay> createState() => _DialogOverlayState();
}

class _DialogOverlayState extends ConsumerState<DialogOverlay> {
  // 當前對話文本
  String _currentDialogue = '';

  // 是否是商店NPC
  bool get _isShopkeeper => widget.npc is ShopkeeperNpc;

  @override
  void initState() {
    super.initState();
    // 隨機選擇一個對話
    _selectRandomDialogue();
  }

  void _selectRandomDialogue() {
    if (widget.npc.conversations.isNotEmpty) {
      // 從NPC的對話列表中隨機選擇一個
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch %
          widget.npc.conversations.length;
      setState(() {
        _currentDialogue = widget.npc.conversations[randomIndex];
      });
    } else if (widget.npc.greetings.isNotEmpty) {
      // 如果沒有對話，則使用問候語
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % widget.npc.greetings.length;
      setState(() {
        _currentDialogue = widget.npc.greetings[randomIndex];
      });
    } else {
      // 如果都沒有，使用默認文本
      setState(() {
        _currentDialogue = '你好，冒險者！';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 半透明背景，用於點擊關閉對話
          GestureDetector(
            onTap: () => widget.game.overlays.remove('DialogOverlay'),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),

          // 對話框
          Positioned(
            bottom: 100,
            left: 50,
            right: 50,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NPC名稱
                  Text(
                    widget.npc.name,
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 對話內容
                  Text(
                    _currentDialogue,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // 操作按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 只有商店NPC才顯示"購物"按鈕
                      if (_isShopkeeper)
                        ElevatedButton(
                          onPressed: () {
                            // 關閉對話，打開商店
                            widget.game.overlays.remove('DialogOverlay');
                            (widget.npc as ShopkeeperNpc).openShop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('查看商店'),
                        ),
                      const SizedBox(width: 12),

                      // "換個話題"按鈕
                      OutlinedButton(
                        onPressed: _selectRandomDialogue,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white30),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          '換個話題',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // "離開"按鈕
                      ElevatedButton(
                        onPressed: () {
                          widget.game.overlays.remove('DialogOverlay');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('離開'),
                      ),
                    ],
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
