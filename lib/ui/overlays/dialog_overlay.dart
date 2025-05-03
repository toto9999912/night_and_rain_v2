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
import '../../components/astrologer_mumu.dart';
import '../../providers/player_buffs_provider.dart';

/// 對話選項模型
class DialogOption {
  final String text;
  final VoidCallback onSelect;

  DialogOption({required this.text, required this.onSelect});
}

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

  // 對話選項
  List<DialogOption> _dialogOptions = [];

  // 是否顯示選項
  bool _showOptions = false;

  // 是否是商店NPC
  bool get _isShopkeeper => widget.npc is ShopkeeperNpc;

  // 是否是占星員
  bool get _isAstrologer => widget.npc is AstrologerMumu;

  @override
  void initState() {
    super.initState();
    // 初始化對話
    _initializeDialogue();
  }

  void _initializeDialogue() {
    if (_isAstrologer) {
      // 占星員特殊對話
      _initializeAstrologerDialogue();
    } else {
      // 標準對話
      _selectRandomDialogue();
    }
  }

  void _initializeAstrologerDialogue() {
    setState(() {
      _currentDialogue = '我能在星象中看到你的未來... 你想選擇哪種星盤指引？';
      _showOptions = true;
      _dialogOptions = [
        DialogOption(
          text: '速度星盤：移動速度+30',
          onSelect: () {
            _applySpeedBuff();
          },
        ),
        DialogOption(
          text: '生命星盤：最大生命值+20',
          onSelect: () {
            _applyHealthBuff();
          },
        ),
      ];
    });
  }

  // 應用速度加成
  void _applySpeedBuff() {
    // 添加速度加成
    ref
        .read(playerBuffsProvider.notifier)
        .addSpeedBuff(30.0, duration: const Duration(minutes: 5));

    setState(() {
      _currentDialogue = '速度星盤已啟用！感受星辰的速度在你體內流動吧。這個加成將持續5分鐘。';
      _showOptions = false;
    });
  }

  // 應用生命值加成
  void _applyHealthBuff() {
    // 添加最大生命值加成
    ref
        .read(playerBuffsProvider.notifier)
        .addMaxHealthBuff(20.0, duration: const Duration(minutes: 5));

    setState(() {
      _currentDialogue = '生命星盤已啟用！你的生命力得到了星辰的祝福。這個加成將持續5分鐘。';
      _showOptions = false;
    });
  }

  void _selectRandomDialogue() {
    if (widget.npc.conversations.isNotEmpty) {
      // 從NPC的對話列表中隨機選擇一個
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch %
          widget.npc.conversations.length;
      setState(() {
        _currentDialogue = widget.npc.conversations[randomIndex];
        _showOptions = false;
      });
    } else if (widget.npc.greetings.isNotEmpty) {
      // 如果沒有對話，則使用問候語
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % widget.npc.greetings.length;
      setState(() {
        _currentDialogue = widget.npc.greetings[randomIndex];
        _showOptions = false;
      });
    } else {
      // 如果都沒有，使用默認文本
      setState(() {
        _currentDialogue = '你好，冒險者！';
        _showOptions = false;
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

                  // 選項按鈕（如果有）
                  if (_showOptions) ...[
                    for (final option in _dialogOptions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ElevatedButton(
                          onPressed: option.onSelect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            minimumSize: const Size(double.infinity, 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            option.text,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                      ),
                  ],

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

                      if (!_showOptions) ...[
                        const SizedBox(width: 12),

                        // "換個話題"按鈕 - 僅在非選項模式下顯示
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
                      ],

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
