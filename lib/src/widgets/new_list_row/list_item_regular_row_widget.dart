import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ListItemRegularRowWidget extends StatelessWidget {
  const ListItemRegularRowWidget({
    super.key,
    required this.keyValue,
    required this.label,
    this.subtitle,
    this.trailingText,
    this.iconPath,
    this.onTap,
    this.isFirstInSection = false,
    this.isLastInSection = false,
    this.showArrow = true,
    this.trailingIconPath,
    this.truncateTrailingText = false,
    this.foregroundColor,
    this.trailingIconSize,
    this.bottomWidget,
    this.trailingWidget
  });

  final String keyValue;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final String? iconPath;
  final VoidCallback? onTap;
  final bool isFirstInSection;
  final bool isLastInSection;
  final bool showArrow;
  final String? trailingIconPath;
  final Widget? bottomWidget;
  final Widget? trailingWidget;
  final bool truncateTrailingText;
  final Color? foregroundColor;
  final double? trailingIconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingTextToShow =
        truncateTrailingText && trailingText != null && trailingText!.length > 20
            ? "${trailingText!.substring(0, 17)}..."
            : trailingText;

    return ListItemStyleWrapper(
      onTap: onTap,
        iconPath: iconPath,
        isFirstInSection: isFirstInSection,
        isLastInSection: isLastInSection,
        builder: (context, textStyle, labelStyle) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (iconPath != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: CakeImageWidget(imageUrl: iconPath!, width: 24,height: 24,)
                          ),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label,
                                  style: foregroundColor == null
                                      ? textStyle
                                      : textStyle.copyWith(color: foregroundColor)),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: labelStyle.copyWith(fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (trailingTextToShow != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 4.0, right: 8.0),
                          child: Text(
                            trailingTextToShow,
                            style: labelStyle,
                          ),
                        ),
                      if (trailingWidget != null)
                        trailingWidget!
                      else if (trailingIconPath != null)
                        CakeImageWidget(imageUrl:
                        trailingIconPath!,
                          height: trailingIconSize ?? 18,
                          width:trailingIconSize ?? 18,
                          colorFilter: ColorFilter.mode(foregroundColor ?? Theme.of(context).colorScheme.onSurfaceVariant,BlendMode.srcIn),
                        )
                      else if (showArrow)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7.0),
                            child: CakeImageWidget(imageUrl:
                            "assets/new-ui/arrow_forward.svg",
                                height: 14,
                                color: theme.colorScheme.onSurfaceVariant
                            ),
                          )
                    ],
                  ),
                ],
              ),
              if (bottomWidget != null) bottomWidget!
            ],
          );
        });
  }
}
