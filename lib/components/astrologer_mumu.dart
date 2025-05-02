import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'npc_component.dart';

/// 姆姆占星員NPC
class AstrologerMumu extends NpcComponent {
  AstrologerMumu({required Vector2 position})
    : super(
        name: '姆姆占星員',
        position: position,
        size: Vector2(40, 40),
        color: Colors.purple,
        greetings: [
          '歡迎來到星座屋！',
          '今天的星象對你非常有利！',
          '你的命運線顯示有趣的冒險即將開始...',
          '星辰透露，今天適合嘗試新事物。',
          '想了解你的未來嗎？',
        ],
        interactionRadius: 120,
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
