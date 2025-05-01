import '../models/player.dart';

abstract class PlayerEffect {
  final String name;
  final String description;
  final double duration; // 效果持續時間（秒）

  PlayerEffect({
    required this.name,
    required this.description,
    required this.duration,
  });

  // 初始應用效果
  void apply(Player player);

  // 持續效果的每幀更新
  void update(Player player, double dt);

  // 效果結束時調用
  void end(Player player);

  // 產生效果描述
  String getDescription() => description;
}
