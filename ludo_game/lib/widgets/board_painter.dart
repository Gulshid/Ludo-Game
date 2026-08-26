import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/board_constants.dart';

/// Draws the entire static Ludo board onto a canvas, cell by cell,
/// using a logical 15x15 grid (see [BoardConstants.gridSize]).
///
/// Layout reference (row, col — both 0-indexed):
///  - Yards: 4 corners, each a 6x6 block.
///  - Cross arms: the remaining "+" shaped path (rows/cols 6-8).
///  - Center 3x3 (rows 6-8, cols 6-8): the finishing triangle area.
///  - Each arm's middle row/column (excluding the outer starting cell)
///    is colored as that player's home lane.
///  - 8 safe cells (4 colored start cells + 4 star cells) are marked.
class BoardPainter extends CustomPainter {
  final double cellSize;

  BoardPainter({required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    _drawYards(canvas);
    _drawPathCells(canvas);
    _drawHomeLanes(canvas);
    _drawStartCells(canvas);
    _drawStarCells(canvas);
    _drawCenterTriangle(canvas);
    _drawGridLines(canvas);
  }

  // ---------------------------------------------------------------------
  // Yards
  // ---------------------------------------------------------------------
  void _drawYards(Canvas canvas) {
    BoardConstants.yardBounds.forEach((colorKey, bounds) {
      final color = AppColors.fromKey(colorKey);
      final rect = _rectFromBounds(bounds);

      // Outer colored square.
      canvas.drawRect(rect, Paint()..color = color);

      // Inner white "tray" that visually holds the 4 tokens, inset by
      // roughly 3/4 of a cell on every side.
      final inset = cellSize * 0.75;
      final innerRect = Rect.fromLTRB(
        rect.left + inset,
        rect.top + inset,
        rect.right - inset,
        rect.bottom - inset,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(cellSize * 0.6)),
        Paint()..color = Colors.white,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Cross-shaped path (white background cells)
  // ---------------------------------------------------------------------
  void _drawPathCells(Canvas canvas) {
    final paint = Paint()..color = AppColors.pathCell;
    for (int row = 0; row < BoardConstants.gridSize; row++) {
      for (int col = 0; col < BoardConstants.gridSize; col++) {
        if (_isCrossCell(row, col)) {
          canvas.drawRect(_cellRect(row, col), paint);
        }
      }
    }
  }

  /// True for any cell that belongs to the "+" shaped path/home area
  /// (i.e. NOT one of the 4 corner yards).
  bool _isCrossCell(int row, int col) {
    final inMiddleCols = col >= 6 && col <= 8;
    final inMiddleRows = row >= 6 && row <= 8;
    return inMiddleCols || inMiddleRows;
  }

  // ---------------------------------------------------------------------
  // Colored home lanes (5 cells per color leading into the center)
  // ---------------------------------------------------------------------
  void _drawHomeLanes(Canvas canvas) {
    BoardConstants.homeLaneCells.forEach((colorKey, cells) {
      final paint = Paint()..color = AppColors.fromKey(colorKey);
      for (final cell in cells) {
        canvas.drawRect(_cellRect(cell[0], cell[1]), paint);
      }
    });
  }

  // ---------------------------------------------------------------------
  // Colored + safe starting cells
  // ---------------------------------------------------------------------
  void _drawStartCells(Canvas canvas) {
    BoardConstants.startCells.forEach((colorKey, cell) {
      final color = AppColors.fromKey(colorKey);
      final rect = _cellRect(cell[0], cell[1]);

      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.25));
      _drawStar(canvas, rect.center, cellSize * 0.32, color);
    });
  }

  // ---------------------------------------------------------------------
  // Plain (uncolored) safe cells, marked with a grey star
  // ---------------------------------------------------------------------
  void _drawStarCells(Canvas canvas) {
    for (final cell in BoardConstants.starCells) {
      final rect = _cellRect(cell[0], cell[1]);
      _drawStar(canvas, rect.center, cellSize * 0.32, AppColors.disabled);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    const int points = 5;
    final path = Path();
    final double innerRadius = radius * 0.45;

    for (int i = 0; i < points * 2; i++) {
      final double r = i.isEven ? radius : innerRadius;
      final double angle = (i * math.pi / points) - math.pi / 2;
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.85));
  }

  // ---------------------------------------------------------------------
  // Center triangle ("home") — 4 triangles meeting at the middle,
  // each colored and pointing inward, matching that color's home lane.
  // ---------------------------------------------------------------------
  void _drawCenterTriangle(Canvas canvas) {
    final Rect centerRect = _rectFromBounds([6, 8, 6, 8]);
    final Offset topLeft = centerRect.topLeft;
    final Offset topRight = centerRect.topRight;
    final Offset bottomLeft = centerRect.bottomLeft;
    final Offset bottomRight = centerRect.bottomRight;
    final Offset middle = centerRect.center;

    // Red triangle — left side, pointing right into the middle.
    _fillTriangle(canvas, [topLeft, bottomLeft, middle], AppColors.red);
    // Green triangle — top side, pointing down into the middle.
    _fillTriangle(canvas, [topLeft, topRight, middle], AppColors.green);
    // Blue triangle — right side, pointing left into the middle.
    _fillTriangle(canvas, [topRight, bottomRight, middle], AppColors.blue);
    // Yellow triangle — bottom side, pointing up into the middle.
    _fillTriangle(canvas, [bottomLeft, bottomRight, middle], AppColors.yellow);
  }

  void _fillTriangle(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // ---------------------------------------------------------------------
  // Grid lines (drawn last, on top, so every path/yard cell has a crisp
  // border)
  // ---------------------------------------------------------------------
  void _drawGridLines(Canvas canvas) {
    final paint = Paint()
      ..color = AppColors.cellBorder
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    for (int row = 0; row < BoardConstants.gridSize; row++) {
      for (int col = 0; col < BoardConstants.gridSize; col++) {
        if (_isCrossCell(row, col)) {
          canvas.drawRect(_cellRect(row, col), paint);
        }
      }
    }
  }

  // ---------------------------------------------------------------------
  // Geometry helpers
  // ---------------------------------------------------------------------
  Rect _cellRect(int row, int col) {
    return Rect.fromLTWH(
      col * cellSize,
      row * cellSize,
      cellSize,
      cellSize,
    );
  }

  Rect _rectFromBounds(List<int> bounds) {
    final rowStart = bounds[0];
    final rowEnd = bounds[1];
    final colStart = bounds[2];
    final colEnd = bounds[3];
    return Rect.fromLTWH(
      colStart * cellSize,
      rowStart * cellSize,
      (colEnd - colStart + 1) * cellSize,
      (rowEnd - rowStart + 1) * cellSize,
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter oldDelegate) {
    return oldDelegate.cellSize != cellSize;
  }
}
