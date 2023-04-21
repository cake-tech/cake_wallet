import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class AlertCloseButton extends StatelessWidget {
  AlertCloseButton({this.image, this.bottom});

  final Image? image;
  final double? bottom;

  final closeButton = Image.asset(
    'assets/images/close.png',
    color: Palette.darkBlueCraiola,
  );

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom ?? 60,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Center(
            child: image ?? closeButton,
          ),
        ),
      ),
    );
  }
}
