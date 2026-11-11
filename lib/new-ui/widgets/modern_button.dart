import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";

enum ModernButtonShape { circle, roundedSquare }

class ModernButton extends StatelessWidget {
  const ModernButton({
    required this.size,
    required this.icon,
    required this.onPressed,
    super.key,
    this.iconSize,
    this.iconColor,
    this.backgroundColor,
    this.label,
    this.semanticLabel,
    this.shape = ModernButtonShape.circle,
    this.cornerRadius,
  }) : svgPath = null;

  const ModernButton.svg(
      {required this.size,
      required this.svgPath,
      required this.onPressed,
      super.key,
      this.iconSize,
      this.iconColor,
      this.backgroundColor,
      this.label,
      this.semanticLabel,
      this.shape = ModernButtonShape.circle,
      this.cornerRadius})
      : icon = null;
  final double size;
  final String? svgPath;
  final Widget? icon;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? iconSize;
  final String? label;

  final ModernButtonShape shape;
  final double? cornerRadius;
  final String? semanticLabel;
  static const iconSvgSizeRatio = 2 / 3;
  static const squareCornerRadiusRatio = 1 / 3;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? Theme.of(context).colorScheme.primary;
    final resolvedIconSize = iconSize ?? size * (svgPath != null ? 1 : iconSvgSizeRatio);
    final resolvedBackgroundColor =
        backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer;

    final isSquare = shape == ModernButtonShape.roundedSquare;
    final borderRadius = BorderRadius.circular(
      isSquare ? (cornerRadius ?? size * squareCornerRadiusRatio) : size,
    );
    final Widget resolvedIcon = svgPath != null
        ? CakeImageWidget(
            imageUrl: svgPath,
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

    // A single accessibility node for the whole control: the visible caption
    // duplicates the accessible name, so it is excluded to avoid a second,
    // detached stop for screen readers.
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: semanticLabel ?? label,
        child: Column(
          spacing: 8,
          children: [
            Container(
              decoration: BoxDecoration(
                color: resolvedBackgroundColor,
                borderRadius: borderRadius,
              ),
              width: size,
              height: size,
              child: IconButton(
                padding: EdgeInsets.zero,
                // Keep the pressed/ripple effect inside the rounded square.
                style: isSquare
                    ? IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: borderRadius),
                      )
                    : null,
                onPressed: onPressed,
                icon: ExcludeSemantics(child: resolvedIcon),
              ),
            ),
            if (label != null && label!.isNotEmpty)
              ExcludeSemantics(
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
