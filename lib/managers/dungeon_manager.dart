import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/collisions.dart';
import 'dart:math' as math;

import '../components/enemy_component.dart';
import '../components/boss_component.dart';
import '../components/portal_component.dart';
import '../components/npc_component.dart';
import '../components/player_component.dart';
import '../components/map_component.dart';
import '../components/mirror_man_component.dart';
import '../components/treasure_chest_component.dart';
import '../main.dart';

/// 地下城管理器，負責地下城的創建和管理
class DungeonManager {
  /// 地下城房間大小
  final Vector2 roomSize = Vector2(1000, 1000);

  /// 當前激活的房間ID
  String? currentRoomId;

  /// 所有地下城房間
  final Map<String, DungeonRoom> _rooms = {};

  /// 主遊戲引用
  final NightAndRainGame game;

  /// 地下城入口在主世界的位置
  final Vector2 entrancePosition;

  /// 地下城是否已創建
  bool _isDungeonCreated = false;

  /// 主世界的NPC和元素存儲
  final List<Component> _mainWorldComponents = [];

  /// 主世界可視
  bool _isMainWorldVisible = true;

  DungeonManager(this.game, {required this.entrancePosition});

  /// 初始化地下城
  void initialize() {
    if (_isDungeonCreated) return;

    // 創建地下城入口傳送門
    final entrancePortal = PortalComponent(
      position: entrancePosition,
      type: PortalType.dungeonEntrance,
      destinationId: 'dungeon_room_1',
      portalName: '地下城入口',
      color: Colors.purple,
    );

    game.gameWorld.add(entrancePortal);

    // 創建三個地下城房間
    _createDungeonRooms();

    _isDungeonCreated = true;
  }

  /// 創建地下城房間
  void _createDungeonRooms() {
    // 房間1 - 入口房間（簡單的敵人）
    _rooms['dungeon_room_1'] = DungeonRoom(
      id: 'dungeon_room_1',
      name: '地下城入口',
      backgroundColor: Colors.grey.shade900,
      size: roomSize,
      portalPositions: {
        'main_world': Vector2(roomSize.x * 0.5, roomSize.y * 0.8), // 回到主世界
        'dungeon_room_2': Vector2(roomSize.x * 0.8, roomSize.y * 0.5), // 去往房間2
      },
      enemyConfigs: [
        EnemyConfig(
          type: EnemyType.melee,
          count: 3,
          center: Vector2(roomSize.x * 0.3, roomSize.y * 0.3),
          radius: 100,
          color: Colors.red,
          health: 80,
          damage: 10,
          speed: 60,
        ),
        EnemyConfig(
          type: EnemyType.ranged,
          count: 2,
          center: Vector2(roomSize.x * 0.7, roomSize.y * 0.3),
          radius: 80,
          color: Colors.blue,
          health: 60,
          damage: 15,
          speed: 50,
          attackRange: 200,
        ),
      ],
      obstacles: [
        // 入口房間障礙物 - 石柱
        ObstacleData(
          position: Vector2(roomSize.x * 0.3, roomSize.y * 0.5),
          size: Vector2(40, 40),
          color: Colors.grey.shade800,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.7, roomSize.y * 0.5),
          size: Vector2(40, 40),
          color: Colors.grey.shade800,
        ),
        // 中央區域障礙
        ObstacleData(
          position: Vector2(roomSize.x * 0.5 - 60, roomSize.y * 0.4),
          size: Vector2(120, 20),
          color: Colors.grey.shade700,
        ),
      ],
    );

