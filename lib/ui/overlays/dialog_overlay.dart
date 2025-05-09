import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/components/npc_component.dart';
import 'package:flame/game.dart';
import '../../components/shopkeeper_npc.dart';
import '../../components/astrologer_mumu.dart';
import '../../providers/player_buffs_provider.dart';
import '../../providers/player_provider.dart';

/// 與NPC對話的覆蓋層
class DialogOverlay extends ConsumerStatefulWidget {
  final FlameGame game;
  final NpcComponent npc;

  const DialogOverlay({super.key, required this.game, required this.npc});

  @override
  ConsumerState<DialogOverlay> createState() => _DialogOverlayState();
}

class _DialogOverlayState extends ConsumerState<DialogOverlay> {
  // 當前對話文本
  String _currentDialogue = '';

  // 對話選項
  List<PlayerResponse> _dialogResponses = [];

  // 是否顯示選項
  bool _showOptions = false;

  // 是否有下一個對話可用
  bool _hasNextDialogue = false;

  // 下一個對話的ID
  String? _nextDialogueId;

  // 是否是商店NPC
  bool get _isShopkeeper => widget.npc is ShopkeeperNpc;

  // 是否是占星員

  // 當前說話者名稱
  String _currentSpeaker = '';

  // 焦點節點，用於捕獲鍵盤事件
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 初始化對話
    _initializeDialogue();

    // 確保獲得焦點
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) {
        FocusScope.of(context).requestFocus(_focusNode);
        print('對話框請求焦點');
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _initializeDialogue() {
    if (widget.npc.dialogueTree.isNotEmpty) {
      // 如果有對話樹，使用交互式對話模式
      _loadDialogueFromTree();
    } else {
      // 如果沒有任何對話內容，顯示默認訊息
      setState(() {
        _currentDialogue = '你好，冒險者！';
        _currentSpeaker = widget.npc.name;
        _showOptions = false;
      });
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
      // 解析對話內容，檢查是否包含角色名和旁白
      final parsedDialogue = _parseDialogueText(dialogue.npcText);
      _currentDialogue = parsedDialogue.text;
      _currentSpeaker = parsedDialogue.speaker;

      _dialogResponses = dialogue.responses;
      _showOptions = dialogue.responses.isNotEmpty;

      // 設置下一個對話ID（如果有）
      _nextDialogueId = dialogue.nextDialogueId;
      _hasNextDialogue =
          dialogue.responses.isEmpty && dialogue.nextDialogueId != null;
    });
  }

  // 處理進入下一個對話
  void _proceedToNextDialogue() {
    if (_hasNextDialogue && _nextDialogueId != null) {
      widget.npc.setAndGetDialogue(_nextDialogueId!);
      _loadDialogueFromTree();
    }
  }

  // 解析對話文本，檢查是否包含角色前綴如【旁白】或【角色名】
  ParsedDialogue _parseDialogueText(String text) {
    final RegExp regex = RegExp(r'^\【(.*?)\】(.*)$');
    final match = regex.firstMatch(text);

    if (match != null && match.groupCount >= 2) {
      final speaker = match.group(1)!;
      final content = match.group(2)!.trim();
      return ParsedDialogue(speaker: speaker, text: content);
    }

    return ParsedDialogue(speaker: '', text: text);
  }

  // 選擇玩家回應後處理
  void _handlePlayerResponse(PlayerResponse response) {
    // 根據對話ID直接處理特殊操作
    if (widget.npc is AstrologerMumu) {
      final dialogueId = response.nextDialogueId;
      if (dialogueId == 'speed_buff') {
        _applySpeedBuff();
      } else if (dialogueId == 'health_buff') {
        _applyHealthBuff();
      }
    }

    setState(() {
      _showOptions = false;
      _hasNextDialogue = false;
    });

    // 如果有動作，執行動作
    if (response.action != null) {
      response.action!();
    }

    // 立即加載下一個對話，不再顯示玩家選擇的內容
    if (response.nextDialogueId != null) {
      widget.npc.setAndGetDialogue(response.nextDialogueId!);
      _loadDialogueFromTree();
    }
  }

  void _initializeAstrologerDialogue() {
    setState(() {
      _currentDialogue = '我能在星象中看到你的未來... 你想選擇哪種星盤指引？';
      _currentSpeaker = widget.npc.name;
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
      _currentSpeaker = widget.npc.name;
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
      _currentSpeaker = widget.npc.name;
      _showOptions = false;
    });
  }

  void _selectRandomDialogue() {
    if (widget.npc.greetings.isNotEmpty) {
      // 如果沒有對話，則使用問候語
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % widget.npc.greetings.length;
      setState(() {
        _currentDialogue = widget.npc.greetings[randomIndex];
        _currentSpeaker = widget.npc.name;
        _showOptions = false;
      });
    } else {
      // 如果都沒有，使用默認文本
      setState(() {
        _currentDialogue = '你好，冒險者！';
        _currentSpeaker = widget.npc.name;
        _showOptions = false;
      });
    }
  }

  // 處理鍵盤事件
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // 使用print輸出按下的鍵值以便於調試

      if (event.logicalKey == LogicalKeyboardKey.keyE) {
        // 按下E鍵時進入下一個對話
        if (_hasNextDialogue) {
          _proceedToNextDialogue();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 獲取玩家名稱
    final playerName = ref.watch(playerProvider).name;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Material(
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
                    // 當前對話
                    if (_currentDialogue.isNotEmpty) ...[
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  _currentSpeaker.isNotEmpty
                                      ? "$_currentSpeaker: "
                                      : "${widget.npc.name}: ",
                              style: TextStyle(
                                color:
                                    _currentSpeaker == '旁白'
                                        ? Colors.purple
                                        : _currentSpeaker == playerName
                                        ? Colors.cyan
                                        : Colors.yellow,
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

                    // 顯示「按E繼續」提示（當有下一個對話但沒有選項時）
                    if (_hasNextDialogue && !_showOptions) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade800.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '按 E 繼續',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // 操作按鈕
                    const SizedBox(height: 16),
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

                        if (!_showOptions &&
                            widget.npc.dialogueTree.isEmpty) ...[
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

                        // "繼續"按鈕 - 當有下一個對話時顯示
                        if (_hasNextDialogue) ...[
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _proceedToNextDialogue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('繼續'),
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
      ),
    );
  }
}

/// 解析後的對話數據
class ParsedDialogue {
  final String speaker;
  final String text;

  ParsedDialogue({required this.speaker, required this.text});
}
