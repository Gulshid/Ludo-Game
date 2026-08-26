import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/board_constants.dart';
import 'board_painter.dart';

/// Renders the full static Ludo board: 4 colored yards, the cross-shaped
/// path, colored home lanes, safe/star cells, the center triangle, and
/// 4 dummy tokens per color sitting in their yards.
///
/// This widget is purely visual for Phase 2 — it doesn't yet know about
/// real game state. From Phase 3 onward, token positions will come from
/// [GameProvider] instead of the hardcoded yard slots used here.
class LudoBoard extends StatelessWidget {
  const LudoBoard({super.key});

  @override
  Widget build(BuildContext context) {
    // Deliberately a plain LayoutBuilder, not ScreenUtil: the board must
    // exactly fill whatever square space GameScreen hands it, which is a
    // live-constraint value, not a fixed design-pixel value to scale.
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
              // The board itself: grid, yards, path, home triangle.
              CustomPaint(
                size: Size(size, size),
                painter: BoardPainter(cellSize: cellSize),
              ),
              // Dummy tokens placed in each yard to verify sizing/alignment.
              ..._buildDummyTokens(cellSize),
            ],
          ),
        );
      },
    );
  }

  /// Builds 4 dummy tokens (one color's full set of 4) positioned inside
  /// each yard using [BoardConstants.yardTokenSlots], just to confirm the
  /// token size and alignment look right against the board (per the
  /// Phase 2 "Definition of Done").
  List<Widget> _buildDummyTokens(double cellSize) {
    final tokens = <Widget>[];
    final double tokenSize = cellSize * 1.3;

    BoardConstants.yardBounds.forEach((colorKey, bounds) {
      final rowStart = bounds[0];
      final rowEnd = bounds[1];
      final colStart = bounds[2];
      final colEnd = bounds[3];

      final double yardLeft = colStart * cellSize;
      final double yardTop = rowStart * cellSize;
      final double yardWidth = (colEnd - colStart + 1) * cellSize;
      final double yardHeight = (rowEnd - rowStart + 1) * cellSize;

      for (final slot in BoardConstants.yardTokenSlots) {
        final double dx = yardLeft + slot[0] * yardWidth - tokenSize / 2;
        final double dy = yardTop + slot[1] * yardHeight - tokenSize / 2;

        tokens.add(
          Positioned(
            left: dx,
            top: dy,
            width: tokenSize,
            height: tokenSize,
            child: _Token(color: AppColors.fromKey(colorKey)),
          ),
        );
      }
    });

    return tokens;
  }
}

/// A single circular game token with a subtle 3D-ish highlight.
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
