import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'npc_component.dart';

/// 漫遊NPC - 在地圖上隨機移動的可愛米蟲村民
class WanderingNpc extends NpcComponent {
  // 移動速度
  final double _moveSpeed;

  // 移動方向
  Vector2 _direction = Vector2.zero();

  // 方向變更計時器
  late Timer _directionChangeTimer;

  // 閒置計時器（有時會停下來）
  late Timer _idleTimer;

  // 是否正在閒置
  bool _isIdle = false;

  // 用於呼吸動畫效果
  double _animationTime = 0;

  // 人物朝向 (1為右，-1為左)
  int _facingDirection = 1;

  // 顏色配置
  final Color _bodyColor; // 米蟲身體顏色
  final Color _accentColor; // 米蟲額外裝飾顏色
  final bool _isRound; // 圓形或橢圓形米蟲

  // 移動範圍
  final double _wanderRadius;

  WanderingNpc({
    required super.position,
    required super.name,
    List<String>? greetings,
    Color? color,
    double speed = 35.0, // 米蟲移動較慢
    double wanderRadius = 120.0,
  }) : _moveSpeed = speed,
       _wanderRadius = wanderRadius,
       _bodyColor = color ?? _getRandomRiceBugColor(),
       _accentColor = _getRandomAccentColor(),
       _isRound = Random().nextBool(), // 隨機決定米蟲形狀
       super(
         size: Vector2(40, 40),
         color: Colors.transparent, // 透明底色，用繪製方式渲染
         greetings:
             greetings ??
             const [
               '唔~今天也是懶洋洋的好日子~',
               '嗨！你要來一些特製的精力湯嗎？',
               '聽說去睡覺是恢復精力的最好方式！',
               '躺著就能賺錢，這是我的人生理想～',
               '米蟲精神，永不放棄...啊，好累，休息一下...',
             ],
         supportConversation: true, // 支持對話
       );

  // 獲取米蟲的隨機顏色
  static Color _getRandomRiceBugColor() {
    final List<Color> riceBugColors = [
      Color.fromARGB(255, 243, 231, 176), // 米黃色
      Color.fromARGB(255, 252, 239, 197), // 淺米色
      Color.fromARGB(255, 255, 245, 210), // 白米色
      Color.fromARGB(255, 250, 226, 156), // 金黃米色
      Color.fromARGB(255, 236, 217, 165), // 深米色
    ];

    return riceBugColors[Random().nextInt(riceBugColors.length)];
  }

  // 獲取裝飾用的隨機顏色
  static Color _getRandomAccentColor() {
    final List<Color> accentColors = [
      Color.fromARGB(255, 126, 188, 137), // 清新綠
      Color.fromARGB(255, 252, 186, 107), // 暖橙色
      Color.fromARGB(255, 142, 202, 230), // 天空藍
      Color.fromARGB(255, 251, 177, 172), // 淺粉色
      Color.fromARGB(255, 183, 156, 237), // 紫色
    ];

    return accentColors[Random().nextInt(accentColors.length)];
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 初始化原點位置 (保存起始位置)
    _originPosition = position.clone();

    // 初始化方向變更計時器（每3-8秒改變一次方向）
    _directionChangeTimer = Timer(
      Random().nextDouble() * 5 + 3,
      onTick: _changeDirection,
      repeat: true,
    );

    // 初始化閒置計時器（米蟲懶惰，經常停下來休息）
    _idleTimer = Timer(
      Random().nextDouble() * 8 + 4,
      onTick: _toggleIdle,
      repeat: true,
    );

    // 初始方向
    _changeDirection();

    // 啟動計時器
    _directionChangeTimer.start();
    _idleTimer.start();
  }

  // 保存原點位置，用於限制移動範圍
  late final Vector2 _originPosition;

  @override
  void update(double dt) {
    super.update(dt);

    // 更新計時器
    _directionChangeTimer.update(dt);
    _idleTimer.update(dt);

    // 更新動畫時間
    _animationTime += dt;

    // 如果不在閒置狀態，則移動
    if (!_isIdle) {
      // 計算位移
      final movement = _direction * _moveSpeed * dt;
      position.add(movement);

      // 更新朝向
      if (_direction.x > 0) {
        _facingDirection = 1;
      } else if (_direction.x < 0) {
        _facingDirection = -1;
      }

      // 檢查是否超出移動範圍
      if (position.distanceTo(_originPosition) > _wanderRadius) {
        // 如果超出範圍，修改方向朝向原點
        _direction = (_originPosition - position)..normalize();
      }
    }
  }

  // 改變移動方向
  void _changeDirection() {
    // 如果正在閒置，不改變方向
    if (_isIdle) return;

    // 檢查是否離原點太遠
    if (position.distanceTo(_originPosition) > _wanderRadius * 0.8) {
      // 如果接近邊界，有70%機會往回走
      if (Random().nextDouble() < 0.7) {
        _direction = (_originPosition - position)..normalize();
        return;
      }
    }

    // 隨機方向，但傾向於較慢的移動（米蟲懶散）
    final angle = Random().nextDouble() * 2 * pi;
    _direction = Vector2(cos(angle), sin(angle));

    // 減弱方向向量，使移動更慢更隨意
    _direction.scale(0.5 + Random().nextDouble() * 0.5);

    // 重置計時器時間
    _directionChangeTimer.limit = Random().nextDouble() * 5 + 3;
  }

  // 切換閒置狀態
  void _toggleIdle() {
    _isIdle = !_isIdle;

    if (_isIdle) {
      // 進入閒置狀態，2-6秒後自動退出（米蟲喜歡休息）
      _idleTimer.limit = Random().nextDouble() * 4 + 2;
      _direction = Vector2.zero();
    } else {
      // 退出閒置狀態，4-12秒後可能再次進入
      _idleTimer.limit = Random().nextDouble() * 8 + 4;
      _changeDirection();
    }
  }

