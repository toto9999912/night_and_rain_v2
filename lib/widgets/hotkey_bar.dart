import 'package:flutter/material.dart';

/// 熱鍵欄
class HotkeyBar extends StatelessWidget {
  HotkeyBar({super.key});

  final List<String> hotkeys = ['1', '2', '3', '4', '5'];

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      // 確保能夠在較小屏幕上顯示
      fit: BoxFit.scaleDown,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children:
              hotkeys
                  .map(
                    (key) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: HotkeyButton(
                        label: key,
                        onPressed: () {
                          // TODO: 使用綁定的物品
                        },
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

/// 熱鍵按鈕
class HotkeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const HotkeyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = 46;

    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Stack(
          children: [
            // 背景和邊框
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isActive
                        ? const Color(0xFF387AAF).withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.5),
                border: Border.all(
                  color:
                      isActive
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isActive
                            ? const Color(0xFF387AAF).withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),

            // 輕微光澤效果
            ClipOval(
              child: Container(
                width: buttonSize,
                height: buttonSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),

            // 數字標籤
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    shadows: const [
                      Shadow(
                        color: Colors.black,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 中央物品槽
            Center(
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
