import 'package:flutter/material.dart';

class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key,});


  final double size = 5;
  final Color color = const Color(0xFFFFC414);
  final Duration fadeOutDuration = const Duration(milliseconds: 2000);
  final Duration restDuration = const Duration(milliseconds: 2000);
  final double restOpacity = 0.3;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.fadeOutDuration,
      reverseDuration: Duration.zero,
      value: 1.0,
    );
    _loop();
  }

  Future<void> _loop() async {
    while (mounted) {
      await controller.animateTo(
        widget.restOpacity,
        curve: Curves.easeOutQuad,
        duration: widget.fadeOutDuration,
      );
      await Future.delayed(widget.restDuration);
      controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}