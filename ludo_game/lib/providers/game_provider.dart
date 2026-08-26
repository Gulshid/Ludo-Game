import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/board_path.dart';
import '../models/game_phase.dart';
import '../models/game_rules.dart';
import '../models/player.dart';
import '../models/player_color.dart';
import '../models/token.dart';

/// The single source of truth for an in-progress match: which players
/// are playing, whose turn it is, the last dice roll, the current phase
/// of the turn state machine, and now (Phase 5/6) legal move computation,
/// step-by-step token movement, blocking, and capturing.
///
/// Full turn-cycle polish (player setup, skipped-turn messaging, etc.)
/// is fleshed out in Phase 7; win detection/game-over screen in Phase 8.
class GameProvider extends ChangeNotifier {
  List<Player> _players = [];
  int _currentPlayerIndex = 0;
  int? _lastDiceValue;
  GamePhase _phase = GamePhase.rollPhase;
  int _consecutiveSixes = 0;
  bool _isAnimating = false;

  // Phase 6: house-rule toggles, exposed so a future settings screen
  // (Phase 7+) can flip them.
  bool enableBlocking = true;
  bool enableExtraTurnOnCapture = true;

  // Lets the UI show a one-off "X captured Y's token!" message without
  // re-showing it on every rebuild: the UI remembers the last event id
  // it displayed and compares against this one.
  int _captureEventId = 0;
  String? _lastCaptureMessage;

  final Random _random = Random();

  static const Duration _stepAnimationDelay = Duration(milliseconds: 260);
  static const Duration _autoPassDelay = Duration(milliseconds: 900);

  List<Player> get players => List.unmodifiable(_players);
  bool get isInitialized => _players.isNotEmpty;

  Player get currentPlayer => _players[_currentPlayerIndex];
  int get currentPlayerIndex => _currentPlayerIndex;

  int? get lastDiceValue => _lastDiceValue;
  GamePhase get phase => _phase;
  bool get isAnimating => _isAnimating;

  int get captureEventId => _captureEventId;
  String? get lastCaptureMessage => _lastCaptureMessage;

  /// The current player's tokens that can legally move with the last
  /// rolled value, right now. Empty outside [GamePhase.movePhase] or
  /// while a move is mid-animation.
  List<Token> get movableTokens {
    if (!isInitialized || _lastDiceValue == null) return const [];
    if (_phase != GamePhase.movePhase || _isAnimating) return const [];
    return GameRules.legalMovesForPlayer(
      currentPlayer,
      _lastDiceValue!,
      _players,
      enableBlocking: enableBlocking,
    );
  }

  Set<String> get movableTokenIds =>
      movableTokens.map((t) => t.id).toSet();

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
    _isAnimating = false;
    _captureEventId = 0;
    _lastCaptureMessage = null;
    notifyListeners();
  }

  /// Rolls the dice for the current player and stores the result so
  /// [movableTokens] (and Phase 5's move UI) can consume it. Returns the
  /// rolled value so the Dice widget's animation can land on it.
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
      // Fire-and-forget: if it turns out nothing can legally move,
      // auto-pass the turn after a short pause so the player can see
      // why, rather than getting stuck.
      _autoPassIfNoLegalMoves();
    }

    notifyListeners();
    return value;
  }

  Future<void> _autoPassIfNoLegalMoves() async {
    if (movableTokens.isNotEmpty) return;
    await Future.delayed(_autoPassDelay);
    // Re-check: state may have changed while we were waiting.
    if (_phase == GamePhase.movePhase && !_isAnimating && movableTokens.isEmpty) {
      _lastDiceValue = null;
      _advanceTurn();
      notifyListeners();
    }
  }

  /// Moves [token] by the last rolled value, animating it one cell at a
  /// time (per Phase 5's "no teleporting" requirement), then resolves
  /// captures (Phase 6) and hands off the turn.
  Future<void> moveToken(Token token) async {
    if (!isInitialized || _phase != GamePhase.movePhase || _isAnimating) return;
    if (token.color != currentPlayer.color) return;
    if (_lastDiceValue == null) return;

    final newStep = GameRules.computeNewStep(token, _lastDiceValue!);
    if (newStep == null) return; // illegal move, ignore silently

    if (enableBlocking && newStep >= 0 && newStep <= 50) {
      final destCell = BoardPath.absolutePosition(token.color, newStep);
      if (destCell != null &&
          GameRules.isBlockedForOpponent(_players, token.color, destCell)) {
        return; // destination is blocked by a stacked opponent pair
      }
    }

    _isAnimating = true;
    notifyListeners();

    final int startStep = token.step;
    if (startStep == -1) {
      // Leaving the yard is a single hop onto the start cell — there
      // are no intermediate cells to walk through.
      token.step = 0;
      notifyListeners();
      await Future.delayed(_stepAnimationDelay);
    } else {
      for (int s = startStep + 1; s <= newStep; s++) {
        token.step = s;
        notifyListeners();
        await Future.delayed(_stepAnimationDelay);
      }
    }

    bool captured = false;
    if (token.isOnSharedPath) {
      final cell = BoardPath.absolutePosition(token.color, token.step)!;
      final capturedTokens =
          GameRules.captureOpponentsAt(_players, token.color, cell);
      if (capturedTokens.isNotEmpty) {
        for (final t in capturedTokens) {
          t.step = -1; // sent back to yard
        }
        captured = true;
        _captureEventId++;
        _lastCaptureMessage = capturedTokens.length == 1
            ? '${token.color.label} captured ${capturedTokens.first.color.label}\'s token!'
            : '${token.color.label} captured ${capturedTokens.length} tokens!';
      }
    }

    _isAnimating = false;

    final bool rolledSix = _lastDiceValue == 6;
    _lastDiceValue = null;

    if (rolledSix || (captured && enableExtraTurnOnCapture)) {
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