    // 房間2 - 中間房間（混合類型敵人）
    _rooms['dungeon_room_2'] = DungeonRoom(
      id: 'dungeon_room_2',
      name: '黑暗走廊',
      backgroundColor: Colors.blueGrey.shade900,
      size: roomSize,
      portalPositions: {
        'dungeon_room_1': Vector2(roomSize.x * 0.2, roomSize.y * 0.5), // 回到房間1
        'dungeon_room_3': Vector2(
          roomSize.x * 0.5,
          roomSize.y * 0.2,
        ), // 去往房間3（Boss房）
      },
      enemyConfigs: [
        EnemyConfig(
          type: EnemyType.hybrid,
          count: 4,
          center: Vector2(roomSize.x * 0.5, roomSize.y * 0.5),
          radius: 150,
          color: Colors.purple,
          health: 120,
          damage: 12,
          speed: 70,
          attackRange: 150,
        ),
        EnemyConfig(
          type: EnemyType.hunter,
          count: 2,
          center: Vector2(roomSize.x * 0.7, roomSize.y * 0.7),
          radius: 100,
          color: Colors.red.shade800,
          health: 100,
          damage: 18,
          speed: 90,
          attackRange: 50,
          detectionRange: 400,
        ),
      ],
      obstacles: [
        // 走廊障礙物 - 黑暗走廊的柱子
        ObstacleData(
          position: Vector2(roomSize.x * 0.3, roomSize.y * 0.3),
          size: Vector2(30, 30),
          color: Colors.blueGrey.shade700,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.7, roomSize.y * 0.3),
          size: Vector2(30, 30),
          color: Colors.blueGrey.shade700,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.3, roomSize.y * 0.7),
          size: Vector2(30, 30),
          color: Colors.blueGrey.shade700,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.7, roomSize.y * 0.7),
          size: Vector2(30, 30),
          color: Colors.blueGrey.shade700,
        ),
        // 中央十字障礙
        ObstacleData(
          position: Vector2(roomSize.x * 0.5 - 100, roomSize.y * 0.5 - 10),
          size: Vector2(200, 20),
          color: Colors.blueGrey.shade800,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.5 - 10, roomSize.y * 0.5 - 100),
          size: Vector2(20, 200),
          color: Colors.blueGrey.shade800,
        ),
      ],
    );

    // 房間3 - Boss房間
    _rooms['dungeon_room_3'] = DungeonRoom(
      id: 'dungeon_room_3',
      name: '深淵王座',
      backgroundColor: Colors.red.shade900.withOpacity(0.5),
      size: roomSize,
      portalPositions: {
        'dungeon_room_2': Vector2(roomSize.x * 0.5, roomSize.y * 0.8), // 回到房間2
      },
      enemyConfigs: [],
      bossConfig: BossConfig(
        position: Vector2(roomSize.x * 0.5, roomSize.y * 0.4),
        bossName: '蘋果怪客',
        color: Colors.deepPurple,
        health: 1500,
        damage: 25,
        speed: 60,
        enemySize: 50,
        attackRange: 180,
      ),
      obstacles: [
        // Boss房間障礙物 - 王座周圍的柱子
        ObstacleData(
          position: Vector2(roomSize.x * 0.3, roomSize.y * 0.3),
          size: Vector2(35, 35),
          color: Colors.red.shade800,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.7, roomSize.y * 0.3),
          size: Vector2(35, 35),
          color: Colors.red.shade800,
        ),
        // 王座平台
        ObstacleData(
          position: Vector2(roomSize.x * 0.4, roomSize.y * 0.2),
          size: Vector2(200, 15),
          color: Colors.deepPurple.shade900,
        ),
      ],
    );

    // 秘密走廊 - 只能在擊敗Boss後透過特殊傳送門進入
    _rooms['secret_corridor'] = DungeonRoom(
      id: 'secret_corridor',
      name: '神秘迴廊',
      backgroundColor: Colors.indigo.shade900.withOpacity(0.7),
      size: roomSize,
      portalPositions: {
        'dungeon_room_3': Vector2(
          roomSize.x * 0.1,
          roomSize.y * 0.5,
        ), // 回到Boss房間
      },
      enemyConfigs: [], // 沒有敵人
      obstacles: [
        // 中央區域 - 寶箱台座
        ObstacleData(
          position: Vector2(roomSize.x * 0.5 - 50, roomSize.y * 0.5 - 50),
          size: Vector2(100, 100),
          color: Colors.indigo.shade800,
        ),
        // 裝飾性的柱子
        ObstacleData(
          position: Vector2(roomSize.x * 0.3, roomSize.y * 0.2),
          size: Vector2(30, 30),
          color: Colors.purple.shade800,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.7, roomSize.y * 0.2),
          size: Vector2(30, 30),
          color: Colors.purple.shade800,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.3, roomSize.y * 0.8),
          size: Vector2(30, 30),
          color: Colors.purple.shade800,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.7, roomSize.y * 0.8),
          size: Vector2(30, 30),
          color: Colors.purple.shade800,
        ),
        // 鏡子框架
        ObstacleData(
          position: Vector2(roomSize.x * 0.5 - 100, roomSize.y * 0.3 - 5),
          size: Vector2(200, 10),
          color: Colors.grey.shade600,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.5 - 100, roomSize.y * 0.7 - 5),
          size: Vector2(200, 10),
          color: Colors.grey.shade600,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.5 - 105, roomSize.y * 0.3),
          size: Vector2(10, 400),
          color: Colors.grey.shade600,
        ),
        ObstacleData(
          position: Vector2(roomSize.x * 0.5 + 95, roomSize.y * 0.3),
          size: Vector2(10, 400),
          color: Colors.grey.shade600,
        ),
      ],
      specialSetup: (game, room) {
        // 添加鏡像人NPC
        final mirrorMan = MirrorManComponent(
          position: Vector2(roomSize.x * 0.5, roomSize.y * 0.5),
          name: '鏡像人',
          color: Colors.lightBlue.shade300,
          dialogues: [
            '歡迎來到鏡像世界...',
            '你看到的是真實的自己嗎？',
            '寶箱的密碼就是你的倒影...',
            '用數字表達自己，找到真相...',
          ],
        );
        game.gameWorld.add(mirrorMan);

        // 添加寶箱 - 需要密碼打開
        final treasureChest = TreasureChestComponent(
          position: Vector2(roomSize.x * 0.5, roomSize.y * 0.5 - 60),
          name: '神秘寶箱',
          password: '42815', // 這是密碼，可以根據遊戲需求修改
        );
        game.gameWorld.add(treasureChest);
      },
    );
  }

  /// 處理傳送門傳送
  void handlePortalTransport(String destinationId, PortalType type) {
    switch (type) {
      case PortalType.dungeonEntrance:
        // 從主世界進入地下城
        _hideMainWorld(); // 先隱藏主世界
        _activateRoom(destinationId);
        break;
      case PortalType.dungeonRoom:
        // 在地下城房間間移動
        _activateRoom(destinationId);
        break;
      case PortalType.returnToMainWorld:
        // 從地下城返回主世界
        _returnToMainWorld();
        break;
    }
  }

  /// 激活指定房間
  void _activateRoom(String roomId) {
    // 獲取要激活的房間
    final room = _rooms[roomId];
    if (room == null) return;

    // 清除當前世界組件（敵人、傳送門等）
    _clearGameWorld();

    // 設置當前房間ID
    currentRoomId = roomId;

    // 載入房間
    room.loadIntoWorld(game);
  }

  /// 返回主世界
  void _returnToMainWorld() {
    // 清除當前世界組件
    _clearGameWorld();

    // 重設當前房間ID
    currentRoomId = null;

    // 重置玩家位置到入口附近
    game.resetPlayerPosition(entrancePosition + Vector2(0, 50));

    // 重新添加入口傳送門（如果需要）
    final entrancePortal = PortalComponent(
      position: entrancePosition,
      type: PortalType.dungeonEntrance,
      destinationId: 'dungeon_room_1',
      portalName: '地下城入口',
      color: Colors.purple,
    );

    game.gameWorld.add(entrancePortal);

    // 顯示主世界
    _showMainWorld();
  }

  /// 清除遊戲世界
  void _clearGameWorld() {
    // 移除所有敵人
    game.gameWorld.children.whereType<EnemyComponent>().forEach((enemy) {
      enemy.removeFromParent();
    });

    // 移除所有Boss
    game.gameWorld.children.whereType<BossComponent>().forEach((boss) {
      boss.removeFromParent();
    });

    // 移除所有傳送門
    game.gameWorld.children.whereType<PortalComponent>().forEach((portal) {
      portal.removeFromParent();
    });
  }

  /// 隱藏主世界中的NPC和其他元素
  void _hideMainWorld() {
    if (!_isMainWorldVisible) return;

    _mainWorldComponents.clear();

    // 保存並隱藏所有NPC
    game.gameWorld.children.whereType<NpcComponent>().toList().forEach((npc) {
      _mainWorldComponents.add(npc);
      npc.removeFromParent();
    });

    // 保存並隱藏主世界的背景和障礙物
    final componentsToHide = <Component>[];

    game.gameWorld.children.forEach((component) {
      // 不處理玩家和敵人
      if (component is! PlayerComponent &&
          component is! EnemyComponent &&
          component is! BossComponent &&
          component is! PortalComponent) {
        // 地圖元素需要保存起來
        if (component is RectangleComponent ||
            component is MapComponent ||
            component is BoundaryWall ||
            component is Obstacle) {
          componentsToHide.add(component);
        }
      }
    });

    // 移除已保存的組件
    for (final component in componentsToHide) {
      if (component.parent != null) {
        _mainWorldComponents.add(component);
        component.removeFromParent();
      }
    }

    _isMainWorldVisible = false;
  }

  /// 恢復主世界
  void _showMainWorld() {
    if (_isMainWorldVisible) return;

    // 恢復所有主世界元素
    for (final component in _mainWorldComponents) {
      if (component.parent == null) {
        game.gameWorld.add(component);
      }
    }

    _mainWorldComponents.clear();
    _isMainWorldVisible = true;
  }
}

