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
        name: '幸運星-蕾絲翠',
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
            responses: [],
          ),

          // 占卜選項
          'astrology_options': Dialogue(
            npcText: '我能在星象中看到你的未來... 你想選擇哪種星盤指引？',
            responses: [
              PlayerResponse(
                text: '速度星盤：移動速度+30',
                nextDialogueId: 'speed_buff',
              ),
              PlayerResponse(
                text: '生命星盤：最大生命值+20',
                nextDialogueId: 'health_buff',
              ),
              PlayerResponse(text: '讓我再考慮一下', nextDialogueId: 'start'),
            ],
          ),

          // 速度加成
          'speed_buff': Dialogue(
            npcText: '速度星盤已啟用！感受星辰的速度在你體內流動吧。這個加成將持續5分鐘。',
            responses: [
              PlayerResponse(
                text: '謝謝你，蕾翠絲',
                nextDialogueId: 'after_buff',
                action: () {
                  // 此處的具體實現會在DialogOverlay中處理
                  // 因為需要訪問Riverpod提供者
                },
              ),
            ],
          ),

          // 生命加成
          'health_buff': Dialogue(
            npcText: '生命星盤已啟用！你的生命力得到了星辰的祝福。這個加成將持續5分鐘。',
            responses: [
              PlayerResponse(
                text: '感謝你的祝福',
                nextDialogueId: 'after_buff',
                action: () {
                  // 此處的具體實現會在DialogOverlay中處理
                },
              ),
            ],
          ),

          // 加成後對話
          'after_buff': Dialogue(
            npcText: '星辰之力會在暗中守護你。記得在加成消失前再回來找我。',
            responses: [
              PlayerResponse(text: '我還有其他問題', nextDialogueId: 'start'),
              PlayerResponse(text: '謝謝，我該走了', nextDialogueId: 'goodbye'),
            ],
          ),

          // 關於星象的知識
          'about_stars': Dialogue(
            npcText:
                '星象是宇宙對我們低語的方式。每個星座都有自己的力量和特質，影響著我們的命運軌跡。通過解讀星象，我們可以窺見命運的一角，甚至引導它朝著有利的方向發展。',
            responses: [
              PlayerResponse(
                text: '這太神奇了，我想進行占卜',
                nextDialogueId: 'astrology_options',
              ),
              PlayerResponse(text: '回到之前的話題', nextDialogueId: 'start'),
            ],
          ),

          // 關於占星師的背景
          'about_astrologer': Dialogue(
            npcText:
                '我從小就能看到別人看不見的光芒。起初我以為那只是幻覺，直到一位老占星師告訴我，那是星辰在向我傳遞訊息。我花了十年時間學習解讀這些訊息，現在我可以將這種力量用來幫助像你這樣的冒險者。',
            responses: [
              PlayerResponse(
                text: '我想體驗這種力量，進行占卜吧',
                nextDialogueId: 'astrology_options',
              ),
              PlayerResponse(text: '回到之前的話題', nextDialogueId: 'start'),
            ],
          ),

          // 告別
          'goodbye': Dialogue(
            npcText: '願星辰指引你的道路。無論何時需要指引，都可以回來找我。',
            responses: [],
          ),
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
              ..color = Colors.yellow.withOpacity(
                0.7 + random.nextDouble() * 0.3,
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
            if (starComponent.paint.color.opacity! > 0.5) {
              starComponent.paint.color = Colors.yellow.withOpacity(
                0.3 + random.nextDouble() * 0.4,
              );
            } else {
              starComponent.paint.color = Colors.yellow.withOpacity(
                0.7 + random.nextDouble() * 0.3,
              );
            }
          },
        ),
      );
    }
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
