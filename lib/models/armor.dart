import '../enum/item_type.dart';
import 'item.dart';
import 'player.dart';

class Armor extends Item {
  final int defense;

  Armor({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.icon,
    required super.price,
    required this.defense,
  }) : super(type: ItemType.material); // 暫時使用material類型，後續可增加專用類型

  @override
  void use(Player player) {
    player.equipArmor(this);
  }
}
