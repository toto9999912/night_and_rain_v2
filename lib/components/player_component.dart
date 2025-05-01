import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/player_provider.dart';
import 'package:flame/events.dart' as flame_events;
import '../main.dart';

class PlayerComponent extends PositionComponent
    with
        KeyboardHandler,
        TapCallbacks,
        HasGameReference<NightAndRainGame>,
        PointerMoveCallbacks,
        RiverpodComponentMixin {
  final Set<LogicalKeyboardKey> _keysPressed = {};

  // 1. 將 weaponManager 宣告為可為空

  // 2. 新增初始化標記
  bool _weaponManagerInitialized = false;

  // 瞄準方向（默認向上）
  Vector2 aimDirection = Vector2(0, -1);

  // 鼠標位置追踪
  Vector2 _mousePosition = Vector2.zero();

  // 射擊控制
  bool _isShooting = false;

  // 新增射擊冷卻計時器
  double _shootCooldown = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 玩家視覺效果
    add(RectangleComponent(size: size, paint: Paint()..color = Colors.white));

    // 瞄準方向指示器
    add(AimDirectionIndicator());

    // 3. 移除在 onLoad 中初始化武器管理器的代碼
    // 我們會在 update 中初始化
  }

  // 5. 新增初始化方法
  void _initializeWeaponManager() {
    try {
      // 確保只有在 ref 可用時才嘗試讀取
      if (_weaponManagerInitialized) return;

      _weaponManagerInitialized = true;
    } catch (e) {
      // 如果 provider 還沒準備好，我們會在下一幀再試
      debugPrint('武器管理器初始化失敗: $e');
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // 更新按鍵狀態
    _keysPressed
      ..clear()
      ..addAll(keysPressed);

    // 空格鍵射擊（作為備用射擊方式）
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      debugPrint('空格鍵射擊');
      _isShooting = true;
    } else if (event is KeyUpEvent &&
        event.logicalKey == LogicalKeyboardKey.space) {
      debugPrint('空格鍵停止射擊');
      _isShooting = false;
    }

    return true;
  }

  @override
  void onPointerMove(flame_events.PointerMoveEvent event) {
    _mousePosition = event.localPosition; // 或 event.canvasPosition，視需求而定
    _updateAimDirection();
  }

  @override
  void onTapDown(TapDownEvent event) {
    // 滑鼠左鍵射擊
    _isShooting = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _isShooting = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isShooting = false;
  }

  void _updateAimDirection() {
    // 計算從玩家中心到鼠標位置的向量
    final playerCenter = position + size / 2;
    aimDirection = (_mousePosition - playerCenter)..normalize();

    // 更新瞄準指示器
    children.whereType<AimDirectionIndicator>().forEach((indicator) {
      indicator.updateDirection(aimDirection);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 6. 嘗試初始化武器管理器（如果尚未初始化）
    if (!_weaponManagerInitialized) {
      _initializeWeaponManager();

      // 如果仍未初始化成功，則跳過此幀的剩餘更新
      if (!_weaponManagerInitialized) return;
    }

    // 獲取移動速度
    final speed = ref.watch(playerProvider).speed;
    final move = Vector2.zero();

    // 處理移動
    if (_keysPressed.contains(LogicalKeyboardKey.keyW) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      move.y = -1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyS) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      move.y = 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyA) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      move.x = -1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyD) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      move.x = 1;
    }

    // 移動玩家
    if (move.length > 0) {
      move.normalize();
      position += move * speed * dt;

      // 在移動後更新瞄準方向（因為玩家位置變化）
      _updateAimDirection();
    }
  }
}

// 瞄準方向指示器
class AimDirectionIndicator extends PositionComponent {
  final Paint _paint =
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

  AimDirectionIndicator() : super(size: Vector2(20, 20));

  void updateDirection(Vector2 direction) {
    // 使指示器指向瞄準方向
    angle = direction.angleTo(Vector2(1, 0));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawLine(Offset.zero, Offset(size.x, 0), _paint);

    // 繪製箭頭
    final path =
        Path()
          ..moveTo(size.x - 5, -5)
          ..lineTo(size.x, 0)
          ..lineTo(size.x - 5, 5);

    canvas.drawPath(path, _paint);
  }

  @override
  void onMount() {
    super.onMount();
    // 將指示器置於玩家中心
    if (parent is PositionComponent) {
      position = (parent as PositionComponent).size / 2;
      anchor = Anchor.center;
    }
  }
}
