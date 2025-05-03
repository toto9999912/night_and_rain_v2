// 狀態條組
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/player_buffs_provider.dart';
import '../../providers/player_provider.dart';

class StatusGroup extends ConsumerWidget {
  final int health;
  final int mana;
  // 添加最大生命值參數
  final int? maxHealth;

  const StatusGroup({
    super.key,
    required this.health,
    required this.mana,
    this.maxHealth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 獲取玩家狀態

    // 使用傳入的最大生命值或從Provider獲取
    // 確保有一個預設值，避免null值
    final actualMaxHealth =
        maxHealth ?? ref.watch(playerMaxHealthProvider) ?? 100;
    // 獲取玩家加成效果
    final buffs = ref.watch(playerBuffsProvider).activeBuffs;

    return Column(
      mainAxisSize: MainAxisSize.min, // 確保緊湊布局
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 生命值條
        _StatusBar(
          value: (health / actualMaxHealth).clamp(0.0, 1.0),
          maxValue: actualMaxHealth,
          currentValue: health,
          barColor: const Color(0xFFF24C6D),
          backgroundColor: const Color(0x99423042),
          icon: Icons.favorite,
          width: 160,
        ),

        const SizedBox(height: 8),

        // 魔力值條
        _StatusBar(
          value: (mana / 100).clamp(0.0, 1.0),
          maxValue: 100,
          currentValue: mana,
          barColor: const Color(0xFF5AB3FF),
          backgroundColor: const Color(0x99304254),
          icon: Icons.auto_awesome,
          width: 160,
        ),

        // 顯示加成效果
        if (buffs.isNotEmpty) ...[
          const SizedBox(height: 8),
          _BuffsDisplay(buffs: buffs),
        ],
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
                            '$currentValue/$maxValue',
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

// 加成效果顯示組件
class _BuffsDisplay extends StatelessWidget {
  final List<PlayerBuff> buffs;

  const _BuffsDisplay({required this.buffs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final buff in buffs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: buff.color.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(buff.icon, color: buff.color, size: 12),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      buff.description,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
