import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ludo_game/models/player_color.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/game_phase.dart';
import '../providers/game_provider.dart';

/// A tappable 3D dice. At rest it's a raised, beveled cube showing the
/// last rolled value. While rolling, it deliberately shows **no
/// specific number at all** — only a blurred/spinning face — so there
/// is never a crisp digit on screen that could be mistaken for the
/// real result before the roll has actually finished. The true value
/// only ever appears once, right when it settles.
///
/// The tumble duration always matches [GameProvider.diceRollDuration]
/// — that's also how long the provider waits before it lets tokens
/// become tappable, so the number you see it land on is always
/// exactly what a token move will use.
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
  double _spinsX = 2.4;
  double _spinsY = 1.8;

  @override
  void initState() {
    super.initState();
    _tumbleController = AnimationController(
      vsync: this,
      duration: GameProvider.diceRollDuration,
    );
  }

  @override
  void dispose() {
    _tumbleController.dispose();
    super.dispose();
  }

  Future<void> _handleTap(GameProvider provider) async {
    // Guard against any possible double-trigger (fast double-tap,
    // stray rebuild, etc.) — a roll can only ever start once per turn
    // and only while the provider itself agrees it's roll time.
    if (_isRolling || provider.isRollingDice) return;
    if (!provider.isInitialized || provider.phase != GamePhase.rollPhase) return;

    setState(() {
      _isRolling = true;
      _spinsX = 2 + _random.nextDouble() * 1.5;
      _spinsY = 1.4 + _random.nextDouble() * 1.5;
    });

    _tumbleController.forward(from: 0);
    // The real result is decided right now — but deliberately not
    // shown until the animation below finishes, so what settles on
    // screen is always the one and only number that was ever "the
    // roll".
    final finalValue = provider.rollDice();

    await Future.delayed(GameProvider.diceRollDuration);
    if (!mounted) return;

    setState(() {
      _displayValue = finalValue;
      _isRolling = false;
    });
    _tumbleController.value = 0;
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
          isRolling: _isRolling,
        ),
      ),
    );
  }
}

/// A raised, beveled cube: a darker "slab" offset down-right behind a
/// bright front face forms a clean, always-readable 3D die — the
/// tumble animation in the parent then rotates this whole thing in 3D.
///
/// While [isRolling] is true, the pip face is replaced by a spinning
/// blur so no specific number is ever visible mid-roll.
class _DiceCube extends StatefulWidget {
  final int value;
  final Color accent;
  final bool dimmed;
  final bool isRolling;

  const _DiceCube({
    required this.value,
    required this.accent,
    required this.dimmed,
    required this.isRolling,
  });

  @override
  State<_DiceCube> createState() => _DiceCubeState();
}

class _DiceCubeState extends State<_DiceCube> with SingleTickerProviderStateMixin {
  late final AnimationController _blurSpin;

  @override
  void initState() {
    super.initState();
    _blurSpin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat();
  }

  @override
  void dispose() {
    _blurSpin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = 66.w;
    final double depth = 9.w;

    return Opacity(
      opacity: widget.dimmed ? 0.55 : 1.0,
      child: SizedBox(
        width: s + depth,
        height: s + depth,
        child: Stack(
          children: [
            // The slab: a solid, darker block sitting behind + below
            // the face, whose visible sliver reads as cube thickness.
            Positioned(
              left: depth,
              top: depth,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(widget.accent, Colors.black, 0.35)!,
                      Color.lerp(widget.accent, Colors.black, 0.55)!,
                    ],
                  ),
                ),
              ),
            ),
            // The front face — always straight-on, so the pips are
            // never distorted.
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: widget.accent, width: 3.w),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF3EFE2)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 12.r,
                      offset: Offset(3.w, 7.h),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Soft top-left sheen for extra glossiness.
                    Positioned(
                      left: 6.w,
                      top: 6.h,
                      right: s * 0.45,
                      height: s * 0.28,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.r),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.75),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.isRolling)
                      _RollingBlur(controller: _blurSpin, accent: widget.accent)
                    else
                      _DiceFace(value: widget.value),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of a pip face while the dice is mid-roll: a softly
/// spinning ring of dots with no fixed count and no readable number —
/// unambiguously "still deciding", never mistakable for a result.
class _RollingBlur extends StatelessWidget {
  final AnimationController controller;
  final Color accent;

  const _RollingBlur({required this.controller, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.all(10.w),
          child: Center(
            child: Transform.rotate(
              angle: controller.value * 2 * pi,
              child: Stack(
                alignment: Alignment.center,
                children: List.generate(6, (i) {
                  final angle = (2 * pi * i / 6);
                  final radius = 15.w;
                  final fade = (0.35 + 0.65 * ((i / 6 + controller.value) % 1.0));
                  return Transform.translate(
                    offset: Offset(cos(angle) * radius, sin(angle) * radius),
                    child: Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: fade),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
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
      padding: EdgeInsets.all(10.w),
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
                            width: 11.w,
                            height: 11.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                center: const Alignment(-0.4, -0.5),
                                colors: [
                                  Color.lerp(AppColors.appBarText, Colors.white, 0.25)!,
                                  AppColors.appBarText,
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 1.5),
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
