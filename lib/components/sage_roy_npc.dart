// sage_roy_npc.dart - 智者羅伊NPC，展示新的對話系統功能
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../providers/player_provider.dart';
import '../providers/player_buffs_provider.dart';
import 'npc_component.dart';

/// 智者羅伊 - 一位擁有豐富知識的老者，可以與玩家進行深入對話
class SageRoyNpc extends NpcComponent {
  // 是否已經贈送過武器
  bool _hasGivenWeapon = false;

  // 是否已經給過智慧加成
  bool _hasGivenWisdomBuff = false;

  SageRoyNpc({required Vector2 position, Vector2? size})
    : super(
        name: '智者羅伊',
        position: position,
        size: size ?? Vector2(48, 48), // 稍微大一點的NPC
        color: Colors.purple.shade800, // 紫色代表智慧
        supportConversation: true, // 支持對話
        interactionRadius: 120, // 稍大的互動範圍
        greetings: [
          '年輕的冒險者，歡迎來到這片神秘的土地。',
          '願星辰指引你前進的道路...',
          '在這個世界中，知識往往比武器更強大。',
        ],
        // 創建完整的對話樹
        dialogueTree: {
          // 初始對話
          'start': Dialogue(
            npcText: '啊，你好，年輕的冒險者。我是羅伊，人們稱我為智者。你似乎有許多疑問...我能為你解答什麼呢？',
            responses: [
              PlayerResponse(
                text: '你能告訴我關於這個世界的事情嗎？',
                nextDialogueId: 'about_world',
              ),
              PlayerResponse(
                text: '我在尋找更強大的力量。',
                nextDialogueId: 'about_power',
              ),
              PlayerResponse(text: '你是如何成為智者的？', nextDialogueId: 'about_sage'),
            ],
          ),

          // 關於世界的對話
          'about_world': Dialogue(
            npcText:
                '這個世界被稱為「夜雨」，一個充滿神秘力量和危險的地方。古老的魔法與科技在這裡共存，而黑暗的力量也隨之而來。你需要變得更加強大，才能在這裡找到屬於自己的道路。',
            responses: [
              PlayerResponse(
                text: '有什麼地方我需要特別注意嗎？',
                nextDialogueId: 'world_dangers',
              ),
              PlayerResponse(
                text: '聽起來很危險，我需要更好的裝備。',
                nextDialogueId: 'about_equipment',
              ),
            ],
          ),

          // 世界的危險
          'world_dangers': Dialogue(
            npcText:
                '北方的森林中有許多未知的生物，東邊的山脈則隱藏著古老的遺跡。最危險的地方是西邊的「暗影谷」，那裡的敵人非常強大，沒有足夠的準備請不要冒然前往。',
            responses: [
              PlayerResponse(
                text: '謝謝你的提醒，我會小心的。',
                nextDialogueId: 'sage_advice',
              ),
            ],
          ),

          // 關於力量的對話
          'about_power': Dialogue(
            npcText: '力量有許多形式...武器、知識、甚至是朋友的幫助。你追求的是哪種力量呢？',
            responses: [
              PlayerResponse(
                text: '我需要更強的武器。',
                nextDialogueId: 'about_weapons',
              ),
              PlayerResponse(
                text: '智慧和知識才是我追求的。',
                nextDialogueId: 'about_wisdom',
              ),
            ],
          ),

          // 關於武器的對話
          'about_weapons': Dialogue(
            npcText:
                '武器固然重要，但使用者的技巧更為關鍵。金牛級和銀牛級的武器威力很強，但也要注意魔力消耗。如果你真的需要武器，或許我可以給你一些幫助...',
            responses: [
              PlayerResponse(
                text: '如果可以，我很需要你的幫助。',
                nextDialogueId: 'give_weapon',
              ),
              PlayerResponse(
                text: '謝謝建議，我會自己尋找的。',
                nextDialogueId: 'sage_advice',
              ),
            ],
          ),

          // 贈送武器
          'give_weapon': Dialogue(
            npcText: '既然如此，我會給你一把特別的武器。雖然它看起來普通，但蘊含著特殊的力量。使用它時請記住，真正的力量來自內心。',
            responses: [
              PlayerResponse(
                text: '非常感謝！我會好好利用它的。',
                nextDialogueId: 'after_gift',
                // 在這裡將觸發武器贈送動作
              ),
            ],
          ),

          // 贈送後
          'after_gift': Dialogue(
            npcText: '願這把武器能幫助你度過難關。記住，在夜雨世界中，朋友和盟友同樣重要。',
            responses: [
              PlayerResponse(text: '我會記住這一點的。', nextDialogueId: 'sage_advice'),
            ],
          ),

          // 關於智慧
          'about_wisdom': Dialogue(
            npcText:
                '追求智慧是最高尚的道路。在這個世界上，有許多古老的知識等待被發現。如果你願意，我可以賜予你智慧的祝福，幫助你在戰鬥中更加冷靜和專注。',
            responses: [
              PlayerResponse(
                text: '我很樂意接受你的祝福。',
                nextDialogueId: 'give_wisdom_buff',
              ),
              PlayerResponse(text: '先不了，謝謝。', nextDialogueId: 'sage_advice'),
            ],
          ),

          // 給予智慧加成
          'give_wisdom_buff': Dialogue(
            npcText: '我將星辰的智慧賜予你，非雨。在接下來的時間裡，你將獲得額外的冷靜和專注，這會提高你的攻擊力。',
            responses: [
              PlayerResponse(
                text: '感受到力量在我體內流動...謝謝你！',
                nextDialogueId: 'after_buff',
                // 在這裡將觸發加成效果
              ),
            ],
          ),

          // 加成後
          'after_buff': Dialogue(
            npcText: '記住，智慧的力量來自於經驗和思考。即使沒有我的加持，你也能通過自己的努力獲得更強大的力量。',
            responses: [
              PlayerResponse(text: '謝謝你的教導。', nextDialogueId: 'sage_advice'),
            ],
          ),

          // 關於智者的來歷
          'about_sage': Dialogue(
            npcText:
                '我曾經也是像你一樣的冒險者，經歷了無數的險境和挑戰。隨著時間的推移，我發現知識和智慧比任何武器都更有價值。所以我選擇了這條路，希望能幫助像你這樣的年輕冒險者。',
            responses: [
              PlayerResponse(text: '你的經歷令人敬佩。', nextDialogueId: 'sage_past'),
            ],
          ),

          // 智者的過去
          'sage_past': Dialogue(
            npcText: '謝謝你的讚美。生命是一段漫長的旅程，每個人都有自己的道路要走。我相信你會找到屬於自己的答案。',
            responses: [
              PlayerResponse(text: '你有什麼建議給我嗎？', nextDialogueId: 'sage_advice'),
            ],
          ),

          // 智者的建議
          'sage_advice': Dialogue(
            npcText: '保持好奇心，尋找知識，與人為善。記住，在最黑暗的地方，往往藏著最珍貴的寶藏。如果你遇到困難，不要害怕尋求幫助。',
            responses: [
              PlayerResponse(
                text: '謝謝你的智慧分享，我該繼續我的旅程了。',
                nextDialogueId: 'goodbye',
              ),
            ],
          ),

          // 告別
          'goodbye': Dialogue(
            npcText: '願星辰指引你的道路，非雨。無論你走到哪裡，記住我在這裡等著聽你的故事。',
            responses: [],
            // 空的回應列表意味著對話結束
          ),
        },
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 額外添加一些視覺效果，讓NPC看起來更有特色
    // 例如，添加一個小圓圈代表法杖頂端的寶石
    add(
      CircleComponent(
        radius: 6,
        position: Vector2(size.x / 4, -size.y / 4),
        paint: Paint()..color = Colors.cyan,
      ),
    );
  }

  // 根據對話選擇執行特定動作
  void giveWeapon(covariant PlayerNotifier playerNotifier) {
    if (_hasGivenWeapon) return; // 確保只贈送一次

    // 這裡應該有增加武器到玩家背包的邏輯
    // playerNotifier.addWeapon(someSpecialWeapon);

    _hasGivenWeapon = true;
  }

  // 給予智慧加成
  void giveWisdomBuff(covariant PlayerBuffsNotifier buffsNotifier) {
    if (_hasGivenWisdomBuff) return; // 確保只加持一次

    // 添加一個攻擊力加成
    // buffsNotifier.addAttackBuff(15.0, duration: const Duration(minutes: 5));

    _hasGivenWisdomBuff = true;
  }
}
