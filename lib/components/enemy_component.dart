// 敵人元件，會主動檢測並攻擊玩家
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'bullet_component.dart';
import 'player_component.dart';
import 'map_component.dart';
import '../main.dart'; // 添加對 main.dart 的引用，其中包含 NightAndRainGame 類

/// 敵人類型列舉
enum EnemyType {
  // 近戰敵人，會追蹤玩家並近距離攻擊
  melee,
  // 遠程敵人，會保持距離射擊玩家
  ranged,
  // 混合型敵人，有多種攻擊方式
  hybrid,
  // 獵手型敵人，會持續追蹤玩家，即使看不到也能找到
  hunter,
  // Boss型敵人，擁有特殊技能和多階段戰鬥機制
  boss,
}

/// 基礎敵人元件
class EnemyComponent extends PositionComponent
    with HasGameReference<NightAndRainGame>, CollisionCallbacks, HasPaint {
  // 敵人基本屬性
  final EnemyType type;
  final double maxHealth;
  double health;
  final double _baseDamage; // 重命名為基礎傷害
  final double _baseSpeed; // 重命名為基礎速度
  double _speedMultiplier = 1.0; // 添加速度倍增器
  double _damageMultiplier = 1.0; // 添加傷害倍增器

  // 攻擊相關屬性
  final double attackRange; // 攻擊範圍
  final double detectionRange; // 偵測範圍
  final double _baseAttackCooldown; // 重命名為基礎攻擊冷卻時間
  double _attackCooldownMultiplier = 1.0; // 添加攻擊冷卻倍增器
  double _currentAttackCooldown = 0; // 當前攻擊冷卻計時器

  // 計算後的屬性
  double get speed => _baseSpeed * _speedMultiplier;
  double get damage => _baseDamage * _damageMultiplier;
  double get attackCooldown => _baseAttackCooldown * _attackCooldownMultiplier;

  // 視覺樣式
  final Color color;
  // 存儲敵人視覺大小，但不覆蓋 PositionComponent 的 size 屬性
  final double enemySize;

  // 行為控制
  bool _isChasing = false; // 是否正在追踪玩家
  bool _isDead = false; // 是否已死亡
  PlayerComponent? _target; // 追踪目標
  final MapComponent mapComponent; // 地圖元件，用於碰撞檢測

  // 隨機數生成器，用於小幅度隨機移動
  final math.Random _random = math.Random();
  Vector2 _randomDirection = Vector2.zero();
  double _randomDirectionTimer = 0;

  // 玩家最後看到的位置，用於跟隨
  Vector2 _lastKnownPlayerPosition = Vector2.zero();

  // 生命條顯示相關
  bool _showHealthBar = false;
  double _healthBarDisplayTimer = 0;
  static const double _healthBarDisplayDuration = 3.0; // 顯示生命條的持續時間

  EnemyComponent({
    required Vector2 position,
    required this.type,
    required this.mapComponent,
    this.maxHealth = 100,
    double speed = 60,
    double damage = 10,
    this.attackRange = 30,
    this.detectionRange = 200,
    double attackCooldown = 1.0,
    this.color = Colors.red,
    this.enemySize = 20,
  }) : health = maxHealth,
       _baseSpeed = speed,
       _baseDamage = damage,
       _baseAttackCooldown = attackCooldown,
       super(
         position: position,
         size: Vector2.all(enemySize),
         anchor: Anchor.center,
       );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 添加碰撞形狀
    add(CircleHitbox()..collisionType = CollisionType.active);

    // 添加敵人視覺效果
    add(EnemyVisual(size: enemySize, color: color, type: type));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDead) return;

    // 更新攻擊冷卻
    if (_currentAttackCooldown > 0) {
      _currentAttackCooldown -= dt;
    }

    // 更新生命條顯示計時器
    if (_showHealthBar) {
      _healthBarDisplayTimer -= dt;
      if (_healthBarDisplayTimer <= 0) {
        _showHealthBar = false;
      }
    }

    // 尋找並追蹤玩家
    _findAndChasePlayer(dt);

    // 攻擊邏輯
    _handleAttack(dt);

    // 隨機移動邏輯（在非追蹤狀態時）
    _handleRandomMovement(dt);
  }

  /// 尋找並追蹤玩家
  void _findAndChasePlayer(double dt) {
    // 針對獵手型敵人使用直接方法獲取玩家
    if (type == EnemyType.hunter) {
      // 直接從遊戲實例獲取玩家
      final player = (game as NightAndRainGame).getPlayer();

      _isChasing = true;
      _target = player;

      // 玩家的中心位置
      final playerCenter = player.position + player.size / 2;
      final enemyCenter = position + size / 2;

      // 更新最後已知玩家位置
      _lastKnownPlayerPosition = playerCenter.clone();

      // 計算距離和方向
      final distanceToPlayer = enemyCenter.distanceTo(playerCenter);
      final directionToPlayer = (playerCenter - enemyCenter)..normalize();

      // 獵手型敵人有更大的追蹤速度加成
      double hunterSpeedMultiplier = 1.3; // 速度提高30%

      // 只有在超出攻擊範圍時才移動，否則準備攻擊
      if (distanceToPlayer > attackRange) {
        _moveInDirection(
          directionToPlayer,
          dt,
          speedMultiplier: hunterSpeedMultiplier,
        );
      } else {
        // 在攻擊範圍內，準備攻擊
        debugPrint('獵手敵人在攻擊範圍內，準備攻擊');
      }
      return; // 獵手型敵人處理完畢，直接返回
    }

    // 其他類型敵人的舊邏輯
    // 獲取世界中的所有玩家
    final players = game.children.whereType<PlayerComponent>();
    if (players.isEmpty) return;

    // 簡單起見，只追蹤第一個玩家
    final player = players.first;

    // 計算與玩家的距離（使用中心點而不是角落）
    final playerCenter = player.position + player.size / 2;
    final enemyCenter = position + size / 2;
    final distanceToPlayer = enemyCenter.distanceTo(playerCenter);

    // 玩家在檢測範圍內，開始追蹤
    if (distanceToPlayer <= detectionRange) {
      _isChasing = true;
      _target = player;

      // 更新最後已知玩家位置
      _lastKnownPlayerPosition = playerCenter.clone();

      // 計算朝向玩家的方向
      final directionToPlayer = (playerCenter - enemyCenter)..normalize();

      // 根據敵人類型決定行為
      if (type == EnemyType.ranged && distanceToPlayer < attackRange * 0.7) {
        // 遠程敵人會保持距離
        final retreatDirection = -directionToPlayer;
        _moveInDirection(retreatDirection, dt);
      } else if (distanceToPlayer > attackRange) {
        // 追蹤玩家 - 對於混合型敵人，使其更積極地追蹤
        double chaseSpeedMultiplier = 1.0;
        if (type == EnemyType.hybrid) {
          chaseSpeedMultiplier = 1.2; // 混合型敵人移動速度提高20%
        }
        _moveInDirection(
          directionToPlayer,
          dt,
          speedMultiplier: chaseSpeedMultiplier,
        );
      } else {
        // 在攻擊範圍內，保持位置
        debugPrint('敵人在攻擊範圍內，停止移動並準備攻擊');
      }
    } else {
      // 如果玩家不在檢測範圍內，但我們之前正在追蹤，保持較長時間的"記憶"
      if (_isChasing && _target != null) {
        // 漸進式降低追蹤意願，而不是立即停止
        // 計算新方向 - 朝向最後已知的玩家位置
        final directionToLastKnown =
            (_lastKnownPlayerPosition - enemyCenter)..normalize();

        // 檢查是否仍然需要移動
        if (enemyCenter.distanceTo(_lastKnownPlayerPosition) > 10) {
          _moveInDirection(directionToLastKnown, dt);
          return; // 保持追蹤狀態
        }
      }

      // 如果到達最後已知位置或從未追蹤過，則進入隨機移動狀態
      _isChasing = false;
      _target = null;
    }
  }

  /// 處理攻擊邏輯
  void _handleAttack(double dt) {
    if (_target == null || _currentAttackCooldown > 0) return;

    final distanceToTarget = position.distanceTo(
      _target!.position + _target!.size / 2,
    );

    // 如果目標在攻擊範圍內，進行攻擊
    if (distanceToTarget <= attackRange) {
      _attack();
      _currentAttackCooldown = attackCooldown;
    }
  }

  /// 攻擊實現
  void _attack() {
    if (_target == null) return;

    // 計算攻擊方向
    final attackDirection =
        (_target!.position + _target!.size / 2 - position)..normalize();

    // 根據敵人類型執行不同攻擊
    switch (type) {
      case EnemyType.melee:
        // 近戰攻擊：直接對玩家造成傷害
        _target!.takeDamage(damage.toInt());

        // 添加攻擊視覺效果
        _showMeleeAttackEffect(attackDirection);
        break;

      case EnemyType.ranged:
        // 遠程攻擊：發射子彈
        _fireProjectile(attackDirection);
        break;

      case EnemyType.hybrid:
        // 混合型：根據距離選擇攻擊方式
        final distanceToTarget = position.distanceTo(
          _target!.position + _target!.size / 2,
        );

        if (distanceToTarget < attackRange * 0.5) {
          // 近距離使用近戰攻擊
          _target!.takeDamage(damage.toInt());
          _showMeleeAttackEffect(attackDirection);
        } else {
          // 遠距離發射子彈
          _fireProjectile(attackDirection);
        }
        break;

      case EnemyType.hunter:
        // 獵手型敵人：更強力的近戰攻擊
        // 造成更高的傷害
        _target!.takeDamage((damage * 1.2).toInt());

        // 添加特殊的攻擊視覺效果 - 獵手攻擊更兇猛
        _showMeleeAttackEffect(attackDirection);

        // 添加額外的視覺效果，表示獵手的特殊攻擊
        final secondaryEffect = MeleeAttackEffect(
          position: position + attackDirection * enemySize * 1.2,
          direction: attackDirection,
          size: enemySize * 1.0, // 稍大的效果
          color: Colors.red.shade700, // 紅色攻擊效果
        );
        parent?.add(secondaryEffect);
        break;
      case EnemyType.boss:
        // Boss型敵人：使用特殊攻擊
        break;
    }

    debugPrint('敵人 ${identityHashCode(this)} 攻擊玩家');
  }

  /// 顯示近戰攻擊效果
  void _showMeleeAttackEffect(Vector2 direction) {
    final attackEffect = MeleeAttackEffect(
      position: position + direction * enemySize,
      direction: direction,
      size: enemySize * 0.8,
      color: color,
    );

    parent?.add(attackEffect);
  }

  /// 發射子彈
  void _fireProjectile(Vector2 direction) {
    // 計算子彈生成位置
    final bulletPosition = position + direction * enemySize / 2;

    // 創建敵人子彈
    final bullet = BulletComponent(
      position: bulletPosition,
      direction: direction,
      speed: 200, // 子彈速度
      damage: damage * 0.8, // 子彈傷害
      range: 300, // 子彈射程
      color: color.withOpacity(0.8), // 子彈顏色
      size: enemySize * 0.25, // 子彈大小
    );

    // 添加到遊戲世界
    parent?.add(bullet);
  }

  /// 處理敵人的隨機移動
  void _handleRandomMovement(double dt) {
    if (_isChasing) return; // 如果正在追踪玩家，則不執行隨機移動

    // 每隔一段時間更新隨機方向
    _randomDirectionTimer -= dt;
    if (_randomDirectionTimer <= 0) {
      _randomDirection = Vector2(
        _random.nextDouble() * 2 - 1,
        _random.nextDouble() * 2 - 1,
      )..normalize();

      _randomDirectionTimer = 2 + _random.nextDouble() * 3; // 2-5秒後更新方向
    }

    // 隨機移動
    _moveInDirection(_randomDirection, dt);
  }

  /// 朝指定方向移動
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

  /// 受到傷害
  void takeDamage(double amount) {
    if (_isDead) return;

    health -= amount;

    // 顯示生命條
    _showHealthBar = true;
    _healthBarDisplayTimer = _healthBarDisplayDuration;

    debugPrint('敵人 ${identityHashCode(this)} 受到 $amount 點傷害，剩餘生命: $health');

    // 檢查是否死亡
    if (health <= 0) {
      health = 0;
      _die();
    }
  }

  /// 敵人死亡
  void _die() {
    _isDead = true;

    // 添加死亡效果
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.5),
        onComplete: () => removeFromParent(),
      ),
    );

    // 添加爆炸效果
    parent?.add(
      ExplosionComponent(
        position: position.clone(),
        size: Vector2.all(enemySize * 1.5),
        color: color,
      ),
    );

    debugPrint('敵人 ${identityHashCode(this)} 死亡');
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 渲染生命條
    if (_showHealthBar) {
      _renderHealthBar(canvas);
    }
  }

  /// 渲染生命條
  void _renderHealthBar(Canvas canvas) {
    const barHeight = 4.0;
    final barWidth = enemySize;
    final barX = -enemySize / 2;
    final barY = -enemySize / 2 - 10;

    // 背景
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()..color = Colors.grey.withOpacity(0.7),
    );

    // 生命值
    final healthRatio = health / maxHealth;
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth * healthRatio, barHeight),
      Paint()..color = Colors.green.withOpacity(0.8),
    );

    // 邊框
    canvas.drawRect(
      Rect.fromLTWH(barX, barY, barWidth, barHeight),
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    // 如果碰到玩家的子彈，受到傷害
    if (other is BulletComponent) {
      takeDamage(other.damage);
    }

    // 如果碰到玩家，直接造成傷害
    if (other is PlayerComponent && _currentAttackCooldown <= 0) {
      other.takeDamage(damage.toInt());
      _currentAttackCooldown = attackCooldown;
    }
  }
}

