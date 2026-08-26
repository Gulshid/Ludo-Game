import 'package:flutter/foundation.dart';

/// Placeholder game state for Phase 1.
///
/// This just proves the Provider wiring works end-to-end (created here,
/// consumed in the widget tree). Real fields (players, tokens, dice
/// value, turn index, game phase) get added in Phase 3 onward.
class GameProvider extends ChangeNotifier {
  int _playerCount = 4;

  int get playerCount => _playerCount;

  void setPlayerCount(int count) {
    if (count < 2 || count > 4) return;
    _playerCount = count;
    notifyListeners();
  }
}
