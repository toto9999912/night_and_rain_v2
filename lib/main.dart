import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame_audio/flame_audio.dart'; // 引入 flame_audio
import 'package:flame_tiled/flame_tiled.dart'; // 引入 flame_tiled
import 'components/greedy_shopkeeper_bug.dart';
import 'components/map_component.dart';
import 'components/astrologer_mumu.dart';
import 'components/enemy_component.dart';
import 'components/mediterranean_man_npc.dart';
import 'components/npc_component.dart';
import 'components/shopkeeper_bug.dart';
import 'components/wandering_npc.dart';
import 'components/pig_friend_npc.dart'; // 引入新的智者羅伊NPC
import 'components/portal_component.dart'; // 引入傳送門組件
import 'managers/dungeon_manager.dart'; // 引入地下城管理器
import 'models/consumable.dart';
import 'models/weapon.dart';
import 'providers/inventory_provider.dart';
import 'providers/items_data_provider.dart';
import 'providers/player_provider.dart';
import 'components/player_component.dart';
import 'ui/screens/main_menu_screen.dart'; // 引入主選單畫面

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
  const NightAndRainApp({super.key});

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
      // 更改為從主選單開始
      home: const MainMenuScreen(),
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
  final Vector2 mapSize = Vector2(1024, 1536);

  // 地下城管理器
  DungeonManager? dungeonManager;

  // 交互提示信息
  TextComponent? _interactionPromptComponent;
  // 音樂控制變數
  bool _isBgmPlaying = false;
  bool _isDungeonBgmPlaying = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 預先加載背景音樂
    await FlameAudio.audioCache.load('bgm.mp3');
    await FlameAudio.audioCache.load('dungeon_bgm.mp3');

    // 播放背景音樂 (循環播放)
    _playBackgroundMusic();

    // 確保遊戲在啟動時獲取焦點
    Future.delayed(const Duration(milliseconds: 100), () {
      gameFocusNode.requestFocus();
    }); // world + camera
    gameWorld = World();
    await add(gameWorld);
    _cameraComponent = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center;
    await add(_cameraComponent);

    // 添加地圖背景
    _mapComponent = MapComponent(mapSize: Vector2(1024, 1536));

    // 載入 Tiled 地圖 - 從 assets/maps 目錄載入
    final tiledMap = await TiledComponent.load(
      'map.tmx', // 注意路徑是相對於 assets 目錄的
      Vector2.all(32), // 瓦片大小
    );

    // 設置 Tiled 地圖到 MapComponent
    _mapComponent.tiledMap = tiledMap;

    // 添加到遊戲世界
    gameWorld.add(tiledMap);
    gameWorld.add(_mapComponent);

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
      position: Vector2(mapSize.x * 0.775, mapSize.y * 0.6),
    );
    gameWorld.add(astrologerMumu);

    // 添加米蟲商店員 - 放在地圖的右上區域
    final shopkeeperBug = ShopkeeperBug(
      position: Vector2(mapSize.x * 0.8, mapSize.y * 0.45),
    );
    gameWorld.add(shopkeeperBug);

    // 添加米蟲商店員 - 放在地圖的右上區域
    final greedyBug = GreedyShopkeeperBug(
      position: Vector2(mapSize.x * 0.75, mapSize.y * 0.2),
    );
    gameWorld.add(greedyBug);

    // 地中海50歲老人
    final mediterraneanManNpc = MediterraneanManNpc(
      position: Vector2(mapSize.x * 0.25, mapSize.y * 0.25),
    );
    gameWorld.add(mediterraneanManNpc);

    // 添加豬比 - 放在地圖中央位置
    final sageRoy = PigFriendNpc(
      position: Vector2(mapSize.x * 0.3, mapSize.y * 0.6),
    );
    gameWorld.add(sageRoy);

    // 添加3個會隨機走動的NPC

    // 放在地圖中央偏左的位置
    final wanderingNpc1 = WanderingNpc(
      name: '米蟲村民Ａ',
      position: Vector2(mapSize.x * 0.4, mapSize.y * 0.5),
      color: Colors.teal,
      greetings: ['今天天氣真好！', '你好啊！', '你問地下城在哪裡？下面直走不就是了', '我在這裡等我的貓。'],
    );
    gameWorld.add(wanderingNpc1);

    // 放在地圖中央偏右的位置
    final wanderingNpc2 = WanderingNpc(
      name: '米蟲村民Ｂ',
      position: Vector2(mapSize.x * 0.6, mapSize.y * 0.6),
      color: Colors.deepOrange,
      greetings: ['聽說蕾絲翠占卜超準的', '我又被米蟲奸商騙了...', '據說地下城深處藏著一個藏鏡人'],
      speed: 40.0, // 稍微慢一點
    );
    gameWorld.add(wanderingNpc2);

    // 放在地圖的底部
    final wanderingNpc3 = WanderingNpc(
      name: '米蟲村民Ｃ',
      position: Vector2(mapSize.x * 0.5, mapSize.y * 0.8),
      color: Colors.indigo,
      greetings: ['我已經探索過很多地方了', '想聽聽我的冒險故事嗎？', '小夥子，你看起來很有潛力！'],
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
    final initialWeapon = itemsData['shotgun_silver'] as Weapon; // 銅牛級手槍

    // 獲取紅藥水和藍藥水的原型
    final healthPotionPrototype =
        itemsData['health_potion_basic'] as Consumable;
    final manaPotionPrototype = itemsData['mana_potion_basic'] as Consumable;

    // 獲取 inventoryNotifier 和 playerNotifier
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final playerNotifier = ref.read(playerProvider.notifier);

    // 添加到玩家庫存並裝備武器
    inventoryNotifier.addItem(initialWeapon);

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
    // inventoryNotifier.addItem(itemsData['health_potion_premium'] as Consumable);
    // inventoryNotifier.addItem(itemsData['mana_potion_premium'] as Consumable);
  }

  @override
  void onMouseMove(PointerHoverInfo info) {
    super.onMouseMove(info);
    // 將滑鼠位置從畫布座標轉換為世界座標
    Vector2 worldPos = _cameraComponent.viewfinder.globalToLocal(
      info.eventPosition.widget,
    );

    // 確保滑鼠位置不超出地圖範圍
    worldPos.x = worldPos.x.clamp(0, mapSize.x);
    worldPos.y = worldPos.y.clamp(0, mapSize.y);

    _lastMousePosition = worldPos;
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
    Vector2 worldPos = _cameraComponent.viewfinder.globalToLocal(pos);

    // 確保點擊位置不超出地圖範圍
    worldPos.x = worldPos.x.clamp(0, mapSize.x);
    worldPos.y = worldPos.y.clamp(0, mapSize.y);

    // 同時更新最後的滑鼠位置
    _lastMousePosition = worldPos;
    _player.shoot(worldPos);
    return true;
  }

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
    // 設置默認位置為地圖中央
    Vector2 targetPosition = position ?? Vector2(mapSize.x / 2, mapSize.y / 2);

    // 確保目標位置在地圖範圍內
    if (!_mapComponent.isInsideMap(targetPosition, _player.size)) {
      // 如果不在範圍內，重新設置為地圖中央
      targetPosition = Vector2(mapSize.x / 2, mapSize.y / 2);
    }

    // 將玩家移至目標位置
    _player.position = targetPosition;

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
      entrancePosition: Vector2(mapSize.x * 0.34, mapSize.y * 0.95),
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
    // 移除現有提示（如果有）
    if (_interactionPromptComponent != null) {
      _interactionPromptComponent!.removeFromParent();
      _interactionPromptComponent = null;
    } // 創建新的提示文本
    _interactionPromptComponent = TextComponent(
      text: prompt,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontFamily: 'Cubic11', // 使用 Cubic11 字體
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
    // 移除提示
    if (_interactionPromptComponent != null) {
      _interactionPromptComponent!.removeFromParent();
      _interactionPromptComponent = null;
    }
  }

  // 重置鍵盤處理
  void resetKeyboardHandling() {
    // 確保玩家組件正確重置按鍵狀態
    _player.resetKeyboardState();
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

  Future<void> _playBackgroundMusic() async {
    if (!_isBgmPlaying) {
      try {
        // 使用主線程調用
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 使用 bgm.mp3 作為遊戲背景音樂
          FlameAudio.bgm.play('bgm.mp3', volume: 0.25);
          _isBgmPlaying = true;
          _isDungeonBgmPlaying = false;
        });
      } catch (e) {
        print('背景音樂播放失敗: $e');
      }
    }
  }

  // 切換到地下城音樂
  void switchToDungeonMusic() {
    if (!_isDungeonBgmPlaying) {
      try {
        // 先停止主世界音樂
        FlameAudio.bgm.stop();
        // 播放地下城音樂
        FlameAudio.bgm.play('dungeon_bgm.mp3', volume: 0.25);
        _isBgmPlaying = false;
        _isDungeonBgmPlaying = true;
        debugPrint('已切換到地下城音樂');
      } catch (e) {
        debugPrint('地下城音樂播放失敗: $e');
      }
    }
  }

  // 切換回主世界音樂
  void switchToMainWorldMusic() {
    if (!_isBgmPlaying) {
      try {
        // 先停止地下城音樂
        FlameAudio.bgm.stop();
        // 播放主世界音樂
        FlameAudio.bgm.play('bgm.mp3', volume: 0.25);
        _isBgmPlaying = true;
        _isDungeonBgmPlaying = false;
        debugPrint('已切換回主世界音樂');
      } catch (e) {
        debugPrint('主世界音樂播放失敗: $e');
      }
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
