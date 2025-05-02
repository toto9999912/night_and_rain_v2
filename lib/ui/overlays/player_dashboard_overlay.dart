import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:night_and_rain_v2/main.dart';
import 'package:night_and_rain_v2/models/item.dart';
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

    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 400,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 關閉按鈕
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => game.overlays.remove('InventoryOverlay'),
                ),
              ),
              const SizedBox(height: 8),

              // 角色狀態
              Text('角色狀態', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 4),
              _buildBar('HP', player.health / 100, Colors.red),
              const SizedBox(height: 4),
              _buildBar('MP', player.mana / 100, Colors.blue),
              const SizedBox(height: 4),
              Text(
                'Speed: ${player.speed.toStringAsFixed(0)}',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),

              // 裝備欄
              Text('裝備', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 4),
              Row(
                children: [
                  weapon != null
                      ? _equipSlot('武器', weapon.name)
                      : _equipSlot('武器', '無'),
                  const SizedBox(width: 16),
                  // 裝備防具的位置（待開發）
                  _equipSlot('防具', '無'),
                ],
              ),
              const SizedBox(height: 12),

              // 物品使用提示
              if (selectedItem != null)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedItem!.icon,
                        color: selectedItem!.rarity.color,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedHotkey != null
                              ? '已選擇: ${selectedItem!.name} - 按數字鍵 ${selectedHotkey} 確認綁定到熱鍵'
                              : '已選擇: ${selectedItem!.name} - 按 E 使用，或按數字鍵 1-5 綁定熱鍵',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              // 熱鍵綁定顯示
              Container(
                margin: EdgeInsets.symmetric(vertical: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white30),
                ),
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${selectedItem!.name} 已綁定到熱鍵 $hotkey',
                              ),
                              duration: Duration(seconds: 1),
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
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              selectedHotkey == hotkey
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.black38,
                          border: Border.all(
                            color:
                                selectedHotkey == hotkey
                                    ? Colors.yellow
                                    : Colors.white30,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Stack(
                          children: [
                            // 熱鍵數字
                            Positioned(
                              top: 1,
                              left: 2,
                              child: Text(
                                '$hotkey',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
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
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // 背包格子
              Text('背包', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  itemCount: inventory.capacity,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (_, idx) {
                    // 檢查索引是否在物品列表範圍內
                    final hasItem = idx < inventory.items.length;
                    final item = hasItem ? inventory.items[idx] : null;

                    return GestureDetector(
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
                          border: Border.all(
                            color:
                                hasItem && item == selectedItem
                                    ? Colors.yellow
                                    : Colors.white54,
                            width: hasItem && item == selectedItem ? 2 : 1,
                          ),
                          color: Colors.grey[800],
                        ),
                        child:
                            hasItem
                                ? Stack(
                                  children: [
                                    Center(
                                      child: Icon(
                                        item!.icon,
                                        color: item.rarity.color,
                                      ),
                                    ),
                                    // 如果是可堆疊物品且數量大於1，顯示數量
                                    if (item.isStackable && item.quantity > 1)
                                      Positioned(
                                        right: 2,
                                        bottom: 2,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'x${item.quantity}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                                : null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(String label, double value, Color color) {
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
      ],
    );
  }

  Widget _equipSlot(String label, String itemName) {
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
          Text(itemName, style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
