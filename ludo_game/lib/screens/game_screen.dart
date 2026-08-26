import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../widgets/ludo_board.dart';

/// The main gameplay screen.
///
/// Phase 1: just a Scaffold with an AppBar so navigation works end to end.
/// Phase 2: renders the static LudoBoard, sized responsively and kept
/// perfectly square regardless of the device's screen dimensions.
/// Dice, token interaction and turn UI are added from Phase 4 onward.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        foregroundColor: AppColors.appBarText,
        title: const Text(
          'Ludo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Keep the board perfectly square and never larger than the
            // available space, with a little breathing room on the sides.
            final double maxSize = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;
            final double boardSize = maxSize * 0.94;

            return Center(
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: const LudoBoard(),
              ),
            );
          },
        ),
      ),
    );
  }
}
