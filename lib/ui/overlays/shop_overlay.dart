import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:night_and_rain_v2/enum/item_type.dart';
import 'package:night_and_rain_v2/models/consumable.dart';

import '../../components/npc_component.dart';
import '../../managers/shop_manager.dart';
import '../../models/item.dart';
import '../../models/inventory.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/player_provider.dart';
import '../../enum/item_rarity.dart';

class ShopOverlay extends ConsumerStatefulWidget {
  final FlameGame game;
  final NpcComponent shopkeeper;

  const ShopOverlay({super.key, required this.game, required this.shopkeeper});

  @override
  ConsumerState<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends ConsumerState<ShopOverlay> {
  // 選中的物品
  Item? _selectedItem;
  // 用於顯示提示信息
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 監聽商店管理器
    final shopManager = ref.watch(shopManagerProvider);
    // 獲取玩家資料
    final player = ref.watch(playerProvider);
    // 獲取玩家背包
    final inventory = ref.watch(inventoryProvider);

    // 準備顯示的商品列表
    final shopItems = shopManager.shopItems.values.toList();

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Material(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30, width: 2),
              ),
              child: Column(
                children: [
                  // 頂部標題欄
                  _buildShopHeader(shopManager, player),

                  // 商店內容區域
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左側商品列表
                        Expanded(
                          flex: 3,
                          child: _buildItemsList(shopItems, shopManager),
                        ),

                        // 右側物品詳情和操作按鈕
                        Expanded(flex: 2, child: _buildItemDetails(inventory)),
                      ],
                    ),
                  ),

                  // 底部按鈕欄
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 商店頂部標題欄
  Widget _buildShopHeader(ShopManager shopManager, dynamic player) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white24, width: 1)),
        color: Colors.black54,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 商店名稱
          Text(
            shopManager.shopName.isNotEmpty
                ? shopManager.shopName
                : "${widget.shopkeeper.name}的商店",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          // 折扣信息
          if (shopManager.discountRate < 1.0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "全場${shopManager.discountText}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // 玩家金錢
          Row(
            children: [
              const Icon(Icons.monetization_on, color: Colors.amber),
              const SizedBox(width: 5),
              Text(
                "${player.money}",
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 商店物品列表
  Widget _buildItemsList(List<Item> shopItems, ShopManager shopManager) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "可購買物品",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // 物品列表
          Expanded(
            child:
                shopItems.isEmpty
                    ? const Center(
                      child: Text(
                        "商店目前沒有商品",
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                    : ListView.builder(
                      itemCount: shopItems.length,
                      itemBuilder: (context, index) {
                        final item = shopItems[index];
                        final isSelected = _selectedItem == item;
                        final discountedPrice = shopManager.getDiscountedPrice(
                          item,
                        );

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.blue.withOpacity(0.3),
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                            });
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.rarity.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: item.rarity.color.withOpacity(0.5),
                              ),
                            ),
                            child: Icon(item.icon, color: item.rarity.color),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              color: item.rarity.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            item.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (shopManager.discountRate < 1.0)
                                Text(
                                  "${item.price}",
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    decoration: TextDecoration.lineThrough,
                                    fontSize: 12,
                                  ),
                                ),
                              const SizedBox(width: 5),
                              Text(
                                "$discountedPrice",
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // 右側物品詳情和購買按鈕
  Widget _buildItemDetails(Inventory inventory) {
    final player = ref.read(playerProvider);
    final shopManager = ref.read(shopManagerProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child:
          _selectedItem == null
              ? const Center(
                child: Text(
                  "選擇物品查看詳情",
                  style: TextStyle(color: Colors.white60),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 物品名稱
                  Text(
                    _selectedItem!.name,
                    style: TextStyle(
                      color: _selectedItem!.rarity.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 物品圖標和稀有度
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedItem!.rarity.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedItem!.rarity.color.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _selectedItem!.icon,
                          color: _selectedItem!.rarity.color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "稀有度：${_selectedItem!.rarity.name}",
                            style: TextStyle(
                              color: _selectedItem!.rarity.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "類型：${_getItemTypeName(_selectedItem!.type)}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 物品描述
                  const Text(
                    "描述",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedItem!.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  // 物品詳細屬性
                  const Text(
                    "屬性",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildItemStats(_selectedItem!),
                  const Spacer(),

                  // 購買按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          player.money >=
                                  shopManager.getDiscountedPrice(_selectedItem!)
                              ? () => _purchaseItem(_selectedItem!)
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        player.money >=
                                shopManager.getDiscountedPrice(_selectedItem!)
                            ? "購買 (${shopManager.getDiscountedPrice(_selectedItem!)}金幣)"
                            : "金幣不足",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 是否能放入背包的提示
                  if (inventory.isFull())
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "警告：背包已滿",
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  // 底部按鈕欄
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white24, width: 1)),
        color: Colors.black54,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: () {
              // 關閉商店界面
              widget.game.overlays.remove('ShopOverlay');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              "離開商店",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 物品屬性展示
  Widget _buildItemStats(Item item) {
    // 取得物品的各種屬性並顯示
    String statsText = "";

    // 使用 item.getDescription() 中的格式來展示屬性
    // 但不包括名稱、描述等已在其他地方顯示的內容
    if (item.weaponItem != null) {
      statsText = item.weaponItem!.getStats();
    } else {
      // 根據物品類型顯示不同的屬性
      switch (item.type) {
        case ItemType.consumable:
          if (item is Consumable) {
            if (item.healthRestore > 0) {
              statsText += "生命恢復: +${item.healthRestore}\n";
            }
            if (item.manaRestore > 0) {
              statsText += "魔力恢復: +${item.manaRestore}\n";
            }
          }
          break;
        // case ItemType.armor:
        //   if (item is Armor) {
        //     statsText += "防禦力: +${item.defense}\n";
        //   }
        //   break;
        default:
          statsText = "暫無詳細屬性";
      }
    }

    return Text(statsText, style: const TextStyle(color: Colors.white70));
  }

  // 購買物品的方法
  void _purchaseItem(Item item) {
    final playerNotifier = ref.read(playerProvider.notifier);
    final inventoryNotifier = ref.read(inventoryProvider.notifier);
    final shopManager = ref.read(shopManagerProvider);
    final player = ref.read(playerProvider);
    final inventory = ref.read(inventoryProvider);

    // 計算折扣後的價格
    final discountedPrice = shopManager.getDiscountedPrice(item);

    // 檢查玩家金錢是否足夠
    if (player.money < discountedPrice) {
      _showMessage("金錢不足，無法購買");
      return;
    }

    // 檢查背包是否已滿（對於非堆疊物品）
    if (!item.isStackable && inventory.isFull()) {
      _showMessage("背包已滿，無法購買");
      return;
    }

    // 購買流程：扣除金錢並添加物品到背包
    if (playerNotifier.spendMoney(discountedPrice)) {
      // 嘗試將物品添加到背包
      if (inventoryNotifier.addItem(item)) {
        _showMessage("成功購買 ${item.name}");
      } else {
        // 如果添加失敗（例如背包已滿），退還金錢
        playerNotifier.addMoney(discountedPrice);
        _showMessage("無法添加物品到背包");
      }
    } else {
      _showMessage("購買失敗");
    }
  }

  // 顯示消息給玩家
  void _showMessage(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // 獲取物品類型名稱
  String _getItemTypeName(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return "武器";
      // case ItemType.armor:
      //   return "護甲";
      case ItemType.consumable:
        return "消耗品";
      case ItemType.material:
        return "材料";
      case ItemType.quest:
        return "任務物品";
    }
  }
}
