import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'npc_component.dart'; // 添加這行以導入 Dialogue 和 PlayerResponse 類別
import 'shopkeeper_npc.dart';

/// 米蟲商店員 - 販賣多種物品的商店NPC
class ShopkeeperBug extends ShopkeeperNpc {
  // 儲存精靈圖元件
  SpriteComponent? _spriteComponent;

  // 閒置動畫計時器
  Timer? _idleAnimationTimer;

  // 用於呼吸效果的振幅和頻率
  final double _breathAmplitude = 0.03;
  final double _breathFrequency = 1.2;

  // 記錄動畫時間
  double _animationTime = 0;
  // 米蟲商人的對話內容
  static const List<String> _bugConversations = [
    '五月特惠！全館只要一折！這是我們年度最大優惠！',
    '冒險者，現在是五月，所有商品只要原價的十分之一！',
    '這個月的特價活動讓我們的庫存快被掃空了！趕快挑選吧！',
    '我老闆說我瘋了，居然做一折特價，但我就是要回饋顧客！',
    '不要猶豫了！五月特價只有這個月，錯過就要等明年！',
    '今天運氣真好，你來的正是我們年度最大折扣的時候！',
  ];

  // 米蟲商店的商品列表
  static const List<String> _bugShopItems = [
    // 武器
    'pistol_ricebug', 'pistol_copper', 'pistol_silver',
    'shotgun_ricebug', 'shotgun_copper',
    'machinegun_ricebug',
    'sniper_ricebug',

    // 消耗品
    'health_potion', 'health_potion_premium',
    'mana_potion', 'mana_potion_premium',
  ];

  // 特別行銷活動 - 折扣
  bool _hasSpecialDiscount = false;

  ShopkeeperBug({
    required super.position,
    super.discountRate, // 預設無折扣
  }) : super(
         name: '米蟲商人',
         size: Vector2(64, 64),
         color: Colors.transparent, // 改為透明色，因為我們會使用精靈圖
         shopItems: _bugShopItems,
         shopName: '米蟲精品商店',
         greetings: const [
           '嘿，現在是米蟲教主誕辰！五月特惠全館一折！過來看看我的商品吧！',
           '聽說你要去地下城探險？趁著五月特價，把裝備都更新一下吧！',
           '五月限定！所有武器和藥水只要一折，絕對讓你驚喜！',
         ],
       );
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 判斷是否為5月，若是則啟動特殊折扣
    final now = DateTime.now();
    _hasSpecialDiscount = (now.month == 5);

    // 載入精靈圖
    final sprite = await Sprite.load('ShopkeeperBug.png');

    // 創建精靈圖元件
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2(72, 72), // 設置精靈圖大小
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
    _idleAnimationTimer!.start(); // 設定對話樹
    _setupDialogueTree();
  }

  // 設定對話樹
  void _setupDialogueTree() {
    // 隨機選擇一個對話內容
    final randomIndex = Random().nextInt(_bugConversations.length);
    final randomConversation = _bugConversations[randomIndex];
    final discountText =
        _hasSpecialDiscount
            ? '今天是你的幸運日！五月全館大特價！所有商品都只要原價的十分之一！這是本年度最低價！'
            : '我的價格絕對公道，物超所值！';

    // 設置對話樹
    dialogueTree.addAll({
      'start': Dialogue(
        npcText: randomConversation,
        responses: [
          PlayerResponse(text: '我想看看你的商品', nextDialogueId: 'show_shop'),
          PlayerResponse(
            text: '你今天有什麼特別優惠嗎？',
            nextDialogueId: 'discount_question',
          ),
          PlayerResponse(text: '你的商品品質如何？', nextDialogueId: 'quality_question'),
          PlayerResponse(
            text: '我先看看再說',
            nextDialogueId: null, // 結束對話
          ),
        ],
      ),
      'discount_question': Dialogue(
        npcText: discountText,
        responses: [
          PlayerResponse(text: '那我要看看你的商品', nextDialogueId: 'show_shop'),
          PlayerResponse(
            text: '我再考慮一下',
            nextDialogueId: null, // 結束對話
          ),
        ],
      ),
      'quality_question': Dialogue(
        npcText: '所有武器都經過親自測試，藥水也都是用最純淨的材料釀造的！品質保證！',
        responses: [
          PlayerResponse(text: '聽起來不錯，我想看看', nextDialogueId: 'show_shop'),
          PlayerResponse(
            text: '我再考慮一下',
            nextDialogueId: null, // 結束對話
          ),
        ],
      ),
      'show_shop': Dialogue(
        npcText:
            '這些都是我的精選商品，慢慢挑選，別客氣！${_hasSpecialDiscount ? '記得現在是五月特價，所有商品只要一折，錯過就要等明年啦！' : ''}',
        responses: [
          PlayerResponse(
            text: '開始購物',
            action: openShop,
            nextDialogueId: null, // 結束對話
          ),
        ],
      ),
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新閒置動畫計時器
    _idleAnimationTimer?.update(dt);

    // 更新動畫時間
    _animationTime += dt;
  }

  // 更新呼吸動畫
  void _updateIdleAnimation() {
    if (_spriteComponent == null) return;

    // 使用正弦波創造簡單的呼吸效果
    final breathCycle = sin(_animationTime * _breathFrequency);

    // 垂直方向的呼吸效果
    final verticalBreath = breathCycle * _breathAmplitude;

    // 呼吸時的輕微上移效果
    final verticalOffset = verticalBreath * 3;

    // 應用簡單的上下移動和縮放效果
    _spriteComponent!.scale = Vector2(
      1.0, // 水平方向保持不變
      1.0 + verticalBreath, // 垂直方向輕微縮放
    );

    // 添加輕微的上下移動
    _spriteComponent!.position = Vector2(0, -verticalOffset);
  }

  // 覆蓋父類的折扣率方法，實現特別折扣
  @override
  double get discountRate {
    // 如果是五月，提供超級優惠的0.1折
    if (_hasSpecialDiscount) {
      return 0.1; // 0.1折，超級優惠！
    }
    return super.discountRate; // 使用建構時設定的折扣率
  }

  // 覆蓋父類的對話方法，確保對話後能打開商店
  @override
  void startDialogue() {
    // 重設對話樹，以確保每次對話都是新的隨機內容
    _setupDialogueTree();

    // 呼叫父類的方法來啟動對話界面
    super.startDialogue();
  }
}
