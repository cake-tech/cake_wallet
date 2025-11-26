import 'package:flutter/material.dart';

class ListItemDropdownWidget extends StatelessWidget {
  const ListItemDropdownWidget({
    super.key,
    required this.keyValue,
    required this.label,
    this.trailingText,
    required this.onTap,
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String keyValue;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;
  final bool isFirstInSection;
  final bool isLastInSection;

  BorderRadius get radius => BorderRadius.vertical(
        top: Radius.circular(isFirstInSection ? 16 : 0),
        bottom: Radius.circular(isLastInSection ? 16 : 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.surfaceContainerHigh;

    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontFamily: 'Wix Madefor Text',
      color: theme.colorScheme.onSurface,
    );

    final labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Wix Madefor Text',
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ClipRRect(
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            border: isLastInSection
                ? null
                : Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: textStyle),
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
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
