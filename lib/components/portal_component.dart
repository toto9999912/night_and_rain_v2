import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:night_and_rain_v2/main.dart';
import 'package:flame/particles.dart';

import 'player_component.dart';

/// 傳送門類型
enum PortalType {
  /// 進入地下城
  dungeonEntrance,

  /// 地下城內部的房間傳送
  dungeonRoom,

  /// 返回主世界
  returnToMainWorld,
}

/// 傳送門組件，用於玩家在不同區域間傳送
class PortalComponent extends PositionComponent
    with HasGameReference<NightAndRainGame>, CollisionCallbacks, HasPaint
    implements OpacityProvider {
  /// 傳送門類型
  final PortalType type;

  /// 傳送目的地的唯一ID
  final String destinationId;

  /// 傳送門顏色
  final Color color;

  /// 傳送門大小
  final double portalSize;

  /// 是否顯示傳送效果
  final bool showEffects;

  /// 傳送門的名稱或說明
  final String portalName;

  /// 玩家是否在傳送門範圍內
  bool _playerInRange = false;

  /// 特效發生器
  Timer? _particleTimer;

  /// 是否正在冷卻（防止連續傳送）
  bool _isCooldown = false;
  double _cooldownTime = 0;
  static const double _cooldownDuration = 2.0; // 冷卻時間2秒

  /// 透明度屬性，實現OpacityProvider接口
  double _opacity = 1.0;

  @override
  double get opacity => _opacity;

  @override
  set opacity(double value) {
    _opacity = value;
  }

  PortalComponent({
    required Vector2 position,
    required this.type,
    required this.destinationId,
    this.color = Colors.purple,
    this.portalSize = 40,
    this.showEffects = true,
    this.portalName = "傳送門",
  }) : super(
         position: position,
         size: Vector2.all(portalSize),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加碰撞檢測區域
    add(CircleHitbox()..collisionType = CollisionType.passive);

    // 設置粒子效果定時器
    if (showEffects) {
      _particleTimer = Timer(
        0.1, // 每0.1秒產生一次粒子
        onTick: _generateParticles,
        repeat: true,
        autoStart: true,
      );
    }

    // 根據傳送門類型添加不同的視覺效果
    switch (type) {
      case PortalType.dungeonEntrance:
        add(
          CircleComponent(
            radius: portalSize / 2,
            paint: Paint()..color = color.withValues(alpha: 0.7),
          ),
        );
        break;
      case PortalType.dungeonRoom:
        add(
          CircleComponent(
            radius: portalSize / 2,
            paint: Paint()..color = color.withValues(alpha: 0.6),
          ),
        );
        break;
      case PortalType.returnToMainWorld:
        add(
          CircleComponent(
            radius: portalSize / 2,
            paint:
                Paint()
                  ..color = Colors.purple.withValues(alpha: 0.7), // 改變回主世界傳送門顏色
          ),
        );
        break;
    } // 添加名稱標籤
    add(
      TextComponent(
        text: portalName,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontFamily: 'Cubic11', // 使用 Cubic11 字體
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: Vector2(0, -portalSize / 2 - 15),
        anchor: Anchor.bottomCenter,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新動畫時間

    // 更新粒子效果定時器
    _particleTimer?.update(dt);

    // 更新冷卻時間
    if (_isCooldown) {
      _cooldownTime -= dt;
      if (_cooldownTime <= 0) {
        _isCooldown = false;
      }
    }

    // 檢查玩家是否在範圍內且按下E鍵
    if (_playerInRange && !_isCooldown) {
      // 傳送邏輯在碰撞檢測和交互邏輯中處理
    }
  }

  /// 生成粒子特效
  void _generateParticles() {
    if (!showEffects) return;

    final random = math.Random();
    final particlesComponent = ParticleSystemComponent(
      particle: Particle.generate(
        count: 1,
        lifespan: 1.5,
        generator: (i) {
          final angle = random.nextDouble() * 2 * math.pi;
          final radius = portalSize / 2 * random.nextDouble();
          final position = Vector2(
            math.cos(angle) * radius,
            math.sin(angle) * radius,
          );

          return AcceleratedParticle(
            position: position,
            speed: Vector2(
              (random.nextDouble() - 0.5) * 20,
              (random.nextDouble() - 0.5) * 20,
            ),
            acceleration: Vector2(0, 0),
            child: CircleParticle(
              radius: 1 + random.nextDouble() * 2,
              paint:
                  Paint()
                    ..color = color.withValues(
                      alpha: 0.6 + random.nextDouble() * 0.4,
                    ),
            ),
          );
        },
      ),
    );

    add(particlesComponent);
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is PlayerComponent) {
      _playerInRange = true; // 顯示交互提示（使用遊戲中的全局方法，確保字體統一）
      final interactionText = "按 E 使用${portalName}";
      game.showInteractionPrompt(interactionText);

      // 添加放大效果
      add(
        ScaleEffect.by(
          Vector2.all(1.1),
          EffectController(
            duration: 0.3,
            reverseDuration: 0.3,
            infinite: true,
            curve: Curves.easeInOut,
          ),
        ),
      );
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    if (other is PlayerComponent) {
      _playerInRange = false;

      // 隱藏交互提示
      game.hideInteractionPrompt();

      // 移除所有效果
      children.whereType<ScaleEffect>().forEach(
        (effect) => effect.removeFromParent(),
      );
    }
  }

  /// 激活傳送門
  void activate() {
    if (_isCooldown) return;

    // 設置冷卻
    _isCooldown = true;
    _cooldownTime = _cooldownDuration;

    // 添加傳送特效
    add(OpacityEffect.fadeOut(EffectController(duration: 0.5)));

    // 執行傳送
    game.triggerPortalTransport(destinationId, type);
  }
}
