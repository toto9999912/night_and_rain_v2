import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/events.dart' as flame_events;
import 'package:flame/collisions.dart';
import '../enum/item_rarity.dart';
import '../enum/weapon_type.dart';
import '../main.dart';
import '../models/melee_weapon.dart';
import '../models/ranged_weapon.dart';
import '../providers/player_provider.dart';
import '../providers/inventory_provider.dart';
import '../models/weapon.dart';
import 'bullet_component.dart';
import 'map_component.dart';
import 'npc_component.dart';

class PlayerComponent extends PositionComponent
    with
        KeyboardHandler,
        TapCallbacks,
        DragCallbacks,
        HasGameReference<NightAndRainGame>,
        PointerMoveCallbacks,
        RiverpodComponentMixin,
        CollisionCallbacks {
  final Set<LogicalKeyboardKey> _keysPressed = {};
  final MapComponent mapComponent;

  // Provider 初始化狀態
  bool _isProviderInitialized = false;

  // 當前可互動的NPC
  NpcComponent? _interactiveNpc;

  // 熱鍵綁定 - 存儲熱鍵對應的物品ID

  Timer? _manaRegenerationTimer;
  final double _manaRegenerationInterval = 0.5; // 0.5秒恢復一次

  // 瞄準方向（默認向上）
  Vector2 aimDirection = Vector2(0, -1);

  // 鼠標位置追踪
  Vector2 _mousePosition = Vector2.zero();

  // 射擊控制
  bool _isShooting = false;

  // 射擊冷卻計時器
  double _shootCooldown = 0;

  // 碰撞反彈參數
  double _collisionCooldown = 0;
  Vector2 _lastCollisionDirection = Vector2.zero();
  static const double _collisionRecoilTime = 0.15; // 反彈時間
  static const double _collisionRecoilForce = 100; // 反彈力度

  PlayerComponent({required this.mapComponent}) : super();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // 初始化魔力恢復計時器
    _manaRegenerationTimer = Timer(
      _manaRegenerationInterval,
      onTick: _regenerateMana,
      repeat: true,
    );

    // 玩家視覺效果
    add(RectangleComponent(size: size, paint: Paint()..color = Colors.white));

    // 瞄準方向指示器
    add(AimDirectionIndicator());

    // 添加碰撞檢測盒
    add(RectangleHitbox()..collisionType = CollisionType.active);
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

    // E鍵與NPC對話
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyE &&
        _interactiveNpc != null &&
        !game.overlays.isActive('InventoryOverlay') &&
        !game.overlays.isActive('DialogOverlay')) {
      debugPrint('E鍵與NPC [${_interactiveNpc!.name}] 對話');
      // 啟動新的對話覆蓋層
      _openDialogWithNpc(_interactiveNpc!);
      return true;
    }

    // 武器切換 (Q鍵切換武器)
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyQ &&
        _isProviderInitialized) {
      ref.read(playerProvider.notifier).switchToNextWeapon();
    }

    // 添加C鍵打開背包功能
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyC &&
        _isProviderInitialized) {
      debugPrint('C鍵打開背包');
      // 檢查背包是否已打開
      if (game.overlays.isActive('InventoryOverlay')) {
        game.overlays.remove('InventoryOverlay');
      } else {
        game.overlays.add('InventoryOverlay');
      }
    }

    // 數字鍵 1-5 熱鍵功能 - 只處理背包關閉時的數字鍵
    if (event is KeyDownEvent &&
        _isProviderInitialized &&
        !game.overlays.isActive('InventoryOverlay') &&
        event.logicalKey.keyId >= LogicalKeyboardKey.digit1.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.digit5.keyId) {
      final hotkeyIndex =
          event.logicalKey.keyId - LogicalKeyboardKey.digit1.keyId + 1;
      _useHotkeyItem(hotkeyIndex);
      return true;
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
    // 更新魔力恢復計時器
    _manaRegenerationTimer?.update(dt);

    // 嘗試初始化 Provider（如果尚未初始化）
    if (!_isProviderInitialized) {
      _initializeProvider();

      // 如果仍未初始化成功，則跳過此幀的剩余更新
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

    // 處理碰撞反彈
    if (_collisionCooldown > 0) {
      _collisionCooldown -= dt;

      // 在反彈時，向反方向移動
      position += _lastCollisionDirection * _collisionRecoilForce * dt;

      // 如果還想要處理正常移動，可以在這裡繼續
      if (_collisionCooldown <= 0) {
        _lastCollisionDirection = Vector2.zero();
      }
    } else {
      // 正常移動處理
      if (move.length > 0) {
        move.normalize();
        final nextPosition = position + move * speed * dt;

        // 檢查是否與障礙物碰撞
        if (!mapComponent.checkObstacleCollision(nextPosition, size)) {
          position = nextPosition;
        } else {
          // 嘗試分別在 X 和 Y 方向上移動（在牆邊滑動）
          final nextPositionX = Vector2(nextPosition.x, position.y);
          final nextPositionY = Vector2(position.x, nextPosition.y);

          if (!mapComponent.checkObstacleCollision(nextPositionX, size)) {
            position = nextPositionX;
          }

          if (!mapComponent.checkObstacleCollision(nextPositionY, size)) {
            position = nextPositionY;
          }
        }
      }
    }

    // 確保玩家不會走出地圖邊界
    position.x = position.x.clamp(0, game.mapSize.x - size.x);
    position.y = position.y.clamp(0, game.mapSize.y - size.y);

    // 在移動後更新瞄準方向（因為玩家位置變化）
    _updateAimDirection();
  }

  void _regenerateMana() {
    final playerNotifier = ref.read(playerProvider.notifier);
    final player = ref.read(playerProvider);

    // 只有在魔力未滿時才恢復
    if (player.mana < player.maxMana) {
      // 使用 Future 延遲更新狀態
      Future(() {
        playerNotifier.addMana(1);
      });
    }
  }

  @override
  void onRemove() {
    _manaRegenerationTimer?.stop();
    super.onRemove();
  }

  // 碰撞檢測回調
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Obstacle || other is BoundaryWall) {
      // 計算反彈方向（從碰撞點到玩家中心）
      final playerCenter = position + size / 2;
      final collisionCenter = Vector2.zero();

      // 計算碰撞點的平均位置
      for (final point in intersectionPoints) {
        collisionCenter.add(point);
      }

      if (intersectionPoints.isNotEmpty) {
        collisionCenter.scale(1 / intersectionPoints.length);

        // 計算反彈方向（從碰撞點指向玩家中心）
        _lastCollisionDirection = (playerCenter - collisionCenter)..normalize();
        _collisionCooldown = _collisionRecoilTime;
      }
    }
  }

  void shoot(Vector2 targetPosition) {
    // 確認 Provider 已初始化
    if (!_isProviderInitialized) return;

    // 計算射擊方向
    final playerCenter = position + size / 2;
    final direction = (targetPosition - playerCenter).normalized();

    // 使用 PlayerNotifier 的 attack 方法（會處理魔力消耗和攻擊邏輯）
    final playerNotifier = ref.read(playerProvider.notifier);
    final player = ref.read(playerProvider);
    final weapon = player.equippedWeapon;

    if (weapon == null) {
      debugPrint('沒有裝備武器！');
      return;
    }

    // 檢查武器冷卻
    if (_shootCooldown > 0) {
      debugPrint('武器冷卻中...');
      return;
    }

    // 嘗試攻擊（PlayerNotifier 會處理魔力消耗）
    if (playerNotifier.attack(direction)) {
      // 攻擊成功，設置冷卻
      _shootCooldown = weapon.cooldown;

      // 獲取子彈速度 - 從武器類型中獲取默認值
      double bulletSpeed = weapon.weaponType.defaultBulletSpeed;

      // 根據武器類型執行不同的攻擊邏輯
      if (weapon is RangedWeapon) {
        // 遠程武器邏輯
        final bulletParams = weapon.getBulletParameters();
        bulletSpeed = bulletParams['speed'] as double;

        // 檢查是否為霰彈槍類型
        if (weapon.weaponType == WeaponType.shotgun) {
          // 霰彈槍發射多個子彈，呈扇形散射
          _fireShotgunBlast(playerCenter, direction, bulletSpeed, weapon);
        } else {
          // 其他遠程武器只發射一個子彈
          _fireSingleBullet(playerCenter, direction, bulletSpeed, weapon);
        }
      } else if (weapon is MeleeWeapon) {
        // 近戰武器邏輯 - 可以在這裡添加劍氣效果等
        // TODO: 實現近戰武器的效果
      }

      debugPrint('使用武器：${weapon.name}，方向：$direction');
    } else {
      debugPrint('無法使用武器！可能是魔力不足');
    }
  }

  // 霰彈槍發射多個子彈的方法
  void _fireShotgunBlast(
    Vector2 origin,
    Vector2 centerDirection,
    double speed,
    Weapon weapon,
  ) {
    // 發射5個子彈，角度偏移
    const int bulletCount = 5;
    const double spreadAngle = 0.3; // 總散射角度（弧度）

    // 檢查是否為 RangedWeapon 類型以獲取更多特效數據
    Map<String, dynamic> bulletParams = {};
    ItemRarity? rarity;
    double size = 6.0;
    String trailEffect = 'none';
    Color bulletColor = Colors.lightBlue; // 默認統一顏色
    WeaponType? weaponType;

    if (weapon is RangedWeapon) {
      bulletParams = weapon.getBulletParameters();
      rarity = bulletParams['rarity'] as ItemRarity?;
      size = bulletParams['size'] as double? ?? 6.0;
      trailEffect = bulletParams['trailEffect'] as String? ?? 'none';
      bulletColor = bulletParams['color'] as Color? ?? Colors.lightBlue;
      weaponType = bulletParams['weaponType'] as WeaponType?;
    }

    // 霰彈槍特殊處理 - 僅調整大小和速度，顏色保持統一
    if (weaponType == WeaponType.shotgun) {
      size *= 1.2; // 霰彈槍彈丸稍大，但保持同一顏色
      speed *= 0.7; // 霰彈槍彈丸速度減慢，提高可見性
    }

    debugPrint(
      '武器發射: 類型=${weapon.weaponType.name}, 彈丸數量=$bulletCount, 彈丸大小=$size, 稀有度=${rarity?.name}',
    );

    for (int i = 0; i < bulletCount; i++) {
      // 計算每個子彈的偏移角度
      double angleOffset = spreadAngle * (i / (bulletCount - 1) - 0.5);

      // 根據偏移角度旋轉方向向量
      Vector2 bulletDirection = centerDirection.clone()..rotate(angleOffset);

      // 輕微調整速度，使外側子彈略慢
      double bulletSpeed =
          speed * (1.0 - 0.1 * (angleOffset.abs() / (spreadAngle / 2)));

      // 創建子彈
      final bullet = BulletComponent(
        position: origin.clone(),
        direction: bulletDirection,
        speed: bulletSpeed,
        damage: weapon.damage.toDouble() * 0.6, // 每顆子彈傷害降低，但總傷害較高
        range:
            weapon.range.toDouble() *
            (1.0 - 0.2 * (angleOffset.abs() / (spreadAngle / 2))), // 外側子彈射程略短
        color: bulletColor, // 使用統一的顏色
        rarity: rarity,
        size: size, // 使用適當的彈丸尺寸
      );

      // 添加到遊戲世界
      game.gameWorld.add(bullet);
    }
  }

  // 新增：標準單發射擊方法
  void _fireSingleBullet(
    Vector2 origin,
    Vector2 direction,
    double speed,
    Weapon weapon,
  ) {
    // 檢查是否為 RangedWeapon 類型以獲取更多特效數據
    Map<String, dynamic> bulletParams = {};
    ItemRarity? rarity;
    double size = 6.0;
    Color bulletColor = Colors.lightBlue; // 默認統一顏色

    if (weapon is RangedWeapon) {
      bulletParams = weapon.getBulletParameters();
      rarity = bulletParams['rarity'] as ItemRarity?;
      size = bulletParams['size'] as double? ?? 6.0;
      bulletColor = bulletParams['color'] as Color? ?? Colors.lightBlue;
    }

    final bullet = BulletComponent(
      position: origin.clone(),
      direction: direction,
      speed: speed,
      damage: weapon.damage.toDouble(),
      range: weapon.range.toDouble(),
      color: bulletColor, // 使用統一的顏色
      rarity: rarity, // 傳遞稀有度
      size: size, // 傳遞子彈大小
    );

    game.gameWorld.add(bullet);
  }

  // 使用熱鍵綁定的物品
  void _useHotkeyItem(int hotkeyIndex) {
    debugPrint('使用熱鍵 $hotkeyIndex');

    // 直接調用 inventoryProvider 的 useHotkeyItem 方法
    try {
      ref.read(inventoryProvider.notifier).useHotkeyItem(hotkeyIndex);
    } catch (e) {
      debugPrint('使用熱鍵物品失敗: $e');
    }
  }

  // 設置當前可互動的NPC
  void setInteractiveNpc(NpcComponent npc) {
    _interactiveNpc = npc;
  }

  // 清除當前互動的NPC
  void clearInteractiveNpc(NpcComponent npc) {
    // 只有當前互動的NPC與參數相同時才清除
    if (_interactiveNpc == npc) {
      _interactiveNpc = null;
    }
  }

  // 打開與NPC的對話介面
  void _openDialogWithNpc(NpcComponent npc) {
    // 確保覆蓋層不會重複添加
    if (game.overlays.isActive('DialogOverlay')) return;

    // 添加覆蓋層前，確保NPC的對話參數已傳遞
    game.dialogNpc = npc;

    // 開始對話
    npc.startDialogue();
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
