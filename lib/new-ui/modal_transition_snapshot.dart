import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class ModalTransitionSnapshot extends StatefulWidget {
  const ModalTransitionSnapshot({required this.child});

  final Widget child;

  @override
  State<ModalTransitionSnapshot> createState() => _ModalTransitionSnapshotState();
}

class _ModalTransitionSnapshotState extends State<ModalTransitionSnapshot> {
  final _controller = SnapshotController();
  Animation<double>? _animation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = CupertinoScaffold.of(context)?.animation;
    if (animation == _animation) {
      return;
    }
    _animation?.removeStatusListener(_onStatusChanged);
    _animation = animation?..addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) =>
      _controller.allowSnapshotting = status.isAnimating;

  @override
  void dispose() {
    _animation?.removeStatusListener(_onStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SnapshotWidget(controller: _controller, mode: SnapshotMode.permissive, child: widget.child);
}
