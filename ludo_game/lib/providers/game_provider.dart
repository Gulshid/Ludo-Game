import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/game_phase.dart';
import '../models/player.dart';
import '../models/player_color.dart';

/// The single source of truth for an in-progress match: which players
/// are playing, whose turn it is, the last dice roll, and the current
/// phase of the turn state machine.
///
/// Phase 5 will add real move-selection/legality here; Phase 6 adds
/// capture/safe-cell rules; Phase 7 fleshes out the full turn cycle.
/// For now this covers Phase 3 (state shape) and Phase 4 (dice rules).
class GameProvider extends ChangeNotifier {
  List<Player> _players = [];
  int _currentPlayerIndex = 0;
  int? _lastDiceValue;
  GamePhase _phase = GamePhase.rollPhase;
  int _consecutiveSixes = 0;

  final Random _random = Random();

  List<Player> get players => List.unmodifiable(_players);
  bool get isInitialized => _players.isNotEmpty;

  Player get currentPlayer => _players[_currentPlayerIndex];
  int get currentPlayerIndex => _currentPlayerIndex;

  int? get lastDiceValue => _lastDiceValue;
  GamePhase get phase => _phase;

  /// Sets up a fresh match with [playerCount] players (2-4). Colors are
  /// assigned in a fixed order; full color-picking UI comes in Phase 7.
  void initGame(int playerCount) {
    assert(playerCount >= 2 && playerCount <= 4);

    const order = [
      PlayerColor.red,
      PlayerColor.green,
      PlayerColor.yellow,
      PlayerColor.blue,
    ];

    _players = order.take(playerCount).map((c) => Player(color: c)).toList();
    _currentPlayerIndex = 0;
    _lastDiceValue = null;
    _phase = GamePhase.rollPhase;
    _consecutiveSixes = 0;
    notifyListeners();
  }

  /// Rolls the dice for the current player and stores the result so the
  /// rest of the app (movement engine in Phase 5) can consume it.
  /// Returns the rolled value so the Dice widget's animation can land on
  /// the correct final face.
  int rollDice() {
    if (!isInitialized || _phase != GamePhase.rollPhase) {
      return _lastDiceValue ?? 1;
    }

    final value = _random.nextInt(6) + 1;
    _lastDiceValue = value;
    _consecutiveSixes = value == 6 ? _consecutiveSixes + 1 : 0;

    if (_consecutiveSixes == 3) {
      // Classic rule: three 6s in a row forfeits the turn entirely.
      _consecutiveSixes = 0;
      _lastDiceValue = null;
      _advanceTurn();
    } else {
      _phase = GamePhase.movePhase;
    }

    notifyListeners();
    return value;
  }

  /// Ends the current player's turn. Rolling a 6 grants an extra turn
  /// (same player rolls again); anything else passes to the next player.
  ///
  /// NOTE: until Phase 5 adds real token movement, nothing calls this
  /// except a temporary auto-advance in [DiceWidget] so the roll/turn
  /// cycle can already be play-tested end to end.
  void endTurn() {
    if (!isInitialized) return;

    final rolledSix = _lastDiceValue == 6;
    _lastDiceValue = null;

    if (rolledSix) {
      _phase = GamePhase.rollPhase; // extra turn, same player
    } else {
      _advanceTurn();
    }
    notifyListeners();
  }

  void _advanceTurn() {
    _consecutiveSixes = 0;
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    _phase = GamePhase.rollPhase;
  }
}
