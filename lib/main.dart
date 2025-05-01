import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame_riverpod/flame_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/weapon.dart';
import 'providers/items_data_provider.dart';
import 'providers/player_provider.dart';
import 'ui/overlays/hud_overlay.dart';
import 'components/player_component.dart';
import 'ui/overlays/player_dashboard_overlay.dart';

final GlobalKey<RiverpodAwareGameWidgetState<NightAndRainGame>> gameWidgetKey =
    GlobalKey<RiverpodAwareGameWidgetState<NightAndRainGame>>();
final gameInstance = NightAndRainGame();

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
        game: NightAndRainGame(),
        key: gameWidgetKey,
        overlayBuilderMap: {
          'HudOverlay': (context, game) => HudOverlay(game: game),
          'InventoryOverlay':
              (context, game) => PlayerDashboardOverlay(game: game),
        },
        initialActiveOverlays: const ['HudOverlay'],
      ),
    );
  }
}

class NightAndRainGame extends FlameGame
    with
        HasKeyboardHandlerComponents,
        HasCollisionDetection, // 添加碰撞檢測功能
        MouseMovementDetector, // 添加鼠標移動檢測
        TapDetector, // 添加點擊檢測
        RiverpodGameMixin {
  late final World gameWorld;
  late final CameraComponent _cameraComponent;
  late final PlayerComponent _player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // world + camera (同之前)
    gameWorld = World();
    await add(gameWorld);
    _cameraComponent = CameraComponent(world: gameWorld)
      ..viewfinder.anchor = Anchor.center;
    await add(_cameraComponent);

    // 背景 & 格線 & 玩家 (同之前)…
    gameWorld.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: size,
        paint: Paint()..color = Colors.lightGreen,
        priority: 0,
      ),
    );
    gameWorld.add(_GridComponent(tileSize: 32)..priority = 1);
    _player =
        PlayerComponent()
          ..position = size / 2
          ..size = Vector2.all(32)
          ..priority = 2;
    gameWorld.add(_player);

    // 相機跟隨
    _cameraComponent.follow(_player);

    // 在這裡為玩家添加初始武器
    await _initializePlayerWeapon();
  }

  Future<void> _initializePlayerWeapon() async {
    // 等待一幀以確保 Provider 已完全初始化
    await Future.delayed(Duration.zero);

    // 從 itemsDataProvider 獲取初始武器
    final itemsData = ref.read(itemsDataProvider);
    final initialWeapon = itemsData['pistol_1'] as Weapon;

    // 添加到玩家庫存並裝備
    final playerNotifier = ref.read(playerProvider.notifier);
    playerNotifier.addItemToInventory(initialWeapon);
    playerNotifier.equipWeapon(initialWeapon);
  }
}

class _GridComponent extends Component with HasGameReference<FlameGame> {
  final double tileSize;
  final Paint _paint =
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..strokeWidth = 1;

  _GridComponent({this.tileSize = 32});

  @override
  void render(Canvas canvas) {
    final w = game.size.x;
    final h = game.size.y;

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
