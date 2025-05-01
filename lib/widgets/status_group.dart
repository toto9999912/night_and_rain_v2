// 狀態條組
import 'package:flutter/material.dart';

class StatusGroup extends StatelessWidget {
  final int health;
  final int mana;

  const StatusGroup({super.key, required this.health, required this.mana});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // 確保緊湊布局
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 生命值條
        _StatusBar(
          value: health / 100,
          maxValue: 100,
          currentValue: health,
          barColor: const Color(0xFFF24C6D),
          backgroundColor: const Color(0x99423042),
          icon: Icons.favorite,
          width: 160,
        ),

        const SizedBox(height: 8),

        // 魔力值條
        _StatusBar(
          value: mana / 100,
          maxValue: 100,
          currentValue: mana,
          barColor: const Color(0xFF5AB3FF),
          backgroundColor: const Color(0x99304254),
          icon: Icons.auto_awesome,
          width: 160,
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final double value;
  final int maxValue;
  final int currentValue;
  final Color barColor;
  final Color backgroundColor;
  final IconData icon;
  final double width;

  const _StatusBar({
    required this.value,
    required this.maxValue,
    required this.currentValue,
    required this.barColor,
    required this.backgroundColor,
    required this.icon,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 28,
      child: Stack(
        children: [
          // 外層陰影
          Container(
            width: width,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),

          // 狀態條主體
          Row(
            children: [
              // 圖標圓形
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: barColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              // 狀態條
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      // 背景
                      Container(height: 28, color: backgroundColor),
                      // 填充
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final barWidth = constraints.maxWidth * value;
                          return Container(
                            height: 28,
                            width: barWidth,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  barColor.withValues(alpha: 0.8),
                                  barColor,
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child:
                                  barWidth > 5
                                      ? Container(
                                        // 只有當條足夠寬時才顯示分隔線
                                        width: 2,
                                        height: 20,
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                      )
                                      : null,
                            ),
                          );
                        },
                      ),
                      // 數值文字
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '$currentValue',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              shadows: [
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
