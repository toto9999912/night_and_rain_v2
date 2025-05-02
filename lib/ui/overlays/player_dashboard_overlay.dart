import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/main.dart';
import 'package:night_and_rain_v2/models/armor.dart';
import 'package:night_and_rain_v2/models/consumable.dart';
import 'package:night_and_rain_v2/models/item.dart';
import 'package:night_and_rain_v2/models/weapon.dart';
import 'package:night_and_rain_v2/providers/inventory_provider.dart';
import 'package:night_and_rain_v2/providers/player_provider.dart';

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
        ref.read(inventoryProvider.notifier).bindHotkey(hotkey, selectedItem!);

        setState(() {
          selectedHotkey = null;
          selectedItem = null;
        });

        // 顯示消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedItem!.name} 已綁定到熱鍵 $hotkey'),
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

    // 計算行數和列數以完整顯示背包內容
    final int rowCount = (inventory.capacity / 6).ceil(); // 使用6列而不是5列
    final double itemSize = 48.0; // 增加每個格子的大小
    final double gridHeight = (rowCount * (itemSize + 8)) + 8; // 計算網格總高度，包含間距

    return Stack(
      children: [
        Material(
          color: Colors.black.withValues(alpha: 0.85),
          child: Center(
            child: Container(
              width: 550, // 背包變得更寬
              height: 600, // 增加高度以適應所有內容
              decoration: BoxDecoration(
                color: Color(0xFF212121), // 更深的灰色背景
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
                  Row(
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
                        onPressed:
                            () => game.overlays.remove('InventoryOverlay'),
                        splashRadius: 20,
                        tooltip: '關閉背包',
                      ),
                    ],
                  ),
                  Divider(color: Colors.white30, thickness: 1),
                  const SizedBox(height: 8),

                  // 角色狀態
                  Container(
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
                        _buildBar(
                          'HP',
                          player.health / 100,
                          Colors.red.shade400,
                          label2: '${player.health}/${player.maxHealth}',
                        ),
                        const SizedBox(height: 6),
                        _buildBar(
                          'MP',
                          player.mana / 100,
                          Colors.blue.shade400,
                          label2: '${player.mana}/${player.maxMana}',
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.bolt, color: Colors.orange, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '移動速度: ${player.speed.toStringAsFixed(0)}',
                              style: TextStyle(color: Colors.white),
                            ),
                            Spacer(),
                            Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '金幣: ${player.money}',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 裝備欄和熱鍵區域
                  Row(
                    children: [
                      // 裝備欄
                      Expanded(
                        flex: 2,
                        child: Container(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  weapon != null
                                      ? _equipSlot(
                                        '武器',
                                        weapon.name,
                                        weaponColor: weapon.rarity.color,
                                      )
                                      : _equipSlot('武器', '無'),
                                  _equipSlot('防具', '無'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // 熱鍵綁定顯示
                      Expanded(
                        flex: 3,
                        child: Container(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(5, (index) {
                                  final hotkey = index + 1;
                                  final item = inventory.hotkeyBindings[hotkey];

                                  return GestureDetector(
                                    onTap: () {
                                      if (selectedItem != null) {
                                        // 綁定物品到這個熱鍵
                                        ref
                                            .read(inventoryProvider.notifier)
                                            .bindHotkey(hotkey, selectedItem!);
                                        setState(() {
                                          selectedHotkey = null;
                                          selectedItem = null;
                                        });
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${selectedItem!.name} 已綁定到熱鍵 $hotkey',
                                            ),
                                            duration: Duration(seconds: 1),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        // 選擇這個熱鍵
                                        setState(() {
                                          selectedHotkey = hotkey;
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 64,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color:
                                            selectedHotkey == hotkey
                                                ? Colors.blue.withValues(
                                                  alpha: 0.3,
                                                )
                                                : Colors.black45,
                                        border: Border.all(
                                          color:
                                              selectedHotkey == hotkey
                                                  ? Colors.yellow
                                                  : Colors.white30,
                                          width:
                                              selectedHotkey == hotkey ? 2 : 1,
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
                                              child: Icon(
                                                item.icon,
                                                color: item.rarity.color,
                                                size: 24,
                                              ),
                                            ),

                                          // 顯示物品名稱提示
                                          if (item != null)
                                            Positioned(
                                              bottom: 2,
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: Text(
                                                  item.name.length > 6
                                                      ? '${item.name.substring(0, 5)}...'
                                                      : item.name,
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 8,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 物品使用提示
                  if (selectedItem != null)
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.5),
                        ),
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
                            child: Icon(
                              selectedItem!.icon,
                              color: selectedItem!.rarity.color,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedItem!.name,
                                  style: TextStyle(
                                    color: selectedItem!.rarity.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  selectedHotkey != null
                                      ? '按數字鍵 ${selectedHotkey} 確認綁定到熱鍵'
                                      : '按 E 使用，或按數字鍵 1-5 綁定熱鍵',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

                  // 背包格子 - 使用固定高度和列數，不再使用Expanded和滾動
                  Container(
                    height: gridHeight,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    padding: EdgeInsets.all(8),
                    child: GridView.builder(
                      physics: NeverScrollableScrollPhysics(), // 禁用滾動
                      itemCount: inventory.capacity,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6, // 從5列改為6列
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.0, // 保持方形
                      ),
                      itemBuilder: (_, idx) {
                        // 檢查索引是否在物品列表範圍內
                        final hasItem = idx < inventory.items.length;
                        final item = hasItem ? inventory.items[idx] : null;

                        return MouseRegion(
                          onEnter:
                              hasItem
                                  ? (event) {
                                    setState(() {
                                      hoveredItem = item;
                                      hoverPosition = event.position;
                                    });
                                  }
                                  : null,
                          onHover:
                              hasItem
                                  ? (event) {
                                    setState(() {
                                      hoverPosition = event.position;
                                    });
                                  }
                                  : null,
                          onExit:
                              hasItem
                                  ? (_) {
                                    setState(() {
                                      hoveredItem = null;
                                      hoverPosition = null;
                                    });
                                  }
                                  : null,
                          child: GestureDetector(
                            onTap:
                                hasItem
                                    ? () {
                                      // 選中物品而不是直接使用
                                      setState(() {
                                        selectedItem = item;
                                      });
                                    }
                                    : null,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    hasItem ? Colors.grey[850] : Colors.black38,
                                border: Border.all(
                                  color:
                                      hasItem && item == selectedItem
                                          ? Colors.yellow
                                          : hasItem && item == hoveredItem
                                          ? Colors.lightBlue
                                          : Colors.white38,
                                  width:
                                      (hasItem && item == selectedItem) ||
                                              (hasItem && item == hoveredItem)
                                          ? 2
                                          : 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child:
                                  hasItem
                                      ? Stack(
                                        children: [
                                          // 物品圖示
                                          Center(
                                            child: Icon(
                                              item!.icon,
                                              color: item.rarity.color,
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
                                                color: item.rarity.color
                                                    .withValues(alpha: 0.7),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),

                                          // 如果是可堆疊物品且數量大於1，顯示數量
                                          if (item.isStackable &&
                                              item.quantity > 1)
                                            Positioned(
                                              right: 2,
                                              bottom: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black87,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: Colors.white24,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${item.quantity}',
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
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 顯示物品懸停詳情卡片
        if (hoveredItem != null && hoverPosition != null)
          Positioned(
            left: hoverPosition!.dx + 15, // 滑鼠位置右側15像素
            top: hoverPosition!.dy - 10, // 滑鼠位置上方10像素
            child: _buildItemDetailCard(hoveredItem!),
          ),
      ],
    );
  }

  Widget _buildBar(String label, double value, Color color, {String? label2}) {
    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(label, style: TextStyle(color: Colors.white)),
        ),
        Expanded(
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: color),
            ),
          ),
        ),
        SizedBox(width: 8),
        Text('${(value * 100).toInt()}', style: TextStyle(color: Colors.white)),
        if (label2 != null) ...[
          SizedBox(width: 8),
          Text(label2, style: TextStyle(color: Colors.white70)),
        ],
      ],
    );
  }

  Widget _equipSlot(String label, String itemName, {Color? weaponColor}) {
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

  // 構建物品詳情卡片
  Widget _buildItemDetailCard(Item item) {
    return Card(
      color: Colors.black87,
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: item.rarity.color.withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 250),
        padding: EdgeInsets.all(12),
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
                SizedBox(width: 8),
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
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),

            // 物品屬性 - 依據物品類型顯示不同屬性
            _buildItemStats(item),

            // 物品底部資訊 (堆疊、價格等)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (item.isStackable)
                  Text(
                    '可堆疊: ${item.quantity}',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                    SizedBox(width: 2),
                    Text(
                      '${item.price}',
                      style: TextStyle(color: Colors.amber, fontSize: 11),
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
  Widget _buildItemStats(Item item) {
    if (item is Weapon) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('武器類型', item.weaponType.name),
          _buildStatRow('傷害', item.damage.toString(), color: Colors.redAccent),
          _buildStatRow('攻擊速度', item.attackSpeed.toString()),
          _buildStatRow('攻擊範圍', item.range.toString()),
          _buildStatRow('冷卻時間', '${item.cooldown}秒'),
          if (item.manaCost > 0)
            _buildStatRow(
              '魔力消耗',
              item.manaCost.toString(),
              color: Colors.blueAccent,
            ),
          SizedBox(height: 4),
        ],
      );
    } else if (item is Consumable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('類型', '消耗品'),
          _buildStatRow('效果', '使用後回復能量'),
          SizedBox(height: 4),
        ],
      );
    } else if (item is Armor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow('類型', '防具'),
          _buildStatRow(
            '防禦力',
            item.defense.toString(),
            color: Colors.blueAccent,
          ),
          SizedBox(height: 4),
        ],
      );
    }

    return SizedBox.shrink(); // 默認為空
  }

  // 構建屬性行顯示
  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
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
