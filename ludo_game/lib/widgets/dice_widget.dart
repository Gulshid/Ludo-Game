import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ludo_game/models/player_color.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/game_phase.dart';
import '../providers/game_provider.dart';

/// A tappable 3D dice: always rendered as a beveled cube (visible top
/// and side faces even at rest), and on tap it genuinely tumbles in 3D
/// (rotateX + rotateY) before landing on the real rolled value from
/// [GameProvider.rollDice].
class DiceWidget extends StatefulWidget {
  const DiceWidget({super.key});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  final Random _random = Random();
  int _displayValue = 1;
  bool _isRolling = false;

  late final AnimationController _tumbleController;
  late double _spinsX;
  late double _spinsY;

  @override
  void initState() {
    super.initState();
    _tumbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _spinsX = 2 + _random.nextDouble();
    _spinsY = 1.5 + _random.nextDouble();
  }

  @override
  void dispose() {
    _tumbleController.dispose();
    super.dispose();
  }

  Future<void> _handleTap(GameProvider provider) async {
    if (_isRolling || !provider.isInitialized || provider.phase != GamePhase.rollPhase) {
      return;
    }

    setState(() {
      _isRolling = true;
      _spinsX = 2 + _random.nextDouble() * 1.5;
      _spinsY = 1.4 + _random.nextDouble() * 1.5;
    });

    // Cycle random faces while the cube tumbles, for extra chaos.
    unawaited(_cyclePips());

    _tumbleController.forward(from: 0);
    final finalValue = provider.rollDice();
    await Future.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    setState(() {
      _displayValue = finalValue;
      _isRolling = false;
    });
    _tumbleController.value = 0;
  }

  Future<void> _cyclePips() async {
    const cycleDelay = Duration(milliseconds: 70);
    for (int i = 0; i < 10; i++) {
      if (!mounted || !_isRolling) return;
      setState(() => _displayValue = _random.nextInt(6) + 1);
      await Future.delayed(cycleDelay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final bool canRoll =
        provider.isInitialized && provider.phase == GamePhase.rollPhase && !_isRolling;

    final Color accent =
        provider.isInitialized ? provider.currentPlayer.color.displayColor : AppColors.disabled;

    return GestureDetector(
      onTap: () => _handleTap(provider),
      child: AnimatedBuilder(
        animation: _tumbleController,
        builder: (context, child) {
          final t = _tumbleController.value;
          final settle = Curves.easeOutCubic.transform(t);
          final rotX = (1 - settle) * _spinsX * 2 * pi;
          final rotY = (1 - settle) * _spinsY * 2 * pi;
          final hop = sin(t * pi) * -14.h;

          return Transform.translate(
            offset: Offset(0, hop),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.003)
                ..rotateX(rotX)
                ..rotateY(rotY),
              child: AnimatedScale(
                scale: canRoll ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                child: child,
              ),
            ),
          );
        },
        child: _DiceCube(
          value: _displayValue,
          accent: accent,
          dimmed: !canRoll && !_isRolling,
        ),
      ),
    );
  }
}

void unawaited(Future<void> future) {}

/// A beveled cube built from three visible faces (front, top, right) so
/// it reads as a real 3D die even while at rest — the tumble animation
/// in the parent widget then rotates this whole cube in 3D space.
class _DiceCube extends StatelessWidget {
  final int value;
  final Color accent;
  final bool dimmed;

  const _DiceCube({required this.value, required this.accent, required this.dimmed});

  @override
  Widget build(BuildContext context) {
    final double s = 58.w;
    final double depth = s * 0.16;

    return Opacity(
      opacity: dimmed ? 0.55 : 1.0,
      child: SizedBox(
        width: s + depth,
        height: s + depth,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Top face (skewed parallelogram) — catches the most light.
            Positioned(
              left: depth,
              top: 0,
              child: Transform(
                transform: Matrix4.skewX(-0.001)
                  ..setEntry(0, 1, -0.55)
                  ..scale(1.0, 0.5),
                alignment: Alignment.topLeft,
                child: Container(
                  width: s,
                  height: depth * 2.6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, const Color(0xFFEDEAE0)],
                    ),
                  ),
                ),
              ),
            ),
            // Right face — darker side, gives the box its depth.
            Positioned(
              left: s,
              top: depth,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(1, 0, 0.55)
                  ..scale(0.5, 1.0),
                alignment: Alignment.topLeft,
                child: Container(
                  width: depth * 2.6,
                  height: s,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.r),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFCFC9B8), Color(0xFFA9A28D)],
                    ),
                  ),
                ),
              ),
            ),
            // Front face — the one showing the rolled value.
            Positioned(
              left: 0,
              top: depth,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: accent, width: 3.w),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF5F2E8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10.r,
                      offset: Offset(2.w, 6.h),
                    ),
                  ],
                ),
                child: _DiceFace(value: value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a classic dice pip layout (1-6) on a 3x3 grid, no image assets
/// required, with each pip rendered as a tiny glossy sphere.
class _DiceFace extends StatelessWidget {
  final int value;

  const _DiceFace({required this.value});

  static const Map<int, List<List<int>>> _pipGrid = {
    1: [
      [1, 1]
    ],
    2: [
      [0, 0],
      [2, 2]
    ],
    3: [
      [0, 0],
      [1, 1],
      [2, 2]
    ],
    4: [
      [0, 0],
      [0, 2],
      [2, 0],
      [2, 2]
    ],
    5: [
      [0, 0],
      [0, 2],
      [1, 1],
      [2, 0],
      [2, 2]
    ],
    6: [
      [0, 0],
      [0, 2],
      [1, 0],
      [1, 2],
      [2, 0],
      [2, 2]
    ],
  };

  @override
  Widget build(BuildContext context) {
    final pips = _pipGrid[value] ?? _pipGrid[1]!;

    return Padding(
      padding: EdgeInsets.all(9.w),
      child: Column(
        children: List.generate(3, (row) {
          return Expanded(
            child: Row(
              children: List.generate(3, (col) {
                final bool hasPip = pips.any((p) => p[0] == row && p[1] == col);
                return Expanded(
                  child: Center(
                    child: hasPip
                        ? Container(
                            width: 9.w,
                            height: 9.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.4, -0.5),
                                colors: [
                                  Color.lerp(AppColors.appBarText, Colors.white, 0.3)!,
                                  AppColors.appBarText,
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 1),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
