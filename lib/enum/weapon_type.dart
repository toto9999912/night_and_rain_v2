enum WeaponType {
  sword('劍'), // 近戰

  // 遠程武器
  pistol('手槍'), // 中等傷害、中等冷卻
  machineGun('機關槍'), // 低傷害、極低冷卻
  shotgun('霰彈槍'), // 高傷害（範圍）、高冷卻
  sniper('狙擊槍'); // 極高傷害、極高冷卻

  final String displayName;

  const WeaponType(this.displayName);

  /// 判斷是否為近戰武器
  bool get isMelee => this == WeaponType.sword;

  /// 判斷是否為遠程武器
  bool get isRanged => !isMelee;
}
