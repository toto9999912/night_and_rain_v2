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

  // 裝備欄
  Weapon? equippedWeapon;
  Armor? equippedArmor;

  // 背包
  Inventory inventory;

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
  }) : equippedWeapon = weapon,
       equippedArmor = armor,
       inventory = playerInventory ?? Inventory(capacity: 20);

  // 玩家行為管理
  void move(Vector2 direction) {
    // 在遊戲組件中實現移動邏輯
    // 這裡僅作為數據模型
  }

  void aim(Vector2 direction) {
    // 在遊戲組件中實現瞄準邏輯
    // 這裡僅作為數據模型
  }

  void shoot() {
    // 在遊戲組件中實現射擊邏輯
    // 這裡僅作為數據模型
  }

  void useItem(Item item) {
    // 使用物品
    item.use(this);
  }

  void equipWeapon(Weapon weapon) {
    // 裝備武器
    equippedWeapon = weapon;
  }

  void equipArmor(Armor armor) {
    // 裝備護甲
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

  // 更新生命值
  void updateHealth(int newHealth) {
    health = newHealth;
    if (health > maxHealth) health = maxHealth;
    if (health < 0) health = 0;
  }

  // 更新魔力值
  void updateMana(int newMana) {
    mana = newMana;
    if (mana > maxMana) mana = maxMana;
    if (mana < 0) mana = 0;
  }

  // 扣除金錢
  bool spendMoney(int amount) {
    if (money >= amount) {
      money -= amount;
      return true;
    }
    return false;
  }
}
