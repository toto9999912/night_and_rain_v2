import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';

class MapComponent extends Component with HasGameRef {
  final Vector2 mapSize;
  TiledComponent? _tiledMap;

  MapComponent({required this.mapSize});
  // 設置 Tiled 地圖引用
  set tiledMap(TiledComponent? tiledMap) {
    _tiledMap = tiledMap;
  }

  // 獲取 Tiled 地圖引用
  TiledComponent? get tiledMap => _tiledMap;

  // 檢查障礙物碰撞
  bool checkObstacleCollision(Vector2 position, Vector2 size) {
    // 如果尚未設置 Tiled 地圖，直接返回 false
    if (_tiledMap == null) {
      return false;
    }

    // 獲取碰撞層 (如果有的話)
    final obstacleLayer = _tiledMap!.tileMap.getLayer<ObjectGroup>('obstacles');

    // 如果沒有碰撞層，暫時返回 false
    if (obstacleLayer == null) {
      return false;
    }

    // 實現簡單的碰撞檢測邏輯
    // 這裡需要根據你地圖中的具體障礙物設計來實現
    // 暫時返回 false，表示無碰撞
    return false;
  }

  // 檢查位置是否在地圖邊界內
  bool isInsideMap(Vector2 position, Vector2 size) {
    // 計算考慮物體大小的邊界
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;

    // 檢查是否在地圖範圍內
    return position.x >= halfWidth &&
        position.x <= mapSize.x - halfWidth &&
        position.y >= halfHeight &&
        position.y <= mapSize.y - halfHeight;
  }
}
