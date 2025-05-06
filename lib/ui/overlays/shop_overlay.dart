import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:night_and_rain_v2/enum/item_type.dart';
import 'package:night_and_rain_v2/models/consumable.dart';
import 'package:night_and_rain_v2/ui/widgets/item_decorations.dart';

import '../../components/npc_component.dart';
import '../../managers/shop_manager.dart';
import '../../models/item.dart';
import '../../models/inventory.dart';
import '../../models/armor.dart';
import '../../models/weapon.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/player_provider.dart';
import '../widgets/stat_row.dart';

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

  // 背包中選中的物品
  Item? _selectedInventoryItem;
  // 懸停顯示的物品
  // 懸停位置

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
              width: MediaQuery.of(context).size.width * 0.9, // 增加寬度以顯示背包
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

                        // 中間物品詳情和操作按鈕
                        Expanded(flex: 2, child: _buildItemDetails(inventory)),

                        // 右側玩家背包區域
                        Expanded(
                          flex: 3,
                          child: _buildPlayerInventory(inventory),
                        ),
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
                            decoration: ItemDecorations.getItemIconDecoration(
                              item.rarity,
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
                        decoration: ItemDecorations.getItemIconDecoration(
                          _selectedItem!.rarity,
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

  // 玩家背包部分
  Widget _buildPlayerInventory(Inventory inventory) {
    final player = ref.watch(playerProvider);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.white24, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 背包標題和金幣顯示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "我的背包",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${player.money}",
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 物品數量顯示
          Text(
            "物品: ${inventory.items.length}/${inventory.capacity}",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),

          // 背包物品列表
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              padding: const EdgeInsets.all(8),
              child:
                  inventory.items.isEmpty
                      ? const Center(
                        child: Text(
                          "背包是空的",
                          style: TextStyle(color: Colors.white60),
                        ),
                      )
                      : GridView.builder(
                        itemCount: inventory.capacity,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4, // 4列
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 1.0, // 保持方形
                            ),
                        itemBuilder: (_, idx) {
                          final hasItem = idx < inventory.items.length;
                          final item = hasItem ? inventory.items[idx] : null;

                          return MouseRegion(
                            onEnter:
                                hasItem
                                    ? (event) {
                                      setState(() {});
                                    }
                                    : null,
                            onHover:
                                hasItem
                                    ? (event) {
                                      setState(() {});
                                    }
                                    : null,
                            onExit:
                                hasItem
                                    ? (_) {
                                      setState(() {});
                                    }
                                    : null,
                            child: GestureDetector(
                              onTap:
                                  hasItem
                                      ? () {
                                        // 選中背包物品
                                        setState(() {
                                          _selectedInventoryItem =
                                              _selectedInventoryItem == item
                                                  ? null
                                                  : item;
                                        });
                                      }
                                      : null,
                              child: Container(
                                decoration:
                                    hasItem
                                        ? ItemDecorations.getItemBorderDecoration(
                                          item!.rarity,
                                          isSelected:
                                              item == _selectedInventoryItem,
                                        )
                                        : BoxDecoration(
                                          color: Colors.black38,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: Colors.white38,
                                          ),
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
                                                size: 24,
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
                                                      .withOpacity(0.7),
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
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white24,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '${item.quantity}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold,
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
          ),

          // 如果選擇了背包中的物品，顯示該物品的詳情
          if (_selectedInventoryItem != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectedInventoryItem!.rarity.color.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _selectedInventoryItem!.icon,
                        color: _selectedInventoryItem!.rarity.color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedInventoryItem!.name,
                          style: TextStyle(
                            color: _selectedInventoryItem!.rarity.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_selectedInventoryItem!.price > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.monetization_on,
                              color: Colors.amber,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${_selectedInventoryItem!.price}',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedInventoryItem!.description,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 根據物品類型構建不同的屬性顯示
  Widget _buildItemStats(Item item) {
    if (item is Weapon) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatRow(label: '武器類型', value: item.weaponType.name),
          StatRow(
            label: '傷害',
            value: item.damage.toString(),
            color: Colors.redAccent,
          ),
          StatRow(label: '射擊速度', value: (1 / item.cooldown).toStringAsFixed(1)),
          StatRow(label: '攻擊範圍', value: item.range.toString()),
          StatRow(label: '冷卻時間', value: '${item.cooldown}秒'),
          if (item.manaCost > 0)
            StatRow(
              label: '魔力消耗',
              value: item.manaCost.toString(),
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
          if (item.healthRestore > 0)
            StatRow(
              label: '生命恢復',
              value: '+${item.healthRestore}',
              color: Colors.redAccent,
            ),
          if (item.manaRestore > 0)
            StatRow(
              label: '魔力恢復',
              value: '+${item.manaRestore}',
              color: Colors.blueAccent,
            ),
          const SizedBox(height: 4),
        ],
      );
    } else if (item is Armor) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatRow(label: '類型', value: '防具'),
          StatRow(
            label: '防禦力',
            value: item.defense.toString(),
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 4),
        ],
      );
    }

    return const SizedBox.shrink(); // 默認為空
  }
}
