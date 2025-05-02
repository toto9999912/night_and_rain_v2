import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'npc_component.dart';

/// 米蟲商店員NPC
class ShopkeeperBug extends NpcComponent {
  ShopkeeperBug({required super.position})
    : super(
        name: '米蟲商店員',
        size: Vector2(40, 40),
        color: Colors.amber,
        greetings: [
          '今天有特價商品喔！',
          '勇者大人，需要補給品嗎？',
          '最新的武器已經上架了！',
          '用過我們的藥水嗎？效果奇佳！',
          '歡迎來到米蟲雜貨店～',
          '我們接受金幣和寶石交易！',
        ],
        interactionRadius: 120,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加商店元素，例如小錢袋
    final coinBag = RectangleComponent(
      size: Vector2(15, 15),
      position: Vector2(-size.x / 2 - 10, 0),
      paint: Paint()..color = Colors.amberAccent,
    );

    add(coinBag);
  }
}
