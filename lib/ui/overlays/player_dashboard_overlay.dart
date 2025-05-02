import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/providers/inventory_provider.dart';
import 'package:night_and_rain_v2/providers/player_provider.dart';

class PlayerDashboardOverlay extends ConsumerWidget {
  final FlameGame game;
  const PlayerDashboardOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final inventory = ref.watch(inventoryProvider);
    final weapon = player.equippedWeapon;
    // final armor = player.equippedArmor;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          width: 400,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 關閉提示
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => game.overlays.remove('InventoryOverlay'),
                ),
              ),
              const SizedBox(height: 8),

              // 角色狀態
              Text('角色狀態', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 4),
              _buildBar('HP', player.health / 100, Colors.red),
              const SizedBox(height: 4),
              _buildBar('MP', player.mana / 100, Colors.blue),
              const SizedBox(height: 4),
              Text(
                'Speed: ${player.speed.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),

              // 裝備欄
              Text('裝備', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 4),
              Row(
                children: [
                  weapon != null
                      ? _equipSlot('武器', weapon.name)
                      : _equipSlot('武器', '無'),
                  const SizedBox(width: 16),
                  // 裝備防具的位置（待開發）
                  _equipSlot('防具', '無'),
                ],
              ),
              const SizedBox(height: 12),

              // 背包格子
              Text('背包', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  itemCount: inventory.capacity,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (_, idx) {
                    // 檢查索引是否在物品列表範圍內
                    final hasItem = idx < inventory.items.length;
                    final item = hasItem ? inventory.items[idx] : null;

                    return GestureDetector(
                      onTap:
                          hasItem
                              ? () {
                                ref
                                    .read(playerProvider.notifier)
                                    .useItem(item!);
                                // 如果物品是裝備類型，使用後通常會關閉背包
                                game.overlays.remove('InventoryOverlay');
                              }
                              : null,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white54),
                          color: Colors.grey[800],
                        ),
                        child: Center(
                          child:
                              hasItem
                                  ? Icon(item!.icon, color: item.rarity.color)
                                  : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double fraction, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(label, style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  color: color.withOpacity(0.3),
                ),
              ),
              Container(
                width:
                    fraction *
                    MediaQueryData.fromView(
                      WidgetsBinding.instance.window,
                    ).size.width *
                    0.2,
                height: 16,
                color: color,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _equipSlot(String title, String name) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white54),
            color: Colors.grey[800],
          ),
          child: Center(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}
