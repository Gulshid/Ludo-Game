import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/game_phase.dart';
import '../providers/game_provider.dart';

/// Minimal "whose turn is it" indicator. A fuller turn-management UI
/// (avatars, skipped-turn messaging, player setup, etc.) is built out
/// in Phase 7 — this just makes the Phase 3/4 state visible so the
/// dice/turn cycle is actually playtestable right now.
class TurnBanner extends StatelessWidget {
  const TurnBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    if (!provider.isInitialized) {
      return SizedBox(height: 28.h);
    }

    final color = provider.currentPlayer.color;
    final String phaseText = provider.phase == GamePhase.rollPhase
        ? 'Tap the dice to roll'
        : 'Rolled ${provider.lastDiceValue} — next turn starting…';

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
}
