import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ludo_game/models/player_color.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/game_phase.dart';
import '../providers/game_provider.dart';

/// Minimal "whose turn is it" indicator. A fuller turn-management UI
/// (avatars, skipped-turn messaging, player setup, etc.) is built out
/// in Phase 7 — this surfaces the roll/move/animating/no-moves state
/// from Phases 4-6 so the game is playtestable right now.
class TurnBanner extends StatelessWidget {
  const TurnBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    if (!provider.isInitialized) {
      return SizedBox(height: 28.h);
    }

    final color = provider.currentPlayer.color;
    final String phaseText = _phaseText(provider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 14.w,
          height: 14.w,
          decoration: BoxDecoration(
            color: color.displayColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5.w),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            "${color.label}'s turn  •  $phaseText",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.appBarText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _phaseText(GameProvider provider) {
    if (provider.phase == GamePhase.rollPhase) {
      return 'Tap the dice to roll';
    }
    // GamePhase.movePhase
    if (provider.isAnimating) {
      return 'Moving…';
    }
    if (provider.movableTokens.isEmpty) {
      return 'No legal moves — turn passing…';
    }
    return 'Rolled ${provider.lastDiceValue} — tap a highlighted token';
  }
}
