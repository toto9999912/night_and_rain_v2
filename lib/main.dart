import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/map_component.dart';
import 'components/astrologer_mumu.dart';
import 'components/enemy_component.dart';
import 'components/mediterranean_man_npc.dart';
import 'components/npc_component.dart';
import 'components/shopkeeper_bug.dart';
import 'components/wandering_npc.dart';
import 'components/sage_roy_npc.dart'; // 引入新的智者羅伊NPC
import 'components/portal_component.dart'; // 引入傳送門組件
import 'managers/dungeon_manager.dart'; // 引入地下城管理器
import 'models/consumable.dart';
import 'models/weapon.dart';
import 'providers/inventory_provider.dart';
import 'providers/items_data_provider.dart';
import 'providers/player_provider.dart';
import 'ui/overlays/hud_overlay.dart';
import 'components/player_component.dart';
import 'ui/overlays/password_input_overlay.dart';
import 'ui/overlays/player_dashboard_overlay.dart';
import 'ui/overlays/dialog_overlay.dart';
import 'ui/overlays/shop_overlay.dart';
import 'ui/overlays/game_over_overlay.dart';

final GlobalKey<RiverpodAwareGameWidgetState<NightAndRainGame>> gameWidgetKey =
    GlobalKey<RiverpodAwareGameWidgetState<NightAndRainGame>>();
final gameInstance = NightAndRainGame();
// 新增遊戲全域焦點節點
final gameFocusNode = FocusNode(debugLabel: 'GameFocusNode');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ProviderScope(child: NightAndRainApp()));
}

class NightAndRainApp extends StatelessWidget {
  NightAndRainApp({super.key});
  final game = NightAndRainGame();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Night and Rain',
      theme: ThemeData(
        fontFamily: 'Cubic11',
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: RiverpodAwareGameWidget<NightAndRainGame>(
        game: gameInstance,
        key: gameWidgetKey,
        focusNode: gameFocusNode,
        autofocus: false,
        overlayBuilderMap: {
          'HudOverlay': (context, game) => HudOverlay(game: game),
          'InventoryOverlay':
              (context, game) => PlayerDashboardOverlay(game: game),
          'DialogOverlay':
              (context, game) =>
                  DialogOverlay(game: game, npc: game.dialogNpc!),
          'ShopOverlay':
              (context, game) =>
                  ShopOverlay(game: game, shopkeeper: game.dialogNpc!),
          'GameOverOverlay': (context, game) => GameOverOverlay(game: game),
          'PasswordInputOverlay':
              (context, game) => PasswordInputOverlay(game: game),
        },
        initialActiveOverlays: const ['HudOverlay'],
      ),
    );
  }
}

