import 'package:flutter/material.dart';

/// A pulsing colored outline drawn over the current player's yard, so
/// it's always obvious whose turn it is just by glancing at the board.
class CurrentTurnGlow extends StatefulWidget {
  final Color color;
  final Rect rect;

  const CurrentTurnGlow({super.key, required this.color, required this.rect});

  @override
  State<CurrentTurnGlow> createState() => _CurrentTurnGlowState();
}

class _CurrentTurnGlowState extends State<CurrentTurnGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: widget.rect,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double t = _controller.value;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.35 + 0.5 * t),
                  width: 3 + 2 * t,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
