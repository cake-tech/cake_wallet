import "dart:ui";

import "package:cake_wallet/utils/show_pop_up.dart";
import "package:flutter/material.dart";

class LongPressPopupBuilder extends StatelessWidget {
  const LongPressPopupBuilder({
    required this.child,
    required this.popup,
    super.key,
    this.spacing = 8,
    this.showOnTap = false,
    this.footer,
  });

  final Widget child;
  final Widget popup;
  final Widget? footer;
  final double spacing;
  final bool showOnTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: () => _showMenu(context),
        onTap: showOnTap ? () => _showMenu(context) : null,
        child: IgnorePointer(ignoring: showOnTap, child: child),
      );

  void _showMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showPopUp(
      context: context,
      builder: (context) => _buildPopup(context, offset, size),
    );
  }

  Widget _buildPopup(BuildContext context, Offset offset, Size size) {
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isOnRightHalf = offset.dx + (size.width / 2) > screenWidth / 2;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Stack(
        children: [
          Positioned(
            left: offset.dx,
            top: offset.dy,
            width: size.width,
            height: size.height,
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
          Positioned(
            left: isOnRightHalf ? null : offset.dx,
            right: isOnRightHalf ? (screenWidth - (offset.dx + size.width)) : null,
            top: offset.dy + size.height + spacing,
            child: Material(
              color: Colors.transparent,
              child: popup,
            ),
          ),
          if (footer != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).viewPadding.bottom,
              child: footer!,
            ),
        ],
      ),
    );
  }
}
