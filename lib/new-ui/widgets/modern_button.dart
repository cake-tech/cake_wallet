import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ModernButton extends StatelessWidget {
  final double size;
  final String? svgPath;
  final Widget? icon;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? iconSize;
  final String? label;
  static const iconSvgSizeRatio = 2/3;


  const ModernButton({
    super.key,
    required this.size,
    required this.icon,
    required this.onPressed,
    this.iconSize,
    this.iconColor,
    this.backgroundColor,
    this.label
  }) : svgPath = null;

  const ModernButton.svg({
    super.key,
    required this.size,
    required this.svgPath,
    required this.onPressed,
    this.iconSize,
    this.iconColor,
    this.backgroundColor,
    this.label
  }) : icon = null;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? Theme.of(context).colorScheme.primary;
    final resolvedIconSize = iconSize ?? size*(svgPath != null ? 1 : iconSvgSizeRatio);
    final resolvedBackgroundColor = backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer;
    final Widget resolvedIcon = svgPath != null
        ? SvgPicture.asset(
      svgPath!,
      width: resolvedIconSize,
      height: resolvedIconSize,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      allowDrawingOutsideViewBox: true,
      colorFilter: ColorFilter.mode(resolvedIconColor, BlendMode.srcIn),
    )
        : IconTheme(
      data: IconThemeData(color: resolvedIconColor, size: resolvedIconSize),
      child: icon!,
    );

    return Column(
      spacing: 8,
      children: [
        Container(
          decoration: BoxDecoration(
            color: resolvedBackgroundColor,
            borderRadius: BorderRadius.circular(size),
          ),
          width: size,
          height: size,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            icon: resolvedIcon,
          ),
        ),
        if(label != null && label!.isNotEmpty) Text(label!, style: TextStyle(fontSize:12, fontWeight: FontWeight.w400, color: Theme.of(context).colorScheme.onSurface),)

      ],
    );
  }
}