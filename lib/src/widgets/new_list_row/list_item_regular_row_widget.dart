import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
import 'package:flutter/material.dart';

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
  });

  final String keyValue;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final String? iconPath;
  final VoidCallback? onTap;
  final bool isFirstInSection;
  final bool isLastInSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListItemStyleWrapper(
        isFirstInSection: isFirstInSection,
        isLastInSection: isLastInSection,
        height: subtitle != null ? 60 : 48,
        builder: (context, textStyle, labelStyle) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if(iconPath != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Image.asset(
                        iconPath!,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: textStyle),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: labelStyle.copyWith(fontSize: 12),
                        ),
                    ],
                  ),
                ],
              ),

              Row(
                children: [
                  if (trailingText != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        trailingText!,
                        style: labelStyle,
                      ),
                    ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          );
        }
    );
  }
}