/// 敵人視覺效果組件
class EnemyVisual extends Component {
  final double size;
  final Color color;
  final EnemyType type;

  EnemyVisual({required this.size, required this.color, required this.type});

  @override
  void render(Canvas canvas) {
    // 繪製敵人的主體
    final paint = Paint()..color = color;

    // 根據敵人類型繪製不同外觀
    switch (type) {
      case EnemyType.melee:
        // 近戰敵人：方形
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: size, height: size),
          paint,
        );

        // 畫眼睛
        final eyePaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(-size / 5, -size / 5), size / 8, eyePaint);
        canvas.drawCircle(Offset(size / 5, -size / 5), size / 8, eyePaint);

        break;

      case EnemyType.ranged:
        // 遠程敵人：圓形
        canvas.drawCircle(Offset.zero, size / 2, paint);

        // 畫眼睛
        final eyePaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(-size / 5, -size / 6), size / 10, eyePaint);
        canvas.drawCircle(Offset(size / 5, -size / 6), size / 10, eyePaint);

        break;

      case EnemyType.hybrid:
        // 混合型敵人：多邊形
        final path = Path();
        const sides = 6; // 六邊形
        final radius = size / 2;

        for (int i = 0; i < sides; i++) {
          final angle = 2 * math.pi * i / sides;
          final x = math.cos(angle) * radius;
          final y = math.sin(angle) * radius;

          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }

        path.close();
        canvas.drawPath(path, paint);

        // 畫眼睛
        final eyePaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(-size / 6, -size / 6), size / 12, eyePaint);
        canvas.drawCircle(Offset(size / 6, -size / 6), size / 12, eyePaint);

        break;

      case EnemyType.hunter:
        // 獵手型敵人：鑽石形狀 + 尖角
        // 畫主體（鑽石形）
        final path = Path();
        path.moveTo(0, -size / 2); // 頂部
        path.lineTo(size / 2, 0); // 右側
        path.lineTo(0, size / 2); // 底部
        path.lineTo(-size / 2, 0); // 左側
        path.close();

        // 填充主體
        canvas.drawPath(path, paint);

        // 畫尖角（使其看起來更具攻擊性）
        final spikePaint =
            Paint()
              ..color = color.withRed((color.red + 50).clamp(0, 255))
              ..style = PaintingStyle.fill;

        // 頂部尖角
        final topSpike =
            Path()
              ..moveTo(-size / 6, -size / 2)
              ..lineTo(0, -size * 0.8)
              ..lineTo(size / 6, -size / 2)
              ..close();
        canvas.drawPath(topSpike, spikePaint);

        // 右側尖角
        final rightSpike =
            Path()
              ..moveTo(size / 2, -size / 6)
              ..lineTo(size * 0.8, 0)
              ..lineTo(size / 2, size / 6)
              ..close();
        canvas.drawPath(rightSpike, spikePaint);

        // 底部尖角
        final bottomSpike =
            Path()
              ..moveTo(-size / 6, size / 2)
              ..lineTo(0, size * 0.8)
              ..lineTo(size / 6, size / 2)
              ..close();
        canvas.drawPath(bottomSpike, spikePaint);

        // 左側尖角
        final leftSpike =
            Path()
              ..moveTo(-size / 2, -size / 6)
              ..lineTo(-size * 0.8, 0)
              ..lineTo(-size / 2, size / 6)
              ..close();
        canvas.drawPath(leftSpike, spikePaint);

        // 畫紅色眼睛，讓獵手看起來更加危險
        final eyePaint = Paint()..color = Colors.red.shade700;
        canvas.drawCircle(Offset(-size / 5, -size / 6), size / 10, eyePaint);
        canvas.drawCircle(Offset(size / 5, -size / 6), size / 10, eyePaint);

        // 紅色眼睛的高光
        final highlightPaint = Paint()..color = Colors.red.shade300;
        canvas.drawCircle(
          Offset(-size / 5, -size / 6),
          size / 25,
          highlightPaint,
        );
        canvas.drawCircle(
          Offset(size / 5, -size / 6),
          size / 25,
          highlightPaint,
        );

        break;
      case EnemyType.boss:
        // Boss型敵人：更複雜的外觀
        final path = Path();
        path.moveTo(0, -size / 2); // 頂部
        path.lineTo(size / 2, 0); // 右側
        path.lineTo(0, size / 2); // 底部
        path.lineTo(-size / 2, 0); // 左側
        path.close();

        // 填充主體
        canvas.drawPath(path, paint);

        // 畫尖角（使其看起來更具攻擊性）
        final spikePaint =
            Paint()
              ..color = color.withRed((color.red + 50).clamp(0, 255))
              ..style = PaintingStyle.fill;

        // 頂部尖角
        final topSpike =
            Path()
              ..moveTo(-size / 6, -size / 2)
              ..lineTo(0, -size * 0.8)
              ..lineTo(size / 6, -size / 2)
              ..close();
        canvas.drawPath(topSpike, spikePaint);

        // 右側尖角
        final rightSpike =
            Path()
              ..moveTo(size / 2, -size / 6)
              ..lineTo(size * 0.8, 0)
              ..lineTo(size / 2, size / 6)
              ..close();
        canvas.drawPath(rightSpike, spikePaint);

        // 底部尖角
        final bottomSpike =
            Path()
              ..moveTo(-size / 6, size / 2)
              ..lineTo(0, size * 0.8)
              ..lineTo(size / 6, size / 2)
              ..close();
        canvas.drawPath(bottomSpike, spikePaint);

        // 左側尖角
        final leftSpike =
            Path()
              ..moveTo(-size / 2, -size / 6)
              ..lineTo(-size * 0.8, 0)
              ..lineTo(-size / 2, size / 6)
              ..close();
        canvas.drawPath(leftSpike, spikePaint);

        // 畫紅色眼睛，讓Boss看起來更加危險
        final eyePaint = Paint()..color = Colors.red.shade700;
        canvas.drawCircle(Offset(-size / 5, -size / 6), size / 10, eyePaint);
        canvas.drawCircle(Offset(size / 5, -size / 6), size / 10, eyePaint);

        // 紅色眼睛的高光
        final highlightPaint = Paint()..color = Colors.red.shade300;
        canvas.drawCircle(
          Offset(-size / 5, -size / 6),
          size / 25,
          highlightPaint,
        );
        canvas.drawCircle(
          Offset(size / 5, -size / 6),
          size / 25,
          highlightPaint,
        );

        break;
    }
  }
}

