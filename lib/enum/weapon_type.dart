enum WeaponType {
  sword('劍', 1.0, 0), // 近戰

  // 遠程武器
  pistol('手槍', 0.5, 400), // 中等傷害、中等冷卻、中等速度
  machineGun('機關槍', 0.1, 500), // 低傷害、極低冷卻、高速度
  shotgun('霰彈槍', 0.8, 300), // 高傷害（範圍）、高冷卻、低速度
  sniper('狙擊槍', 1.5, 800); // 極高傷害、極高冷卻、極高速度

  final String displayName;
  final double defaultCooldown; // 預設冷卻時間(秒)
  final double defaultBulletSpeed; // 預設子彈速度

  const WeaponType(
    this.displayName,
    this.defaultCooldown,
    this.defaultBulletSpeed,
  );

  /// 判斷是否為近戰武器
  bool get isMelee => this == WeaponType.sword;

  /// 判斷是否為遠程武器
  bool get isRanged => !isMelee;
}
