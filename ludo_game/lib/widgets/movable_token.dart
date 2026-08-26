import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/player_color.dart';
import '../models/token.dart';

/// A single token on the board. When [isMovable] is true it gently
/// pulses to invite a tap; tapping plays a quick bounce before calling
/// [onTap] (which triggers the actual move in GameProvider).
class MovableToken extends StatefulWidget {
  final Token token;
  final Color color;
  final bool isMovable;
  final VoidCallback? onTap;

  const MovableToken({
    super.key,
    required this.token,
    required this.color,
    required this.isMovable,
    required this.onTap,
  });

  @override
  State<MovableToken> createState() => _MovableTokenState();
}

class _MovableTokenState extends State<MovableToken>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _syncPulsing();
  }

  @override
  void didUpdateWidget(covariant MovableToken oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMovable != widget.isMovable) {
      _syncPulsing();
    }
  }

  void _syncPulsing() {
    if (widget.isMovable) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  Future<void> _handleTap() async {
    if (!widget.isMovable || widget.onTap == null) return;
    _controller.stop();
    // Quick bounce feedback before the actual step-by-step move begins.
    await _controller.animateTo(1.0, duration: const Duration(milliseconds: 90));
    await _controller.animateTo(0.0, duration: const Duration(milliseconds: 90));
    widget.onTap!();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.token.color.label} token',
      button: widget.isMovable,
      child: GestureDetector(
        onTap: widget.isMovable ? _handleTap : null,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final scale = widget.isMovable ? _pulse.value : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              border: Border.all(
                color: Colors.white,
                width: widget.isMovable ? 3.w : 2.w,
              ),
              boxShadow: [
                if (widget.isMovable)
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.7),
                    blurRadius: 10.r,
                    spreadRadius: 1.r,
                  )
                else
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
          ),
        ),
      ),
    );
  }
}
