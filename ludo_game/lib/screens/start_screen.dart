import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'game_screen.dart';

/// The very first screen the player sees.
/// Phase 1 keeps this simple: a title and a "Play" button that pushes
/// the GameScreen. Player-count / color selection gets added in Phase 7.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ColorDotsRow(),
                const SizedBox(height: 24),
                const Text(
                  'LUDO',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: AppColors.appBarText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Flutter Edition',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'PLAY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small decorative row of the 4 player colors shown above the title.
class _ColorDotsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.red,
      AppColors.green,
      AppColors.yellow,
      AppColors.blue,
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors
          .map(
            (c) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
