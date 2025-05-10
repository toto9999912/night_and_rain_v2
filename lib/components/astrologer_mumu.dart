import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'npc_component.dart';

/// 姆姆占星員NPC
class AstrologerMumu extends NpcComponent {
  // 儲存精靈圖元件
  SpriteComponent? _spriteComponent;

  // 閒置動畫計時器
  Timer? _idleAnimationTimer;

  // 用於呼吸效果的振幅和頻率
  final double _breathAmplitude = 0.05;
  final double _breathFrequency = 1.5;

  // 記錄動畫時間
  double _animationTime = 0;

  // 閒置動畫狀態
  final int _idleState = 0;

  AstrologerMumu({required super.position})
    : super(
        name: '蕾絲翠',

        greetings: [
          '歡迎來占卜',
          '我收到水瓶使者的邀請過來的',
          '嗚...我是代班中～',
          '討厭T^T星軌抄寫員又不見了',
          '哈囉～非雨小姐，生日快樂',
          '你好，我來自星界神話',
        ],
        size: Vector2(64, 64), // 將大小從 40x40 增加到 64x64
        color: Colors.transparent, // 使用透明色，因為我們會使用精靈圖
        interactionRadius: 60, // 將互動範圍從 120 縮小到 80
        supportConversation: true,
        dialogueTree: {
          // 初始對話
          'start': Dialogue(
            npcText: '想知道運勢、幸運色嗎？快來找我吧！不準也可以當參考哦',
            nextDialogueId: 'talk_1',
          ),
          'talk_1': Dialogue(
            npcText: '哈囉～非雨小姐好久不見！生日快樂',
            nextDialogueId: 'talk_2',
          ),
          'talk_2': Dialogue(
            npcText: '【非雨】為什麼你會在這？你不會也能在這占卜吧？',
            nextDialogueId: 'talk_3',
          ),
          'talk_3': Dialogue(
            npcText: '當然～而且壽星可以免費占卜一次哦！',
            nextDialogueId: 'talk_４',
          ),
          // 旁白1
          'talk_４': Dialogue(
            npcText: '【非雨】你的抉擇',
            responses: [
              PlayerResponse(
                text: '這麼好，趕緊來占卜一下',
                nextDialogueId: 'astrology_talk',
              ),
              PlayerResponse(text: '讓我再考慮一下', nextDialogueId: 'goodbye'),
            ],
          ),

          // 占卜選項
          'astrology_talk': Dialogue(
            npcText:
                '【旁白】突然間，熟悉的感覺，你依然聽到有個聲音在你的耳邊呢喃，不過好像沒有其他人聽到，說不定這個聲音是來自你的心中？',
            nextDialogueId: 'astrology_talk2',
          ),
          'astrology_talk2': Dialogue(
            npcText: '【神祕的聲音】追尋命運的人啊！摸著自己的內心，誠實回答我的問題吧！',
            nextDialogueId: 'astrology_ask',
          ),
          'astrology_ask': Dialogue(
            npcText: '【神祕的聲音】想像你跟著最喜歡的人漫步在碧空海濱，突然地上長出一堆螺肉，這時候你會怎麼做？',
            nextDialogueId: 'astrology_options',
          ),

          'astrology_options': Dialogue(
            npcText: '【旁白】這些選擇，會有怎樣的結局呢？',
            responses: [
              PlayerResponse(
                text: '把螺肉苟到他眼睛上',
                nextDialogueId: 'speed_buff',
                action: () {
                  // 此處的具體實現會在DialogOverlay中處理
                },
              ),
              PlayerResponse(
                text: '陪著他一起把它吃光光',
                nextDialogueId: 'health_buff',
                action: () {
                  // 此處的具體實現會在DialogOverlay中處理
                },
              ),
            ],
          ),

          // 速度加成
          'speed_buff': Dialogue(
            npcText: '【神祕的聲音】老實說，你會選這個選項我是完全不意外',
            nextDialogueId: 'after_buff',
          ),

          // 生命加成
          'health_buff': Dialogue(
            npcText: '【神祕的聲音】恩～真的是這樣嗎？',
            nextDialogueId: 'after_buff',
          ),

          // 加成後對話
          'after_buff': Dialogue(
            npcText: '【旁白】奇妙的聲音再次在你耳邊響起，但因為你在空島聽過無數遍，所以並不會覺得哪裡奇怪',
            nextDialogueId: 'end_talk',
          ),

          // 關於星象的知識
          'end_talk': Dialogue(
            npcText:
                '【神祕的聲音】追尋命運的人啊！準備了解自己的命運了嗎？要記住，你的命運並不是已經被注定的，相信自己的力量，你的命運要靠你自己來開創！',
            responses: [
              PlayerResponse(text: '我準備了解我的命運了！', nextDialogueId: 'end_talk2'),
            ],
          ),
          'end_talk2': Dialogue(
            npcText:
                '【神祕的聲音】根據你的選擇，我幫你預測今天的你的運勢極好，對你最有利的顏色是『藍色』，幸運數字是『01』跟『20』，跟你最有默契的星座是『水瓶座』。',
            nextDialogueId: 'end_talk3',
          ),
          'end_talk3': Dialogue(npcText: '【神祕的聲音】呵～呵～你是不是在猶豫要不要相信呢？跟隨你自己的內心吧！'),
        },
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 載入精靈圖
    final sprite = await Sprite.load('AstrologerMumu.png');

    // 創建精靈圖元件
    _spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2(72, 72), // 將精靈圖大小從 48x48 增加到 72x72
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

    // 添加星星特效裝飾
    _addStarDecorations();
  }

