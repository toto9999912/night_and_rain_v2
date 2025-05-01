// 當前武器展示
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../enum/weapon_type.dart';

class CurrentWeaponDisplay extends ConsumerWidget {
  final String weaponName;
  final WeaponType weaponType;

  const CurrentWeaponDisplay({
    super.key,
    required this.weaponName,
    required this.weaponType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200), // 限制最大寬度
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          // 確保子元素高度一致
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 武器圖標
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF636363).withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _getWeaponIcon(weaponType),
              ),
              const SizedBox(width: 10),
              // 武器名稱和彈藥信息
              Flexible(
                // 使用Flexible允許文本自適應
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
                  children: [
                    Text(
                      '裝備中',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      weaponName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis, // 防止文本溢出
                      maxLines: 1, // 限制一行
                    ),

                    // 武器冷卻進度條
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 根據武器類型獲取圖標
  Widget _getWeaponIcon(WeaponType type) {
    IconData iconData;

    switch (type) {
      case WeaponType.pistol:
        iconData = Icons.sports_handball;
        break;
      case WeaponType.machineGun:
        iconData = Icons.settings_input_component;
        break;
      case WeaponType.shotgun:
        iconData = Icons.open_with;
        break;
      case WeaponType.sniper:
        iconData = Icons.center_focus_strong;
        break;
      case WeaponType.sword:
        iconData = Icons.sports_martial_arts;
        break;
    }

    return Icon(iconData, color: Colors.white, size: 20);
  }

  // 根據武器類型獲取冷卻條顏色
  Color _getCooldownColor(WeaponType type) {
    switch (type) {
      case WeaponType.pistol:
        return Colors.yellow.withValues(alpha: 0.7);
      case WeaponType.machineGun:
        return Colors.orange.withValues(alpha: 0.7);
      case WeaponType.shotgun:
        return Colors.red.withValues(alpha: 0.7);
      case WeaponType.sniper:
        return Colors.purple.withValues(alpha: 0.7);
      default:
        return Colors.blue.withValues(alpha: 0.7);
    }
  }
}
