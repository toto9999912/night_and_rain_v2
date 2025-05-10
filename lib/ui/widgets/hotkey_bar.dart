import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/providers/inventory_provider.dart';
import 'package:night_and_rain_v2/providers/player_provider.dart';

/// 熱鍵欄
class HotkeyBar extends ConsumerWidget {
  HotkeyBar({super.key});

  final List<String> hotkeys = ['1', '2', '3', '4', '5'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(inventoryProvider);
    return FittedBox(
      // 確保能夠在較小屏幕上顯示
      fit: BoxFit.scaleDown,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: List.generate(5, (index) {
            final slot = index + 1;
            final item = inventory.hotkeyBindings[slot];
            return HotkeyButton(
              onPressed: () {
                if (item == null) return;
                ref.read(playerProvider.notifier).useItem(item);
              },
              isActive: item != null,
              icon: item?.icon ?? Icons.close,
              keyNumber: slot.toString(),
            );
          }),
        ),
      ),
    );
  }
}

/// 熱鍵按鈕
class HotkeyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;
  final String keyNumber;

  const HotkeyButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isActive = false,
    required this.keyNumber,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = 48; // 與背包中的熱鍵大小一致

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.3) : Colors.black45,
          border: Border.all(
            color: isActive ? Colors.yellow : Colors.white30,
            width: isActive ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            // 熱鍵數字
            Positioned(
              top: 2,
              left: 4,
              child: Text(
                keyNumber,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 顯示物品圖示
            Center(
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF87CEEB) : Colors.white54,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
