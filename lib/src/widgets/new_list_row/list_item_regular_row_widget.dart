import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/copy_wrapper.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ListItemRegularRowWidget extends StatelessWidget {
  const ListItemRegularRowWidget(
      {super.key,
      required this.keyValue,
      required this.label,
      this.subtitle,
      this.trailingText,
      this.iconPath,
      this.badgeIconPath,
      this.onTap,
      this.isFirstInSection = false,
      this.isLastInSection = false,
      this.showArrow = true,
      this.trailingIconPath,
      this.truncateTrailingText = false,
      this.foregroundColor,
      this.trailingIconSize,
      this.bottomWidget,
      this.trailingWidget,
      this.copyableText,
      this.leadingIconErrorWidget,
      this.leadingIconSize,
      this.badgeIconSize,
      this.iconColor});

  final String keyValue;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final String? iconPath;
  final String? badgeIconPath;
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
  final String? copyableText;
  final Widget? leadingIconErrorWidget;
  final double? leadingIconSize;
  final double? badgeIconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trailingTextToShow =
        truncateTrailingText && trailingText != null && trailingText!.length > 20
            ? "${trailingText!.substring(0, 17)}..."
            : trailingText;

    return CopyWrapper(
      data: copyableText != null ? ClipboardData(text: copyableText!) : null,
      builder: (context, copied) => AnimatedSwitcher(
        duration: Duration(milliseconds: 150),
        child: ListItemStyleWrapper(
            key: ValueKey(copied),
            backgroundColor: copied ? Theme.of(context).colorScheme.surfaceContainerHigh : null,
            onTap: onTap,
            iconPath: iconPath,
            isFirstInSection: isFirstInSection,
            isLastInSection: isLastInSection,
            builder: (context, textStyle, labelStyle) {
              final leadingIcon = iconPath != null
                  ? CakeImageWidget(
                      imageUrl: iconPath!,
                      width: leadingIconSize ?? 24,
                      height: leadingIconSize ?? 24,
                      errorWidget: leadingIconErrorWidget,
                      colorFilter:
                          iconColor == null ? null : ColorFilter.mode(iconColor!, BlendMode.srcIn),
                    )
                  : null;

              final imageWidget = badgeIconPath != null
                  ? Stack(
                      clipBehavior: Clip.none,
                      children: [
                        leadingIcon!,
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: theme.colorScheme.surfaceContainerHigh,
                                width: 2,
                              ),
                              color: theme.colorScheme.onSurface,
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CakeImageWidget(
                              imageUrl: badgeIconPath!,
                              width: badgeIconSize ?? 12,
                              height: badgeIconSize ?? 12,
                              fit: BoxFit.cover,
                              color: theme.colorScheme.surface,
                              errorWidget: leadingIconErrorWidget,
                            ),
                          ),
                        ),
                      ],
                    )
                  : leadingIcon;
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
                                child: imageWidget ?? SizedBox(),
                              ),
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (copied)
                                    Text(
                                      S.of(context).copied,
                                      style: textStyle.copyWith(
                                          color: Theme.of(context).colorScheme.primary),
                                    )
                                  else
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
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                trailingTextToShow,
                                style: labelStyle,
                              ),
                            ),
                          if (trailingWidget != null)
                            trailingWidget!
                          else if (trailingIconPath != null)
                            CakeImageWidget(
                              imageUrl: trailingIconPath!,
                              height: trailingIconSize ?? 18,
                              width: trailingIconSize ?? 18,
                              colorFilter: ColorFilter.mode(
                                  foregroundColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
                                  BlendMode.srcIn),
                            )
                          else if (showArrow)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7.0),
                              child: CakeImageWidget(
                                  imageUrl: "assets/new-ui/arrow_forward.svg",
                                  height: 14,
                                  color: theme.colorScheme.onSurfaceVariant),
                            )
                        ],
                      ),
                    ],
                  ),
                  if (bottomWidget != null) bottomWidget!
                ],
              );
            }),
      ),
    );
  }
}
