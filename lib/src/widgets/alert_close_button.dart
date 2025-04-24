import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class AlertCloseButton extends StatelessWidget {
  AlertCloseButton({
    this.image,
    this.bottom,
    this.onTap,
    this.isPositioned = true,
    super.key,
  });

  final VoidCallback? onTap;

  final Image? image;
  final double? bottom;
  final bool isPositioned;

  final closeButton = Image.asset(
    'assets/images/close.png',
    color: Palette.darkBlueCraiola,
  );

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
        onTap: onTap ?? () => Navigator.of(context).pop(),
        child: Semantics(
            label: S.of(context).close,
            button: true,
            enabled: true,
            child: Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(child: image ?? closeButton))));

    return isPositioned ? Positioned(bottom: bottom ?? 60, child: button) : button;
  }
}
