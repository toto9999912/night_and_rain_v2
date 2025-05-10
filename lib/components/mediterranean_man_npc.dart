// mediterranean_man_npc.dart - 地中海50歲老人NPC
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'npc_component.dart';

/// 地中海50歲老人NPC，展示無歷史訊息的對話系統和玩家互動選項
class MediterraneanManNpc extends NpcComponent {
  // 儲存精靈圖元件
  SpriteComponent? _spriteComponent;

  // 閒置動畫計時器
  Timer? _idleAnimationTimer;

  // 用於呼吸效果的振幅和頻率
  final double _breathAmplitude = 0.04;
  final double _breathFrequency = 1.2;

  // 記錄動畫時間
  double _animationTime = 0;

  MediterraneanManNpc({required super.position, Vector2? size})
    : super(
        name: '地中海50歲老人',
        size: size ?? Vector2(64, 64),
        color: Colors.transparent, // 使用透明色，因為我們會使用精靈圖
        supportConversation: true, // 支持對話
        isInteractive: true,
        greetings: ['年輕人，過來聊聊天吧！', '我...我才不是50歲', '嘿！這邊！'],
        // 建立對話樹
        dialogueTree: {
          // 初始對話
          'start': Dialogue(
            npcText: '年輕人，願意聽個老頭的故事嗎？也許能學點什麼。',
            nextDialogueId: 'super',
          ),
          'super': Dialogue(
            npcText: '【非雨】蛤...可以不要嗎？ ',
            responses: [
              PlayerResponse(
                text: '反正我也閒著，說來聽聽。',
                nextDialogueId: 'story_part1',
              ),
              PlayerResponse(text: '不了，我很忙。', nextDialogueId: 'leave'),
            ],
          ),

          // 故事第一部分
          'story_part1': Dialogue(
            npcText:
                '我年輕時遇到一個很有趣女孩...我們一起走過闖蕩世界，是對方冒險的最佳拍檔，旅途中發生了許多刺激又好玩的冒險。她既壞心又善良，別看她慵懶總說自己是大懶蟲，她總會對該做的事情認真勤奮。可惜造化弄人阿...我們到最後卻...',
            nextDialogueId: 'narrator1',
          ),

          // 旁白1
          'narrator1': Dialogue(
            npcText: '【旁白】老人沉默片刻，轉身望向身後，一道孤單的背影在陽光下拉得老長，似乎在預示著這個故事最後將以悲劇收尾',
            responses: [
              PlayerResponse(
                text: '然後呢？你別吊我胃口啊。',
                nextDialogueId: 'player_question',
              ),
              PlayerResponse(text: '這太私人了，我不方便聽……', nextDialogueId: 'leave'),
            ],
          ),

          // 玩家追問
          'player_question': Dialogue(
            npcText: '【非雨】你們後來...發生了什麼？她還在你身邊嗎？',
            nextDialogueId: 'story_part2',
          ),

          // 故事第二部分
          'story_part2': Dialogue(
            npcText: '後來啊……嘿嘿',
            nextDialogueId: 'narrator2',
          ),

          // 旁白2
          'narrator2': Dialogue(
            npcText: '【旁白】就在這時，背後的老屋突然傳來一陣嘎啦聲響，一道熟悉又魔性的聲音響起。',
            nextDialogueId: 'wife_speaks',
          ),

          // 妻子說話
          'wife_speaks': Dialogue(
            npcText: '【謎之聲】欸欸！傻夜你快看，這顆燈泡是不是跟你禿頭一樣亮啊～',
            nextDialogueId: 'final_part',
          ),

          // 最終部分
          'final_part': Dialogue(
            npcText: '欸欸欸！妳又來！我正講到最精采的部分呢，結果又被妳搗亂啦～害我整人失敗了',
            nextDialogueId: 'end',
          ),

          // 對話結束
          'end': Dialogue(
            npcText: '哈哈哈，年輕人，我的故事雖然完美，但幸福從來不是必然，唯有雙方誠心相待，你們才能像我一樣抓住屬於自己的好結局。',
            responses: [
              PlayerResponse(text: '謝啦老先生，我會記住的。', nextDialogueId: 'leave'),
            ],
          ),

          // 離開對話
          'leave': Dialogue(npcText: '再見了，冒險者！別忘了，每段故事，都值得被好好聽完。'),
        },
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 載入精靈圖
    final sprite = await Sprite.load('MediterraneanMan.png');

    // 創建精靈圖元件
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2(72, 72), // 設定精靈圖大小
      anchor: Anchor.center,
    );

    // 添加精靈圖
    add(_spriteComponent!);

    // 初始化閒置動畫計時器
    _idleAnimationTimer = Timer(
      0.1, // 每0.1秒更新一次
      onTick: _updateIdleAnimation,
      repeat: true,
    );
    _idleAnimationTimer!.start();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新閒置動畫計時器
    _idleAnimationTimer?.update(dt);

    // 更新動畫時間
    _animationTime += dt;
  }

  void _updateIdleAnimation() {
    if (_spriteComponent == null) return;

    // 使用正弦波來創造呼吸效果
    final breathCycle = sin(_animationTime * _breathFrequency);

    // 垂直方向的呼吸效果（較明顯）
    final verticalBreath = breathCycle * _breathAmplitude;

    // 水平方向的呼吸效果（較微弱）
    final horizontalBreath = breathCycle * (_breathAmplitude * 0.3);

    // 呼吸時的輕微上移效果（吸氣時身體微微上升）
    final verticalOffset = verticalBreath * 3;

    // 自然呼吸狀態
    // 非均勻縮放：垂直方向縮放大於水平方向
    _spriteComponent!.scale = Vector2(
      1.0 + horizontalBreath, // 水平方向輕微縮放
      1.0 + verticalBreath, // 垂直方向更明顯的縮放
    );

    // 添加輕微的上下移動
    _spriteComponent!.position = Vector2(0, -verticalOffset);

    // 呼吸時的輕微前傾/後仰（極其微小的角度）
    _spriteComponent!.angle = breathCycle * 0.01;
  }
}
