import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'npc_component.dart';

/// 姆姆占星員NPC
class AstrologerMumu extends NpcComponent {
  AstrologerMumu({required super.position})
    : super(
        name: '姆姆占星員-蕾翠絲',
        size: Vector2(40, 40),
        color: Colors.purple,
        greetings: [
          '我的蕾翠絲~~',
          '今天的星象對你非常有利！',
          '你的命運線顯示有趣的冒險即將開始...',
          '星辰透露，今天適合嘗試新事物。',
          '想了解你的未來嗎？',
        ],
        interactionRadius: 120,
        supportConversation: true,
        conversations: [
          '哎呀，命運的軌跡在你身上交織成美麗的圖案！',
          '我在星象中看到了你的潛力，勇敢的冒險者。',
          '大難臨頭之際，記得仰望夜空。星辰會指引你前進的方向。',
          '這個世界的秘密遠比你想像的要多。想要了解更多，就繼續你的旅程吧！',
          '如果你收集到了星辰碎片，可以帶來給我。我會為你解讀其中的力量。',
        ],
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加一些特殊的視覺元素，例如星星裝飾
    final starDecoration = CircleComponent(
      radius: 8,
      position: Vector2(size.x / 2, -size.y / 4),
      paint: Paint()..color = Colors.yellow,
    );

    add(starDecoration);
  }
}
