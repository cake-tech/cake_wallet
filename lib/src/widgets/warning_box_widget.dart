import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:flutter/material.dart';

class WarningBox extends StatelessWidget {
  const WarningBox({
    required this.content,
    this.showBorder = true,
    this.textColor,
    this.textAlign,
    this.iconSize,
    this.padding,
    this.iconSpacing,
    this.textWeight,
    this.showIcon = true,
    super.key,
  });

  final String content;
  final bool showBorder;
  final Color? textColor;
  final TextAlign? textAlign;
  final double? iconSize;
  final EdgeInsets? padding;
  final double? iconSpacing;
  final FontWeight? textWeight;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.customColors.warningContainerColor,
        borderRadius: BorderRadius.all(Radius.circular(12)),
        border: showBorder
            ? Border.all(
                color: context.customColors.warningOutlineColor,
                width: 2.0,
              )
            : null,
      ),
      child: Row(
        children: [
          if (showIcon)
            Icon(
              Icons.warning_amber_rounded,
              size: iconSize ?? 64,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          SizedBox(width: iconSpacing ?? 6),
          Expanded(
            child: Text(
              content,
              textAlign: textAlign ?? TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: textWeight ?? FontWeight.w800,
                    color: textColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
