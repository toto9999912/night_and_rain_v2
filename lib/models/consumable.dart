import 'package:flame/effects.dart';

import '../enum/item_type.dart';
import 'item.dart';
import 'player.dart';

class Consumable extends Item {
  final int healthRestore;
  final int manaRestore;
  final List<Effect> effects;

  Consumable({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price, // 添加價格參數
    this.healthRestore = 0,
    this.manaRestore = 0,
    this.effects = const [],
  }) : super(type: ItemType.consumable);
  @override
  void use(Player player) {
    player.updateHealth(player.health + healthRestore);
    player.updateMana(player.mana + manaRestore);

    // // 應用效果
    // for (final effect in effects) {
    //   effect.apply(player);
    // }
  }
}
