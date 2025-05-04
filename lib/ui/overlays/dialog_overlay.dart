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
import '../../providers/player_provider.dart'; // 添加player provider引用

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

  // 當前顯示的玩家回應（如果有）
  String? _playerResponse;

  // 對話選項
  List<PlayerResponse> _dialogResponses = [];

  // 是否顯示選項
  bool _showOptions = false;

  // 對話歷史記錄
  List<Map<String, String>> _dialogueHistory = [];

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
    } else if (widget.npc.dialogueTree.isNotEmpty) {
      // 如果有對話樹，使用交互式對話模式
      _loadDialogueFromTree();
    } else {
      // 標準對話
      _selectRandomDialogue();
    }
  }

  // 從對話樹加載對話
  void _loadDialogueFromTree() {
    final dialogue = widget.npc.getCurrentDialogue();
    if (dialogue == null) {
      // 如果沒有當前對話，默認使用隨機對話
      _selectRandomDialogue();
      return;
    }

    setState(() {
      _currentDialogue = dialogue.npcText;
      _dialogResponses = dialogue.responses;
      _showOptions = dialogue.responses.isNotEmpty;
      _playerResponse = null; // 清除玩家回應顯示

      // 將NPC對話添加到歷史記錄
      _addToDialogueHistory(speaker: widget.npc.name, text: _currentDialogue);
    });

    // 如果沒有玩家回應選項但有下一個對話ID，延遲後自動加載下一個對話
    if (dialogue.responses.isEmpty && dialogue.nextDialogueId != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          widget.npc.setAndGetDialogue(dialogue.nextDialogueId!);
          _loadDialogueFromTree();
        }
      });
    }
  }

  // 選擇玩家回應後處理
  void _handlePlayerResponse(PlayerResponse response) {
    final playerName = ref.read(playerProvider).name;

    setState(() {
      _playerResponse = response.text;
      _showOptions = false;

      // 將玩家回應添加到歷史記錄
      _addToDialogueHistory(speaker: playerName, text: response.text);
    });

    // 如果有動作，執行動作
    if (response.action != null) {
      response.action!();
    }

    // 延遲後加載下一個對話
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && response.nextDialogueId != null) {
        widget.npc.setAndGetDialogue(response.nextDialogueId!);
        _loadDialogueFromTree();
      }
    });
  }

  // 添加對話到歷史記錄
  void _addToDialogueHistory({required String speaker, required String text}) {
    setState(() {
      _dialogueHistory.add({'speaker': speaker, 'text': text});

      // 限制歷史記錄長度，保留最近的5條
      if (_dialogueHistory.length > 5) {
        _dialogueHistory.removeAt(0);
      }
    });
  }

  void _initializeAstrologerDialogue() {
    setState(() {
      _currentDialogue = '我能在星象中看到你的未來... 你想選擇哪種星盤指引？';
      _showOptions = true;
      _dialogResponses = [
        PlayerResponse(
          text: '速度星盤：移動速度+30',
          action: () {
            _applySpeedBuff();
          },
        ),
        PlayerResponse(
          text: '生命星盤：最大生命值+20',
          action: () {
            _applyHealthBuff();
          },
        ),
      ];

      // 將NPC對話添加到歷史記錄
      _addToDialogueHistory(speaker: widget.npc.name, text: _currentDialogue);
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

      // 將NPC回應添加到歷史記錄
      _addToDialogueHistory(speaker: widget.npc.name, text: _currentDialogue);
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

      // 將NPC回應添加到歷史記錄
      _addToDialogueHistory(speaker: widget.npc.name, text: _currentDialogue);
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

        // 將NPC對話添加到歷史記錄
        _addToDialogueHistory(speaker: widget.npc.name, text: _currentDialogue);
      });
    } else if (widget.npc.greetings.isNotEmpty) {
      // 如果沒有對話，則使用問候語
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % widget.npc.greetings.length;
      setState(() {
        _currentDialogue = widget.npc.greetings[randomIndex];
        _showOptions = false;

        // 將NPC對話添加到歷史記錄
        _addToDialogueHistory(speaker: widget.npc.name, text: _currentDialogue);
      });
    } else {
      // 如果都沒有，使用默認文本
      setState(() {
        _currentDialogue = '你好，冒險者！';
        _showOptions = false;

        // 將NPC對話添加到歷史記錄
        _addToDialogueHistory(speaker: widget.npc.name, text: _currentDialogue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 獲取玩家名稱
    final playerName = ref.watch(playerProvider).name;

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
            bottom: 80,
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
                  // 對話歷史記錄
                  if (_dialogueHistory.isNotEmpty) ...[
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final entry in _dialogueHistory)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "${entry['speaker']}: ",
                                        style: TextStyle(
                                          color:
                                              entry['speaker'] == playerName
                                                  ? Colors.cyan
                                                  : Colors.yellow,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      TextSpan(
                                        text: entry['text'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white30, height: 16),
                  ],

                  // 當前對話
                  if (_currentDialogue.isNotEmpty) ...[
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "${widget.npc.name}: ",
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: _currentDialogue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 當前玩家回應（如果有）
                  if (_playerResponse != null) ...[
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "$playerName: ",
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: _playerResponse!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 玩家選項按鈕（如果有）
                  if (_showOptions) ...[
                    const SizedBox(height: 8),
                    for (final response in _dialogResponses)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ElevatedButton(
                          onPressed: () => _handlePlayerResponse(response),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade700,
                            minimumSize: const Size(double.infinity, 0),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            response.text,
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

                      if (!_showOptions && widget.npc.dialogueTree.isEmpty) ...[
                        const SizedBox(width: 12),

                        // "換個話題"按鈕 - 僅在非選項模式下顯示，且僅適用於非對話樹模式
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
                          // 重置對話狀態
                          widget.npc.resetDialogue();
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
