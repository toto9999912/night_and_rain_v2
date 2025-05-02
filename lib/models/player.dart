import 'package:flame/components.dart';
import 'armor.dart';
import 'inventory.dart';
import 'item.dart';
import 'weapon.dart';

class Player {
  // 基礎屬性
  int health;
  int maxHealth;
  int mana;
  int maxMana;
  double speed;
  int money;

  // 裝備
  Weapon? _equippedWeapon;
  Armor? equippedArmor;

  // 背包
  final Inventory inventory;

  // 構造函數
  Player({
    this.health = 100,
    this.maxHealth = 100,
    this.mana = 100,
    this.maxMana = 100,
    this.speed = 150.0,
    this.money = 0,
    Weapon? weapon,
    Armor? armor,
    Inventory? playerInventory,
  }) : _equippedWeapon = weapon,
       equippedArmor = armor,
       inventory = playerInventory ?? Inventory(capacity: 20);

  // 當前武器的 getter
  Weapon? get equippedWeapon => _equippedWeapon;

  // 計算屬性：是否為遠程武器
  bool get hasRangedWeapon =>
      _equippedWeapon != null && _equippedWeapon!.weaponType.isRanged;

  // 計算屬性：當前武器的魔力消耗
  int get weaponManaCost => _equippedWeapon?.manaCost ?? 0;

  // 計算屬性：是否有足夠魔力射擊
  bool get canShoot {
    if (_equippedWeapon == null) return true;
    return mana >= weaponManaCost;
  }

  // 裝備武器
  void equipWeapon(Weapon weapon) {
    // 檢查物品是否在背包中，如果不在則自動添加
    if (!inventory.items.contains(weapon)) {
      inventory.addItem(weapon);
    }
    _equippedWeapon = weapon;
  }

  // 卸下武器
  void unequipWeapon() {
    _equippedWeapon = null;
  }

  // 使用當前武器攻擊
  bool attack(Vector2 direction) {
    if (_equippedWeapon == null) return false;

    // 執行攻擊
    return _equippedWeapon!.attack(direction, this);
  }

  // 切換到下一個武器
  void switchToNextWeapon() {
    if (inventory.items.isEmpty) return;

    // 找出所有武器
    final weapons = inventory.getWeapons();
    if (weapons.isEmpty) return;

    // 找到當前武器的索引
    int currentIndex = -1;
    if (_equippedWeapon != null) {
      currentIndex = weapons.indexWhere((w) => w.id == _equippedWeapon!.id);
    }

    // 切換到下一個武器
    int nextIndex = (currentIndex + 1) % weapons.length;
    equipWeapon(weapons[nextIndex]);
  }

  // 切換到上一個武器
  void switchToPreviousWeapon() {
    if (inventory.items.isEmpty) return;

    // 找出所有武器
    final weapons = inventory.getWeapons();
    if (weapons.isEmpty) return;

    // 找到當前武器的索引
    int currentIndex = -1;
    if (_equippedWeapon != null) {
      currentIndex = weapons.indexWhere((w) => w.id == _equippedWeapon!.id);
    }

    // 切換到上一個武器
    int prevIndex = currentIndex <= 0 ? weapons.length - 1 : currentIndex - 1;
    equipWeapon(weapons[prevIndex]);
  }

  // 使用物品
  void useItem(Item item) {
    // 確保物品在背包中
    if (inventory.items.contains(item)) {
      // 先使用物品
      item.use(this);

      // 如果是可堆疊物品，則減少數量
      if (item.isStackable) {
        inventory.removeItem(item, quantityToRemove: 1);
      } else {
        // 非堆疊物品（如武器和防具）使用後不消耗
      }
    }
  }

  // 裝備護甲
  void equipArmor(Armor armor) {
    // 檢查物品是否在背包中，如果不在則自動添加
    if (!inventory.items.contains(armor)) {
      inventory.addItem(armor);
    }
    equippedArmor = armor;
  }

  // 扣除魔力值
  bool consumeMana(int amount) {
    if (mana >= amount) {
      mana -= amount;
      if (mana < 0) mana = 0;
      return true;
    }
    return false;
  }

  // 增加魔力值
  void addMana(int amount) {
    mana += amount;
    if (mana > maxMana) mana = maxMana;
  }

  // 扣除生命值
  void takeDamage(int amount) {
    health -= amount;
    if (health < 0) health = 0;
  }

  // 增加生命值
  void heal(int amount) {
    health += amount;
    if (health > maxHealth) health = maxHealth;
  }

  // 增加金錢
  void addMoney(int amount) {
    money += amount;
  }

  // 扣除金錢
  bool spendMoney(int amount) {
    if (money >= amount) {
      money -= amount;
      return true;
    }
    return false;
  }

  // 複製對象（用於 Riverpod 狀態更新）
  Player copyWith({
    int? health,
    int? maxHealth,
    int? mana,
    int? maxMana,
    double? speed,
    int? money,
    Weapon? equippedWeapon,
    Armor? equippedArmor,
  }) {
    return Player(
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      mana: mana ?? this.mana,
      maxMana: maxMana ?? this.maxMana,
      speed: speed ?? this.speed,
      money: money ?? this.money,
      weapon: equippedWeapon ?? this.equippedWeapon,
      armor: equippedArmor ?? this.equippedArmor,
      playerInventory: this.inventory,
    );
  }
}