/// 地下城房間類
class DungeonRoom {
  /// 房間ID
  final String id;

  /// 房間名稱
  final String name;

  /// 背景顏色
  final Color backgroundColor;

  /// 房間大小
  final Vector2 size;

  /// 傳送門位置 Map<目的地ID, 位置>
  final Map<String, Vector2> portalPositions;

  /// 敵人配置
  final List<EnemyConfig> enemyConfigs;

  /// Boss配置（如果有）
  final BossConfig? bossConfig;

  /// 房間內的障礙物
  final List<ObstacleData> obstacles;

  /// 特殊設置函數 - 用於添加自定義元素到房間
  final Function(NightAndRainGame, DungeonRoom)? specialSetup;

  DungeonRoom({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.size,
    required this.portalPositions,
    this.enemyConfigs = const [],
    this.bossConfig,
    this.obstacles = const [],
    this.specialSetup,
  });

  /// 將房間加載到遊戲世界
  void loadIntoWorld(NightAndRainGame game) {
    // 1. 添加房間背景
    game.gameWorld.add(
      RectangleComponent(
        position: Vector2.zero(),
        size: size,
        paint: Paint()..color = backgroundColor,
        priority: 0,
      ),
    );

    // 2. 添加房間邊界
    _addRoomBoundaries(game);

    // 3. 添加障礙物
    _addObstacles(game);

    // 4. 添加傳送門
    _addPortals(game);

    // 5. 添加敵人
    _addEnemies(game);

    // 6. 添加Boss（如果有）
    if (bossConfig != null) {
      _addBoss(game);
    }

    // 7. 執行特殊設置（如果有）
    if (specialSetup != null) {
      specialSetup!(game, this);
    }

    // 8. 設置玩家位置（根據來源房間決定）
    _setPlayerPosition(game);
  }

