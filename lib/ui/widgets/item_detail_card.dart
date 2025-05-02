import 'package:flutter/material.dart';
import 'package:night_and_rain_v2/models/armor.dart';
import 'package:night_and_rain_v2/models/consumable.dart';
import 'package:night_and_rain_v2/models/item.dart';
import 'package:night_and_rain_v2/models/weapon.dart';

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
                color: item.rarity.color.withOpacity(0.2),
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
          _buildStatRow('武器類型', weapon.weaponType.name),
          _buildStatRow(
            '傷害',
            weapon.damage.toString(),
            color: Colors.redAccent,
          ),
          _buildStatRow('攻擊速度', weapon.attackSpeed.toString()),
          _buildStatRow('攻擊範圍', weapon.range.toString()),
          _buildStatRow('冷卻時間', '${weapon.cooldown}秒'),
          if (weapon.manaCost > 0)
            _buildStatRow(
              '魔力消耗',
              weapon.manaCost.toString(),
              color: Colors.blueAccent,
            ),
          const SizedBox(height: 4),
        ],
      );
    } else if (item is Consumable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('類型', '消耗品'),
          _buildStatRow('效果', '使用後回復能量'),
          const SizedBox(height: 4),
        ],
      );
    } else if (item is Armor) {
      final armor = item as Armor;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('類型', '防具'),
          _buildStatRow(
            '防禦力',
            armor.defense.toString(),
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 4),
        ],
      );
    }

    return const SizedBox.shrink(); // 默認為空
  }

  // 構建屬性行顯示
  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
