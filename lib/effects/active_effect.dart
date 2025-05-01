import 'player_effect.dart';

class ActiveEffect {
  final PlayerEffect effect;
  double remainingTime;

  ActiveEffect(this.effect) : remainingTime = effect.duration;
}