  /// 添加房間邊界
  void _addRoomBoundaries(NightAndRainGame game) {
    // 上邊界
    game.gameWorld.add(
      RectangleComponent(
        position: Vector2(0, 0),
        size: Vector2(size.x, 10),
        paint: Paint()..color = Colors.black,
      )..add(RectangleHitbox()..collisionType = CollisionType.passive),
    );

    // 下邊界
    game.gameWorld.add(
      RectangleComponent(
        position: Vector2(0, size.y - 10),
        size: Vector2(size.x, 10),
        paint: Paint()..color = Colors.black,
      )..add(RectangleHitbox()..collisionType = CollisionType.passive),
    );

    // 左邊界
    game.gameWorld.add(
      RectangleComponent(
        position: Vector2(0, 0),
        size: Vector2(10, size.y),
        paint: Paint()..color = Colors.black,
      )..add(RectangleHitbox()..collisionType = CollisionType.passive),
    );

    // 右邊界
    game.gameWorld.add(
      RectangleComponent(
        position: Vector2(size.x - 10, 0),
        size: Vector2(10, size.y),
        paint: Paint()..color = Colors.black,
      )..add(RectangleHitbox()..collisionType = CollisionType.passive),
    );

    // 添加可見的邊界線框 - 這有助於視覺上區分地下城與主世界
    game.gameWorld.add(
      RectangleComponent(
        position: Vector2(0, 0),
        size: size,
        paint:
            Paint()
              ..color = Colors.white.withOpacity(0.1)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
      ),
    );
  }

