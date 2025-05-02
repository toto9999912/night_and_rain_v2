import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/events.dart' as flame_events;
import '../main.dart';
import '../providers/player_provider.dart';
import '../models/weapon.dart';
import 'bullet_component.dart';

class PlayerComponent extends PositionComponent
    with
        KeyboardHandler,
        TapCallbacks,
        DragCallbacks,
        HasGameReference<NightAndRainGame>,
        PointerMoveCallbacks,
        RiverpodComponentMixin {
  final Set<LogicalKeyboardKey> _keysPressed = {};

  // 移除 WeaponManager，改為直接使用 Player
  bool _isProviderInitialized = false;

  // 瞄準方向（默認向上）
  Vector2 aimDirection = Vector2(0, -1);

  // 鼠標位置追踪
  Vector2 _mousePosition = Vector2.zero();

  // 射擊控制
  bool _isShooting = false;

  // 射擊冷卻計時器
  double _shootCooldown = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 玩家視覺效果
    add(RectangleComponent(size: size, paint: Paint()..color = Colors.white));

    // 瞄準方向指示器
    add(AimDirectionIndicator());
  }

  // 簡化初始化方法
  void _initializeProvider() {
    try {
      if (_isProviderInitialized) return;

      // 嘗試訪問 provider，測試是否可用
      ref.read(playerProvider);
      _isProviderInitialized = true;
    } catch (e) {
      debugPrint('Provider 初始化失敗: $e');
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

    // 武器切換 (Q鍵切換武器)
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyQ &&
        _isProviderInitialized) {
      ref.read(playerProvider.notifier).switchToNextWeapon();
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

    // 嘗試初始化 Provider（如果尚未初始化）
    if (!_isProviderInitialized) {
      _initializeProvider();

      // 如果仍未初始化成功，則跳過此幀的剩餘更新
      if (!_isProviderInitialized) return;
    }

    // 獲取移動速度
    final player = ref.watch(playerProvider);
    final speed = player.speed;
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

    // 更新射擊冷卻
    if (_shootCooldown > 0) {
      _shootCooldown -= dt;
    }

    // 射擊邏輯 - 使用統一的射擊方法
    if (_isShooting && _shootCooldown <= 0 && _isProviderInitialized) {
      // 計算玩家前方位置作為目標
      final playerCenter = position + size / 2;
      final targetPosition = playerCenter + aimDirection * 100;

      // 調用統一的射擊方法
      shoot(targetPosition);
    }

    // 移動玩家
    if (move.length > 0) {
      move.normalize();
      position += move * speed * dt;

      // 在移動後更新瞄準方向（因為玩家位置變化）
      _updateAimDirection();
    }
  }

  // 添加射擊方法
  void shoot(Vector2 targetPosition) {
    // 確認 Provider 已初始化
    if (!_isProviderInitialized) return;

    // 獲取玩家當前武器
    final playerState = ref.read(playerProvider);
    final weapon = playerState.equippedWeapon;

    if (weapon != null) {
      // 確認武器冷卻已結束
      if (_shootCooldown <= 0) {
        // 計算射擊方向
        final playerCenter = position + size / 2;
        final direction = (targetPosition - playerCenter).normalized();

        // 使用攻擊方法（會消耗魔力）
        if (ref.read(playerProvider.notifier).attack(direction)) {
          // 攻擊成功，設置冷卻
          _shootCooldown = weapon.cooldown;

          // 創建子彈並添加到遊戲世界
          final bullet = BulletComponent(
            position: playerCenter.clone(),
            direction: direction,
            speed: 400, // 子彈速度，可以根據武器類型調整
            damage:
                weapon.damage.toDouble(), // 轉換為 double 以符合 BulletComponent 參數類型
            range:
                weapon.range.toDouble(), // 轉換為 double 以符合 BulletComponent 參數類型
            color: _getBulletColor(weapon), // 根據武器類型設定子彈顏色
          );

          // 將子彈添加到遊戲世界
          game.gameWorld.add(bullet);

          debugPrint('發射子彈：${weapon.name}，方向：$direction');
        } else {
          debugPrint('魔力不足，無法射擊！');
        }
      } else {
        debugPrint('武器冷卻中...');
      }
    } else {
      debugPrint('沒有裝備武器！');
    }
  }

  // 根據武器類型獲取子彈顏色
  Color _getBulletColor(Weapon weapon) {
    switch (weapon.weaponType.name) {
      case 'pistol':
        return Colors.yellow;
      case 'shotgun':
        return Colors.orange;
      case 'rifle':
        return Colors.blue;
      case 'machineGun':
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}

// AimDirectionIndicator 類保持不變
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
