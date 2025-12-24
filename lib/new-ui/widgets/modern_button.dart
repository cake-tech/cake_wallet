import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ModernButton extends StatelessWidget {
  final double size;
  final String? svgPath;
  final Widget? icon;
  final VoidCallback onPressed;
  final Color? color;

  static const iconSvgSizeRatio = 2/3;


  const ModernButton({
    super.key,
    required this.size,
    required this.icon,
    required this.onPressed,
    this.color
  }) : svgPath = null;

  const ModernButton.svg({
    super.key,
    required this.size,
    required this.svgPath,
    required this.onPressed,
    this.color
  }) : icon = null;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final Widget resolvedIcon = svgPath != null
        ? SvgPicture.asset(
      svgPath!,
      width: size,
      height: size,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      allowDrawingOutsideViewBox: true,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    )
        : IconTheme(
      data: IconThemeData(color: color, size: size*iconSvgSizeRatio),
      child: icon!,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(size),
      ),
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: resolvedIcon,
      ),
    );
  }
}