  // 添加星星裝飾
  void _addStarDecorations() {
    // 添加多個不同大小的星星，圍繞在角色周圍
    final random = Random();

    for (int i = 0; i < 5; i++) {
      final starSize = 2.0 + random.nextDouble() * 4.0;
      final distance = 15.0 + random.nextDouble() * 15.0;
      final angle = random.nextDouble() * 2 * pi;

      final starPosition = Vector2(
        cos(angle) * distance,
        sin(angle) * distance - 10, // 稍微上移一點
      );

      final starComponent = CircleComponent(
        radius: starSize,
        position: starPosition,
        paint:
            Paint()
              ..color = Colors.yellow.withValues(
                alpha: 0.7 + random.nextDouble() * 0.3,
              ),
      );

      add(starComponent);

      // 為每個星星添加閃爍動畫
      final blinkPeriod = 0.5 + random.nextDouble() * 2.0; // 隨機閃爍間隔
      add(
        TimerComponent(
          period: blinkPeriod,
          repeat: true,
          onTick: () {
            if (starComponent.paint.color.opacity > 0.5) {
              starComponent.paint.color = Colors.yellow.withValues(
                alpha: 0.3 + random.nextDouble() * 0.4,
              );
            } else {
              starComponent.paint.color = Colors.yellow.withValues(
                alpha: 0.7 + random.nextDouble() * 0.3,
              );
            }
          },
        ),
      );
    }
    final textComponent = TextComponent(
      text: '幸運星',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontFamily: 'Cubic11', // 使用Cubic11字體
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
      position: Vector2(0, -size.y / 2 - 36),
    );
    add(textComponent);
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

    // 使用兩個不同頻率的正弦波來創造更自然的呼吸效果
    final breathCycle = sin(_animationTime * _breathFrequency);

    // 垂直方向的呼吸效果（較明顯）
    final verticalBreath = breathCycle * _breathAmplitude;

    // 水平方向的呼吸效果（較微弱）
    final horizontalBreath = breathCycle * (_breathAmplitude * 0.3);

    // 呼吸時的輕微上移效果（吸氣時身體微微上升）
    final verticalOffset = verticalBreath * 3;

    // 根據閒置狀態應用不同的變換
    switch (_idleState) {
      case 0: // 自然呼吸狀態
        // 非均勻縮放：垂直方向縮放大於水平方向
        _spriteComponent!.scale = Vector2(
          1.0 + horizontalBreath, // 水平方向輕微縮放
          1.0 + verticalBreath, // 垂直方向更明顯的縮放
        );

        // 添加輕微的上下移動
        _spriteComponent!.position = Vector2(0, -verticalOffset);

        // 呼吸時的輕微前傾/後仰（極其微小的角度）
        _spriteComponent!.angle = breathCycle * 0.01;
        break;

      // 其他狀態保持不變...
      case 1:
        _spriteComponent!.scale = Vector2(
          1.0 + horizontalBreath,
          1.0 + verticalBreath,
        );
        _spriteComponent!.position = Vector2(
          sin(_animationTime * 2) * 2,
          -verticalOffset,
        );
        break;

      case 2:
        // 為輕微縮放狀態也應用非均勻縮放
        final baseScale = 1.0 + verticalBreath * 1.2;
        _spriteComponent!.scale = Vector2(
          baseScale * 0.95, // 水平稍小
          baseScale, // 垂直保持原值
        );
        _spriteComponent!.position = Vector2(0, -verticalOffset * 0.7);
        break;
    }
  }
}
