import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class YatCloseButton extends StatelessWidget {
  YatCloseButton({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onClose,
        child: Container(
            height: 28,
            width: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Palette.manatee,
                shape: BoxShape.circle
            ),
            child: Icon(
                Icons.clear,
                color: Colors.white,
                size: 20)
        )
    );
  }
}