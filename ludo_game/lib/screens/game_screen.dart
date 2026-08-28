import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/game_phase.dart';
import '../models/player_color.dart';
import '../providers/game_provider.dart';
import '../utils/page_transitions.dart';
import '../widgets/dice_widget.dart';
import '../widgets/ludo_board.dart';
import '../widgets/turn_banner.dart';
import 'game_over_screen.dart';

/// The main gameplay screen: turn banner, the 3D board, and the dice —
/// laid out over a dark felt-table backdrop for a premium, tactile feel.
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
    bool isCapture = false;
    if (provider.captureEventId != _lastShownCaptureEventId) {
      _lastShownCaptureEventId = provider.captureEventId;
      message = provider.lastCaptureMessage;
      isCapture = true;
    } else if (provider.turnEventId != _lastShownTurnEventId) {
      _lastShownTurnEventId = provider.turnEventId;
      message = provider.lastTurnMessage;
    }
    if (message == null) return;

    if (isCapture) _buzz();

    final toShow = message;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            // The theme is Brightness.dark, so Material3's default
            // SnackBar text color (colorScheme.onInverseSurface) is
            // dark — meant for a light background. We override the
            // background to a dark color below, so the text color
            // must be overridden too, or it's dark-on-dark and
            // unreadable.
            content: Text(
              toShow,
              style: TextStyle(
                color: AppColors.scaffoldBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.appBarText,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          ),
        );
    });
  }

  Future<void> _buzz() async {
    try {
      // flutter/services' HapticFeedback is built into the SDK (no
      // extra plugin needed, so nothing to configure per-platform) —
      // mediumImpact gives a satisfying, distinct "thud" for a capture.
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Haptics are a nice-to-have; never let a failure affect gameplay.
    }
  }

  void _maybeNavigateToGameOver(GameProvider provider) {
    if (!provider.isInitialized) return;
    if (provider.phase != GamePhase.gameOver) return;
    if (_navigatedToGameOver) return;

    _navigatedToGameOver = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        FadeScaleRoute(page: const GameOverScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    _maybeShowEventSnackBars(provider);
    _maybeNavigateToGameOver(provider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Ludo',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20.sp, letterSpacing: 1.2),
        ),
        actions: [
          IconButton(
            tooltip: provider.isMuted ? 'Unmute' : 'Mute',
            icon: Icon(provider.isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: provider.isInitialized ? provider.toggleMute : null,
          ),
          SizedBox(width: 4.w),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.4,
            colors: [Color(0xFF1B5B49), Color(0xFF0B2A21)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              children: [
                SizedBox(height: kToolbarHeight - 30.h),
                const TurnBanner(),
                SizedBox(height: 10.h),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double maxSize =
                          constraints.maxWidth < constraints.maxHeight
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
                SizedBox(height: 16.h),
                const DiceWidget(),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
