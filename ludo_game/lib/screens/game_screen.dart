import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/game_phase.dart';
import '../models/player_color.dart';
import '../providers/game_provider.dart';
import '../widgets/dice_widget.dart';
import '../widgets/ludo_board.dart';
import '../widgets/turn_banner.dart';
import 'game_over_screen.dart';

/// The main gameplay screen: turn banner, the board, and the dice.
///
/// Either pass [colors] to start a fresh match (from [SetupScreen]), or
/// set [resume] to true to load a saved match instead. If neither is
/// given (e.g. hot-reload during development), falls back to a default
/// 4-player match so the screen is never left blank.
class GameScreen extends StatefulWidget {
  final List<PlayerColor>? colors;
  final bool resume;

  const GameScreen({super.key, this.colors, this.resume = false});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _lastShownCaptureEventId = 0;
  int _lastShownTurnEventId = 0;
  bool _navigatedToGameOver = false;

  @override
  void initState() {
    super.initState();
    // Deferred to after the first frame: calling notifyListeners()
    // (which initGame/restoreSavedMatch do) during build would throw.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<GameProvider>();
      if (provider.isInitialized) return;

      if (widget.resume) {
        final restored = await provider.restoreSavedMatch();
        if (restored) return;
      }
      provider.initGame(
        widget.colors ??
            const [
              PlayerColor.red,
              PlayerColor.green,
              PlayerColor.yellow,
              PlayerColor.blue,
            ],
      );
    });
  }

  void _maybeShowEventSnackBars(GameProvider provider) {
    if (!provider.isInitialized) return;

    String? message;
    if (provider.captureEventId != _lastShownCaptureEventId) {
      _lastShownCaptureEventId = provider.captureEventId;
      message = provider.lastCaptureMessage;
    } else if (provider.turnEventId != _lastShownTurnEventId) {
      _lastShownTurnEventId = provider.turnEventId;
      message = provider.lastTurnMessage;
    }
    if (message == null) return;

    final toShow = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(toShow),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
  }

  void _maybeNavigateToGameOver(GameProvider provider) {
    if (!provider.isInitialized) return;
    if (provider.phase != GamePhase.gameOver) return;
    if (_navigatedToGameOver) return;

    _navigatedToGameOver = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameOverScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    _maybeShowEventSnackBars(provider);
    _maybeNavigateToGameOver(provider);

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
        actions: [
          IconButton(
            tooltip: provider.isMuted ? 'Unmute' : 'Mute',
            icon: Icon(provider.isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: provider.isInitialized ? provider.toggleMute : null,
          ),
        ],
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
