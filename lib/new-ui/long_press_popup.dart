import 'dart:ui';

import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';

class LongPressPopupBuilder extends StatelessWidget {
  const LongPressPopupBuilder({super.key, required this.child, required this.popup, this.spacing=8});

  final Widget child;
  final Widget popup;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final offset = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        showPopUp(
          context: context,
          builder: (context) => _buildPopup(context, offset, size),
        );
      },
      child: child,
    );
  }

  Widget _buildPopup(BuildContext context, Offset offset, Size size) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
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
            left: offset.dx*2,
            top: offset.dy + size.height + spacing,
            child: Material(
              color: Colors.transparent,
              child: popup,
            ),
          ),
        ],
      ),
    );
  }
}
