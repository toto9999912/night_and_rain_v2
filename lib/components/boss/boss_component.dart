// 敵人元件，會主動檢測並攻擊玩家
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../bullet_component.dart';
import '../enemy_component.dart';
import '../player_component.dart';
import '../map_component.dart';
import '../../main.dart';
import '../portal_component.dart';
import 'aoe_component.dart';
import 'aoe_indicator_component.dart';
import 'beam_component.dart';
import 'beam_warning_component.dart';
import 'boss_aura_component.dart';
import 'boss_death_explosion_component.dart';
import 'boss_phase_transition_effect.dart';

/// Boss攻擊模式枚舉
enum BossAttackPattern {
  circularAttack, // 圓形彈幕
  beamAttack, // 光束攻擊
  aoeAttack, // 範圍攻擊
  rapidFire, // 快速射擊
  teleport, // 瞬移
}

/// Boss狀態枚舉 - 添加明確的狀態管理
enum BossState {
  normal, // 普通狀態
  phaseChange, // 階段轉換中
  specialAttack, // 執行特殊攻擊中
}

/// Boss元件，直接繼承自PositionComponent，擁有獨立的戰鬥邏輯、技能和智能
class BossComponent extends PositionComponent
    with HasGameReference<NightAndRainGame>, CollisionCallbacks, HasPaint
    implements OpacityProvider {
  // Boss基本屬性
  final String bossName; // Boss名稱，用於顯示
  final double maxHealth;
  double health;
  final double baseDamage;
  final double baseSpeed;
  double _speedMultiplier = 1.0;
  double _damageMultiplier = 1.0;

  // 攻擊相關屬性
  final double attackRange; // 攻擊範圍
  final double detectionRange; // 偵測範圍
  final double baseAttackCooldown;
  double _attackCooldownMultiplier = 1.0;
  double _currentAttackCooldown = 0; // 當前攻擊冷卻計時器

  // 計算後的屬性
  double get speed => baseSpeed * _speedMultiplier;
  double get damage => baseDamage * _damageMultiplier;
  double get attackCooldown => baseAttackCooldown * _attackCooldownMultiplier;

  // 視覺樣式
  final Color color;
  final double enemySize;

  // 行為控制
  bool _isDead = false;
  PlayerComponent? _target;
  final MapComponent mapComponent;

  // Sprite相關屬性
  SpriteComponent? _spriteComponent;
  Sprite? _phase1Sprite;
  Sprite? _phase2Sprite;
  Sprite? _phase3Sprite;
  bool _isFacingLeft = false;
  Vector2 _lastPosition = Vector2.zero();

  // 生命條顯示相關
  bool _showHealthBar = true; // Boss總是顯示生命條

  // Boss特有屬性
  int _currentPhase = 1; // 當前階段
  final int totalPhases; // 總階段數

  // 特殊技能冷卻時間
  double _specialAttackCooldown = 0;
  final double specialAttackInterval; // 特殊攻擊間隔

  // 召喚小怪冷卍
  double _summonCooldown = 0;
  final double summonInterval; // 召喚間隔

  // 技能模式
  int _currentAttackPattern = 0;
  final List<BossAttackPattern> attackPatterns;

  // 追蹤上次血量，用於判斷階段轉換
  double _lastHealthPercentage = 1.0;

  // ===== 無敵狀態管理相關變量 - 重新設計 =====
  // 當前Boss狀態
  BossState _currentState = BossState.normal;

  // 各種狀態的計時器
  double _stateTimer = 0.0;

  // 最大無敵時間，防止永久無敵
  static const double _maxInvincibilityTime = 5.0;

  // 階段轉換計時器
  double _phaseChangeTime = 0.0;

  // 記錄無敵開始時間，用於檢測是否卡住
  double _invincibilityStartTime = 0.0;

  // 全局遊戲時間計數器
  double _gameTimeCounter = 0.0;

  BossComponent({
    required Vector2 position,
    required this.mapComponent,
    required this.bossName,
    this.totalPhases = 3,
    this.specialAttackInterval = 8.0,
    this.summonInterval = 15.0,
    this.attackPatterns = const [
      BossAttackPattern.circularAttack,
      BossAttackPattern.beamAttack,
      BossAttackPattern.aoeAttack,
    ],
    this.maxHealth = 1000,
    double speed = 40,
    double damage = 10,
    this.attackRange = 150,
    this.detectionRange = 500,
    double attackCooldown = 1.5,
    this.color = Colors.deepPurple,
    this.enemySize = 40,
  }) : health = maxHealth,
       baseSpeed = speed,
       baseDamage = damage,
       baseAttackCooldown = attackCooldown,
       super(
         position: position,
         size: Vector2.all(enemySize),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 增加碰撞檢測範圍，從原本的1.2倍提高到1.5倍
    final hitboxRadius = size.x / 2 * 1.5; // 增加50%的半徑，使Boss更容易被擊中
    add(
      CircleHitbox(radius: hitboxRadius)..collisionType = CollisionType.active,
    );

    // 載入精靈圖
    try {
      _phase1Sprite = await Sprite.load('BossPhase1.png');
      _phase2Sprite = await Sprite.load('BossPhase2.png');
      _phase3Sprite = await Sprite.load('BossPhase3.png');

      // 創建精靈組件
      _spriteComponent = SpriteComponent(
        sprite: _phase1Sprite,
        size: Vector2.all(enemySize * 1.5),
        anchor: Anchor.center,
      );

      add(_spriteComponent!);
    } catch (e) {
      debugPrint('載入Boss精靈圖失敗: $e');
      // 添加一個fallback顯示，防止沒有圖像時無法看到Boss
      add(
        RectangleComponent(
          size: Vector2.all(enemySize),
          paint: Paint()..color = color,
        ),
      );
    }

    // 儲存初始位置
    _lastPosition = position.clone();

    // 添加脈衝效果
    add(TimerComponent(period: 2.0, repeat: true, onTick: _addPulseEffect));

    // 添加Boss名稱標籤
    add(
      TextComponent(
        text: bossName,
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 2),
            ],
          ),
        ),
        position: Vector2(0, -enemySize - 25),
        anchor: Anchor.bottomCenter,
      ),
    );

    // 添加定期檢查無敵狀態的計時器，確保不會永久卡在無敵狀態
    add(
      TimerComponent(
        period: 1.0,
        repeat: true,
        onTick: _checkInvincibilityStuck,
      ),
    );
  }

  // 檢查是否卡在無敵狀態
  void _checkInvincibilityStuck() {
    if (_currentState == BossState.phaseChange) {
      // 只檢查階段轉換的無敵狀態是否卡住
      double invincibilityDuration = _gameTimeCounter - _invincibilityStartTime;

      // 如果無敵時間超過最大限制，強制解除無敵
      if (invincibilityDuration > _maxInvincibilityTime) {
        debugPrint('⚠️ Boss可能卡在階段轉換無敵狀態($invincibilityDuration秒)，強制解除無敵！');
        _resetToNormalState();
      }
    }
  }

  // 重置到正常狀態的方法
  void _resetToNormalState() {
    // 移除所有可能的閃爍效果
    if (_spriteComponent != null) {
      _spriteComponent!.children.whereType<ColorEffect>().forEach((effect) {
        effect.removeFromParent();
      });
    }

    _currentState = BossState.normal;
    _stateTimer = 0.0;
    _phaseChangeTime = 0.0;
    debugPrint('Boss已重置為正常狀態');
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 更新全局時間計數器
    _gameTimeCounter += dt;

    if (_isDead) return;

    // 更新冷卻計時器
    if (_currentAttackCooldown > 0) {
      _currentAttackCooldown -= dt;
    }
    if (_specialAttackCooldown > 0) {
      _specialAttackCooldown -= dt;
    }
    if (_summonCooldown > 0) {
      _summonCooldown -= dt;
    }

    // 更新狀態計時器
    if (_currentState != BossState.normal) {
      _stateTimer -= dt;

      // 階段轉換有獨立的計時器
      if (_currentState == BossState.phaseChange) {
        _phaseChangeTime -= dt;

        // 階段轉換計時結束，返回正常狀態
        if (_phaseChangeTime <= 0) {
          debugPrint('Boss階段轉換完成，恢復可被攻擊狀態');
          _completePhaseChange();
        }
      }

      // 一般狀態計時結束，返回正常狀態
      if (_stateTimer <= 0) {
        if (_currentState == BossState.specialAttack) {
          _currentState = BossState.normal;
          debugPrint('Boss特殊攻擊結束，恢復可被攻擊狀態');
        }
      }
    }

    // 檢查階段轉換
    _checkPhaseTransition();

    // 根據當前狀態決定行為
    switch (_currentState) {
      case BossState.normal:
        // 正常狀態下追蹤玩家並攻擊
        _bossAggressiveTracking(dt);
        _bossPrimaryAttack(dt);

        // 檢查是否可以使用特殊攻擊
        if (_specialAttackCooldown <= 0) {
          _performSpecialAttack();
          _specialAttackCooldown = specialAttackInterval / _currentPhase;
        }

        // 檢查是否可以召喚小怪
        if (_summonCooldown <= 0 && _currentPhase >= 2) {
          _summonMinions();
          _summonCooldown = summonInterval;
        }
        break;

      case BossState.phaseChange:
        // 階段轉換中只進行簡單的移動，不攻擊
        _simpleBossMovement(dt);
        break;

      case BossState.specialAttack:
        // 特殊攻擊中也只進行簡單的移動
        _simpleBossMovement(dt);
        break;
    }

    // 更新精靈朝向
    _updateSpriteOrientation();
  }

  // 簡化版的Boss移動，用於特殊狀態下
  void _simpleBossMovement(double dt) {
    if (_target == null) return;

    final playerCenter = _target!.position + _target!.size / 2;
    final bossCenter = position + size / 2;
    final distanceToPlayer = bossCenter.distanceTo(playerCenter);

    // 保持與玩家的適當距離
    if (distanceToPlayer < attackRange * 0.5 ||
        distanceToPlayer > attackRange * 1.5) {
      final directionToPlayer = (playerCenter - bossCenter)..normalize();

      // 如果太近就遠離，太遠就靠近
      Vector2 moveDirection;
      if (distanceToPlayer < attackRange * 0.5) {
        moveDirection = -directionToPlayer;
      } else {
        moveDirection = directionToPlayer;
      }

      // 以較慢的速度移動
      _moveInDirection(moveDirection, dt, speedMultiplier: 0.5);
    }
  }

  // 更新精靈朝向 - 簡化方法
  void _updateSpriteOrientation() {
    if (_spriteComponent == null) return;

    final movement = position - _lastPosition;
    if (movement.length > 0.1) {
      // 只在有顯著移動時才調整朝向
      if (movement.x < 0 && !_isFacingLeft) {
        _spriteComponent!.flipHorizontally();
        _isFacingLeft = true;
      } else if (movement.x > 0 && _isFacingLeft) {
        _spriteComponent!.flipHorizontally();
        _isFacingLeft = false;
      }
    }

    _lastPosition = position.clone();
  }

  // 進入新階段
  void _enterPhase(int phase) {
    _currentPhase = phase;
    debugPrint('Boss進入第$_currentPhase階段！');

    // 更新精靈圖
    if (_spriteComponent != null) {
      switch (phase) {
        case 1:
          _spriteComponent!.sprite = _phase1Sprite;
          break;
        case 2:
          _spriteComponent!.sprite = _phase2Sprite;
          break;
        case 3:
          _spriteComponent!.sprite = _phase3Sprite;
          break;
      }
    }

    // 切換到階段轉換狀態
    _currentState = BossState.phaseChange;

    // 設置階段轉換持續時間
    _stateTimer = 3.0;
    _phaseChangeTime = 3.0;

    // 記錄無敵開始時間
    _invincibilityStartTime = _gameTimeCounter;

    debugPrint('Boss進入階段轉換，短暫無敵狀態 (${_stateTimer}秒)');

    // 執行階段轉換特效
    _performPhaseTransitionEffect();

    // 根據階段調整屬性
    switch (phase) {
      case 2:
        _speedMultiplier *= 1.2;
        _attackCooldownMultiplier *= 0.8;
        break;
      case 3:
        _speedMultiplier *= 1.5;
        _attackCooldownMultiplier *= 0.6;
        _damageMultiplier *= 1.3;
        break;
    }
  }

  // 階段轉換完成
  void _completePhaseChange() {
    // 移除閃爍效果
    if (_spriteComponent != null) {
      _spriteComponent!.children.whereType<ColorEffect>().forEach((effect) {
        effect.removeFromParent();
      });
    }

    // 重置為正常狀態
    _currentState = BossState.normal;
    _stateTimer = 0.0;
    _phaseChangeTime = 0.0;

    debugPrint('Boss階段轉換無敵狀態結束，可以被攻擊');
  }

  // 階段轉換特效 - 徹底解決方案
  void _performPhaseTransitionEffect() {
    // 添加視覺特效到場景
    parent?.add(
      BossPhaseTransitionEffect(
        position: position.clone(),
        color: _currentPhase == 2 ? Colors.orange : Colors.red,
        size: Vector2.all(enemySize * 3),
      ),
    );

    // 使用純縮放效果代替閃爍效果，避免使用ColorEffect
    final scaleController = EffectController(
      duration: 0.2,
      reverseDuration: 0.2,
      infinite: true,
      alternate: true,
    );

    // 為Boss本體添加縮放效果
    final scaleEffect = ScaleEffect.by(
      Vector2.all(1.2), // 放大到1.2倍
      scaleController,
    );

    // 直接添加到Boss本體
    add(scaleEffect);

    // 2秒後移除效果
    add(
      TimerComponent(
        period: 2.0,
        removeOnFinish: true,
        onTick: () {
          // 找到並移除所有縮放效果
          children.whereType<ScaleEffect>().forEach((effect) {
            effect.removeFromParent();
          });
          // 確保恢復正常縮放
          scale = Vector2.all(1.0);
          debugPrint('階段轉換視覺效果已結束');
        },
      ),
    );

    // 添加額外的爆炸效果來增強視覺體驗
    for (int i = 0; i < 3; i++) {
      add(
        TimerComponent(
          period: 0.3 * i,
          removeOnFinish: true,
          onTick: () {
            // 在Boss周圍創建爆炸效果
            final explosionOffset = Vector2(
              (math.Random().nextDouble() - 0.5) * enemySize,
              (math.Random().nextDouble() - 0.5) * enemySize,
            );

            parent?.add(
              ExplosionComponent(
                position: position + explosionOffset,
                size: Vector2.all(enemySize * (0.8 + i * 0.2)),
                color:
                    _currentPhase == 2
                        ? Colors.orange.withValues(alpha: 0.7)
                        : Colors.red.withValues(alpha: 0.7),
              ),
            );
          },
        ),
      );
    }
  }

  // 追蹤玩家行為 - 簡化實現
  void _bossAggressiveTracking(double dt) {
    final player = game.getPlayer();
    _target = player;

    final playerCenter = player.position + player.size / 2;
    final bossCenter = position + size / 2;
    final distanceToPlayer = bossCenter.distanceTo(playerCenter);
    final directionToPlayer = (playerCenter - bossCenter)..normalize();

    // 簡化距離計算
    double idealDistance = attackRange * (1.0 - _currentPhase * 0.2);
    double moveSpeedMultiplier = 1.0 + (_currentPhase - 1) * 0.2;

    // 簡化移動邏輯
    if ((distanceToPlayer - idealDistance).abs() > 20) {
      Vector2 movementDirection;
      if (distanceToPlayer > idealDistance) {
        movementDirection = directionToPlayer;
      } else {
        movementDirection = -directionToPlayer;
      }

      // 添加隨機側向移動（第2階段以上）
      if (_currentPhase >= 2) {
        final perpendicular = Vector2(
          -directionToPlayer.y,
          directionToPlayer.x,
        );
        final randomFactor = math.sin(_specialAttackCooldown * 2) * 0.5;
        movementDirection += perpendicular * randomFactor;
        movementDirection.normalize();
      }

      _moveInDirection(
        movementDirection,
        dt,
        speedMultiplier: moveSpeedMultiplier,
      );
    } else if (_currentPhase >= 2) {
      // 在理想距離時的側向移動
      final perpendicular = Vector2(-directionToPlayer.y, directionToPlayer.x);
      final randomFactor = math.sin(_specialAttackCooldown * 2) * 0.5;
      _moveInDirection(
        perpendicular * randomFactor,
        dt,
        speedMultiplier: moveSpeedMultiplier * 0.7,
      );
    }
  }

  // 移動處理
  void _moveInDirection(
    Vector2 direction,
    double dt, {
    double speedMultiplier = 1.0,
  }) {
    if (_isDead) return;

    final movement = direction * speed * speedMultiplier * dt;
    final nextPosition = position + movement;

    // 嘗試移動並處理障礙物碰撞
    if (!mapComponent.checkObstacleCollision(
      nextPosition,
      Vector2.all(enemySize),
    )) {
      position = nextPosition;
    } else {
      // 嘗試X和Y方向的分離移動
      final nextPositionX = Vector2(nextPosition.x, position.y);
      final nextPositionY = Vector2(position.x, nextPosition.y);

      if (!mapComponent.checkObstacleCollision(
        nextPositionX,
        Vector2.all(enemySize),
      )) {
        position = nextPositionX;
      }

      if (!mapComponent.checkObstacleCollision(
        nextPositionY,
        Vector2.all(enemySize),
      )) {
        position = nextPositionY;
      }
    }
  }

  // 主要攻擊
  void _bossPrimaryAttack(double dt) {
    if (_target == null || _currentAttackCooldown > 0) return;

    final distanceToTarget = position.distanceTo(
      _target!.position + _target!.size / 2,
    );

    if (distanceToTarget <= attackRange * 1.2) {
      switch (_currentPhase) {
        case 1:
          _fireBossProjectile();
          break;
        case 2:
          _fireBossMultiProjectiles(3);
          break;
        case 3:
          _fireBossMultiProjectiles(5);
          break;
      }

      _currentAttackCooldown = attackCooldown;
    }
  }

  // 發射單個子彈
  void _fireBossProjectile() {
    if (_target == null) return;

    final attackDirection =
        (_target!.position + _target!.size / 2 - position)..normalize();
    final bulletPosition = position + attackDirection * enemySize / 2;

    final bullet = BulletComponent(
      position: bulletPosition,
      direction: attackDirection,
      speed: 280,
      damage: damage * 0.6,
      range: 500,
      color: color,
      size: enemySize * 0.3,
      trailEffect: 'shine',
      isEnemyBullet: true,
    );

    parent?.add(bullet);
    parent?.add(
      ExplosionComponent(
        position: bulletPosition,
        size: Vector2.all(enemySize * 0.5),
        color: color,
      ),
    );
  }

  // 發射多個子彈
  void _fireBossMultiProjectiles(int count) {
    if (_target == null) return;

    final baseDirection =
        (_target!.position + _target!.size / 2 - position)..normalize();
    final spreadAngle = 0.4;

    for (int i = 0; i < count; i++) {
      final angleOffset = spreadAngle * (2 * i / (count - 1) - 1);
      final angle = math.atan2(baseDirection.y, baseDirection.x) + angleOffset;
      final direction = Vector2(math.cos(angle), math.sin(angle));
      final bulletPosition = position + direction * enemySize / 2;

      String trailEffectType =
          i == count ~/ 2 ? 'particles' : (i % 2 == 0 ? 'simple' : 'none');

      final bullet = BulletComponent(
        position: bulletPosition,
        direction: direction,
        speed: 250 + 20 * i.toDouble(),
        damage: damage * 0.45,
        range: 450,
        color: color,
        size: enemySize * 0.25,
        trailEffect: trailEffectType,
        isEnemyBullet: true,
      );

      parent?.add(bullet);
      parent?.add(
        ExplosionComponent(
          position: bulletPosition,
          size: Vector2.all(enemySize * 0.3),
          color: color.withValues(alpha: 0.7),
        ),
      );
    }

    parent?.add(
      ExplosionComponent(
        position: position.clone(),
        size: Vector2.all(enemySize * 0.8),
        color: color,
      ),
    );
  }

  // 檢查階段轉換
  void _checkPhaseTransition() {
    // 只在正常狀態下檢查階段轉換
    if (_currentState != BossState.normal) return;

    final healthPercentage = health / maxHealth;

    if (_currentPhase == 1 &&
        healthPercentage <= 0.7 &&
        _lastHealthPercentage > 0.7) {
      _enterPhase(2);
    } else if (_currentPhase == 2 &&
        healthPercentage <= 0.3 &&
        _lastHealthPercentage > 0.3) {
      _enterPhase(3);
    }

    _lastHealthPercentage = healthPercentage;
  }

  // 執行特殊攻擊
  void _performSpecialAttack() {
    if (_target == null) return;

    final attackPattern = attackPatterns[_currentAttackPattern];
    _currentAttackPattern = (_currentAttackPattern + 1) % attackPatterns.length;

    debugPrint('Boss使用特殊攻擊: $attackPattern');

    // 切換到特殊攻擊狀態
    _currentState = BossState.specialAttack;
    _stateTimer = 2.0;

    // 記錄無敵開始時間
    _invincibilityStartTime = _gameTimeCounter;

    switch (attackPattern) {
      case BossAttackPattern.circularAttack:
        _performCircularAttack();
        break;
      case BossAttackPattern.beamAttack:
        _performBeamAttack();
        break;
      case BossAttackPattern.aoeAttack:
        _performAoeAttack();
        break;
      case BossAttackPattern.rapidFire:
        _performRapidFire();
        break;
      case BossAttackPattern.teleport:
        _performTeleport();
        break;
    }
  }

  // 圓形彈幕攻擊
  void _performCircularAttack() {
    const int bulletCount = 16;
    const double radius = 20.0;

    for (int i = 0; i < bulletCount; i++) {
      final angle = 2 * math.pi * i / bulletCount;
      final direction = Vector2(math.cos(angle), math.sin(angle));
      final bulletPosition = position + direction * radius;

      final bullet = BulletComponent(
        position: bulletPosition,
        direction: direction,
        speed: 150,
        damage: damage * 0.35,
        range: 300,
        color: color,
        size: enemySize * 0.2,
        isEnemyBullet: true,
      );

      parent?.add(bullet);
      parent?.add(
        ExplosionComponent(
          position: bulletPosition,
          size: Vector2.all(enemySize * 0.3),
          color: color.withValues(alpha: 0.5),
        ),
      );
    }

    parent?.add(
      ExplosionComponent(
        position: position.clone(),
        size: Vector2.all(enemySize * 1.5),
        color: color,
      ),
    );
  }

  // 光束攻擊
  void _performBeamAttack() {
    if (_target == null) return;

    final targetDirection = (_target!.position - position)..normalize();

    add(
      TimerComponent(
        period: 1.0,
        removeOnFinish: true,
        onTick: () {
          for (double offset = -0.2; offset <= 0.2; offset += 0.2) {
            final angle =
                math.atan2(targetDirection.y, targetDirection.x) + offset;
            final adjustedDirection = Vector2(math.cos(angle), math.sin(angle));

            final beam = BeamComponent(
              position: position.clone(),
              direction: adjustedDirection,
              length: 600,
              width: 25,
              damage: damage * 1.5,
              duration: 0.8,
              color: color,
              isEnemyAttack: true,
            );

            parent?.add(beam);
          }
        },
      ),
    );

    final warningLine = BeamWarningComponent(
      position: position.clone(),
      direction: targetDirection,
      length: 600,
      color: Colors.red.withValues(alpha: 0.5),
      duration: 1.0,
    );

    parent?.add(warningLine);
  }

  // 範圍攻擊
  void _performAoeAttack() {
    if (_target == null) return;

    final targetPos = _target!.position.clone();

    final indicator = AoeIndicatorComponent(
      position: targetPos,
      radius: 120,
      duration: 1.5,
      color: Colors.red.withValues(alpha: 0.3),
    );

    parent?.add(indicator);

    add(
      TimerComponent(
        period: 1.5,
        removeOnFinish: true,
        onTick: () {
          final aoe = AoeComponent(
            position: targetPos,
            radius: 120,
            damage: damage * 2,
            duration: 3.0,
            tickInterval: 0.5,
            color: color.withValues(alpha: 0.6),
          );

          parent?.add(aoe);
          parent?.add(
            ExplosionComponent(
              position: targetPos,
              size: Vector2.all(240),
              color: color,
            ),
          );
        },
      ),
    );
  }

  // 快速射擊
  void _performRapidFire() {
    if (_target == null) return;

    final targetDirection = (_target!.position - position)..normalize();

    for (int i = 0; i < 5; i++) {
      add(
        TimerComponent(
          period: 0.15 * i,
          removeOnFinish: true,
          onTick: () {
            final randomAngle = (math.Random().nextDouble() - 0.5) * 0.3;
            final angle =
                math.atan2(targetDirection.y, targetDirection.x) + randomAngle;
            final adjustedDirection = Vector2(math.cos(angle), math.sin(angle));

            final bullet = BulletComponent(
              position: position + adjustedDirection * enemySize / 2,
              direction: adjustedDirection,
              speed: 350,
              damage: damage * 0.4,
              range: 400,
              color: color,
              size: enemySize * 0.15,
              isEnemyBullet: true,
            );

            parent?.add(bullet);
          },
        ),
      );
    }
  }

  // 瞬移
  void _performTeleport() {
    if (_target == null) return;

    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = 100 + random.nextDouble() * 100;

    final teleportDestination =
        _target!.position +
        Vector2(math.cos(angle) * distance, math.sin(angle) * distance);

    if (!mapComponent.checkObstacleCollision(
      teleportDestination,
      Vector2.all(enemySize),
    )) {
      parent?.add(
        ExplosionComponent(
          position: position.clone(),
          size: Vector2.all(enemySize * 0.8),
          color: color.withValues(alpha: 0.7),
        ),
      );

      position = teleportDestination;
      debugPrint('Boss 瞬移到新位置');

      parent?.add(
        ExplosionComponent(
          position: position.clone(),
          size: Vector2.all(enemySize * 0.8),
          color: color.withValues(alpha: 0.7),
        ),
      );
    }
  }

  // 召喚小怪
  void _summonMinions() {
    final minionCount = _currentPhase;
    final random = math.Random();

    for (int i = 0; i < minionCount; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = 100 + random.nextDouble() * 50;

      final summonPos =
          position +
          Vector2(math.cos(angle) * distance, math.sin(angle) * distance);

      if (!mapComponent.checkObstacleCollision(summonPos, Vector2.all(24))) {
        try {
          EnemyType minionType;
          if (_currentPhase == 2) {
            minionType = EnemyType.melee;
          } else {
            minionType =
                random.nextBool() ? EnemyType.ranged : EnemyType.hybrid;
          }

          final minion = EnemyComponent(
            position: summonPos,
            type: minionType,
            mapComponent: mapComponent,
            maxHealth: 50,
            speed: 80,
            damage: 8,
            attackRange: 30,
            detectionRange: 300,
            color: color.withRed((color.red + 40).clamp(0, 255)),
            enemySize: 24,
          );

          parent?.add(minion);
          parent?.add(
            ExplosionComponent(
              position: summonPos,
              size: Vector2.all(48),
              color: color.withValues(alpha: safeOpacity(0.8)),
            ),
          );
        } catch (e) {
          debugPrint('召喚小怪時發生錯誤: $e');
        }
      }
    }

    debugPrint('Boss召喚了$minionCount個小怪');
  }

  /// 確保透明度值在有效範圍內 (0.0-1.0)
  double safeOpacity(double value) {
    if (value.isNaN) return 1.0;
    return value.clamp(0.0, 1.0);
  }

  // 添加脈衝光環效果
  void _addPulseEffect() {
    add(
      ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(duration: 0.5),
        onComplete: () {
          add(
            ScaleEffect.to(Vector2.all(1.0), EffectController(duration: 0.5)),
          );
        },
      ),
    );

    parent?.add(
      BossAuraComponent(
        position: position.clone(),
        radius: enemySize * 1.5,
        color: color.withValues(alpha: 0.3),
      ),
    );
  }

  // 受傷處理方法 - 移除了30%最大傷害的限制
  void takeDamage(double amount) {
    if (_isDead) return;

    // 只在階段轉換時無敵，特殊攻擊時可以受到傷害
    if (_currentState == BossState.phaseChange) {
      // 顯示傷害抵抗視覺效果
      final resistPos = position + Vector2(0, -enemySize / 2);
      final resistText = TextComponent(
        text: '無敵!',
        textRenderer: TextPaint(
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        position: resistPos,
        anchor: Anchor.center,
      );

      // 添加向上移動效果
      resistText.add(
        MoveEffect.by(Vector2(0, -20), EffectController(duration: 0.6)),
      );

      // 使用TimerComponent替代OpacityEffect來移除組件
      resistText.add(
        TimerComponent(
          period: 0.6,
          removeOnFinish: true,
          onTick: () {
            resistText.removeFromParent();
          },
        ),
      );

      parent?.add(resistText);

      debugPrint(
        'Boss處於階段轉換狀態，無敵中 (剩餘${_phaseChangeTime.toStringAsFixed(1)}秒)',
      );
      return;
    }

    // 移除了30%最大生命值的傷害限制
    health -= amount;

    // 顯示生命條
    _showHealthBar = true;

    debugPrint('Boss $bossName 受到 $amount 點傷害，剩餘生命: $health');

    // 檢查是否死亡
    if (health <= 0) {
      health = 0;
      _die();
    }
  }

  // 渲染生命條
  void _renderHealthBar(Canvas canvas) {
    const barHeight = 12.0; // 放大兩倍
    final barWidth = enemySize * 3.0; // 放大兩倍
    final barX = -barWidth / 2;
    final barY = -enemySize / 2 - 20; // 稍微上移，避免與Boss重疊

    // 背景
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()..color = Colors.grey.withValues(alpha: 0.7),
    );

    // 生命值
    final healthRatio = health / maxHealth;

    // 根據階段使用不同顏色
    Color healthColor;
    switch (_currentPhase) {
      case 1:
        healthColor = Colors.green.shade600;
        break;
      case 2:
        healthColor = Colors.orange.shade600;
        break;
      case 3:
        healthColor = Colors.red.shade600;
        break;
      default:
        healthColor = Colors.green.shade600;
    }

    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthRatio, barHeight),
      Paint()..color = healthColor.withValues(alpha: 0.8),
    );

    // 邊框
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 階段指示器
    final phase2X = barX + barWidth * 0.7;
    final phase3X = barX + barWidth * 0.3;

    // 第二階段線
    canvas.drawLine(
      Offset(phase2X, barY - 2),
      Offset(phase2X, barY + barHeight + 2),
      Paint()..color = Colors.white,
    );

    // 第三階段線
    canvas.drawLine(
      Offset(phase3X, barY - 2),
      Offset(phase3X, barY + barHeight + 2),
      Paint()..color = Colors.white,
    );

    // 顯示當前狀態指示器 - 只在階段轉換時顯示無敵狀態
    if (_currentState == BossState.phaseChange) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: "階段轉換中 (無敵)",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(barX + (barWidth - textPainter.width) / 2, barY - 20),
      );
    } else if (_currentState == BossState.specialAttack) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: "特殊攻擊中",
          style: TextStyle(
            color: Colors.yellow,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(barX + (barWidth - textPainter.width) / 2, barY - 20),
      );
    }
  }

  // 死亡處理
  void _die() {
    _isDead = true;

    // 確保清除所有無敵狀態
    _currentState = BossState.normal;
    _stateTimer = 0;
    _phaseChangeTime = 0;

    final bossPosition = position.clone();
    final gameRef = game;
    final dungeonManager = gameRef.dungeonManager;
    final isInBossRoom =
        dungeonManager != null &&
        dungeonManager.currentRoomId == 'dungeon_room_3';

    debugPrint('Boss死亡，當前房間: ${dungeonManager?.currentRoomId}');

    // 創建死亡特效
    for (int i = 0; i < 5; i++) {
      final delay = i * 0.2;
      gameRef.gameWorld.add(
        TimerComponent(
          period: delay,
          removeOnFinish: true,
          onTick: () {
            final random = math.Random();
            final offset = Vector2(
              (random.nextDouble() - 0.5) * enemySize,
              (random.nextDouble() - 0.5) * enemySize,
            );

            gameRef.gameWorld.add(
              ExplosionComponent(
                position: bossPosition + offset,
                size: Vector2.all(enemySize * (1.0 + i * 0.3)),
                color: i % 2 == 0 ? color : Colors.orange,
              ),
            );
          },
        ),
      );
    }

    // 添加主要爆炸效果和創建傳送門
    gameRef.gameWorld.add(
      TimerComponent(
        period: 1.0,
        removeOnFinish: true,
        onTick: () {
          gameRef.gameWorld.add(
            BossDeathExplosionComponent(
              position: bossPosition.clone(),
              size: Vector2.all(enemySize * 5),
            ),
          );

          // 如果在Boss房間，創建傳送門
          if (isInBossRoom) {
            debugPrint('確認在Boss房間，準備顯示通知和創建迴廊');

            gameRef.showInteractionPrompt('一條鏡中迴廊出現了...');

            gameRef.gameWorld.add(
              TimerComponent(
                period: 2.0,
                removeOnFinish: true,
                onTick: () {
                  debugPrint('正在創建通往鏡中迴廊的傳送門...');

                  try {
                    final portalPosition = Vector2(
                      dungeonManager!.roomSize.x * 0.8,
                      dungeonManager.roomSize.y * 0.3,
                    );

                    final secretPortal = PortalComponent(
                      position: portalPosition,
                      type: PortalType.dungeonRoom,
                      destinationId: 'secret_corridor',
                      portalName: '鏡中迴廊',
                      color: Colors.purple.shade700,
                    );

                    gameRef.gameWorld.add(secretPortal);
                    debugPrint('鏡中迴廊傳送門創建成功，位置: $portalPosition');
                    gameRef.hideInteractionPrompt();
                  } catch (e) {
                    debugPrint('創建傳送門時發生錯誤: $e');
                  }
                },
              ),
            );
          } else {
            debugPrint('不在Boss房間，不創建迴廊');
          }
        },
      ),
    );

    // 添加淡出效果
    add(OpacityEffect.fadeOut(EffectController(duration: 1.0)));

    // 移除自身
    removeFromParent();

    debugPrint('Boss $bossName 已經被擊敗！');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 渲染生命條
    if (_showHealthBar) {
      _renderHealthBar(canvas);
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 與玩家子彈碰撞處理
    if (other is BulletComponent && !other.isEnemyBullet) {
      takeDamage(other.damage);
      other.removeFromParent();
    }

    // 與玩家直接碰撞處理
    if (other is PlayerComponent && _currentAttackCooldown <= 0) {
      debugPrint('Boss 與玩家碰撞！嘗試造成 ${damage.toInt()} 點傷害');

      try {
        other.takeDamage(damage.toInt());
        debugPrint('Boss 成功對玩家造成傷害');
      } catch (e) {
        debugPrint('Boss 對玩家造成傷害時出錯: $e');
      }

      _currentAttackCooldown = attackCooldown;

      try {
        parent?.add(
          ExplosionComponent(
            position: other.position + other.size / 2,
            size: Vector2.all(enemySize * 0.5),
            color: color,
          ),
        );
      } catch (e) {
        debugPrint('添加碰撞效果時出錯: $e');
      }
    }
  }

  @override
  double get opacity => _opacity;
  double _opacity = 1.0;
  @override
  set opacity(double value) {
    if (value < 0 || value > 1) {
      developer.log('警告: Boss設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }

    if ((value - _opacity).abs() > 0.1) {
      developer.log('Boss透明度從 $_opacity 變更到 $value', name: 'OpacityDebug');
    }

    _opacity = value;
  }
}
