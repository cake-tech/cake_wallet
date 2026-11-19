import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
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

  /// Accessible name announced by screen readers. Falls back to [label] (the
  /// visible caption) when omitted, so one of the two is required. Must be
  /// localized by the caller.
  final String? semanticLabel;
  static const iconSvgSizeRatio = 2 / 3;

  const ModernButton(
      {super.key,
      required this.size,
      required this.icon,
      required this.onPressed,
      this.iconSize,
      this.iconColor,
      this.backgroundColor,
      this.label,
      this.semanticLabel})
      : svgPath = null;

  const ModernButton.svg(
      {super.key,
      required this.size,
      required this.svgPath,
      required this.onPressed,
      this.iconSize,
      this.iconColor,
      this.backgroundColor,
      this.label,
      this.semanticLabel})
      : icon = null;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? Theme.of(context).colorScheme.primary;
    final resolvedIconSize = iconSize ?? size * (svgPath != null ? 1 : iconSvgSizeRatio);
    final resolvedBackgroundColor =
        backgroundColor ?? Theme.of(context).colorScheme.surfaceContainer;
    final Widget resolvedIcon = svgPath != null
        ? CakeImageWidget(
            imageUrl: svgPath!,
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
                borderRadius: BorderRadius.circular(size),
              ),
              width: size,
              height: size,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onPressed,
                icon: ExcludeSemantics(child: resolvedIcon),
              ),
            ),
            if (label != null && label!.isNotEmpty)
              ExcludeSemantics(
                // The caption can be longer than the circle (Tamil
                // "தொகையை அமைக்கவும்"); bound it to the button width so rows of
                // buttons cannot overflow the screen.
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: size + 16),
                  // Tamil "தொகையை அமைக்கவும்" needs more room than the
                  // circle gives; shrink to fit rather than break mid-word.
                  child: AutoSizeText(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    // The "copied" confirmation is one long word in Tamil
                    // ("நகலெடுக்கப்பட்டது") and cannot wrap, so allow a deep
                    // shrink and never clip silently.
                    minFontSize: 6,
                    overflow: TextOverflow.ellipsis,
                    wrapWords: false,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
