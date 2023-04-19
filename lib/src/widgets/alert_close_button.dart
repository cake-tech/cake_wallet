import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class AlertCloseButton extends StatelessWidget {
  AlertCloseButton({this.image, this.bottom, this.isPositioned = true});

  final Image? image;
  final double? bottom;
  final bool isPositioned;

  final closeButton = Image.asset(
    'assets/images/close.png',
    color: Palette.darkBlueCraiola,
  );

  @override
  Widget build(BuildContext context) {
    final closeButtonContent = GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(
          child: image ?? closeButton,
        ),
      ),
    );
    return isPositioned
        ? Positioned(
            bottom: bottom ?? 60,
            child: closeButtonContent,
          )
        : closeButtonContent;
  }
}
