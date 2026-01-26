import 'dart:math';

import 'package:flutter/material.dart';

class ConfirmSwiper extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String swiperText;

  const ConfirmSwiper({super.key, required this.onConfirmed, required this.swiperText});

  @override
  State<ConfirmSwiper> createState() => _ConfirmSwiperState();
}

class _ConfirmSwiperState extends State<ConfirmSwiper> {
  double pillHorizontalPadding = 4;
  double pillVerticalPadding = 2;
  double pillSize = 48;
  late double drag;

  @override
  void initState() {
    super.initState();
    setState(() {
      drag = pillHorizontalPadding;
    });
  }

  @override
  Widget build(BuildContext context) {
    final areaWidth = MediaQuery.of(context).size.width * 0.77;

    final radius = (pillSize + pillHorizontalPadding * 2) / 2;

    return GestureDetector(
      onHorizontalDragUpdate: (d) {
        setState(() {
          drag = max(pillHorizontalPadding,
              min(areaWidth - pillSize - pillHorizontalPadding, drag + d.delta.dx));
        });
      },
      onHorizontalDragEnd: (_) {
        if (drag > areaWidth - 80) {
          widget.onConfirmed();
          setState(() => drag = pillHorizontalPadding);
        } else {
          setState(() => drag = pillHorizontalPadding);
        }
      },
      child: SizedBox(
        height: pillSize + pillHorizontalPadding * 2,
        width: areaWidth,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipPath(
              clipper: TrackClipper(
                cut: drag - pillHorizontalPadding,
                radius: radius,
              ),
              child: Container(
                height: pillSize + pillHorizontalPadding * 2,
                width: areaWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(99999),
                ),
                child: Center(child: FlowingText(text: widget.swiperText, opacity: 1 - (drag / (areaWidth - pillSize)))),
              ),
            ),
            Positioned(
              left: drag,
              child: Container(
                height: pillSize,
                width: pillSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackClipper extends CustomClipper<Path> {
  final double cut;
  final double radius;

  TrackClipper({required this.cut, required this.radius});

  @override
  Path getClip(Size size) {
    final left = cut.clamp(0.0, size.width);
    final rect = Rect.fromLTRB(left, 0, size.width, size.height);
    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
  }

  @override
  bool shouldReclip(covariant TrackClipper oldClipper) {
    return oldClipper.cut != cut;
  }
}

class FlowingText extends StatefulWidget {
  const FlowingText({super.key, required this.text, required this.opacity});

  final String text;
  final double opacity;

  @override
  State<FlowingText> createState() => _FlowingTextState();
}

class _FlowingTextState extends State<FlowingText> with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
        lowerBound: -1.0,
        upperBound: 2.0)
      ..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          return ShaderMask(
            shaderCallback: (r) {
              return LinearGradient(
                begin: Alignment(-1 + (controller.value) * 2, 0),
                end: Alignment(controller.value * 2, 0),
                colors: [Colors.transparent, Theme.of(context).colorScheme.surfaceContainerHighest, Colors.transparent],
              ).createShader(r);
            },
            blendMode: BlendMode.srcATop,
            child: Text(
              widget.text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w400,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}
