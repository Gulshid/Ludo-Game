import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/player_color.dart';
import '../providers/game_provider.dart';
import 'setup_screen.dart';
import 'start_screen.dart';

/// Shown once [GameProvider.phase] reaches [GamePhase.gameOver]: final
/// standings, a confetti celebration, and two ways to continue.
class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Finish order first, then any players who never finished (only
  /// possible if the match ended after the first winner).
  List<PlayerColor> _finalStandings(GameProvider provider) {
    final standings = <PlayerColor>[...provider.finishOrder];
    for (final player in provider.players) {
      if (!standings.contains(player.color)) {
        standings.add(player.color);
      }
    }
    return standings;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    final standings =
        provider.isInitialized ? _finalStandings(provider) : <PlayerColor>[];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  Text(
                    'GAME OVER',
                    style: TextStyle(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: AppColors.appBarText,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  if (standings.isNotEmpty)
                    Text(
                      '${standings.first.label} wins!',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: standings.first.displayColor,
                      ),
                    ),
                  SizedBox(height: 24.h),
                  Expanded(
                    child: standings.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.separated(
                            itemCount: standings.length,
                            separatorBuilder: (_, __) => SizedBox(height: 10.h),
                            itemBuilder: (context, index) {
                              return _StandingRow(
                                rank: index + 1,
                                color: standings[index],
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SetupScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'PLAY AGAIN',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.appBarText,
                        side: const BorderSide(color: AppColors.disabled),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const StartScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(
                        'BACK TO MENU',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 20,
              minBlastForce: 8,
              emissionFrequency: 0.04,
              numberOfParticles: 24,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                AppColors.red,
                AppColors.green,
                AppColors.yellow,
                AppColors.blue,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final int rank;
  final PlayerColor color;

  const _StandingRow({required this.rank, required this.color});

  String get _medal {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32.w,
            child: Text(_medal, style: TextStyle(fontSize: 16.sp)),
          ),
          Container(
            width: 20.w,
            height: 20.w,
            margin: EdgeInsets.only(right: 12.w),
            decoration: BoxDecoration(
              color: color.displayColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.w),
            ),
          ),
          Text(
            color.label,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