  @override
  void render(Canvas canvas) {
    // 保存當前狀態以便還原
    canvas.save();

    // 計算呼吸效果 - 米蟲呼吸慢而深
    final breathOffset = sin(_animationTime * 0.8) * 3;

    // 移動效果
    double bounceOffset = 0;
    if (!_isIdle && _direction.length > 0.1) {
      // 米蟲蠕動的彈跳效果
      bounceOffset = sin(_animationTime * 6) * 1.5;
    }

    // 移動畫布到元件中心
    canvas.translate(size.x / 2, size.y / 2 + bounceOffset);

    // 如果朝向左邊，水平翻轉
    if (_facingDirection < 0) {
      canvas.scale(-1, 1);
    }

    // 繪製可愛的米蟲
    _drawRiceBug(canvas, breathOffset);

    // 恢復畫布狀態
    canvas.restore();

    // 調用父類的render方法來處理其他繪製，如互動範圍指示器等
    super.render(canvas);
  }

  // 繪製可愛的米蟲
  void _drawRiceBug(Canvas canvas, double breathOffset) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // 米蟲身體尺寸 (根據呼吸效果輕微縮放)
    final bodyWidthBase = size.x * 0.75;
    final bodyHeightBase = size.y * 0.65;

    final bodyWidth = bodyWidthBase + breathOffset * 0.3;
    final bodyHeight = bodyHeightBase - breathOffset * 0.2;

    // 米蟲身體
    paint.color = _bodyColor;

    if (_isRound) {
      // 圓形米蟲
      canvas.drawCircle(Offset(0, 0), bodyWidth * 0.5, paint);
    } else {
      // 橢圓形米蟲
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, 0),
          width: bodyWidth,
          height: bodyHeight,
        ),
        paint,
      );
    }
    // 米蟲眼睛 - 修改為更小、更可愛的樣式
    paint.color = Colors.black;
    // 調整眼睛位置，稍微向上移動一點
    final eyeY = -bodyHeight * 0.18;
    // 調整眼睛間距，讓眼睛更靠近
    final eyeDistanceX = bodyWidth * 0.15;

    // 大幅減小眼睛尺寸，改為更小巧的點狀
    final eyeSize = 2.0 - breathOffset * 0.08;

    // 左眼
    canvas.drawCircle(Offset(-eyeDistanceX, eyeY), eyeSize, paint);
    // 右眼
    canvas.drawCircle(Offset(eyeDistanceX, eyeY), eyeSize, paint);

    // 可選：添加眼睛反光點，增加可愛度
    paint.color = Colors.white;
    final highlightSize = eyeSize * 0.4;
    canvas.drawCircle(
      Offset(-eyeDistanceX + 0.5, eyeY - 0.5),
      highlightSize,
      paint,
    );
    canvas.drawCircle(
      Offset(eyeDistanceX + 0.5, eyeY - 0.5),
      highlightSize,
      paint,
    );

    // 微笑嘴巴
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;

    // 微笑強度隨呼吸變化
    final smileHeight = 6 + breathOffset * 0.5;

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, eyeY + bodyHeight * 0.2),
        width: bodyWidth * 0.4,
        height: smileHeight,
      ),
      0,
      pi,
      false,
      paint,
    );

    // 在米蟲身上添加裝飾花紋
    paint.style = PaintingStyle.fill;
    paint.color = _accentColor;

    if (_isRound) {
      // 圓形花紋
      for (int i = 0; i < 3; i++) {
        final angle = pi / 6 + i * pi / 4;
        final spotX = cos(angle) * bodyWidth * 0.3;
        final spotY = sin(angle) * bodyHeight * 0.3;

        canvas.drawCircle(
          Offset(spotX, spotY + bodyHeight * 0.1),
          bodyWidth * 0.08,
          paint,
        );
      }
    } else {
      // 橢圓形花紋
      for (int i = 0; i < 3; i++) {
        final spotX = -bodyWidth * 0.2 + i * bodyWidth * 0.2;
        final spotY = bodyHeight * 0.1;

        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(spotX, spotY),
            width: bodyWidth * 0.16,
            height: bodyHeight * 0.12,
          ),
          paint,
        );
      }
    }

    // 繪製小觸角
    paint.color = _bodyColor.withOpacity(0.8);
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;

    // 左觸角
    final antennaPath1 =
        Path()
          ..moveTo(-bodyWidth * 0.2, -bodyHeight * 0.3)
          ..quadraticBezierTo(
            -bodyWidth * 0.3,
            -bodyHeight * 0.5,
            -bodyWidth * 0.25,
            -bodyHeight * 0.55,
          );
    canvas.drawPath(antennaPath1, paint);

    // 右觸角
    final antennaPath2 =
        Path()
          ..moveTo(bodyWidth * 0.2, -bodyHeight * 0.3)
          ..quadraticBezierTo(
            bodyWidth * 0.3,
            -bodyHeight * 0.5,
            bodyWidth * 0.25,
            -bodyHeight * 0.55,
          );
    canvas.drawPath(antennaPath2, paint);

    // 觸角頂端小圓點
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-bodyWidth * 0.25, -bodyHeight * 0.55), 2, paint);
    canvas.drawCircle(Offset(bodyWidth * 0.25, -bodyHeight * 0.55), 2, paint);
  }

  // 走路時的波浪函數
  double bounceWave(double phase) {
    if (_isIdle || _direction.length < 0.1) return 0;
    return sin(_animationTime * 6 + phase) * 1.5;
  }
}
