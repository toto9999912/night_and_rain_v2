// mediterranean_man_npc.dart - 地中海50歲老人NPC
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'npc_component.dart';

/// 地中海50歲老人NPC，展示無歷史訊息的對話系統和玩家互動選項
class MediterraneanManNpc extends NpcComponent {
  MediterraneanManNpc({required super.position, Vector2? size})
    : super(
        name: '地中海50歲老人',
        size: size ?? Vector2(48, 48),
        color: Colors.brown.shade600,
        supportConversation: true, // 支持對話
        isInteractive: true,
        greetings: ['年輕人，過來聊聊天吧！', '看起來像是個有趣的冒險者！', '嘿！這邊！'],
        // 建立對話樹
        dialogueTree: {
          // 初始對話
          'start': Dialogue(
            npcText: '年輕人，願意聽個老骨頭的故事嗎？也許能學點什麼。',
            nextDialogueId: 'super',
          ),
          'super': Dialogue(
            npcText: '【非雨】 ',
            responses: [
              PlayerResponse(text: '反正我也閒著，說來聽聽。'),
              PlayerResponse(text: '不了，我很忙。', nextDialogueId: 'leave'),
            ],
          ),

          // 故事第一部分
          'story_part1': Dialogue(
            npcText:
                '我年輕時遇到一個女孩...我們一起走過風雨，笑過、吵過，也差點被一頭熊吃掉——她總是愛惡作劇，搞得我哭笑不得。可惜啊，後來……',
            nextDialogueId: 'narrator1',
          ),

          // 旁白1
          'narrator1': Dialogue(
            npcText: '【旁白】老人沉默片刻，轉身望向身後，一道孤單的背影在陽光下拉得老長……',
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
            npcText: '後來啊……我以為她離開了，結果她只是去準備「整我」的道具……',
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
            npcText: '欸欸欸！妳又來！我正講得動情呢，結果又被妳搗亂啦～',
            nextDialogueId: 'end',
          ),

          // 對話結束
          'end': Dialogue(
            npcText: '哈哈哈，年輕人，我的故事雖鬧，但幸福從來不是偶然，只有珍惜當下，才能抓住屬於自己的好結局。',
            responses: [
              PlayerResponse(text: '謝啦老哥，我會記住的。', nextDialogueId: 'leave'),
            ],
          ),

          // 離開對話
          'leave': Dialogue(npcText: '再見了，冒險者！別忘了，每段故事，都值得被好好聽完。'),
        },
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加老人的視覺效果
    add(MediterraneanManVisual(size: size.x));
  }
}

/// 地中海老人的視覺效果
class MediterraneanManVisual extends Component {
  final double size;

  MediterraneanManVisual({required this.size});

  @override
  void render(Canvas canvas) {
    // 繪製老人的圓形身體
    final bodyPaint = Paint()..color = Colors.brown.shade700;
    canvas.drawCircle(Offset.zero, size / 2, bodyPaint);

    // 繪製地中海禿頭 (只有周圍有頭髮)
    final headRadius = size * 0.3;
    final headPaint = Paint()..color = Colors.brown;
    canvas.drawCircle(Offset(0, -size * 0.25), headRadius, headPaint);

    // 繪製側邊頭髮
    final hairPaint = Paint()..color = Colors.grey.shade400;
    // 左側頭髮
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, -size * 0.25), radius: headRadius),
      3.8, // 開始角度
      2.0, // 掃過的角度
      true, // 是否連接中心
      hairPaint,
    );

    // 右側頭髮
    canvas.drawArc(
      Rect.fromCircle(center: Offset(0, -size * 0.25), radius: headRadius),
      4.5, // 開始角度
      2.0, // 掃過的角度
      true, // 是否連接中心
      hairPaint,
    );

    // 繪製鬍子
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -size * 0.1),
        width: headRadius * 1.2,
        height: headRadius * 0.8,
      ),
      hairPaint,
    );

    // 繪製眼睛
    final eyePaint = Paint()..color = Colors.black;
    canvas.drawCircle(
      Offset(-headRadius * 0.4, -size * 0.28),
      size * 0.05,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(headRadius * 0.4, -size * 0.28),
      size * 0.05,
      eyePaint,
    );
  }
}