class NightAndRainGame extends FlameGame
    with
        HasKeyboardHandlerComponents,
        HasCollisionDetection,
        MouseMovementDetector,
        TapDetector,
        RiverpodGameMixin {
  late final World gameWorld;
  late final CameraComponent _cameraComponent;
  late final PlayerComponent _player;
  late final MapComponent _mapComponent;

  // 當前對話的NPC
  NpcComponent? dialogNpc;

  // 追蹤滑鼠在世界中的位置
  Vector2 _lastMousePosition = Vector2.zero();

  // 設定固定地圖大小
  final Vector2 mapSize = Vector2(1500, 1500);

  // 地下城管理器
  DungeonManager? dungeonManager;

  // 交互提示信息
  String? _interactionPrompt;
  TextComponent? _interactionPromptComponent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 確保遊戲在啟動時獲取焦點
    Future.delayed(const Duration(milliseconds: 100), () {
      gameFocusNode.requestFocus();
    });

    // world + camera
    gameWorld = World();
    await add(gameWorld);
    _cameraComponent = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center;
    await add(_cameraComponent);

    // 添加地圖背景
    gameWorld.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: mapSize,
        paint: Paint()..color = Colors.lightGreen,
        priority: 0,
      ),
    );

    // 添加地圖組件（含邊界和障礙物）
    _mapComponent = MapComponent(mapSize: mapSize);
    gameWorld.add(_mapComponent);

    // 添加格線
    gameWorld.add(_GridComponent(tileSize: 32, mapSize: mapSize)..priority = 1);

    // 添加玩家
    _player =
        PlayerComponent(mapComponent: _mapComponent)
          ..position = mapSize / 2
          ..size = Vector2.all(32)
          ..priority = 2;
    gameWorld.add(_player);

    // 相機跟隨
    _cameraComponent.follow(_player);

    // 添加NPC到遊戲世界
    await _addNpcs();

    // 添加敵人到遊戲世界
    await _addEnemies();

    // 在這裡為玩家添加初始武器
    await _initializePlayerWeapon();
  }

  // 提供一個公共方法來獲取玩家組件
  PlayerComponent getPlayer() {
    return _player;
  }

  // 添加各種NPC到遊戲世界
  Future<void> _addNpcs() async {
    // 添加姆姆占星員 - 放在地圖的左上區域
    final astrologerMumu = AstrologerMumu(
      position: Vector2(mapSize.x * 0.25, mapSize.y * 0.25),
    );
    gameWorld.add(astrologerMumu);

    // 添加米蟲商店員 - 放在地圖的右上區域
    final shopkeeperBug = ShopkeeperBug(
      position: Vector2(mapSize.x * 0.75, mapSize.y * 0.25),
    );
    gameWorld.add(shopkeeperBug);

    // 添加米蟲商店員 - 放在地圖的右上區域
    final mediterraneanManNpc = MediterraneanManNpc(
      position: Vector2(mapSize.x * 0.70, mapSize.y * 0.20),
    );
    gameWorld.add(mediterraneanManNpc);

    // 添加智者羅伊 - 放在地圖中央位置
    final sageRoy = SageRoyNpc(
      position: Vector2(mapSize.x * 0.5, mapSize.y * 0.4),
    );
    gameWorld.add(sageRoy);

    // 添加3個會隨機走動的NPC

    // 放在地圖中央偏左的位置
    final wanderingNpc1 = WanderingNpc(
      name: '行人小明',
      position: Vector2(mapSize.x * 0.4, mapSize.y * 0.5),
      color: Colors.teal,
      greetings: ['今天天氣真好！', '你好啊，冒隠者！', '這個地方很危險，小心點。'],
    );
    gameWorld.add(wanderingNpc1);

    // 放在地圖中央偏右的位置
    final wanderingNpc2 = WanderingNpc(
      name: '流浪者阿花',
      position: Vector2(mapSize.x * 0.6, mapSize.y * 0.6),
      color: Colors.deepOrange,
      greetings: ['聽說森林裡有寶藏...', '有見過我的貓嗎？', '這裡的怪物越來越多了。'],
      speed: 40.0, // 稍微慢一點
    );
    gameWorld.add(wanderingNpc2);

    // 放在地圖的底部
    final wanderingNpc3 = WanderingNpc(
      name: '探險家老王',
      position: Vector2(mapSize.x * 0.5, mapSize.y * 0.8),
      color: Colors.indigo,
      greetings: ['我已經探索過很多地方了。', '想聽聽我的冒險故事嗎？', '小夥子，你看起來很有潛力！'],
      speed: 60.0, // 稍微快一點
      wanderRadius: 200.0, // 移動範圍更大
    );
    gameWorld.add(wanderingNpc3);
  }

  Future<void> _initializePlayerWeapon() async {
    // 等待一幀以確保 Provider 已完全初始化
    await Future.delayed(Duration.zero);

    // 從 itemsDataProvider 獲取初始武器 - 更新為新的物品 ID
    final itemsData = ref.read(itemsDataProvider);
    final initialWeapon = itemsData['pistol_copper'] as Weapon; // 銅牛級手槍
    final giftWeapons = itemsData['shotgun_copper'] as Weapon; // 銅牛級霰彈槍

    // 獲取紅藥水和藍藥水的原型
    final healthPotionPrototype = itemsData['health_potion'] as Consumable;
    final manaPotionPrototype = itemsData['mana_potion'] as Consumable;

    // 獲取 inventoryNotifier 和 playerNotifier
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final playerNotifier = ref.read(playerProvider.notifier);

    // 添加到玩家庫存並裝備武器
    inventoryNotifier.addItem(initialWeapon);
    inventoryNotifier.addItem(giftWeapons);

    // 為測試目的，添加所有等級的手槍
    // inventoryNotifier.addItem(itemsData['pistol_ricebug'] as Weapon); // 米蟲級
    // inventoryNotifier.addItem(itemsData['pistol_silver'] as Weapon); // 銀牛級
    // inventoryNotifier.addItem(itemsData['pistol_gold'] as Weapon); // 金牛級

    // // 為測試目的，添加所有等級的霰彈槍
    // inventoryNotifier.addItem(itemsData['shotgun_ricebug'] as Weapon); // 米蟲級
    inventoryNotifier.addItem(itemsData['shotgun_silver'] as Weapon); // 銀牛級
    inventoryNotifier.addItem(itemsData['shotgun_gold'] as Weapon); // 金牛級

    // // 為測試目的，添加高等級機關槍和狙擊槍
    // inventoryNotifier.addItem(itemsData['machinegun_gold'] as Weapon);
    inventoryNotifier.addItem(itemsData['sniper_gold'] as Weapon);

    playerNotifier.equipWeapon(initialWeapon);

    // 添加三瓶紅藥水（使用相同ID以實現堆疊）
    for (int i = 0; i < 3; i++) {
      final healthPotion = healthPotionPrototype.copyWith(
        // 保持與原型相同的ID
        quantity: 1, // 每次添加一個
      );
      inventoryNotifier.addItem(healthPotion);
    }
    // 添加三瓶藍藥水（每次創建新的藥水物件）
    for (int i = 0; i < 3; i++) {
      final manaPotion = manaPotionPrototype.copyWith(quantity: 1);
      inventoryNotifier.addItem(manaPotion);
    }

    // 添加高級藥水
    inventoryNotifier.addItem(itemsData['health_potion_premium'] as Consumable);
    inventoryNotifier.addItem(itemsData['mana_potion_premium'] as Consumable);
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    // 將滑鼠位置從畫布座標轉換為世界座標
    _lastMousePosition = _cameraComponent.viewfinder.globalToLocal(
      info.eventPosition.widget,
    );
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isKeyDown = event is KeyDownEvent || event is KeyRepeatEvent;

    // 檢查是否按下空白鍵
    if (isKeyDown &&
        keysPressed.contains(LogicalKeyboardKey.space) &&
        !overlays.isActive('InventoryOverlay') &&
        !overlays.isActive('DialogOverlay')) {
      // 使用最後記錄的滑鼠位置射擊
      _player.shoot(_lastMousePosition);
      return KeyEventResult.handled;
    }

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  bool onTapDown(TapDownInfo info) {
    // 取得畫布內座標
    final pos = info.eventPosition.widget;
    // 轉換為世界座標
    final worldPos = _cameraComponent.viewfinder.globalToLocal(pos);
    // 同時更新最後的滑鼠位置
    _lastMousePosition = worldPos;
    _player.shoot(worldPos);
    return true;
  }

  // 添加敵人到遊戲世界
  Future<void> _addEnemies() async {
    // 使用固定位置添加敵人，確保不會生成在玩家附近

    // // 1. 在地圖左下角區域添加一組近戰敵人
    // _addEnemyGroup(
    //   center: Vector2(mapSize.x * 0.2, mapSize.y * 0.8),
    //   count: 3,
    //   radius: 80.0,
    //   type: EnemyType.melee,
    //   color: Colors.red.shade800,
    //   health: 80,
    //   damage: 10,
    //   speed: 70,
    // );

    // // 2. 在地圖右下角區域添加一組遠程敵人
    // _addEnemyGroup(
    //   center: Vector2(mapSize.x * 0.8, mapSize.y * 0.8),
    //   count: 2,
    //   radius: 120.0,
    //   type: EnemyType.ranged,
    //   color: Colors.purple.shade800,
    //   health: 60,
    //   damage: 15,
    //   speed: 50,
    //   attackRange: 200,
    // );

    // // 3. 在地圖右上角區域添加一組混合型敵人
    // _addEnemyGroup(
    //   center: Vector2(mapSize.x * 0.8, mapSize.y * 0.2),
    //   count: 2,
    //   radius: 100.0,
    //   type: EnemyType.hybrid,
    //   color: Colors.amber.shade800,
    //   health: 100,
    //   damage: 12,
    //   speed: 60,
    //   attackRange: 150,
    // );

    // // 4. 在障礙物附近添加零散敵人
    // // 障礙物位置在地圖的一些關鍵點，所以我們在它們附近添加敵人
    // _addEnemyAt(
    //   position: Vector2(mapSize.x * 0.3, mapSize.y * 0.4),
    //   type: EnemyType.melee,
    //   color: Colors.red.shade700,
    // );

    // _addEnemyAt(
    //   position: Vector2(mapSize.x * 0.7, mapSize.y * 0.4),
    //   type: EnemyType.ranged,
    //   color: Colors.purple.shade700,
    //   attackRange: 180,
    // );

    // _addEnemyAt(
    //   position: Vector2(mapSize.x * 0.4, mapSize.y * 0.7),
    //   type: EnemyType.hybrid,
    //   color: Colors.amber.shade700,
    // );

    // // 5. 添加一個強大的「精英」敵人在地圖中心偏下的位置
    // _addEnemyAt(
    //   position: Vector2(mapSize.x * 0.5, mapSize.y * 0.65),
    //   type: EnemyType.hybrid,
    //   color: Colors.deepOrange,
    //   enemySize: 35, // 這裡已經修改為 enemySize
    //   health: 200,
    //   damage: 20,
    //   speed: 50,
    //   attackRange: 180,
    //   detectionRange: 250,
    // );

    // // 6. 添加幾個獵手型敵人，專門追蹤玩家
    // // 偏遠的左上角
    // _addEnemyAt(
    //   position: Vector2(mapSize.x * 0.15, mapSize.y * 0.15),
    //   type: EnemyType.hunter,
    //   color: Colors.red.shade600, // 深紅色
    //   enemySize: 28, // 較大尺寸
    //   health: 150,
    //   damage: 15,
    //   speed: 80, // 較高的基礎速度
    //   attackRange: 40,
    //   detectionRange: 1000, // 非常大的偵測範圍，基本上能看到整個地圖
    //   attackCooldown: 0.8, // 較短的攻擊冷卻
    // );

    // // 中間偏右區域
    // _addEnemyAt(
    //   position: Vector2(mapSize.x * 0.6, mapSize.y * 0.5),
    //   type: EnemyType.hunter,
    //   color: Colors.pink.shade800, // 粉紅色變種
    //   enemySize: 26,
    //   health: 130,
    //   damage: 12,
    //   speed: 85,
    //   attackRange: 35,
    //   detectionRange: 1000,
    //   attackCooldown: 1.0,
    // );

    // // 在左側中間
    // _addEnemyGroup(
    //   center: Vector2(mapSize.x * 0.2, mapSize.y * 0.5),
    //   count: 2,
    //   radius: 80.0,
    //   type: EnemyType.hunter,
    //   color: Colors.redAccent,
    //   health: 120,
    //   damage: 10,
    //   speed: 75,
    //   attackRange: 35,
    //   detectionRange: 1000,
    //   attackCooldown: 1.2,
    // );

    // // 7. 添加一個超強大的Boss在地圖中心
    // _addBoss(
    //   position: Vector2(mapSize.x * 0.5, mapSize.y * 0.3),
    //   bossName: '深淵之王',
    //   color: Colors.deepPurple,
    //   maxHealth: 2000,
    //   damage: 30,
    //   speed: 50,
    //   enemySize: 45,
    // );
  }

  // // 添加Boss到地圖上
  // void _addBoss({
  //   required Vector2 position,
  //   required String bossName,
  //   Color color = Colors.deepPurple,
  //   double maxHealth = 1500,
  //   double damage = 25,
  //   double speed = 40,
  //   double enemySize = 40,
  //   double attackRange = 150,
  //   double detectionRange = 600,
  //   double attackCooldown = 1.5,
  //   double specialAttackInterval = 8.0,
  //   double summonInterval = 15.0,
  // }) {
  //   // 創建Boss實例
  //   final boss = BossComponent(
  //     position: position,
  //     mapComponent: _mapComponent,
  //     bossName: bossName,
  //     maxHealth: maxHealth,
  //     damage: damage,
  //     speed: speed,
  //     attackRange: attackRange,
  //     detectionRange: detectionRange,
  //     attackCooldown: attackCooldown,
  //     color: color,
  //     enemySize: enemySize,
  //     specialAttackInterval: specialAttackInterval,
  //     summonInterval: summonInterval,
  //     attackPatterns: [
  //       BossAttackPattern.circularAttack,
  //       BossAttackPattern.beamAttack,
  //       BossAttackPattern.aoeAttack,
  //       BossAttackPattern.rapidFire,
  //       BossAttackPattern.teleport,
  //     ],
  //     totalPhases: 3,
  //   );

  //   // 添加到遊戲世界
  //   gameWorld.add(boss);

  //   debugPrint('已生成Boss: $bossName');
  // }

  // 在指定位置添加單個敵人
  void _addEnemyAt({
    required Vector2 position,
    required EnemyType type,
    Color color = Colors.red,
    double enemySize = 24, // 參數名從 size 改為 enemySize
    double health = 100,
    double damage = 10,
    double speed = 60,
    double attackRange = 30,
    double detectionRange = 200,
    double attackCooldown = 1.0,
  }) {
    final enemy = EnemyComponent(
      position: position,
      type: type,
      mapComponent: _mapComponent,
      color: color,
      enemySize: enemySize, // 參數名從 size 改為 enemySize
      maxHealth: health,
      damage: damage,
      speed: speed,
      attackRange: attackRange,
      detectionRange: detectionRange,
      attackCooldown: attackCooldown,
    );

    gameWorld.add(enemy);
  }

  // 在指定區域添加一組敵人
  void _addEnemyGroup({
    required Vector2 center,
    required int count,
    required double radius,
    required EnemyType type,
    Color color = Colors.red,
    double enemySize = 24, // 參數名從 size 改為 enemySize
    double health = 100,
    double damage = 10,
    double speed = 60,
    double attackRange = 30,
    double detectionRange = 200,
    double attackCooldown = 1.0,
  }) {
    final random = math.Random();

    for (int i = 0; i < count; i++) {
      // 在圓形區域內隨機生成位置
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * radius;
      final offset = Vector2(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );

      final position = center + offset;

      // 確保敵人不會生成在障礙物內
      if (!_mapComponent.checkObstacleCollision(
        position,
        Vector2.all(enemySize),
      )) {
        // 使用 enemySize
        _addEnemyAt(
          position: position,
          type: type,
          color: color,
          enemySize: enemySize, // 參數名從 size 改為 enemySize
          health: health,
          damage: damage,
          speed: speed,
          attackRange: attackRange,
          detectionRange: detectionRange,
          attackCooldown: attackCooldown,
        );
      }
    }
  }

  // 重置玩家位置到指定位置
  void resetPlayerPosition([Vector2? position]) {
    // 將玩家移至指定位置或地圖中央
    _player.position = position ?? mapSize / 2;

    // 停止所有可能的移動
    _player.stopAllMovement();

    // 重新設置相機跟隨
    _cameraComponent.follow(_player);
  }

  // 獲取地圖組件
  MapComponent getMapComponent() {
    return _mapComponent;
  }

  // 初始化地下城
  void initializeDungeon() {
    // 如果已經初始化，則不再重複初始化
    if (dungeonManager != null) return;

    // 創建地下城管理器，設置入口位置在地圖中央偏下
    dungeonManager = DungeonManager(
      this,
      entrancePosition: Vector2(mapSize.x * 0.5, mapSize.y * 0.7),
    );

    // 初始化地下城（創建入口傳送門）
    dungeonManager!.initialize();
  }

  // 處理傳送門傳送
  void triggerPortalTransport(String destinationId, PortalType type) {
    // 確保地下城管理器已初始化
    if (dungeonManager == null) {
      initializeDungeon();
    }

    // 處理傳送
    dungeonManager!.handlePortalTransport(destinationId, type);
  }

  // 顯示交互提示
  void showInteractionPrompt(String prompt) {
    _interactionPrompt = prompt;

    // 移除現有提示（如果有）
    if (_interactionPromptComponent != null) {
      _interactionPromptComponent!.removeFromParent();
      _interactionPromptComponent = null;
    }

    // 創建新的提示文本
    _interactionPromptComponent = TextComponent(
      text: prompt,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
          ],
        ),
      ),
      position: Vector2(
        camera.viewport.size.x / 2,
        camera.viewport.size.y * 0.8,
      ),
      anchor: Anchor.center,
    );

    // 添加到相機覆蓋層
    camera.viewport.add(_interactionPromptComponent!);
  }

  // 隱藏交互提示
  void hideInteractionPrompt() {
    _interactionPrompt = null;

    // 移除提示
    if (_interactionPromptComponent != null) {
      _interactionPromptComponent!.removeFromParent();
      _interactionPromptComponent = null;
    }
  }

  // 重置鍵盤處理
  void resetKeyboardHandling() {
    // 確保玩家組件正確重置按鍵狀態
    if (_player != null) {
      _player.resetKeyboardState();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 如果地下城管理器尚未初始化，則初始化它
    if (dungeonManager == null &&
        overlays.activeOverlays.contains('HudOverlay')) {
      initializeDungeon();
    }
  }
}

class _GridComponent extends Component with HasGameReference<FlameGame> {
  final double tileSize;
  final Vector2 mapSize;
  final Paint _paint =
      Paint()
        ..color = Colors.black.withAlpha(77)
        ..strokeWidth = 1;

  _GridComponent({this.tileSize = 32, required this.mapSize});

  @override
  void render(Canvas canvas) {
    final w = mapSize.x;
    final h = mapSize.y;

    // 繪製垂直線
    for (double x = 0; x <= w; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), _paint);
    }
    // 繪製水平線
    for (double y = 0; y <= h; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), _paint);
    }
  }
}
