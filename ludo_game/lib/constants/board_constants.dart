/// The Ludo board is always a 15x15 logical grid, regardless of the
/// screen's actual pixel size. Every widget divides the rendered board
/// size by [gridSize] to get a responsive cell size.
class BoardConstants {
  BoardConstants._();

  static const int gridSize = 15;

  /// The 8 safe (star) cells that are not a colored start cell.
  /// Stored as (row, col).
  static const List<List<int>> starCells = [
    [8, 2],
    [2, 6],
    [6, 12],
    [12, 8],
  ];

  /// Each color's colored starting cell on the shared path (also safe).
  static const Map<String, List<int>> startCells = {
    'red': [6, 1],
    'green': [1, 8],
    'blue': [8, 13],
    'yellow': [13, 6],
  };

  /// Each color's home-lane cells (the 5 colored cells leading into the
  /// center triangle, excluding the center itself). Stored as (row, col).
  static const Map<String, List<List<int>>> homeLaneCells = {
    'red': [
      [7, 1],
      [7, 2],
      [7, 3],
      [7, 4],
      [7, 5],
    ],
    'green': [
      [1, 7],
      [2, 7],
      [3, 7],
      [4, 7],
      [5, 7],
    ],
    'blue': [
      [7, 13],
      [7, 12],
      [7, 11],
      [7, 10],
      [7, 9],
    ],
    'yellow': [
      [13, 7],
      [12, 7],
      [11, 7],
      [10, 7],
      [9, 7],
    ],
  };

  /// Bounding box (rowStart, rowEnd, colStart, colEnd) of each yard,
  /// inclusive.
  static const Map<String, List<int>> yardBounds = {
    'red': [0, 5, 0, 5],
    'green': [0, 5, 9, 14],
    'blue': [9, 14, 9, 14],
    'yellow': [9, 14, 0, 5],
  };

  /// The 4 relative token slot positions inside a yard's inner square,
  /// as fractions (0-1) of the yard's inner box. Used to lay out the
  /// 4 dummy/real tokens neatly inside each yard.
  static const List<List<double>> yardTokenSlots = [
    [0.28, 0.28],
    [0.72, 0.28],
    [0.28, 0.72],
    [0.72, 0.72],
  ];
}
