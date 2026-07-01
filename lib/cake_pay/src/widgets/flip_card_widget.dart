import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 400),
    this.flipOnTouch = true,
  });

  final Widget front;
  final Widget back;
  final Duration duration;
  final bool flipOnTouch;

  @override
  FlipCardState createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
  AnimationController(vsync: this, duration: widget.duration);
  bool _isFront = true;

  void toggleCard() {
    if (_isFront) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final angle = _ctrl.value * math.pi;
        final isFront = angle < math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: isFront ? widget.front
              : Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: widget.back,
          ),
        );
      },
    );

    return widget.flipOnTouch
        ? GestureDetector(onTap: toggleCard, child: content)
        : content;
  }
}
