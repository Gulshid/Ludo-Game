import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/game_provider.dart';
import '../widgets/dice_widget.dart';
import '../widgets/ludo_board.dart';
import '../widgets/turn_banner.dart';

/// The main gameplay screen: turn banner, the board, and the dice.
///
/// Full player-count/color setup happens on a dedicated screen in
/// Phase 7; for now this screen starts a default 4-player match itself
/// so the full dice -> move -> capture -> turn cycle is playable.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _lastShownCaptureEventId = 0;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame: calling notifyListeners()
    // (which initGame does) during build would throw.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GameProvider>();
      if (!provider.isInitialized) {
        provider.initGame(4);
      }
    });
  }

  /// Shows a brief SnackBar the first time a new capture event appears
  /// in [provider]. Comparing against a locally-remembered id keeps this
  /// from re-showing on every rebuild.
  void _maybeShowCaptureSnackBar(GameProvider provider) {
    if (!provider.isInitialized) return;
    if (provider.captureEventId == _lastShownCaptureEventId) return;

    _lastShownCaptureEventId = provider.captureEventId;
    final message = provider.lastCaptureMessage;
    if (message == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    _maybeShowCaptureSnackBar(provider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        foregroundColor: AppColors.appBarText,
        title: Text(
          'Ludo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(8.w),
          child: Column(
            children: [
              const TurnBanner(),
              SizedBox(height: 8.h),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double maxSize =
                        constraints.maxWidth < constraints.maxHeight
                            ? constraints.maxWidth
                            : constraints.maxHeight;
                    final double boardSize = maxSize * 0.96;

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
              SizedBox(height: 16.h),
              const DiceWidget(),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}
