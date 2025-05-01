import '../enum/item_type.dart';
import 'item.dart';
import 'player.dart';

// 如果需要效果系統，可以導入
// import '../effects/player_effect.dart';

class Consumable extends Item {
  final int healthRestore;
  final int manaRestore;
  // 移除對 Flame Effect 的依賴
  // final List<Effect> effects;

  // 如果需要效果系統，可以使用以下註釋行
  // final List<PlayerEffect> effects;

  Consumable({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price,
    this.healthRestore = 0,
    this.manaRestore = 0,
    // this.effects = const [],
  }) : super(type: ItemType.consumable);

  @override
  void use(Player player) {
    // 使用 Player 的正確方法
    if (healthRestore > 0) {
      player.heal(healthRestore);
    }

    if (manaRestore > 0) {
      player.addMana(manaRestore);
    }

    // 如果將來實現效果系統
    // for (final effect in effects) {
    //   player.effectManager.addEffect(effect);
    // }
  }

  @override
  String getDescription() {
    String desc = '${super.getDescription()}\n';

    if (healthRestore > 0) {
      desc += '恢復生命值: +$healthRestore\n';
    }

    if (manaRestore > 0) {
      desc += '恢復魔力值: +$manaRestore\n';
    }

    return desc;
  }
}
