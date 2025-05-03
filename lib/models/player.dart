import 'armor.dart';
import 'weapon.dart';

/// 不可變的 Player 模型
/// 所有狀態更新必須透過 copyWith 來產生新的實例
class Player {
  // 基礎屬性 - 所有屬性都是 final
  final int health;
  final int maxHealth;
  final int mana;
  final int maxMana;
  final double speed;
  final int money;

  // 裝備
  final Weapon? _equippedWeapon;
  final Armor? equippedArmor;

  // 背包ID - 不再直接引用背包，而是使用 ID 來關聯背包
  final String playerId;

  // 構造函數
  const Player({
    this.health = 100,
    this.maxHealth = 100,
    this.mana = 100,
    this.maxMana = 100,
    this.speed = 150.0,
    this.money = 1000, // 初始金幣設為1000
    Weapon? weapon,
    Armor? armor,
    String? id,
  }) : _equippedWeapon = weapon,
       equippedArmor = armor,
       playerId = id ?? 'player_1';

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

  // 以下方法不再修改狀態，而是返回新的 Player 實例

  // 裝備武器 - 回傳新的 Player 實例
  Player withEquippedWeapon(Weapon weapon) {
    return copyWith(equippedWeapon: weapon);
  }

  // 卸下武器 - 回傳新的 Player 實例
  Player withoutWeapon() {
    return copyWith(equippedWeapon: null);
  }

  // 裝備護甲 - 回傳新的 Player 實例
  Player withEquippedArmor(Armor armor) {
    return copyWith(equippedArmor: armor);
  }

  // 扣除魔力值 - 回傳新的 Player 實例，攜帶操作是否成功的信息
  (Player, bool) withManaConsumed(int amount) {
    if (mana >= amount) {
      return (copyWith(mana: mana - amount), true);
    }
    return (this, false);
  }

  // 增加魔力值 - 回傳新的 Player 實例
  Player withAddedMana(int amount) {
    final newMana = mana + amount > maxMana ? maxMana : mana + amount;
    return copyWith(mana: newMana);
  }

  // 扣除生命值 - 回傳新的 Player 實例
  Player withDamageTaken(int amount) {
    final newHealth = health - amount < 0 ? 0 : health - amount;
    return copyWith(health: newHealth);
  }

  // 增加生命值 - 回傳新的 Player 實例
  Player withHealing(int amount) {
    final newHealth = health + amount > maxHealth ? maxHealth : health + amount;
    return copyWith(health: newHealth);
  }

  // 增加金錢 - 回傳新的 Player 實例
  Player withAddedMoney(int amount) {
    return copyWith(money: money + amount);
  }

  // 扣除金錢 - 回傳新的 Player 實例，攜帶操作是否成功的信息
  (Player, bool) withMoneySpent(int amount) {
    if (money >= amount) {
      return (copyWith(money: money - amount), true);
    }
    return (this, false);
  }

  // 使用當前武器攻擊 - 不修改狀態，只檢查是否可以攻擊
  // 實際攻擊邏輯移至 PlayerNotifier 中
  bool canAttack() {
    return _equippedWeapon != null && canShoot;
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
      id: playerId,
    );
  }
}
