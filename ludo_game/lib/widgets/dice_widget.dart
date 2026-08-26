import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ludo_game/models/player_color.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/game_phase.dart';
import '../providers/game_provider.dart';

/// A tappable dice: cycles random faces briefly for a "rolling" feel,
/// lands on the real rolled value, and is disabled whenever it isn't
/// the local player's turn to roll.
class DiceWidget extends StatefulWidget {
  const DiceWidget({super.key});

  @override
  State<DiceWidget> createState() => _DiceWidgetState();
}

class _DiceWidgetState extends State<DiceWidget> {
  final Random _random = Random();
  int _displayValue = 1;
  bool _isRolling = false;

  Future<void> _handleTap(GameProvider provider) async {
    if (_isRolling || !provider.isInitialized || provider.phase != GamePhase.rollPhase) {
      return;
    }

    setState(() => _isRolling = true);

    // Quick random-face cycling to sell the "rolling" feel before
    // landing on the real, provider-generated value.
    const cycleDelay = Duration(milliseconds: 80);
    for (int i = 0; i < 8; i++) {
      setState(() => _displayValue = _random.nextInt(6) + 1);
      await Future.delayed(cycleDelay);
    }

    final finalValue = provider.rollDice();
    if (!mounted) return;
    setState(() {
      _displayValue = finalValue;
      _isRolling = false;
    });

    // No auto-advance here anymore: Phase 5 added real token movement.
    // The turn now ends when the player taps a movable token
    // (GameProvider.moveToken) or, if nothing can legally move,
    // GameProvider auto-passes the turn on its own after a short delay.
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final bool canRoll = provider.isInitialized &&
        provider.phase == GamePhase.rollPhase &&
        !_isRolling;

    final Color borderColor = provider.isInitialized
        ? provider.currentPlayer.color.displayColor
        : AppColors.disabled;

    return GestureDetector(
      onTap: () => _handleTap(provider),
      child: AnimatedScale(
        scale: canRoll ? 1.0 : 0.92,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: 64.w,
          height: 64.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: borderColor, width: 3.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: canRoll ? 8 : 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Opacity(
            opacity: (canRoll || _isRolling) ? 1 : 0.4,
            child: _DiceFace(value: _displayValue),
          ),
        ),
      ),
    );
  }
}

/// Draws a classic dice pip layout (1-6) on a 3x3 grid, no image assets
/// required.
class _DiceFace extends StatelessWidget {
  final int value;

  const _DiceFace({required this.value});

  // Each entry lists which (row, col) cells of a 3x3 grid get a pip.
  static const Map<int, List<List<int>>> _pipGrid = {
    1: [
      [1, 1],
    ],
    2: [
      [0, 0],
      [2, 2],
    ],
    3: [
      [0, 0],
      [1, 1],
      [2, 2],
    ],
    4: [
      [0, 0],
      [0, 2],
      [2, 0],
      [2, 2],
    ],
    5: [
      [0, 0],
      [0, 2],
      [1, 1],
      [2, 0],
      [2, 2],
    ],
    6: [
      [0, 0],
      [0, 2],
      [1, 0],
      [1, 2],
      [2, 0],
      [2, 2],
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
                            decoration: const BoxDecoration(
                              color: AppColors.appBarText,
                              shape: BoxShape.circle,
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