/// 近戰攻擊效果組件
class MeleeAttackEffect extends PositionComponent with HasPaint {
  final Vector2 direction;
  final double effectSize; // 重命名為 effectSize 以避免與 PositionComponent 的 size 屬性衝突
  final Color color;
  double _lifespan = 0.3;

  MeleeAttackEffect({
    required Vector2 position,
    required this.direction,
    required double size, // 參數仍然命名為 size 以保持 API 兼容性
    required this.color,
  }) : effectSize = size, // 將參數 size 賦值給 effectSize
       super(
         position: position,
         anchor: Anchor.center,
         size: Vector2.all(size), // 設置 PositionComponent 的 size 屬性
       ) {
    // 設置初始顏色和不透明度
    paint.color = color.withOpacity(0.7);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 設置旋轉角度
    angle = direction.angleTo(Vector2(1, 0));

    // 添加淡出效果
    add(
      OpacityEffect.fadeOut(
        EffectController(duration: _lifespan),
        onComplete: () => removeFromParent(),
      ),
    );
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
    // 繪製劍氣/攻擊效果
    final paint = Paint()..color = color.withOpacity(0.7);

    final path =
        Path()
          ..moveTo(0, -effectSize / 4)
          ..lineTo(effectSize, 0)
          ..lineTo(0, effectSize / 4)
          ..close();

    canvas.drawPath(path, paint);
  }
}

/// 爆炸效果組件
class ExplosionComponent extends PositionComponent with HasPaint {
  final Color color;
  double _currentRadius = 0;
  final double _maxRadius;
  final double _duration = 0.5;
  double _elapsedTime = 0;

  ExplosionComponent({
    required Vector2 position,
    required Vector2 size,
    required this.color,
  }) : _maxRadius = size.x / 2,
       super(position: position, anchor: Anchor.center) {
    // 初始化 paint
    paint.color = color.withOpacity(0.7);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 3;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsedTime += dt;
    _currentRadius = (_elapsedTime / _duration) * _maxRadius;

    if (_elapsedTime >= _duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    // 確保透明度值在有效範圍內（0.0 到 1.0）
    final opacity = (1.0 - (_elapsedTime / _duration)).clamp(0.0, 1.0);

    // 外圈
    canvas.drawCircle(
      Offset.zero,
      _currentRadius,
      paint..color = color.withOpacity(opacity * 0.7),
    );

    // 內圈
    canvas.drawCircle(
      Offset.zero,
      _currentRadius * 0.7,
      Paint()
        ..color = color.withOpacity(opacity * 0.5)
        ..style = PaintingStyle.fill,
    );
  }
}
