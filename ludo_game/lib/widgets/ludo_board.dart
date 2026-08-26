import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ludo_game/models/player_color.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/board_constants.dart';
import '../models/board_path.dart';
import '../models/token.dart';
import '../providers/game_provider.dart';
import 'board_painter.dart';

/// Renders the full Ludo board: 4 colored yards, the cross-shaped path,
/// colored home lanes, safe/star cells, the center triangle, and every
/// token positioned according to [GameProvider]'s state.
///
/// If the provider hasn't been initialized yet (no active match), this
/// falls back to 4 dummy tokens per color sitting in their yards, purely
/// so the board still looks right in isolation (e.g. before Phase 7's
/// setup screen calls `initGame`).
class LudoBoard extends StatelessWidget {
  const LudoBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double size = constraints.biggest.shortestSide;
        final double cellSize = size / BoardConstants.gridSize;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.boardBackground,
            border: Border.all(color: AppColors.boardOuterBorder, width: 3.w),
            borderRadius: BorderRadius.circular(8.r),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: BoardPainter(cellSize: cellSize),
              ),
              if (gameProvider.isInitialized)
                ..._buildStateTokens(gameProvider, cellSize)
              else
                ..._buildDummyTokens(cellSize),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Real tokens, driven by GameProvider + BoardPath (Phase 3+)
  // ---------------------------------------------------------------------
  List<Widget> _buildStateTokens(GameProvider provider, double cellSize) {
    final tokens = <Widget>[];
    final double tokenSize = cellSize * 1.3;

    for (final player in provider.players) {
      for (final token in player.tokens) {
        final Offset center = _tokenCenter(token, cellSize);
        tokens.add(
          Positioned(
            left: center.dx - tokenSize / 2,
            top: center.dy - tokenSize / 2,
            width: tokenSize,
            height: tokenSize,
            child: _Token(color: token.color.displayColor),
          ),
        );
      }
    }
    return tokens;
  }

  Offset _tokenCenter(Token token, double cellSize) {
    if (token.isInYard) {
      return _yardSlotCenter(token.color.key, token.slot, cellSize);
    }
    if (token.isFinished) {
      // All finished tokens rest near the center; Phase 8 can add a
      // nicer stacked/fan layout for the win celebration.
      return _boardCenter(cellSize);
    }
    final pos = BoardPath.absolutePosition(token.color, token.step)!;
    return Offset(
      pos[1] * cellSize + cellSize / 2,
      pos[0] * cellSize + cellSize / 2,
    );
  }

  // ---------------------------------------------------------------------
  // Dummy tokens — fallback when no match has been initialized yet
  // ---------------------------------------------------------------------
  List<Widget> _buildDummyTokens(double cellSize) {
    final tokens = <Widget>[];
    final double tokenSize = cellSize * 1.3;

    for (final colorKey in BoardConstants.yardBounds.keys) {
      for (int slot = 0; slot < 4; slot++) {
        final center = _yardSlotCenter(colorKey, slot, cellSize);
        tokens.add(
          Positioned(
            left: center.dx - tokenSize / 2,
            top: center.dy - tokenSize / 2,
            width: tokenSize,
            height: tokenSize,
            child: _Token(color: AppColors.fromKey(colorKey)),
          ),
        );
      }
    }
    return tokens;
  }

  // ---------------------------------------------------------------------
  // Shared geometry helpers
  // ---------------------------------------------------------------------
  Offset _yardSlotCenter(String colorKey, int slot, double cellSize) {
    final bounds = BoardConstants.yardBounds[colorKey]!;
    final rowStart = bounds[0];
    final colStart = bounds[2];
    final colEnd = bounds[3];
    final rowEnd = bounds[1];

    final double yardLeft = colStart * cellSize;
    final double yardTop = rowStart * cellSize;
    final double yardWidth = (colEnd - colStart + 1) * cellSize;
    final double yardHeight = (rowEnd - rowStart + 1) * cellSize;

    final fractional = BoardConstants.yardTokenSlots[slot];
    return Offset(
      yardLeft + fractional[0] * yardWidth,
      yardTop + fractional[1] * yardHeight,
    );
  }

  Offset _boardCenter(double cellSize) {
    // Center 3x3 block is rows 6-8, cols 6-8.
    final double left = 6 * cellSize;
    final double top = 6 * cellSize;
    final double extent = 3 * cellSize;
    return Offset(left + extent / 2, top + extent / 2);
  }
}

/// A single circular game token with a subtle highlight.
/// Reused as-is once real token widgets get drag/tap behavior in Phase 5.
class _Token extends StatelessWidget {
  final Color color;

  const _Token({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 3.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: FractionallySizedBox(
        widthFactor: 0.4,
        heightFactor: 0.4,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
