import '../effects/active_effect.dart';
import '../effects/player_effect.dart';
import '../models/player.dart';

class EffectManager {
  final Player player;
  final List<ActiveEffect> _activeEffects = [];

  EffectManager(this.player);

  void addEffect(PlayerEffect effect) {
    // 檢查是否已有相同類型的效果
    // 如果有，可以選擇替換或疊加
    final existingEffectIndex = _activeEffects.indexWhere(
      (activeEffect) => activeEffect.effect.runtimeType == effect.runtimeType,
    );

    if (existingEffectIndex >= 0) {
      // 結束現有效果
      _activeEffects[existingEffectIndex].effect.end(player);
      // 移除現有效果
      _activeEffects.removeAt(existingEffectIndex);
    }

    // 應用新效果
    effect.apply(player);

    // 添加到活動效果列表
    _activeEffects.add(ActiveEffect(effect));
  }

  void update(double dt) {
    // 更新所有效果
    final List<ActiveEffect> expiredEffects = [];

    for (final activeEffect in _activeEffects) {
      // 更新效果
      activeEffect.effect.update(player, dt);

      // 更新剩餘時間
      activeEffect.remainingTime -= dt;

      // 檢查是否過期
      if (activeEffect.remainingTime <= 0) {
        expiredEffects.add(activeEffect);
      }
    }

    // 處理過期效果
    for (final expired in expiredEffects) {
      expired.effect.end(player);
      _activeEffects.remove(expired);
    }
  }

  // 清除所有效果
  void clearEffects() {
    for (final activeEffect in _activeEffects) {
      activeEffect.effect.end(player);
    }
    _activeEffects.clear();
  }

  // 獲取活動效果列表（用於UI顯示）
  // List<ActiveEffect> get activeEffects => UnmodifiableListView(_activeEffects);

  // 根據類型獲取效果
  T? getEffectByType<T extends PlayerEffect>() {
    for (final activeEffect in _activeEffects) {
      if (activeEffect.effect is T) {
        return activeEffect.effect as T;
      }
    }
    return null;
  }
}
