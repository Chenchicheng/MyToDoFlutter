import 'dart:math';
import 'package:flutter/material.dart';

/// 全屏庆祝效果
class CelebrationOverlay {
  static OverlayEntry? _overlayEntry;

  /// 显示庆祝效果
  static void show(BuildContext context) {
    _overlayEntry?.remove();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => const _CelebrationWidget(),
    );

    Overlay.of(context).insert(_overlayEntry!);

    // 2.5秒后自动消失
    Future.delayed(const Duration(milliseconds: 2500), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}

class _CelebrationWidget extends StatefulWidget {
  const _CelebrationWidget();

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final List<_Confetti> _confettiList = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // 淡入淡出动画
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // 缩放动画
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // 彩带动画
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // 生成彩带粒子
    _generateConfetti();

    // 启动动画
    _fadeController.forward();
    _scaleController.forward();
    _confettiController.forward();

    // 淡出效果
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _fadeController.reverse();
      }
    });
  }

  void _generateConfetti() {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFFE66D),
      const Color(0xFF4ECDC4),
      const Color(0xFF45B7D1),
      const Color(0xFFFF9FF3),
      const Color(0xFFFECA57),
      const Color(0xFF5F27CD),
      const Color(0xFF00D2D3),
      const Color(0xFFFF9F43),
      const Color(0xFF10AC84),
    ];

    for (int i = 0; i < 100; i++) {
      _confettiList.add(_Confetti(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.3,
        size: 8 + _random.nextDouble() * 12,
        color: colors[_random.nextInt(colors.length)],
        speedY: 0.3 + _random.nextDouble() * 0.5,
        speedX: (_random.nextDouble() - 0.5) * 0.3,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        shape: _random.nextInt(3), // 0: 方形, 1: 圆形, 2: 三角形
      ));
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _confettiController]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Material(
            color: Colors.black.withOpacity(0.7),
            child: Stack(
              children: [
                // 彩带粒子
                ..._confettiList.map((confetti) {
                  final progress = _confettiController.value;
                  final currentY = confetti.y + confetti.speedY * progress * 1.5;
                  final currentX = confetti.x + confetti.speedX * progress;
                  final currentRotation = confetti.rotation + confetti.rotationSpeed * progress * 360;
                  
                  if (currentY > 1.2) return const SizedBox.shrink();
                  
                  return Positioned(
                    left: currentX * MediaQuery.of(context).size.width,
                    top: currentY * MediaQuery.of(context).size.height,
                    child: Transform.rotate(
                      angle: currentRotation * pi / 180,
                      child: _buildConfettiShape(confetti),
                    ),
                  );
                }),
                
                // 中心祝贺内容
                Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 勾选图标
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C853).withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // 祝贺文字
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                              Color(0xFFFFD700),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            '🎉 任务完成！',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '太棒了，继续保持！',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfettiShape(_Confetti confetti) {
    switch (confetti.shape) {
      case 0: // 方形
        return Container(
          width: confetti.size,
          height: confetti.size,
          decoration: BoxDecoration(
            color: confetti.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 1: // 圆形
        return Container(
          width: confetti.size,
          height: confetti.size,
          decoration: BoxDecoration(
            color: confetti.color,
            shape: BoxShape.circle,
          ),
        );
      case 2: // 长条
        return Container(
          width: confetti.size * 0.4,
          height: confetti.size * 1.5,
          decoration: BoxDecoration(
            color: confetti.color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      default:
        return Container(
          width: confetti.size,
          height: confetti.size,
          color: confetti.color,
        );
    }
  }
}

class _Confetti {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speedY;
  final double speedX;
  final double rotation;
  final double rotationSpeed;
  final int shape;

  _Confetti({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speedY,
    required this.speedX,
    required this.rotation,
    required this.rotationSpeed,
    required this.shape,
  });
}

