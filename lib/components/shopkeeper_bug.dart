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
        supportConversation: true,
        conversations: [
          '歡迎光臨米蟲雜貨店！我是老闆米蟲，有什麼需要的嗎？',
          '我們店裡各種商品應有盡有，從武器到藥水，從裝備到食物，保證讓你滿意！',
          '最近森林深處的怪物越來越多，很多冒險者都在搶購我們的高級藥水。',
          '聽說你是新來的冒險者？第一次購物可以享受9折優惠哦！',
          '如果你找到了稀有材料，也可以帶來給我。我收購的價格絕對公道！',
        ],
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
