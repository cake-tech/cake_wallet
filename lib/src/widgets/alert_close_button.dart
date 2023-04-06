import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class AlertCloseButton extends StatelessWidget {
  AlertCloseButton({this.isPositioned = true});

  final bool isPositioned;
  final String imagePath = 'assets/images/close.png';

  @override
  Widget build(BuildContext context) {
    final closeButton = GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Center(
          child: Image.asset(
            'assets/images/close.png',
            color: Palette.darkBlueCraiola,
          ),
        ),
      ),
    );
    return isPositioned
        ? Positioned(
            bottom: 60,
            child: closeButton,
          )
        : Center(child: closeButton);
  }
}
