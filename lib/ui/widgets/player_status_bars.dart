import 'package:flutter/material.dart';

/// 單一狀態條 - 顯示資源條（如生命值、魔力值）
class StatusBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color barColor;
  final Color backgroundColor;
  final String? valueText;

  const StatusBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.barColor,
    required this.backgroundColor,
    this.valueText,
  });

  @override
  Widget build(BuildContext context) {
    // 計算填充比例
    final fillRatio = value / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標籤
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (valueText != null)
              Text(
                valueText!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 4),

        // 狀態條
        Stack(
          children: [
            // 背景
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(7),
              ),
            ),

            // 前景填充
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 14,
                  width: constraints.maxWidth * fillRatio,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                );
              },
            ),

            // 條紋效果
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                return SizedBox(
                  height: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      (width / 12).floor(),
                      (index) => Container(
                        width: 1.5,
                        height: 14,
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// 狀態列組
class PlayerStatusBars extends StatelessWidget {
  final int health;
  final int maxHealth;
  final int mana;
  final int maxMana;
  final int speed;
  final int money;

  const PlayerStatusBars({
    super.key,
    required this.health,
    required this.maxHealth,
    required this.mana,
    required this.maxMana,
    required this.speed,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '角色狀態',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          StatusBar(
            label: 'HP',
            value: health.toDouble(),
            maxValue: maxHealth.toDouble(),
            barColor: Colors.red.shade400,
            backgroundColor: Colors.red.shade900.withOpacity(0.2),
            valueText: '$health/$maxHealth',
          ),
          const SizedBox(height: 6),
          StatusBar(
            label: 'MP',
            value: mana.toDouble(),
            maxValue: maxMana.toDouble(),
            barColor: Colors.blue.shade400,
            backgroundColor: Colors.blue.shade900.withOpacity(0.2),
            valueText: '$mana/$maxMana',
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                '移動速度: ${speed.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white),
              ),
              const Spacer(),
              const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text('金幣: $money', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