  /// 添加障礙物
  void _addObstacles(NightAndRainGame game) {
    for (final obstacle in obstacles) {
      game.gameWorld.add(
        RectangleComponent(
          position: obstacle.position,
          size: obstacle.size,
          paint: Paint()..color = obstacle.color,
        )..add(RectangleHitbox()..collisionType = CollisionType.passive),
      );
    }
  }

  /// 添加傳送門
  void _addPortals(NightAndRainGame game) {
    portalPositions.forEach((destinationId, position) {
      PortalType portalType;
      String portalName;
      Color portalColor;

      // 決定傳送門類型
      if (destinationId == 'main_world') {
        portalType = PortalType.returnToMainWorld;
        portalName = '返回主世界';
        portalColor = Colors.green;
      } else {
        portalType = PortalType.dungeonRoom;

        // 根據目的地ID設置不同的名稱
        switch (destinationId) {
          case 'dungeon_room_1':
            portalName = '前往入口房間';
            portalColor = Colors.blue;
            break;
          case 'dungeon_room_2':
            portalName = '前往黑暗走廊';
            portalColor = Colors.orange;
            break;
          case 'dungeon_room_3':
            portalName = '前往深淵王座';
            portalColor = Colors.red;
            break;
          default:
            portalName = '傳送門';
            portalColor = Colors.purple;
        }
      }

      // 創建並添加傳送門
      final portal = PortalComponent(
        position: position,
        type: portalType,
        destinationId: destinationId,
        portalName: portalName,
        color: portalColor,
      );

      game.gameWorld.add(portal);
    });
  }

  /// 添加敵人
  void _addEnemies(NightAndRainGame game) {
    for (final config in enemyConfigs) {
      _spawnEnemyGroup(game, config);
    }
  }

  /// 生成敵人組
  void _spawnEnemyGroup(NightAndRainGame game, EnemyConfig config) {
    final random = math.Random();

    for (int i = 0; i < config.count; i++) {
      // 在指定半徑內隨機生成位置
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * config.radius;
      final offset = Vector2(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );

      final position = config.center + offset;

      // 創建敵人
      final enemy = EnemyComponent(
        position: position,
        type: config.type,
        mapComponent: game.getMapComponent(),
        color: config.color,
        maxHealth: config.health,
        damage: config.damage,
        speed: config.speed,
        attackRange: config.attackRange,
        detectionRange: config.detectionRange,
        attackCooldown: config.attackCooldown,
        enemySize: config.enemySize,
      );

      game.gameWorld.add(enemy);
    }
  }

  /// 添加Boss
  void _addBoss(NightAndRainGame game) {
    if (bossConfig == null) return;

    final boss = BossComponent(
      position: bossConfig!.position,
      mapComponent: game.getMapComponent(),
      bossName: bossConfig!.bossName,
      maxHealth: bossConfig!.health,
      damage: bossConfig!.damage,
      speed: bossConfig!.speed,
      attackRange: bossConfig!.attackRange,
      detectionRange: bossConfig!.detectionRange,
      attackCooldown: bossConfig!.attackCooldown,
      color: bossConfig!.color,
      enemySize: bossConfig!.enemySize,
      attackPatterns: bossConfig!.attackPatterns,
      totalPhases: bossConfig!.totalPhases,
      specialAttackInterval: bossConfig!.specialAttackInterval,
      summonInterval: bossConfig!.summonInterval,
    );

    game.gameWorld.add(boss);
  }

