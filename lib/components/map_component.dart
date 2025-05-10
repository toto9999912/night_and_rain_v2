import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

class MapComponent extends Component with HasGameReference {
  late final Vector2 mapSize;
  final List<Obstacle> obstacles = [];

  MapComponent({required this.mapSize});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加邊界牆
    await _addBoundaryWalls();

    // 添加障礙物
    await _addObstacles();
  }

  Future<void> _addBoundaryWalls() async {
    // 上邊界
    await add(
      BoundaryWall(position: Vector2(0, -10), size: Vector2(mapSize.x, 10)),
    );

    // 下邊界
    await add(
      BoundaryWall(
        position: Vector2(0, mapSize.y),
        size: Vector2(mapSize.x, 10),
      ),
    );

    // 左邊界
    await add(
      BoundaryWall(position: Vector2(-10, 0), size: Vector2(10, mapSize.y)),
    );

    // 右邊界
    await add(
      BoundaryWall(
        position: Vector2(mapSize.x, 0),
        size: Vector2(10, mapSize.y),
      ),
    );
  }

  Future<void> _addObstacles() async {
    // 已移除所有障礙物，僅保留邊界牆
    // obstacles 列表將保持為空
  }

  // 檢查指定位置是否與障礙物碰撞
  bool checkObstacleCollision(Vector2 position, Vector2 size) {
    final rect = Rect.fromLTWH(position.x, position.y, size.x, size.y);

    for (final obstacle in obstacles) {
      final obstacleRect = Rect.fromLTWH(
        obstacle.position.x,
        obstacle.position.y,
        obstacle.size.x,
        obstacle.size.y,
      );

      if (rect.overlaps(obstacleRect)) {
        return true;
      }
    }

    return false;
  }
}

// 邊界牆類
class BoundaryWall extends PositionComponent with CollisionCallbacks {
  BoundaryWall({required Vector2 position, required Vector2 size})
    : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加碰撞檢測
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
}

// 障礙物類
class Obstacle extends PositionComponent with CollisionCallbacks {
  final Color color;

  Obstacle({
    required Vector2 position,
    required Vector2 size,
    this.color = Colors.brown,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 視覺效果
    add(RectangleComponent(size: size, paint: Paint()..color = color));

    // 添加碰撞檢測
    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }
}
