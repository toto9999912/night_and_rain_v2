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
            npcText: '年輕的冒險者阿，你想聽故事嗎',
            responses: [
              PlayerResponse(
                text: '反正我也很閒，就聽你講講吧',
                nextDialogueId: 'story_part1',
              ),
              PlayerResponse(text: '離開', nextDialogueId: 'leave'),
            ],
          ),

          // 故事第一部分
          'story_part1': Dialogue(
            npcText: '我年輕的時候遇上一個女孩，我們一起冒險，發生很多快樂的事情，她總是很喜歡整我...，但後來...唉',
            nextDialogueId: 'narrator1',
          ),

          // 旁白1
          'narrator1': Dialogue(
            npcText: '【旁白】老人默默轉向身後，孤單的背影，貌似預示著不好的結局',
            responses: [
              PlayerResponse(text: '繼續追問', nextDialogueId: 'player_question'),
              PlayerResponse(text: '離開', nextDialogueId: 'leave'),
            ],
          ),

          // 玩家追問
          'player_question': Dialogue(
            npcText: '【非雨】你們後來怎麼樣',
            nextDialogueId: 'story_part2',
          ),

          // 故事第二部分
          'story_part2': Dialogue(
            npcText: '後來阿...',
            nextDialogueId: 'narrator2',
          ),

          // 旁白2
          'narrator2': Dialogue(
            npcText: '【旁白】此時背後的房門突然傳出聲音',
            nextDialogueId: 'wife_speaks',
          ),

          // 妻子說話
          'wife_speaks': Dialogue(
            npcText: '【欸欸】傻夜你看這個燈泡好像你的頭哦，阿你還杵在外面幹嘛',
            nextDialogueId: 'final_part',
          ),

          // 最終部分
          'final_part': Dialogue(
            npcText: '我在整人阿，我之前被你整成這樣。我現在要加倍奉還！',
            nextDialogueId: 'end',
          ),

          // 對話結束
          'end': Dialogue(
            npcText: '哈哈哈，年輕人，別信了。生活總是充滿驚喜！',
            responses: [PlayerResponse(text: '離開', nextDialogueId: 'leave')],
          ),

          // 離開對話
          'leave': Dialogue(npcText: '再見了，冒險者！有空常來聊天！'),
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
