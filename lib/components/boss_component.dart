// 敵人元件，會主動檢測並攻擊玩家
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'bullet_component.dart';
import 'enemy_component.dart';
import 'player_component.dart';
import 'map_component.dart';
import '../main.dart';
import 'portal_component.dart';

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

  // 玩家最後看到的位置，用於跟隨

  // New sprite-related properties
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

  // 標記是否處於特殊行為狀態
  bool _isPerformingSpecialMove = false;
  double _specialMoveTimer = 0;

  // 範圍攻擊視覺指示器
  PositionComponent? _aoeIndicator;

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
    double damage = 25,
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

    // Add collision hitbox
    add(CircleHitbox()..collisionType = CollisionType.active);

    // Load sprites for different phases
    _phase1Sprite = await Sprite.load('BossPhase1.png');
    _phase2Sprite = await Sprite.load('BossPhase2.png');
    _phase3Sprite = await Sprite.load('BossPhase3.png');

    // Create sprite component
    _spriteComponent = SpriteComponent(
      sprite: _phase1Sprite,
      size: Vector2.all(enemySize * 1.5), // Adjust size as needed
      anchor: Anchor.center,
    );

    add(_spriteComponent!);

    // Store initial position
    _lastPosition = position.clone();

    // Add pulse effect
    add(TimerComponent(period: 2.0, repeat: true, onTick: _addPulseEffect));

    // Add boss name label
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
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDead) return;

    // Update attack cooldown
    if (_currentAttackCooldown > 0) {
      _currentAttackCooldown -= dt;
    }

    // Update special attack cooldown
    if (_specialAttackCooldown > 0) {
      _specialAttackCooldown -= dt;
    }

    // Update summon cooldown
    if (_summonCooldown > 0) {
      _summonCooldown -= dt;
    }

    // Handle special move timer
    if (_isPerformingSpecialMove) {
      _specialMoveTimer -= dt;
      if (_specialMoveTimer <= 0) {
        _isPerformingSpecialMove = false;
      }
    }

    // Check phase transition
    _checkPhaseTransition();

    // Aggressive player tracking
    _bossAggressiveTracking(dt);

    // If not performing special move, handle attacks
    if (!_isPerformingSpecialMove) {
      _bossPrimaryAttack(dt);

      if (_specialAttackCooldown <= 0) {
        _performSpecialAttack();
        _specialAttackCooldown = specialAttackInterval / _currentPhase;
      }

      if (_summonCooldown <= 0 && _currentPhase >= 2) {
        _summonMinions();
        _summonCooldown = summonInterval;
      }
    }

    // Detect movement direction and update sprite orientation
    if (_spriteComponent != null) {
      final movement = position - _lastPosition;
      if (movement.length > 0.1) {
        // Add threshold to avoid flipping on small movements
        if (movement.x < 0 && !_isFacingLeft) {
          // Moving left, flip sprite
          _spriteComponent!.flipHorizontally();
          _isFacingLeft = true;
        } else if (movement.x > 0 && _isFacingLeft) {
          // Moving right, restore sprite
          _spriteComponent!.flipHorizontally();
          _isFacingLeft = false;
        }
      }

      // Update last position
      _lastPosition = position.clone();
    }
  }

  // Boss的積極追踪行為
  void _bossAggressiveTracking(double dt) {
    // 直接從遊戲實例獲取玩家，Boss總是知道玩家在哪裡
    final player = game.getPlayer();

    _target = player;

    // 玩家的中心位置
    final playerCenter = player.position + player.size / 2;
    final bossCenter = position + size / 2;

    // 計算距離和方向
    final distanceToPlayer = bossCenter.distanceTo(playerCenter);
    final directionToPlayer = (playerCenter - bossCenter)..normalize();

    // 更新最後已知玩家位置

    // 根據Boss的攻擊階段和距離決定行為
    double idealDistance;
    double moveSpeedMultiplier = 1.0;

    // 第一階段：保持中距離，適合射擊
    // 第二階段：更靈活，靠近後又拉開距離
    // 第三階段：積極貼近玩家

    switch (_currentPhase) {
      case 1:
        idealDistance = attackRange * 0.8; // 保持在射程的80%位置
        moveSpeedMultiplier = 0.9;
        break;
      case 2:
        // 第二階段：更靈活的距離控制
        if (_specialAttackCooldown < specialAttackInterval / 2) {
          // 準備放技能時靠近玩家
          idealDistance = attackRange * 0.5;
          moveSpeedMultiplier = 1.2;
        } else {
          // 剛放完技能就拉開距離
          idealDistance = attackRange * 1.0;
          moveSpeedMultiplier = 1.1;
        }
        break;
      case 3:
        // 第三階段：更激進的追踪
        idealDistance = attackRange * 0.3; // 更靠近玩家
        moveSpeedMultiplier = 1.5;
        break;
      default:
        idealDistance = attackRange * 0.8;
    }

    // 根據當前與理想距離的差異決定移動方向
    if ((distanceToPlayer - idealDistance).abs() > 20) {
      Vector2 movementDirection;

      if (distanceToPlayer > idealDistance) {
        // 太遠，靠近玩家
        movementDirection = directionToPlayer;
      } else {
        // 太近，遠離玩家
        movementDirection = -directionToPlayer;
      }

      // 添加一些隨機的左右移動，讓Boss看起來更不可預測
      if (_currentPhase >= 2) {
        // 第二階段開始才有橫向移動
        final perpendicular = Vector2(
          -directionToPlayer.y,
          directionToPlayer.x,
        );
        final randomFactor =
            math.sin(_specialAttackCooldown * 2) * 0.5; // -0.5到0.5之間擺動
        movementDirection += perpendicular * randomFactor;
        movementDirection.normalize();
      }

      // 執行移動
      _moveInDirection(
        movementDirection,
        dt,
        speedMultiplier: moveSpeedMultiplier,
      );
    } else {
      // 如果已經在理想距離，並且在第二或第三階段，做一些隨機的橫向移動
      if (_currentPhase >= 2) {
        final perpendicular = Vector2(
          -directionToPlayer.y,
          directionToPlayer.x,
        );
        final randomFactor = math.sin(_specialAttackCooldown * 2) * 0.5;
        _moveInDirection(
          perpendicular * randomFactor,
          dt,
          speedMultiplier: moveSpeedMultiplier * 0.7,
        );
      }
    }
  }

  // 朝指定方向移動
  void _moveInDirection(
    Vector2 direction,
    double dt, {
    double speedMultiplier = 1.0,
  }) {
    if (_isDead) return;

    // 計算移動向量
    final movement = direction * speed * speedMultiplier * dt;
    final nextPosition = position + movement;

    // 檢查是否與障礙物碰撞
    if (!mapComponent.checkObstacleCollision(
      nextPosition,
      Vector2.all(enemySize),
    )) {
      position = nextPosition;
    } else {
      // 嘗試分別在 X 和 Y 方向上移動（在牆邊滑動）
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

  // Boss的主要攻擊行為
  void _bossPrimaryAttack(double dt) {
    if (_target == null || _currentAttackCooldown > 0) return;

    final distanceToTarget = position.distanceTo(
      _target!.position + _target!.size / 2,
    );

    // Boss在更遠的距離就可以攻擊
    if (distanceToTarget <= attackRange * 1.2) {
      // 根據階段選擇不同的基本攻擊方式
      switch (_currentPhase) {
        case 1:
          // 第一階段：簡單的子彈攻擊
          _fireBossProjectile();
          break;
        case 2:
          // 第二階段：散射子彈攻擊
          _fireBossMultiProjectiles(3); // 發射3個子彈
          break;
        case 3:
          // 第三階段：更強的散射攻擊
          _fireBossMultiProjectiles(5); // 發射5個子彈
          break;
      }

      _currentAttackCooldown = attackCooldown;
    }
  }

  // 發射單個強力子彈
  void _fireBossProjectile() {
    if (_target == null) return;

    // 計算攻擊方向
    final attackDirection =
        (_target!.position + _target!.size / 2 - position)..normalize();

    // 計算子彈生成位置
    final bulletPosition = position + attackDirection * enemySize / 2;

    // 創建Boss子彈
    final bullet = BulletComponent(
      position: bulletPosition,
      direction: attackDirection,
      speed: 280, // 高速子彈
      damage: damage * 0.9, // 較高傷害
      range: 500, // 長距離
      color: color,
      size: enemySize * 0.3, // 較大子彈
      trailEffect: 'shine', // 使用發光尾跡效果
      isEnemyBullet: true, // 標記為敵人子彈
    );

    // 添加到遊戲世界
    parent?.add(bullet);

    // 添加發射特效
    parent?.add(
      ExplosionComponent(
        position: bulletPosition,
        size: Vector2.all(enemySize * 0.5),
        color: color,
      ),
    );
  }

  // 發射多個子彈（散射攻擊）
  void _fireBossMultiProjectiles(int count) {
    if (_target == null) return;

    // 計算基本攻擊方向
    final baseDirection =
        (_target!.position + _target!.size / 2 - position)..normalize();

    // 散射角度範圍
    final spreadAngle = 0.4; // 總共大約45度的散射範圍

    for (int i = 0; i < count; i++) {
      // 計算當前子彈的角度偏移
      final angleOffset = spreadAngle * (2 * i / (count - 1) - 1);
      final angle = math.atan2(baseDirection.y, baseDirection.x) + angleOffset;

      // 計算偏移後的方向
      final direction = Vector2(math.cos(angle), math.sin(angle));

      // 計算子彈生成位置
      final bulletPosition = position + direction * enemySize / 2;

      // 選擇尾跡效果類型
      String trailEffectType = 'none';
      if (i == count ~/ 2) {
        // 中間的子彈使用粒子尾跡
        trailEffectType = 'particles';
      } else if (i % 2 == 0) {
        // 偶數索引的子彈使用簡單尾跡
        trailEffectType = 'simple';
      }

      // 創建子彈
      final bullet = BulletComponent(
        position: bulletPosition,
        direction: direction,
        speed: 250 + 20 * i.toDouble(), // 子彈速度略有不同，確保使用double
        damage: damage * 0.7, // 每顆子彈傷害稍低
        range: 450,
        color: color,
        size: enemySize * 0.25,
        trailEffect: trailEffectType, // 使用適當的尾跡效果類型
        isEnemyBullet: true, // 標記為敵人子彈
      );

      // 添加到遊戲世界
      parent?.add(bullet);

      // 添加小型發射特效
      parent?.add(
        ExplosionComponent(
          position: bulletPosition,
          size: Vector2.all(enemySize * 0.3),
          color: color.withValues(alpha: 0.7),
        ),
      );
    }

    // 添加中心發射特效
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
    final healthPercentage = health / maxHealth;

    // 當生命值降低到特定百分比時，切換到下一階段
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

  // 進入新階段
  void _enterPhase(int phase) {
    _currentPhase = phase;
    debugPrint('Boss進入第$_currentPhase階段！');

    // Update sprite based on phase
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

    // 階段轉換特效
    _performPhaseTransitionEffect();

    // 根據階段調整屬性
    switch (phase) {
      case 2:
        // 第二階段：增加速度，減少攻擊冷卻
        _speedMultiplier *= 1.2;
        _attackCooldownMultiplier *= 0.8;
        // 短暫無敵
        _isPerformingSpecialMove = true;
        _specialMoveTimer = 3.0;
        break;
      case 3:
        // 第三階段：更激進的屬性提升
        _speedMultiplier *= 1.5;
        _attackCooldownMultiplier *= 0.6;
        _damageMultiplier *= 1.3;
        // 短暫無敵
        _isPerformingSpecialMove = true;
        _specialMoveTimer = 3.0;
        break;
    }
  }

  // 執行特殊攻擊
  void _performSpecialAttack() {
    if (_target == null) return;

    // 循環使用攻擊模式
    final attackPattern = attackPatterns[_currentAttackPattern];
    _currentAttackPattern = (_currentAttackPattern + 1) % attackPatterns.length;

    debugPrint('Boss使用特殊攻擊: $attackPattern');

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

    // 設置為特殊行為狀態，短暫內不執行其他動作
    _isPerformingSpecialMove = true;
    _specialMoveTimer = 2.0;
  }

  // 圓形彈幕攻擊 - 向四周發射多個子彈
  void _performCircularAttack() {
    const int bulletCount = 16; // 子彈數量
    const double radius = 20.0; // 發射半徑

    for (int i = 0; i < bulletCount; i++) {
      final angle = 2 * math.pi * i / bulletCount;
      final direction = Vector2(math.cos(angle), math.sin(angle));

      // 計算子彈起始位置（略微偏移）
      final bulletPosition = position + direction * radius;

      // 創建子彈
      final bullet = BulletComponent(
        position: bulletPosition,
        direction: direction,
        speed: 150, // 較慢的子彈，更易被躲避
        damage: damage * 0.6, // 每顆子彈傷害較低
        range: 300,
        color: color,
        size: enemySize * 0.2,
      );

      // 添加到遊戲世界
      parent?.add(bullet);

      // 添加發射特效
      parent?.add(
        ExplosionComponent(
          position: bulletPosition,
          size: Vector2.all(enemySize * 0.3),
          color: color.withValues(alpha: 0.5),
        ),
      );
    }

    // 添加中心爆發效果
    parent?.add(
      ExplosionComponent(
        position: position.clone(),
        size: Vector2.all(enemySize * 1.5),
        color: color,
      ),
    );
  }

  // 光束攻擊 - 瞄準玩家發射強力光束
  void _performBeamAttack() {
    if (_target == null) return;

    // 警告效果，預示攻擊方向
    final targetDirection = (_target!.position - position)..normalize();

    // 延遲執行實際攻擊
    add(
      TimerComponent(
        period: 1.0, // 1秒警告時間
        removeOnFinish: true,
        onTick: () {
          // 創建3個相鄰的光束，增加命中範圍
          for (double offset = -0.2; offset <= 0.2; offset += 0.2) {
            // 計算偏移方向
            final angle =
                math.atan2(targetDirection.y, targetDirection.x) + offset;
            final adjustedDirection = Vector2(math.cos(angle), math.sin(angle));

            // 創建大型光束子彈
            final beam = BeamComponent(
              position: position.clone(),
              direction: adjustedDirection,
              length: 600, // 非常長的光束
              width: 25,
              damage: damage * 1.5, // 高傷害
              duration: 0.8, // 光束持續時間
              color: color,
              isEnemyAttack: true, // 標記為敵人攻擊
            );

            parent?.add(beam);
          }
        },
      ),
    );

    // 添加警告線效果
    final warningLine = BeamWarningComponent(
      position: position.clone(),
      direction: targetDirection,
      length: 600,
      color: Colors.red.withValues(alpha: 0.5),
      duration: 1.0,
    );

    parent?.add(warningLine);
  }

  // 範圍攻擊 - 在地面創建持續傷害區域
  void _performAoeAttack() {
    if (_target == null) return;

    // 在玩家腳下創建AOE
    final targetPos = _target!.position.clone();

    // 先顯示警告區域
    final indicator = AoeIndicatorComponent(
      position: targetPos,
      radius: 120,
      duration: 1.5, // 警告持續1.5秒
      color: Colors.red.withValues(alpha: 0.3),
    );

    parent?.add(indicator);

    // 延遲後產生實際攻擊
    add(
      TimerComponent(
        period: 1.5,
        removeOnFinish: true,
        onTick: () {
          final aoe = AoeComponent(
            position: targetPos,
            radius: 120,
            damage: damage * 0.8,
            duration: 3.0,
            tickInterval: 0.5, // 每0.5秒造成一次傷害
            color: color.withValues(alpha: 0.6),
          );

          parent?.add(aoe);

          // 添加爆炸效果
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

  // 快速射擊 - 向玩家方向連續發射多個子彈
  void _performRapidFire() {
    if (_target == null) return;

    // 計算方向
    final targetDirection = (_target!.position - position)..normalize();

    // 設置連續射擊
    for (int i = 0; i < 5; i++) {
      add(
        TimerComponent(
          period: 0.15 * i, // 每0.15秒射擊一次
          removeOnFinish: true,
          onTick: () {
            // 略微隨機化射擊方向
            final randomAngle = (math.Random().nextDouble() - 0.5) * 0.3;
            final angle =
                math.atan2(targetDirection.y, targetDirection.x) + randomAngle;
            final adjustedDirection = Vector2(math.cos(angle), math.sin(angle));

            // 創建子彈
            final bullet = BulletComponent(
              position: position + adjustedDirection * enemySize / 2,
              direction: adjustedDirection,
              speed: 350, // 高速子彈
              damage: damage * 0.4,
              range: 400,
              color: color,
              size: enemySize * 0.15,
              isEnemyBullet: true, // 標記為敵人子彈
            );

            parent?.add(bullet);
          },
        ),
      );
    }
  }

  void _performTeleport() {
    if (_target == null) return;

    // 在玩家周圍隨機選擇一個位置
    final random = math.Random();
    final angle = random.nextDouble() * 2 * math.pi;
    final distance = 100 + random.nextDouble() * 100; // 距離玩家100-200單位

    final teleportDestination =
        _target!.position +
        Vector2(math.cos(angle) * distance, math.sin(angle) * distance);

    // 檢查目標位置是否有障礙物
    if (!mapComponent.checkObstacleCollision(
      teleportDestination,
      Vector2.all(enemySize),
    )) {
      // 添加瞬移前的視覺效果
      parent?.add(
        ExplosionComponent(
          position: position.clone(),
          size: Vector2.all(enemySize * 0.8),
          color: color.withValues(alpha: 0.7),
        ),
      );

      // 安全地瞬移
      position = teleportDestination;
      debugPrint('Boss 瞬移到新位置');

      // 添加瞬移後的視覺效果
      parent?.add(
        ExplosionComponent(
          position: position.clone(),
          size: Vector2.all(enemySize * 0.8),
          color: color.withValues(alpha: 0.7),
        ),
      );
    }
  }

  void _summonMinions() {
    // 決定召喚數量，基於當前階段
    final minionCount = _currentPhase;
    final random = math.Random();

    for (int i = 0; i < minionCount; i++) {
      // 在Boss周圍隨機位置召喚
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = 100 + random.nextDouble() * 50; // 距離Boss 100-150單位

      final summonPos =
          position +
          Vector2(math.cos(angle) * distance, math.sin(angle) * distance);

      // 檢查位置是否有障礙物
      if (!mapComponent.checkObstacleCollision(
        summonPos,
        Vector2.all(24), // 小怪體型
      )) {
        try {
          // 根據階段決定召喚的小怪類型
          EnemyType minionType;
          if (_currentPhase == 2) {
            minionType = EnemyType.melee; // 第二階段召喚近戰小怪
          } else {
            // 第三階段有機會召喚更強的小怪
            minionType =
                random.nextBool() ? EnemyType.ranged : EnemyType.hybrid;
          }

          // 創建小怪
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

          // 添加到遊戲世界
          parent?.add(minion);

          // 添加召喚特效
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
    if (value.isNaN) return 1.0; // 處理 NaN 情況
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

    // 添加光環效果
    parent?.add(
      BossAuraComponent(
        position: position.clone(),
        radius: enemySize * 1.5,
        color: color.withValues(alpha: 0.3),
      ),
    );
  }

  // 階段轉換特效
  void _performPhaseTransitionEffect() {
    // 添加視覺特效
    parent?.add(
      BossPhaseTransitionEffect(
        position: position.clone(),
        color: _currentPhase == 2 ? Colors.orange : Colors.red,
        size: Vector2.all(enemySize * 3),
      ),
    );

    // 短暫無敵並閃爍
    final flash = ColorEffect(
      Colors.white, // 遮色片顏色
      EffectController(
        duration: 0.1,
        reverseDuration: 0.1,
        infinite: true, // 無限循環，由計時器手動移除
      ),
      opacityFrom: 0.0, // 不透明度範圍
      opacityTo: 0.8,
    );

    if (_spriteComponent != null) {
      _spriteComponent!.add(flash);
    } else {
      // 沒有 sprite 時才退而求其次加在自己身上
      add(flash);
    }

    // ③ 三秒後結束閃爍並解除無敵
    add(
      TimerComponent(
        period: 3,
        removeOnFinish: true,
        onTick: () {
          flash.removeFromParent();
          _isPerformingSpecialMove = false; // 若要同時解除無敵
        },
      ),
    );
  }

  void takeDamage(double amount) {
    if (_isDead) return;

    // 如果處於階段轉換的特殊狀態，則完全無敵
    if (_isPerformingSpecialMove) {
      // 完全無敵，不受任何傷害
      return;
    }

    // 限制單次傷害最多為最大生命值的30%
    double maxDamageAllowed = maxHealth * 0.3;
    if (amount > maxDamageAllowed) {
      amount = maxDamageAllowed;
      debugPrint('傷害超過上限，已限制為最大生命值的30%: $maxDamageAllowed');
    }

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

  void _renderHealthBar(Canvas canvas) {
    const barHeight = 6.0; // 增加生命條高度
    final barWidth = enemySize * 1.5; // 增加生命條寬度
    final barX = -barWidth / 2;
    final barY = -enemySize / 2 - 15;

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

    // 階段指示器 - 在生命條上顯示階段轉換點
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
  }

  void _die() {
    _isDead = true;

    // 更大型的死亡特效
    for (int i = 0; i < 5; i++) {
      // 延遲添加多個爆炸，創造連鎖爆炸效果
      final delay = i * 0.2;
      add(
        TimerComponent(
          period: delay,
          removeOnFinish: true,
          onTick: () {
            // 隨機在Boss身體各處產生爆炸
            final random = math.Random();
            final offset = Vector2(
              (random.nextDouble() - 0.5) * enemySize,
              (random.nextDouble() - 0.5) * enemySize,
            );

            parent?.add(
              ExplosionComponent(
                position: position + offset,
                size: Vector2.all(enemySize * (1.0 + i * 0.3)),
                color: i % 2 == 0 ? color : Colors.orange,
              ),
            );
          },
        ),
      );
    }

    // 死亡時添加最終大爆炸
    add(
      TimerComponent(
        period: 1.0,
        removeOnFinish: true,
        onTick: () {
          parent?.add(
            BossDeathExplosionComponent(
              position: position.clone(),
              size: Vector2.all(enemySize * 5),
            ),
          );

          // 檢查是否在第三個地下城房間 (Boss房)
          final dungeonManager = game.dungeonManager;
          if (dungeonManager != null &&
              dungeonManager.currentRoomId == 'dungeon_room_3') {
            // 顯示通知
            game.showInteractionPrompt('一條神秘迴廊出現了...');

            // 延遲2秒創建通往秘密迴廊的傳送門
            add(
              TimerComponent(
                period: 2.0,
                removeOnFinish: true,
                onTick: () {
                  // 在適當位置創建傳送門
                  final secretPortal = PortalComponent(
                    position: Vector2(
                      dungeonManager.roomSize.x * 0.8,
                      dungeonManager.roomSize.y * 0.3,
                    ),
                    type: PortalType.dungeonRoom,
                    destinationId: 'secret_corridor', // 關聯到新的秘密走廊
                    portalName: '神秘迴廊',
                    color: Colors.purple.shade700, // 紫色調
                  );

                  // 添加到遊戲世界
                  parent?.add(secretPortal);

                  // 隱藏提示
                  game.hideInteractionPrompt();
                },
              ),
            );
          }

          // 最後移除自身
          removeFromParent();
        },
      ),
    );

    // 添加淡出效果
    add(OpacityEffect.fadeOut(EffectController(duration: 1.0)));

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

    // 如果碰到玩家的子彈，受到傷害
    if (other is BulletComponent && !other.isEnemyBullet) {
      takeDamage(other.damage);

      // 阻止子彈繼續飛行
      other.removeFromParent();
    }

    // 如果碰到玩家，直接造成傷害
    if (other is PlayerComponent && _currentAttackCooldown <= 0) {
      // 記錄碰撞前先輸出調試信息
      debugPrint('Boss 與玩家碰撞！嘗試造成 ${damage.toInt()} 點傷害');
      try {
        other.takeDamage(damage.toInt());
        debugPrint('Boss 成功對玩家造成傷害');
      } catch (e) {
        debugPrint('Boss 對玩家造成傷害時出錯: $e');
      }

      _currentAttackCooldown = attackCooldown;

      // 添加碰撞攻擊視覺效果
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
    // 添加調試日誌來追蹤透明度變更
    if (value < 0 || value > 1) {
      developer.log('警告: Boss設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }

    // 紀錄透明度變更
    if ((value - _opacity).abs() > 0.1) {
      developer.log('Boss透明度從 $_opacity 變更到 $value', name: 'OpacityDebug');
    }

    _opacity = value;
  }
}

/// Boss攻擊模式枚舉
enum BossAttackPattern {
  circularAttack, // 圓形彈幕
  beamAttack, // 光束攻擊
  aoeAttack, // 範圍攻擊
  rapidFire, // 快速射擊
  teleport, // 瞬移
}

/// 光束組件 - 用於Boss的光束攻擊
class BeamComponent extends PositionComponent
    with HasGameReference, CollisionCallbacks
    implements OpacityProvider {
  final Vector2 direction;
  final double length;
  final double width;
  final double damage;
  final Color color;
  double _lifespan;
  final double duration;
  final bool isEnemyAttack;

  BeamComponent({
    required Vector2 position,
    required this.direction,
    required this.length,
    required this.damage,
    required this.duration,
    this.width = 20,
    this.color = Colors.red,
    this.isEnemyAttack = false,
  }) : _lifespan = duration,
       super(
         position: position,
         size: Vector2(length, width),
         anchor: Anchor.centerLeft,
       ) {
    // 設置角度
    angle = direction.angleTo(Vector2(1, 0));
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加碰撞區域
    add(RectangleHitbox()..collisionType = CollisionType.passive);

    try {
      // 添加透明度效果前進行日誌記錄
      developer.log('光束組件添加淡出效果', name: 'OpacityDebug');

      // 添加視覺效果 - 由亮到暗的漸變
      add(
        OpacityEffect.fadeOut(
          EffectController(duration: duration),
          onComplete: () {
            developer.log('光束淡出完成，準備移除', name: 'OpacityDebug');
            removeFromParent();
          },
        ),
      );

      developer.log('光束組件淡出效果已添加', name: 'OpacityDebug');
    } catch (e) {
      developer.log('添加光束淡出效果時發生錯誤: $e', name: 'OpacityDebug');
      // 如果效果添加失敗，還是設置一個定時器來移除光束
      add(
        TimerComponent(
          period: duration,
          removeOnFinish: true,
          onTick: () => removeFromParent(),
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;

    // 繪製主體光束
    canvas.drawRect(Rect.fromLTWH(0, -width / 2, length, width), paint);

    // 繪製光束邊緣（更亮的部分）
    final edgePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(0, -width / 2, length, width), edgePaint);

    // 添加一些小粒子效果
    final random = math.Random();
    for (int i = 0; i < 10; i++) {
      final particleX = random.nextDouble() * length;
      final particleY = (random.nextDouble() - 0.5) * width;
      final particleSize = 1 + random.nextDouble() * 3;

      canvas.drawCircle(
        Offset(particleX, particleY),
        particleSize,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 只有敵人攻擊才會對玩家造成傷害
    if (isEnemyAttack && other is PlayerComponent) {
      debugPrint('光束攻擊命中玩家，嘗試造成 ${damage.toInt()} 點傷害');
      try {
        other.takeDamage(damage.toInt());
        debugPrint('光束成功對玩家造成傷害');
      } catch (e) {
        debugPrint('光束對玩家造成傷害時出錯: $e');
      }
    }
  }

  @override
  double get opacity => _opacity;
  double _opacity = 1.0;
  @override
  set opacity(double value) {
    // 添加調試日誌來追蹤透明度變更
    if (value < 0 || value > 1) {
      developer.log('警告: 光束設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }

    // 只記錄明顯的變化
    if ((value - _opacity).abs() > 0.1) {
      developer.log('光束透明度從 $_opacity 變更到 $value', name: 'OpacityDebug');
    }

    _opacity = value;
  }
}

/// 光束警告組件 - 在發射光束前顯示警告線
class BeamWarningComponent extends PositionComponent {
  final Vector2 direction;
  final double length;
  final Color color;
  double _lifespan;
  final double duration;

  BeamWarningComponent({
    required Vector2 position,
    required this.direction,
    required this.length,
    required this.color,
    required this.duration,
  }) : _lifespan = duration,
       super(
         position: position,
         size: Vector2(length, 10),
         anchor: Anchor.centerLeft,
       ) {
    // 設置角度
    angle = direction.angleTo(Vector2(1, 0));
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // 繪製虛線警告
    final dashPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // 閃爍效果
    final blink = (_lifespan * 10).toInt() % 2 == 0;
    if (blink) {
      dashPaint.color = color.withValues(alpha: 0.8);
    } else {
      dashPaint.color = color.withValues(alpha: 0.4);
    }

    // 繪製虛線
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double currentX = 0;

    while (currentX < length) {
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX + dashWidth, 0),
        dashPaint,
      );
      currentX += dashWidth + dashSpace;
    }
  }
}

/// 範圍攻擊指示器組件
class AoeIndicatorComponent extends PositionComponent {
  final double radius;
  final Color color;
  double _lifespan;
  final double duration;

  AoeIndicatorComponent({
    required Vector2 position,
    required this.radius,
    required this.color,
    required this.duration,
  }) : _lifespan = duration,
       super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  @override
  void update(double dt) {
    super.update(dt);

    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // 閃爍效果
    final blink = (_lifespan * 10).toInt() % 2 == 0;
    final opacity = blink ? 0.6 : 0.3;

    // 繪製外圈
    final outlinePaint =
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    canvas.drawCircle(Offset.zero, radius, outlinePaint);

    // 繪製填充區域
    final fillPaint =
        Paint()
          ..color = color.withValues(alpha: opacity * 0.3)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius, fillPaint);

    // 添加警告標記
    final warningPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    const warningSize = 20.0;

    // 繪製感嘆號
    canvas.drawLine(
      Offset(0, -warningSize / 2),
      Offset(0, warningSize / 2 - 5),
      warningPaint,
    );

    canvas.drawCircle(Offset(0, warningSize / 2 + 2), 2, warningPaint);
  }
}

/// 持續範圍傷害組件
class AoeComponent extends PositionComponent
    with HasGameReference, CollisionCallbacks
    implements OpacityProvider {
  final double radius;
  final double damage;
  final Color color;
  double _lifespan;
  final double duration;
  final double tickInterval;
  double _tickTimer = 0;
  final List<PlayerComponent> _affectedPlayers = [];

  AoeComponent({
    required Vector2 position,
    required this.radius,
    required this.damage,
    required this.duration,
    required this.tickInterval,
    required this.color,
  }) : _lifespan = duration,
       super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加圓形碰撞區域
    add(CircleHitbox(radius: radius)..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
      return;
    }

    // 傷害計時器
    _tickTimer -= dt;
    if (_tickTimer <= 0) {
      _tickTimer = tickInterval;

      // 對所有在範圍內的玩家造成傷害
      for (final player in _affectedPlayers) {
        try {
          debugPrint('AOE嘗試對玩家造成 ${damage.toInt()} 點傷害');
          player.takeDamage(damage.toInt());
          debugPrint('AOE成功對玩家造成傷害');
        } catch (e) {
          debugPrint('AOE對玩家造成傷害時出錯: $e');
        }
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 只對玩家造成傷害，忽略Boss和其他敵人
    if (other is PlayerComponent && !_affectedPlayers.contains(other)) {
      debugPrint('玩家進入AOE攻擊範圍');
      _affectedPlayers.add(other);

      // 立即造成第一次傷害
      try {
        debugPrint('AOE立即對玩家造成 ${damage.toInt()} 點傷害');
        other.takeDamage(damage.toInt());
      } catch (e) {
        debugPrint('AOE初始傷害失敗: $e');
      }

      // 重置計時器，準備下一次傷害
      _tickTimer = tickInterval;
    }
  }

  // OpacityProvider 介面實現
  @override
  double get opacity => _opacityValue;
  double _opacityValue = 1.0;
  @override
  set opacity(double value) {
    if (value < 0 || value > 1) {
      developer.log('警告: AOE設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }
    _opacityValue = value;
  }

  @override
  void render(Canvas canvas) {
    // 計算基於剩餘生命的不透明度
    final lifespanOpacity = (_lifespan / duration).clamp(0.1, 0.6);

    // 結合全局透明度設定
    final effectiveOpacity = lifespanOpacity * _opacityValue;

    // 繪製外圈
    final outlinePaint =
        Paint()
          ..color = color.withValues(alpha: effectiveOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawCircle(Offset.zero, radius, outlinePaint);

    // 繪製填充區域
    final fillPaint =
        Paint()
          ..color = color.withValues(alpha: effectiveOpacity * 0.7)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, radius, fillPaint);

    // 添加流動效果 - 小圓點
    final random = math.Random();
    final particlePaint =
        Paint()..color = Colors.white.withValues(alpha: effectiveOpacity);

    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * radius;
      final particleSize = 1 + random.nextDouble() * 2;

      final x = math.cos(angle) * distance;
      final y = math.sin(angle) * distance;

      canvas.drawCircle(Offset(x, y), particleSize, particlePaint);
    }
  }

  @override
  void onCollisionEnd(PositionComponent other) {
    super.onCollisionEnd(other);

    // 如果玩家離開範圍，從受影響列表移除
    if (other is PlayerComponent) {
      _affectedPlayers.remove(other);
    }
  }
}

/// Boss光環效果組件
class BossAuraComponent extends PositionComponent implements OpacityProvider {
  final double radius;
  final Color color;
  double _lifespan = 1.0;
  double _opacity = 1.0;

  BossAuraComponent({
    required Vector2 position,
    required this.radius,
    required this.color,
  }) : super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  @override
  void update(double dt) {
    super.update(dt);

    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // 繪製光環
    final paint =
        Paint()
          ..color = color.withValues(alpha: 0.6 * _lifespan * _opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * _lifespan;

    canvas.drawCircle(
      Offset.zero,
      radius * (1 + (1 - _lifespan) * 0.5), // 光環會慢慢擴大
      paint,
    );
  }

  // OpacityProvider 介面實現
  @override
  double get opacity => _opacity;
  @override
  set opacity(double value) {
    if (value < 0 || value > 1) {
      developer.log('警告: 光環效果設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }
    _opacity = value;
  }
}

/// Boss階段轉換效果
class BossPhaseTransitionEffect extends PositionComponent
    implements OpacityProvider {
  final Color color;
  double _lifespan = 1.5;
  double _scale = 0;
  final double _maxScale = 1.0;
  double _opacity = 1.0;

  BossPhaseTransitionEffect({
    required Vector2 position,
    required this.color,
    required Vector2 size,
  }) : super(position: position, size: size, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    // 更新生命週期
    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
      return;
    }

    // 擴散效果
    if (_lifespan > 0.75) {
      // 前半部分擴大
      _scale = (_maxScale * (1.5 - _lifespan) / 0.75).clamp(0.0, _maxScale);
    } else {
      // 後半部分保持最大並漸漸消失
      _scale = _maxScale;
    }
  }

  @override
  void render(Canvas canvas) {
    // 確保半徑至少為1，避免繪製尺寸為0的形狀
    final radius = math.max(size.x / 2 * _scale, 1.0);

    // 確保顏色的透明度在有效範圍內，並應用全局透明度設定
    final outlineOpacity = (0.8 * (_lifespan / 1.5) * _opacity).clamp(0.0, 1.0);
    final fillOpacity = (0.3 * (_lifespan / 1.5) * _opacity).clamp(0.0, 1.0);
    final rayOpacity = (0.5 * (_lifespan / 1.5) * _opacity).clamp(0.0, 1.0);

    // 外圈
    final outlinePaint =
        Paint()
          ..color = color.withValues(alpha: outlineOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5;

    // 內圈
    final fillPaint =
        Paint()
          ..color = color.withValues(alpha: fillOpacity)
          ..style = PaintingStyle.fill;

    // 繪製圓形
    canvas.drawCircle(Offset.zero, radius, fillPaint);
    canvas.drawCircle(Offset.zero, radius, outlinePaint);

    // 添加光線效果
    final rayCount = 8;
    final rayPaint =
        Paint()
          ..color = color.withValues(alpha: rayOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    for (int i = 0; i < rayCount; i++) {
      final angle = 2 * math.pi * i / rayCount;
      final innerRadius = radius * 0.8;
      final outerRadius = radius * 1.5;

      canvas.drawLine(
        Offset(math.cos(angle) * innerRadius, math.sin(angle) * innerRadius),
        Offset(math.cos(angle) * outerRadius, math.sin(angle) * outerRadius),
        rayPaint,
      );
    }
  }

  // OpacityProvider 介面實現
  @override
  double get opacity => _opacity;
  @override
  set opacity(double value) {
    if (value < 0 || value > 1) {
      developer.log('警告: 階段轉換效果設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }
    _opacity = value;
  }
}

/// Boss死亡爆炸效果
class BossDeathExplosionComponent extends PositionComponent
    implements OpacityProvider {
  final List<Color> colors = [Colors.red, Colors.orange, Colors.yellow];
  double _lifespan = 2.0;
  double _currentRadius = 0;
  final double _maxRadius;
  double _opacity = 1.0;

  BossDeathExplosionComponent({
    required Vector2 position,
    required Vector2 size,
  }) : _maxRadius = size.x / 2,
       super(position: position, size: size, anchor: Anchor.center);

  @override
  void update(double dt) {
    super.update(dt);

    // 更新生命週期
    _lifespan -= dt;
    if (_lifespan <= 0) {
      removeFromParent();
      return;
    }

    // 擴散效果
    if (_lifespan > 1.0) {
      // 前半部分快速擴大
      _currentRadius = _maxRadius * (1 - _lifespan / 2) * 2;
    } else {
      // 保持最大半徑並慢慢消失
      _currentRadius = _maxRadius;
    }
  }

  @override
  void render(Canvas canvas) {
    // 根據生命週期選擇顏色
    final colorIndex = ((_lifespan * 5) % colors.length).floor().clamp(
      0,
      colors.length - 1,
    );
    final color = colors[colorIndex];

    // 計算有效透明度，結合生命週期和全局透明度設定
    final effectiveOpacity = (_lifespan / 2) * _opacity;

    // 外圈
    final outlinePaint =
        Paint()
          ..color = color.withValues(alpha: 0.9 * effectiveOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8;

    // 內圈
    final fillPaint =
        Paint()
          ..color = color.withValues(alpha: 0.4 * effectiveOpacity)
          ..style = PaintingStyle.fill;

    // 繪製主爆炸圓
    canvas.drawCircle(Offset.zero, _currentRadius, fillPaint);
    canvas.drawCircle(Offset.zero, _currentRadius, outlinePaint);

    // 添加碎片效果
    final random = math.Random();
    final debrisPaint =
        Paint()..color = Colors.white.withValues(alpha: 0.7 * effectiveOpacity);

    for (int i = 0; i < 50; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = random.nextDouble() * _currentRadius;
      final debrisSize = 1 + random.nextDouble() * 4;

      canvas.drawCircle(
        Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        debrisSize,
        debrisPaint,
      );
    }

    // 添加光束效果
    final rayCount = 12;
    final rayPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6 * effectiveOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    for (int i = 0; i < rayCount; i++) {
      final angle = 2 * math.pi * i / rayCount;
      final rayLength = _currentRadius * 1.5;

      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle) * rayLength, math.sin(angle) * rayLength),
        rayPaint,
      );
    }
  }

  // OpacityProvider 介面實現
  @override
  double get opacity => _opacity;
  @override
  set opacity(double value) {
    if (value < 0 || value > 1) {
      developer.log('警告: 死亡爆炸效果設置無效的透明度值: $value', name: 'OpacityDebug');
      value = value.clamp(0, 1);
    }

    // 記錄顯著的透明度變化
    if ((value - _opacity).abs() > 0.1) {
      developer.log('死亡爆炸效果透明度從 $_opacity 變更到 $value', name: 'OpacityDebug');
    }

    _opacity = value;
  }
}

/// Boss視覺效果組件
class BossVisual extends Component {
  final double size;
  final Color color;
  final String bossName;
  final math.Random _random = math.Random();
  double _animationTimer = 0;

  BossVisual({required this.size, required this.color, required this.bossName});

  @override
  void update(double dt) {
    super.update(dt);
    _animationTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    // 繪製Boss的主體 - 使用高階的幾何形狀彰顯與一般敵人的不同
    final paint = Paint()..color = color;

    // 繪製Boss的主體 - 使用複雜圖形
    _drawBossBody(canvas, paint);

    // 繪製眼睛 - 更加明亮和威脅
    _drawBossEyes(canvas);

    // 繪製能量核心
    _drawEnergyCore(canvas);

    // 繪製Boss的護甲裝飾
    _drawArmorDetails(canvas, paint);
  }

  // 繪製Boss的主體
  void _drawBossBody(Canvas canvas, Paint paint) {
    // 八角星形狀的主體
    final path = Path();
    final numPoints = 16;
    final outerRadius = size / 2;
    final innerRadius = size / 2 * 0.6;

    for (int i = 0; i < numPoints; i++) {
      final radius = i % 2 == 0 ? outerRadius : innerRadius;
      final angle = 2 * math.pi * i / numPoints;
      final x = math.cos(angle) * radius;
      final y = math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // 填充主體
    canvas.drawPath(path, paint);

    // 添加輪廓
    final outlinePaint =
        Paint()
          ..color = color.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawPath(path, outlinePaint);
  }

  // 繪製Boss的眼睛
  void _drawBossEyes(Canvas canvas) {
    // 眼睛顏色 - 更加明亮且充滿威脅
    final eyeColor = Colors.red.shade700;
    final eyePaint = Paint()..color = eyeColor;

    // 繪製兩個大型眼睛
    canvas.drawCircle(Offset(-size / 5, -size / 4), size / 7, eyePaint);
    canvas.drawCircle(Offset(size / 5, -size / 4), size / 7, eyePaint);

    // 眼睛中心的高光
    final glowPaint = Paint()..color = Colors.red.shade300;

    // 脈動效果 - 讓高光隨時間變化
    final glowSize = size / 15 + math.sin(_animationTimer * 3) * size / 40;

    canvas.drawCircle(Offset(-size / 5, -size / 4), glowSize, glowPaint);
    canvas.drawCircle(Offset(size / 5, -size / 4), glowSize, glowPaint);

    // 繪製眼睛外圈
    final eyeOutlinePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(-size / 5, -size / 4), size / 7, eyeOutlinePaint);
    canvas.drawCircle(Offset(size / 5, -size / 4), size / 7, eyeOutlinePaint);
  }

  // 繪製能量核心
  void _drawEnergyCore(Canvas canvas) {
    // 中心能量核心 - 脈動發光效果
    final coreSize = size / 6 + math.sin(_animationTimer * 2) * size / 30;

    // 核心漸變效果
    final gradient = RadialGradient(
      colors: [
        Colors.white,
        color.withBlue(math.min(color.blue + 50, 255)),
        color,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromCircle(center: Offset.zero, radius: coreSize);

    final corePaint =
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, coreSize, corePaint);

    // 添加核心光暈
    final glowPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawCircle(Offset.zero, coreSize * 1.2, glowPaint);
  }

  // 繪製護甲細節
  void _drawArmorDetails(Canvas canvas, Paint basePaint) {
    // 暗色調護甲
    final armorPaint =
        Paint()
          ..color = color.withRed((color.red - 30).clamp(0, 255))
          ..style = PaintingStyle.fill;

    // 護甲紋理 - 放射狀線條
    final linePaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // 繪製護甲板塊
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;

      final plateOffset = size / 4;
      final plateWidth = size / 6;
      final plateHeight = size / 3;

      final platePath = Path();
      platePath.moveTo(
        math.cos(angle) * plateOffset,
        math.sin(angle) * plateOffset,
      );
      platePath.lineTo(
        math.cos(angle) * (plateOffset + plateWidth),
        math.sin(angle) * (plateOffset + plateWidth),
      );
      platePath.lineTo(
        math.cos(angle) * (plateOffset + plateWidth) +
            math.cos(angle + math.pi / 2) * plateHeight / 2,
        math.sin(angle) * (plateOffset + plateWidth) +
            math.sin(angle + math.pi / 2) * plateHeight / 2,
      );
      platePath.lineTo(
        math.cos(angle) * plateOffset +
            math.cos(angle + math.pi / 2) * plateHeight / 2,
        math.sin(angle) * plateOffset +
            math.sin(angle + math.pi / 2) * plateHeight / 2,
      );
      platePath.close();

      canvas.drawPath(platePath, armorPaint);
      canvas.drawPath(platePath, linePaint);
    }

    // 添加一些隨機裝飾點 - 小螺栓或能量點
    final detailPaint = Paint()..color = Colors.white.withValues(alpha: 0.6);
    for (int i = 0; i < 8; i++) {
      final angle = 2 * math.pi * i / 8 + math.pi / 8;
      final distance = size * 0.35;
      final detailSize = size * 0.02;

      canvas.drawCircle(
        Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        detailSize,
        detailPaint,
      );
    }
  }
}
