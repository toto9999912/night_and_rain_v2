import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/main.dart';
import 'package:night_and_rain_v2/models/item.dart';
import 'package:night_and_rain_v2/providers/inventory_provider.dart';
import 'package:night_and_rain_v2/providers/player_provider.dart';
import 'package:night_and_rain_v2/ui/widgets/item_decorations.dart';
import 'package:night_and_rain_v2/ui/widgets/status_group.dart'; // 引入統一的 StatusBar 元件
import '../widgets/item_detail_card.dart';

class PlayerDashboardOverlay extends ConsumerStatefulWidget {
  final NightAndRainGame game;

  const PlayerDashboardOverlay({super.key, required this.game});

  @override
  ConsumerState<PlayerDashboardOverlay> createState() =>
      _PlayerDashboardOverlayState();
}

class _PlayerDashboardOverlayState extends ConsumerState<PlayerDashboardOverlay>
    with WidgetsBindingObserver {
  Item? selectedItem;
  // 當前選中的熱鍵（1-5）
  int? selectedHotkey;
  // 懸停顯示的物品
  Item? hoveredItem;
  // 懸停位置
  Offset? hoverPosition;
  NightAndRainGame get game => widget.game;

  @override
  void initState() {
    super.initState();
    // 註冊為觀察者以接收鍵盤事件
    WidgetsBinding.instance.addObserver(this);
    // 設置硬件鍵盤事件回調
    ServicesBinding.instance.keyboard.addHandler(_handleKeyboardEvent);
  }

  @override
  void dispose() {
    // 移除鍵盤事件監聽
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyboardEvent);
    // 移除觀察者
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 使用新的 HardwareKeyboard API 處理鍵盤事件
  bool _handleKeyboardEvent(KeyEvent event) {
    // 處理數字鍵1-5的按下事件
    if (event is KeyDownEvent &&
        event.logicalKey.keyId >= LogicalKeyboardKey.digit1.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.digit5.keyId) {
      final hotkey =
          event.logicalKey.keyId - LogicalKeyboardKey.digit1.keyId + 1;

      // 如果有選中的物品，則綁定熱鍵
      if (selectedItem != null) {
        // 保存選中物品的名稱以便在清除 selectedItem 後仍可使用
        final itemName = selectedItem!.name;

        // 綁定熱鍵
        ref.read(inventoryProvider.notifier).bindHotkey(hotkey, selectedItem!);

        // 更新狀態
        setState(() {
          selectedHotkey = null;
          selectedItem = null;
        });

        // 使用保存的名稱顯示消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemName 已綁定到熱鍵 $hotkey'),
            duration: Duration(seconds: 1),
          ),
        );

        return true;
      }
    }

    // 處理E鍵按下事件
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyE &&
        selectedItem != null) {
      // 使用當前選中的物品 - 現在通過 inventoryProvider
      ref.read(inventoryProvider.notifier).useItem(selectedItem!);

      // 如果物品用完了，取消選中
      if (selectedItem!.isStackable && selectedItem!.quantity <= 1) {
        setState(() {
          selectedItem = null;
        });
      }
      // 返回true表示我們已經處理了這個事件
      return true;
    }
    // 返回false表示我們沒有處理這個事件，允許其他處理器處理
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    final inventory = ref.watch(inventoryProvider);
    final weapon = player.equippedWeapon;

    return Stack(
      children: [
        Material(
          color: Colors.black.withOpacity(0.85),
          child: Scaffold(
            // 添加 Scaffold 以支持 ScaffoldMessenger
            backgroundColor: Colors.transparent, // 保持透明背景
            body: Center(
              child: Container(
                width: 800, // 增加寴度以適應左右兩欄布局
                height: 600, // 保持高度
                decoration: BoxDecoration(
                  color: Color(0xFF212121), // 深灰色背景
                  border: Border.all(color: Color(0xFFDDDDDD), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 標題和關閉按鈕
                    DashboardHeader(
                      onClose: () => game.overlays.remove('InventoryOverlay'),
                    ),

                    Divider(color: Colors.white30, thickness: 1),
                    const SizedBox(height: 8),

                    // 主體內容 - 左右兩欄布局
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 左側欄 - 背包和金錢
                          Expanded(
                            flex: 10, // 左側佔比
                            child: LeftPanel(
                              player: player,
                              inventory: inventory,
                              selectedItem: selectedItem,
                              selectedHotkey: selectedHotkey,
                              onItemSelected: (item) {
                                setState(() {
                                  selectedItem = item;
                                });
                              },
                              onItemHovered: (item, position) {
                                setState(() {
                                  hoveredItem = item;
                                  hoverPosition = position;
                                });
                              },
                              onItemHoverExited: () {
                                setState(() {
                                  hoveredItem = null;
                                  hoverPosition = null;
                                });
                              },
                            ),
                          ),

                          const SizedBox(width: 16), // 左右欄間距
                          // 右側欄 - 角色狀態、裝備和熱鍵
                          Expanded(
                            flex: 8, // 右側佔比
                            child: RightPanel(
                              player: player,
                              inventory: inventory,
                              selectedItem: selectedItem,
                              selectedHotkey: selectedHotkey,
                              weapon: weapon,
                              onHotkeySelected: (hotkey) {
                                setState(() {
                                  selectedHotkey = hotkey;
                                });
                              },
                              onItemBound: (hotkey, item) {
                                ref
                                    .read(inventoryProvider.notifier)
                                    .bindHotkey(hotkey, item);
                                setState(() {
                                  selectedHotkey = null;
                                  selectedItem = null;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${item.name} 已綁定到熱鍵 $hotkey',
                                    ),
                                    duration: Duration(seconds: 1),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 顯示物品懸停詳情卡片
        if (hoveredItem != null && hoverPosition != null)
          Positioned(
            left: hoverPosition!.dx + 15, // 滑鼠位置右側15像素
            top: hoverPosition!.dy - 10, // 滑鼠位置上方10像素
            child: ItemDetailCard(item: hoveredItem!),
          ),
      ],
    );
  }
}

// 頂部標題欄
class DashboardHeader extends StatelessWidget {
  final VoidCallback onClose;

  const DashboardHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '玩家背包',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: onClose,
          splashRadius: 20,
          tooltip: '關閉背包',
        ),
      ],
    );
  }
}

// 左側面板
class LeftPanel extends StatelessWidget {
  final dynamic player;
  final dynamic inventory;
  final Item? selectedItem;
  final int? selectedHotkey;
  final Function(Item) onItemSelected;
  final Function(Item, Offset) onItemHovered;
  final VoidCallback onItemHoverExited;

  const LeftPanel({
    super.key,
    required this.player,
    required this.inventory,
    this.selectedItem,
    this.selectedHotkey,
    required this.onItemSelected,
    required this.onItemHovered,
    required this.onItemHoverExited,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 金錢顯示
        MoneyDisplay(amount: player.money),

        const SizedBox(height: 12),

        // 物品使用提示
        if (selectedItem != null)
          SelectedItemTip(
            selectedItem: selectedItem!,
            selectedHotkey: selectedHotkey,
          ),

        const SizedBox(height: 12),

        // 背包格子標題
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '背包',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${inventory.items.length}/${inventory.capacity}',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 背包格子
        Expanded(
          child: InventoryGrid(
            inventory: inventory,
            selectedItem: selectedItem,
            onItemSelected: onItemSelected,
            onItemHovered: onItemHovered,
            onItemHoverExited: onItemHoverExited,
          ),
        ),
      ],
    );
  }
}

// 右側面板
class RightPanel extends StatelessWidget {
  final dynamic player;
  final dynamic inventory;
  final Item? selectedItem;
  final int? selectedHotkey;
  final dynamic weapon;
  final Function(int) onHotkeySelected;
  final Function(int, Item) onItemBound;

  const RightPanel({
    super.key,
    required this.player,
    required this.inventory,
    this.selectedItem,
    this.selectedHotkey,
    this.weapon,
    required this.onHotkeySelected,
    required this.onItemBound,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 角色狀態
        PlayerStatusCard(player: player),
        const SizedBox(height: 12),

        // 裝備欄
        EquipmentSection(weapon: weapon),
        const SizedBox(height: 12),

        // 熱鍵綁定顯示
        HotkeySection(
          inventory: inventory,
          selectedItem: selectedItem,
          selectedHotkey: selectedHotkey,
          onHotkeySelected: onHotkeySelected,
          onItemBound: onItemBound,
        ),

        // 填充剩餘空間
        Spacer(),

        // 操作提示
        OperationTips(),
      ],
    );
  }
}

// 金錢顯示組件
class MoneyDisplay extends StatelessWidget {
  final int amount;

  const MoneyDisplay({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on, color: Colors.amber, size: 24),
          const SizedBox(width: 8),
          Text(
            '金幣: $amount',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// 選中物品提示
class SelectedItemTip extends StatelessWidget {
  final Item selectedItem;
  final int? selectedHotkey;

  const SelectedItemTip({
    super.key,
    required this.selectedItem,
    this.selectedHotkey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(selectedItem.icon, color: selectedItem.rarity.color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedItem.name,
                  style: TextStyle(
                    color: selectedItem.rarity.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  selectedHotkey != null
                      ? '按數字鍵 $selectedHotkey 確認綁定到熱鍵'
                      : '按 E 使用，或按數字鍵 1-5 綁定熱鍵',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 背包格子網格
class InventoryGrid extends StatelessWidget {
  final dynamic inventory;
  final Item? selectedItem;
  final Function(Item) onItemSelected;
  final Function(Item, Offset) onItemHovered;
  final VoidCallback onItemHoverExited;

  const InventoryGrid({
    super.key,
    required this.inventory,
    this.selectedItem,
    required this.onItemSelected,
    required this.onItemHovered,
    required this.onItemHoverExited,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      padding: EdgeInsets.all(8),
      child: GridView.builder(
        itemCount: inventory.capacity,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // 5列
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0, // 保持方形
        ),
        itemBuilder: (_, idx) {
          // 檢查索引是否在物品列表範圍內
          final hasItem = idx < inventory.items.length;
          final item = hasItem ? inventory.items[idx] : null;

          return InventoryItemCard(
            item: item,
            isSelected: item == selectedItem,
            onTap: hasItem ? () => onItemSelected(item!) : null,
            onEnter:
                hasItem
                    ? (event) => onItemHovered(item!, event.position)
                    : null,
            onHover:
                hasItem
                    ? (event) => onItemHovered(item!, event.position)
                    : null,
            onExit: hasItem ? (_) => onItemHoverExited() : null,
          );
        },
      ),
    );
  }
}

// 物品卡片
class InventoryItemCard extends StatelessWidget {
  final Item? item;
  final bool isSelected;
  final VoidCallback? onTap;
  final Function(PointerEnterEvent)? onEnter;
  final Function(PointerHoverEvent)? onHover;
  final Function(PointerExitEvent)? onExit;

  const InventoryItemCard({
    super.key,
    this.item,
    this.isSelected = false,
    this.onTap,
    this.onEnter,
    this.onHover,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final hasItem = item != null;

    return MouseRegion(
      onEnter: onEnter,
      onHover: onHover,
      onExit: onExit,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration:
              hasItem
                  ? ItemDecorations.getItemBorderDecoration(
                    item!.rarity,
                    isSelected: isSelected,
                  )
                  : BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white38),
                  ),
          child:
              hasItem
                  ? Stack(
                    children: [
                      // 物品圖示
                      Center(
                        child: Icon(
                          item!.icon,
                          color: item!.rarity.color,
                          size: 28,
                        ),
                      ),

                      // 物品稀有度顯示
                      Positioned(
                        top: 2,
                        left: 2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item!.rarity.color.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // 如果是可堆疊物品且數量大於1，顯示數量
                      if (item!.isStackable && item!.quantity > 1)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              '${item!.quantity}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                  : null,
        ),
      ),
    );
  }
}

// 角色狀態卡片
class PlayerStatusCard extends ConsumerWidget {
  final dynamic player;

  const PlayerStatusCard({super.key, required this.player});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用統一的生命值Provider
    final healthData = ref.watch(playerHealthProvider);
    final currentHealth = healthData.$1;
    final maxHealth = healthData.$2;

    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
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
            icon: Icons.favorite,
            value: (currentHealth / maxHealth).clamp(0.0, 1.0),
            currentValue: currentHealth,
            maxValue: maxHealth,
            barColor: Colors.red.shade400,
            backgroundColor: Colors.red.shade900.withOpacity(0.2),
            valueText: '$currentHealth/$maxHealth',
          ),
          const SizedBox(height: 6),
          StatusBar(
            label: 'MP',
            icon: Icons.auto_awesome,
            value: (player.mana / player.maxMana).clamp(0.0, 1.0),
            currentValue: player.mana,
            maxValue: player.maxMana,
            barColor: Colors.blue.shade400,
            backgroundColor: Colors.blue.shade900.withOpacity(0.2),
            valueText: '${player.mana}/${player.maxMana}',
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                '移動速度: ${ref.watch(playerSpeedProvider).toStringAsFixed(0)}', // 顯示包含加成的速度
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 裝備區塊
class EquipmentSection extends StatelessWidget {
  final dynamic weapon;

  const EquipmentSection({super.key, this.weapon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '裝備',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              weapon != null
                  ? EquipmentSlot(
                    label: '武器',
                    itemName: weapon.name,
                    weaponColor: weapon.rarity.color,
                  )
                  : EquipmentSlot(label: '武器', itemName: '無'),
              EquipmentSlot(label: '防具', itemName: '無'),
            ],
          ),
        ],
      ),
    );
  }
}

// 裝備槽位
class EquipmentSlot extends StatelessWidget {
  final String label;
  final String itemName;
  final Color? weaponColor;

  const EquipmentSlot({
    super.key,
    required this.label,
    required this.itemName,
    this.weaponColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
          SizedBox(height: 4),
          Text(
            itemName,
            style: TextStyle(color: weaponColor ?? Colors.white70),
          ),
        ],
      ),
    );
  }
}

// 熱鍵區塊
class HotkeySection extends StatelessWidget {
  final dynamic inventory;
  final Item? selectedItem;
  final int? selectedHotkey;
  final Function(int) onHotkeySelected;
  final Function(int, Item) onItemBound;

  const HotkeySection({
    super.key,
    required this.inventory,
    this.selectedItem,
    this.selectedHotkey,
    required this.onHotkeySelected,
    required this.onItemBound,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '熱鍵',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final hotkey = index + 1;
              final item = inventory.hotkeyBindings[hotkey];

              return HotkeySlot(
                hotkey: hotkey,
                item: item,
                isSelected: selectedHotkey == hotkey,
                onTap: () {
                  if (selectedItem != null) {
                    onItemBound(hotkey, selectedItem!);
                  } else {
                    onHotkeySelected(hotkey);
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// 熱鍵槽位
class HotkeySlot extends StatelessWidget {
  final int hotkey;
  final Item? item;
  final bool isSelected;
  final VoidCallback onTap;

  const HotkeySlot({
    super.key,
    required this.hotkey,
    this.item,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, // 略微縮小
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.black45,
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.white30,
            width: isSelected ? 2 : 1,
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
                '$hotkey',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // 顯示綁定的物品圖示
            if (item != null)
              Center(
                child: Icon(item!.icon, color: item!.rarity.color, size: 24),
              ),

            // 顯示物品名稱提示
            if (item != null)
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    item!.name.length > 4
                        ? '${item!.name.substring(0, 3)}...'
                        : item!.name,
                    style: TextStyle(color: Colors.white70, fontSize: 8),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 操作提示
class OperationTips extends StatelessWidget {
  const OperationTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '操作提示',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'E 鍵：使用選中物品',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            '數字鍵 1-5：綁定或使用熱鍵',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Q 鍵：在遊戲中切換武器',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
