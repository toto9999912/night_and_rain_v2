import 'package:flutter/material.dart';
import 'package:night_and_rain_v2/models/armor.dart';
import 'package:night_and_rain_v2/models/consumable.dart';
import 'package:night_and_rain_v2/models/item.dart';
import 'package:night_and_rain_v2/models/weapon.dart';
import 'package:night_and_rain_v2/ui/widgets/stat_row.dart';

/// 物品詳情卡片 - 顯示物品詳細資訊
class ItemDetailCard extends StatelessWidget {
  final Item item;

  const ItemDetailCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black87,
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: item.rarity.color.withOpacity(0.7), width: 2),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 物品名稱和圖標
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(item.icon, color: item.rarity.color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: item.rarity.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            // 品級顯示
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.rarity.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '品級: ${item.rarity.name}',
                style: TextStyle(
                  color: item.rarity.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),

            // 物品描述
            if (item.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  item.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),

            // 物品屬性 - 依據物品類型顯示不同屬性
            _buildItemStats(),

            // 物品底部資訊 (堆疊、價格等)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.isStackable)
                  Text(
                    '可堆疊: ${item.quantity}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.amber,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${item.price}',
                      style: const TextStyle(color: Colors.amber, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 根據物品類型構建不同的屬性顯示
  Widget _buildItemStats() {
    if (item is Weapon) {
      final weapon = item as Weapon;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatRow(label: '武器類型', value: weapon.weaponType.name),
          StatRow(
            label: '傷害',
            value: weapon.damage.toString(),
            color: Colors.redAccent,
          ),
          StatRow(label: '攻擊速度', value: weapon.cooldown.toString()),
          StatRow(label: '攻擊範圍', value: weapon.range.toString()),
          StatRow(label: '冷卻時間', value: '${weapon.cooldown}秒'),
          if (weapon.manaCost > 0)
            StatRow(
              label: '魔力消耗',
              value: weapon.manaCost.toString(),
              color: Colors.blueAccent,
            ),
          const SizedBox(height: 4),
        ],
      );
    } else if (item is Consumable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatRow(label: '類型', value: '消耗品'),
          StatRow(label: '效果', value: '使用後回復能量'),
          const SizedBox(height: 4),
        ],
      );
    } else if (item is Armor) {
      final armor = item as Armor;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatRow(label: '類型', value: '防具'),
          StatRow(
            label: '防禦力',
            value: armor.defense.toString(),
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 4),
        ],
      );
    }

    return const SizedBox.shrink(); // 默認為空
  }
}
