import 'player_color.dart';
import 'token.dart';

/// One participant in the match: a color plus their 4 tokens.
class Player {
  final PlayerColor color;
  final bool isAI;
  final List<Token> tokens;

  Player({required this.color, this.isAI = false})
      : tokens = List.generate(4, (i) => Token(color: color, slot: i));

  bool get hasWon => tokens.every((t) => t.isFinished);

  int get tokensInYard => tokens.where((t) => t.isInYard).length;

  int get tokensFinished => tokens.where((t) => t.isFinished).length;
}
