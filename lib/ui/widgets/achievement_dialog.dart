import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 旅程成就對話框 - 顯示玩家獲得的成就
class AchievementDialog extends StatefulWidget {
  const AchievementDialog({super.key});

  @override
  State<AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<AchievementDialog>
    with SingleTickerProviderStateMixin {
  // 目前選中的成就類別
  String _selectedCategory = '全部';

  // 目前選中的成就
  Achievement? _selectedAchievement;

  // 動畫控制器
  late AnimationController _animationController;
  late Animation<double> _animation;

  // 成就類別列表
  final List<String> _categories = ['全部', '冒險', '戰鬥', '收集', '隱藏'];

  // 模擬成就數據
  final List<Achievement> _achievements = [
    Achievement(
      id: 'first_steps',
      title: '打開遊戲',
      description: '太好了，你成功打開遊戲了！',
      icon: FontAwesomeIcons.personWalking,
      category: '冒險',
      isUnlocked: true,
      progress: 1.0,
      reward: '米蟲金幣 x 100',
      unlockDate: DateTime(2025, 05, 10),
    ),
    Achievement(
      id: 'treasure_hunter',
      title: '獲得第一個夥伴',
      description: '他才不是寵物！他是你冒險的好夥伴',
      icon: FontAwesomeIcons.handshake,
      category: '冒險',
      isUnlocked: true,
      progress: 0.0,
      reward: '米蟲金幣 x 100',
    ),
    Achievement(
      id: 'night_explorer',
      title: '牛刀小逝',
      description: '試試就真的逝世了',
      icon: FontAwesomeIcons.vials,
      category: '冒險',
      isUnlocked: true,
      progress: 0.0,
      reward: '夜的睿智抄本殘頁 x 5',
    ),
    Achievement(
      id: 'monster_slayer',
      title: '甲級貧戶',
      description: '你辦到了！你成功餓死了你的夥伴。而地下有知的他們十分後悔當初跟隨你',
      icon: FontAwesomeIcons.ghost,
      category: '戰鬥',
      isUnlocked: true,
      progress: 0.0,
      reward: '貧苦人家證明 x 1',
    ),
    Achievement(
      id: 'boss_challenge',
      title: '挑戰者',
      description: '擊敗第一個Boss',
      icon: FontAwesomeIcons.crown,
      category: '戰鬥',
      isUnlocked: true,
      progress: 1.0,
      reward: '銅牛武器藍圖',
    ),
    Achievement(
      id: 'legendary_warrior',
      title: '重來一次，還是選妳！',
      description: '次次的冒險讓你們深刻了解到彼此的重要，也許並非對方不可，但就覺得生活少了什麼',
      icon: FontAwesomeIcons.shield,
      category: '戰鬥',
      isUnlocked: true,
      progress: 0.0,
      reward: '銅牛武器藍圖',
    ),
    Achievement(
      id: 'collector',
      title: '歌神？歌癡！',
      description: '你成功偷錄下來夥伴－夜唱的歌，他會恨你一輩子',
      icon: FontAwesomeIcons.music,
      category: '收集',
      isUnlocked: true,
      progress: 0.0,
      reward: '米蟲金幣 x 100',
    ),
    Achievement(
      id: 'material_master',
      title: '夜不在深，有燈則明',
      description: '你居然在遊戲中實踐了發光體！\n他一定上輩子造孽，否則怎麼會認識妳這個大冤種',
      icon: FontAwesomeIcons.lightbulb,
      category: '收集',
      isUnlocked: true,
      progress: 0.0,
      reward: '夜 - 發光體造型',
    ),
    Achievement(
      id: 'birthday_special',
      title: '解謎高手',
      description: '成功破譯藏鏡人的謎題',
      icon: FontAwesomeIcons.cakeCandles,
      category: '隱藏',
      isUnlocked: true,
      progress: 0.0,
      reward: '限定稱號：福爾摩雨',
    ),
  ];

  // 根據當前類別篩選後的成就列表
  List<Achievement> get _filteredAchievements {
    if (_selectedCategory == '全部') {
      return _achievements;
    } else {
      return _achievements
          .where((a) => a.category == _selectedCategory)
          .toList();
    }
  }

  @override
  void initState() {
    super.initState();

    // 初始化動畫控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    // 啟動動畫
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(_animation),
          child: Container(
            width: 800,
            height: 600,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F35), // 深色背景
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
              border: Border.all(
                color: const Color(0xFF6BC8E2).withValues(alpha: 0.7), // 冰晶藍色邊框
                width: 2,
              ),
            ),
            child: Column(children: [_buildHeader(), _buildBody()]),
          ),
        ),
      ),
    );
  }

  // 對話框頭部
  Widget _buildHeader() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF2A3759), // 深藍色標題背景
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 標題
          const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.trophy,
                  color: Color(0xFFFFD54F), // 金色獎杯圖標
                  size: 22,
                ),
                SizedBox(width: 10),
                Text(
                  '旅程成就',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // 關閉按鈕
          Positioned(
            right: 10,
            top: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                // 先執行關閉動畫，然後關閉對話框
                _animationController.reverse().then((_) {
                  Navigator.of(context).pop();
                });
              },
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }

  // 對話框主體內容
  Widget _buildBody() {
    return Expanded(
      child: Row(
        children: [
          // 左側分類選單
          _buildCategoryMenu(),

          // 成就列表
          _buildAchievementList(),

          // 右側成就詳情
          _buildAchievementDetail(),
        ],
      ),
    );
  }

  // 左側分類選單
  Widget _buildCategoryMenu() {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF20273F),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(14)),
        border: Border(
          right: BorderSide(
            color: Colors.black.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '分類',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._categories.map((category) => _buildCategoryItem(category)),

          const Spacer(),

          // 成就進度摘要
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '完成進度: ${_getCompletionPercentage()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _getCompletionRate(),
                  backgroundColor: Colors.grey.shade800,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF6BC8E2),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 分類選項
  Widget _buildCategoryItem(String category) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _selectedAchievement = null; // 清除選中的成就
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A3759) : Colors.transparent,
          border:
              isSelected
                  ? const Border(
                    left: BorderSide(color: Color(0xFF6BC8E2), width: 4),
                  )
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              _getCategoryIcon(category),
              color: isSelected ? const Color(0xFF6BC8E2) : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 10),
            Text(
              category,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Text(
              _getCategoryCompletion(category),
              style: TextStyle(
                color: isSelected ? const Color(0xFF6BC8E2) : Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 成就列表
  Widget _buildAchievementList() {
    return Expanded(
      child: Container(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: Color(0xFF1A1F35), width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 成就列表標題
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$_selectedCategory 成就',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_getUnlockedCount(_filteredAchievements)} / ${_filteredAchievements.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            // 成就列表主體
            Expanded(
              child:
                  _filteredAchievements.isEmpty
                      ? const Center(
                        child: Text(
                          '此分類暫無成就',
                          style: TextStyle(color: Colors.white60, fontSize: 16),
                        ),
                      )
                      : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredAchievements.length,
                        separatorBuilder:
                            (context, index) => const Divider(
                              color: Color(0xFF2A3759),
                              height: 1,
                            ),
                        itemBuilder: (context, index) {
                          final achievement = _filteredAchievements[index];
                          return _buildAchievementItem(achievement);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  // 單個成就項目
  Widget _buildAchievementItem(Achievement achievement) {
    final isSelected = _selectedAchievement?.id == achievement.id;
    final isLocked = !achievement.isUnlocked;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAchievement = achievement;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF2A3759).withValues(alpha: 0.5)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 成就圖標
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    isLocked ? Colors.grey.shade800 : const Color(0xFF2A3759),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color:
                      isLocked ? Colors.grey.shade600 : const Color(0xFF6BC8E2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                achievement.icon,
                color: isLocked ? Colors.grey : const Color(0xFFFFD54F),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // 成就標題和描述
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLocked
                          ? '??? ${achievement.title.substring(achievement.title.length ~/ 2)}'
                          : achievement.title,
                      style: TextStyle(
                        color: isLocked ? Colors.grey : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLocked && achievement.progress < 0.3
                          ? '未知的挑戰...'
                          : achievement.description,
                      style: TextStyle(
                        color: isLocked ? Colors.grey.shade500 : Colors.white70,
                        fontSize: 12,
                      ),
                    ),

                    // 進度條
                    if (achievement.progress < 1.0) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: achievement.progress,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isLocked
                              ? Colors.grey.shade500
                              : const Color(0xFF6BC8E2),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 5,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(achievement.progress * 100).toInt()}%',
                        style: TextStyle(
                          color:
                              isLocked ? Colors.grey.shade500 : Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 完成標記或獎勵預覽
            if (achievement.progress == 1.0)
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22)
            else
              Tooltip(
                message: achievement.reward,
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.grey,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 右側成就詳情
  Widget _buildAchievementDetail() {
    return SizedBox(
      width: 280,
      child:
          _selectedAchievement == null
              ? const Center(
                child: Text(
                  '選擇一個成就查看詳情',
                  style: TextStyle(color: Colors.white60),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 成就圖標
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              _selectedAchievement!.isUnlocked
                                  ? const Color(0xFF2A3759)
                                  : Colors.grey.shade800,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                          border: Border.all(
                            color:
                                _selectedAchievement!.isUnlocked
                                    ? const Color(0xFF6BC8E2)
                                    : Colors.grey.shade600,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _selectedAchievement!.icon,
                          color:
                              _selectedAchievement!.isUnlocked
                                  ? const Color(0xFFFFD54F)
                                  : Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 成就標題
                    Center(
                      child: Text(
                        _selectedAchievement!.isUnlocked
                            ? _selectedAchievement!.title
                            : '??? ${_selectedAchievement!.title.substring(_selectedAchievement!.title.length ~/ 2)}',
                        style: TextStyle(
                          color:
                              _selectedAchievement!.isUnlocked
                                  ? Colors.white
                                  : Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 成就分類
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A3759),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _selectedAchievement!.category,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 成就描述
                    const Text(
                      '描述',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAchievement!.isUnlocked ||
                              _selectedAchievement!.progress > 0.3
                          ? _selectedAchievement!.description
                          : '未知的挑戰...',
                      style: TextStyle(
                        color:
                            _selectedAchievement!.isUnlocked
                                ? Colors.white70
                                : Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 成就進度
                    const Text(
                      '進度',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _selectedAchievement!.progress,
                      backgroundColor: Colors.grey.shade800,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _selectedAchievement!.isUnlocked
                            ? const Color(0xFF6BC8E2)
                            : Colors.grey.shade500,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAchievement!.progress == 1.0
                          ? '完成!'
                          : '${(_selectedAchievement!.progress * 100).toInt()}% 完成',
                      style: TextStyle(
                        color:
                            _selectedAchievement!.progress == 1.0
                                ? const Color(0xFF4CAF50)
                                : Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 獎勵
                    const Text(
                      '獎勵',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3759),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _selectedAchievement!.progress == 1.0
                                  ? const Color(
                                    0xFFFFD54F,
                                  ).withValues(alpha: 0.5)
                                  : Colors.grey.shade700,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.card_giftcard,
                            color:
                                _selectedAchievement!.progress == 1.0
                                    ? const Color(0xFFFFD54F)
                                    : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _selectedAchievement!.isUnlocked ||
                                      _selectedAchievement!.progress > 0.5
                                  ? _selectedAchievement!.reward
                                  : '???',
                              style: TextStyle(
                                color:
                                    _selectedAchievement!.isUnlocked
                                        ? Colors.white
                                        : Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // 解鎖日期
                    if (_selectedAchievement!.isUnlocked &&
                        _selectedAchievement!.unlockDate != null)
                      Center(
                        child: Text(
                          '解鎖於 ${_formatDate(_selectedAchievement!.unlockDate!)}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  // 取得成就完成進度（百分比）
  String _getCompletionPercentage() {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final percentage = (unlockedCount / _achievements.length * 100).toInt();
    return percentage.toString();
  }

  // 取得成就完成率（小數）
  double _getCompletionRate() {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    return unlockedCount / _achievements.length;
  }

  // 取得指定類別的解鎖數/總數
  String _getCategoryCompletion(String category) {
    if (category == '全部') {
      final unlocked = _achievements.where((a) => a.isUnlocked).length;
      return '$unlocked/${_achievements.length}';
    } else {
      final filtered =
          _achievements.where((a) => a.category == category).toList();
      final unlocked = filtered.where((a) => a.isUnlocked).length;
      return '$unlocked/${filtered.length}';
    }
  }

  // 取得已解鎖成就數量
  int _getUnlockedCount(List<Achievement> achievements) {
    return achievements.where((a) => a.isUnlocked).length;
  }

  // 獲取類別對應的圖標
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '全部':
        return FontAwesomeIcons.list;
      case '冒險':
        return FontAwesomeIcons.personHiking;
      case '戰鬥':
        return FontAwesomeIcons.sackDollar;
      case '收集':
        return FontAwesomeIcons.boxOpen;
      case '隱藏':
        return FontAwesomeIcons.wandSparkles;
      default:
        return FontAwesomeIcons.star;
    }
  }

  // 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

/// 成就數據模型
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String category;
  final bool isUnlocked;
  final double progress; // 0.0 到 1.0
  final String reward;
  final DateTime? unlockDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.isUnlocked,
    required this.progress,
    required this.reward,
    this.unlockDate,
  });
}
