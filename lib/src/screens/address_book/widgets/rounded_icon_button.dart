import 'package:flutter/material.dart';

class RoundedIconButton extends StatelessWidget {
  const RoundedIconButton(
      {required this.icon,
      required this.onPressed,
      this.shape,
      this.width,
      this.height,
      this.iconSize,
      this.fillColor});

  final IconData icon;
  final VoidCallback onPressed;
  final ShapeBorder? shape;
  final double? width;
  final double? height;
  final double? iconSize;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return RawMaterialButton(
      onPressed: onPressed,
      fillColor: fillColor ?? colorScheme.surfaceContainerHighest,
      elevation: 0,
      constraints: BoxConstraints.tightFor(width: width ?? 24, height: height ?? 24),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: shape ?? const CircleBorder(),
      child: Icon(icon, size: iconSize ?? 14, color: colorScheme.onSurface),
    );
  }
}