import 'package:flutter/material.dart';

class DirectionalAnimatedSwitcher extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const DirectionalAnimatedSwitcher({
    super.key,
    required this.child,
    required this.duration,
  });

  @override
  State<DirectionalAnimatedSwitcher> createState() => _DirectionalAnimatedSwitcherState();
}

class _DirectionalAnimatedSwitcherState extends State<DirectionalAnimatedSwitcher> {
  bool _isForward = true;

  @override
  void didUpdateWidget(DirectionalAnimatedSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldKey = (oldWidget.child.key as ValueKey<int>).value;
    final newKey = (widget.child.key as ValueKey<int>).value;

    if (newKey != oldKey) {
      _isForward = newKey > oldKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: widget.duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final double offset = _isForward ? 1.2 : -1.2;

        final inTween = Tween(begin: Offset(offset, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutCubic));

        final outTween = Tween(begin: Offset(-offset, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutCubic));

        if (child.key == widget.child.key) {
          return SlideTransition(position: animation.drive(inTween), child: child);
        } else {
          return SlideTransition(position: animation.drive(outTween), child: child);
        }
      },
      child: widget.child,
    );
  }
}
