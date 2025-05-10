import 'dart:async';
import 'dart:math';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'intro_screen.dart';
import '../widgets/achievement_dialog.dart'; // 引入旅程成就對話框

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  bool _isMusicPlaying = false;

  // 星星動畫控制器
  late AnimationController _starAnimationController;

  // 星星列表，每顆星星有自己的位置、大小和閃爍速度
  final List<Star> _stars = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadAndPlayMenuMusic();

    // 初始化星星動畫控制器
    _starAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // 生成隨機星星
    _generateStars();

    // 開始星星閃爍定時器
    Timer.periodic(const Duration(milliseconds: 50), _updateStars);
  }

  // 生成隨機星星
  void _generateStars() {
    // 生成100顆星星
    for (int i = 0; i < 100; i++) {
      _stars.add(
        Star(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 3 + 1, // 1-4像素大小
          blinkSpeed: _random.nextDouble() * 2 + 0.5, // 閃爍速度
          brightness: _random.nextDouble() * 0.8 + 0.1, // 初始亮度在0.1到0.9之間
          blinkDirection: _random.nextBool(), // 初始閃爍方向
        ),
      );
    }
  }

  // 更新星星動畫
  void _updateStars(Timer timer) {
    if (!mounted) {
      timer.cancel();
      return;
    }

    setState(() {
      for (var star in _stars) {
        // 安全地更新星星亮度
        final double delta = 0.02 * star.blinkSpeed;

        if (star.blinkDirection) {
          // 變亮
          double newBrightness = star.brightness + delta;
          if (newBrightness >= 0.98) {
            newBrightness = 0.98;
            star.blinkDirection = false;
          }
          star.brightness = newBrightness;
        } else {
          // 變暗
          double newBrightness = star.brightness - delta;
          if (newBrightness <= 0.15) {
            newBrightness = 0.15;
            star.blinkDirection = true;
          }
          star.brightness = newBrightness;
        }
      }
    });
  }

  Future<void> _loadAndPlayMenuMusic() async {
    try {
      // 預先加載選單背景音樂
      await FlameAudio.audioCache.load('menu.mp3');
      // 播放選單背景音樂，音量降低
      FlameAudio.bgm.play('menu.mp3', volume: 0.15);
      setState(() {
        _isMusicPlaying = true;
      });
    } catch (e) {
      debugPrint('選單背景音樂播放失敗: $e');
    }
  }

  @override
  void dispose() {
    // 離開選單時停止音樂
    if (_isMusicPlaying) {
      FlameAudio.bgm.stop();
    }

    // 釋放動畫控制器
    _starAnimationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 獲取螢幕尺寸
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 背景漸層
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/MenuBackGround.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 星星動畫層
          CustomPaint(
            size: Size(screenSize.width, screenSize.height),
            painter: StarfieldPainter(_stars),
          ),

          // 主要內容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 遊戲標題圖片
                _buildAnimatedLogo(screenSize), // 按鈕組
                _buildAnimatedButton(
                  '新的日記',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    // 切換到引導畫面
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IntroScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // 生日特別企劃按鈕
                _buildSpecialEventButton(
                  '生日特別企劃',
                  icon: Icons.cake_rounded,
                  onPressed: () {
                    // 切換到引導畫面，並標記為特別企劃
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const IntroScreen(isBirthdaySpecial: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 旅程成就按鈕
                _buildAnimatedButton(
                  '旅程成就',
                  icon: FontAwesomeIcons.award,
                  onPressed: () {
                    // 顯示成就對話框
                    showDialog(
                      context: context,
                      barrierDismissible: false, // 防止點擊外部關閉
                      builder: (_) => const AchievementDialog(),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 離開按鈕
                // 新版：暗夜底色 + 暖金高光
                _buildAnimatedButton(
                  '離開',
                  icon: Icons.exit_to_app,
                  // 洞壁暗夜色
                  color: const Color(0xFF1C1F33),
                  // 邊框 & 圖示採用燈籠暖金色
                  borderColor: const Color(0xFFE8A857),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('確認離開'),
                            content: const Text('確定要離開遊戲嗎？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  // 實際退出邏輯...
                                },
                                child: const Text('確定'),
                              ),
                            ],
                          ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // 版本號和版權信息
                Row(
                  children: [
                    const Text(
                      'Night & Rain v2.0.0 | 2025 © 偷吃螺肉',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 動畫標誌 - 使用更絲滑的浮動效果
  Widget _buildAnimatedLogo(Size screenSize) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        // 使用專門的浮動效果
        return AnimatedFloatingWidget(
          duration: const Duration(milliseconds: 3000), // 較慢的周期
          offsetY: 5.0, // 較小的偏移量
          child: Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0), // 確保透明度值在有效範圍內
              child: Image.asset(
                'assets/images/MenuTitle.png',
                width: screenSize.width * 0.4,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }

  // 美化標準選單按鈕（深藍＋冰晶青）
  Widget _buildAnimatedButton(
    String text, {
    required VoidCallback onPressed,
    required IconData icon,
    Color? color,
    Color? borderColor,
  }) {
    // 深藍主色與冰晶高光
    final baseColor = color ?? const Color(0xFF2A3759);
    final highlightColor = borderColor ?? const Color(0xFF6BC8E2);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 220,
            height: 48,
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: baseColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: highlightColor, width: 2),
                ),
                elevation: 6,
                shadowColor: baseColor.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                textStyle: const TextStyle(
                  shadows: [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 22, color: highlightColor),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 特別活動按鈕（紫水晶漸層＋銀框＋水晶光暈）
  Widget _buildSpecialEventButton(
    String text, {
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.95, end: 1.02),
        duration: const Duration(milliseconds: 1800),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 220,
              height: 48,
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF5C4B8B), Color(0xFF8F7AC4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFCAA1FF).withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(color: const Color(0xFFAEEFFF), width: 1.5),
              ),
              child: Stack(
                children: [
                  // 按鈕內容
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 22, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            letterSpacing: 0.8,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 星星類，用於管理每顆星星的屬性
class Star {
  double x; // 位置 (0-1)
  double y; // 位置 (0-1)
  double size; // 大小
  double blinkSpeed; // 閃爍速度
  double brightness; // 亮度 (0-1)
  bool blinkDirection; // true=變亮，false=變暗

  Star({
    required this.x,
    required this.y,
    required this.size,
    required this.blinkSpeed,
    required this.brightness,
    required this.blinkDirection,
  });
}

// 繪製星空背景的畫筆
class StarfieldPainter extends CustomPainter {
  final List<Star> stars;

  StarfieldPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      // 確保亮度值在有效範圍內
      final safeOpacity = star.brightness.clamp(0.0, 1.0);

      final paint =
          Paint()
            ..color = Colors.white.withValues(alpha: safeOpacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );

      // 閃爍較亮的星星添加光暈效果
      if (star.brightness > 0.7 && star.size > 2) {
        // 確保光暈的透明度也在有效範圍內
        final glowOpacity = (star.brightness * 0.3).clamp(0.0, 1.0);

        final glowPaint =
            Paint()
              ..color = Colors.white.withValues(alpha: glowOpacity)
              ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(star.x * size.width, star.y * size.height),
          star.size * 2,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter oldDelegate) => true;
}

// 專門的浮動動畫Widget
class AnimatedFloatingWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offsetY;

  const AnimatedFloatingWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 2000),
    this.offsetY = 10.0,
  });

  @override
  State<AnimatedFloatingWidget> createState() => _AnimatedFloatingWidgetState();
}

class _AnimatedFloatingWidgetState extends State<AnimatedFloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    // 使用CurvedAnimation使動畫更加平滑
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // 無限循環
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 使用更平滑的補間方式
        final offset = Tween<double>(
          begin: -widget.offsetY,
          end: widget.offsetY,
        ).evaluate(_animation);
        return Transform.translate(offset: Offset(0, offset), child: child);
      },
      child: widget.child,
    );
  }
}