  /// 設置玩家位置
  void _setPlayerPosition(NightAndRainGame game) {
    // 獲取之前的房間ID
    final previousRoomId = game.dungeonManager?.currentRoomId;

    // 如果是從主世界進入，則放在傳送回主世界的傳送門附近
    if (previousRoomId == null) {
      final returnPortalPos = portalPositions['main_world'];
      if (returnPortalPos != null) {
        // 放在回主世界傳送門上方
        game.resetPlayerPosition(returnPortalPos - Vector2(0, 50));
        return;
      }
    }
    // 如果是從其他房間進入，則放在對應的傳送門附近
    else if (portalPositions.containsKey(previousRoomId)) {
      final portalPos = portalPositions[previousRoomId]!;

      // 根據傳送門位置計算出合適的玩家位置
      Vector2 playerOffset = Vector2.zero();

      // 如果傳送門在左側，玩家放在右側
      if (portalPos.x < size.x * 0.3) {
        playerOffset = Vector2(50, 0);
      }
      // 如果傳送門在右側，玩家放在左側
      else if (portalPos.x > size.x * 0.7) {
        playerOffset = Vector2(-50, 0);
      }
      // 如果傳送門在上方，玩家放在下方
      else if (portalPos.y < size.y * 0.3) {
        playerOffset = Vector2(0, 50);
      }
      // 如果傳送門在下方，玩家放在上方
      else if (portalPos.y > size.y * 0.7) {
        playerOffset = Vector2(0, -50);
      }

      game.resetPlayerPosition(portalPos + playerOffset);
      return;
    }

    // 默認位置（如果沒有找到合適的位置）
    game.resetPlayerPosition(Vector2(size.x / 2, size.y / 2));
  }
}

/// 敵人配置類
class EnemyConfig {
  final EnemyType type;
  final int count;
  final Vector2 center;
  final double radius;
  final Color color;
  final double health;
  final double damage;
  final double speed;
  final double attackRange;
  final double detectionRange;
  final double attackCooldown;
  final double enemySize;

  EnemyConfig({
    required this.type,
    required this.count,
    required this.center,
    required this.radius,
    this.color = Colors.red,
    this.health = 100,
    this.damage = 10,
    this.speed = 60,
    this.attackRange = 30,
    this.detectionRange = 200,
    this.attackCooldown = 1.0,
    this.enemySize = 24,
  });
}

/// Boss配置類
class BossConfig {
  final Vector2 position;
  final String bossName;
  final Color color;
  final double health;
  final double damage;
  final double speed;
  final double attackRange;
  final double detectionRange;
  final double attackCooldown;
  final double enemySize;
  final List<BossAttackPattern> attackPatterns;
  final int totalPhases;
  final double specialAttackInterval;
  final double summonInterval;

  BossConfig({
    required this.position,
    required this.bossName,
    this.color = Colors.deepPurple,
    this.health = 1000,
    this.damage = 25,
    this.speed = 40,
    this.attackRange = 150,
    this.detectionRange = 500,
    this.attackCooldown = 1.5,
    this.enemySize = 40,
    this.attackPatterns = const [
      BossAttackPattern.circularAttack,
      BossAttackPattern.beamAttack,
      BossAttackPattern.aoeAttack,
    ],
    this.totalPhases = 3,
    this.specialAttackInterval = 8.0,
    this.summonInterval = 15.0,
  });
}

/// 障礙物數據類
class ObstacleData {
  final Vector2 position;
  final Vector2 size;
  final Color color;

  ObstacleData({
    required this.position,
    required this.size,
    this.color = Colors.black54,
  });
}

/// 邊界牆壁類 - 用於碰撞檢測
class BoundaryWall extends PositionComponent with CollisionCallbacks {
  BoundaryWall({required Vector2 position, required Vector2 size})
    : super(position: position, size: size) {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
}

/// 障礙物類 - 用於碰撞檢測
class Obstacle extends PositionComponent with CollisionCallbacks {
  Obstacle({required Vector2 position, required Vector2 size})
    : super(position: position, size: size) {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
}
