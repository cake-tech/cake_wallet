import 'package:flutter/material.dart';

class ListItemSelectorWidget extends StatelessWidget {
  const ListItemSelectorWidget({
    super.key,
    required this.keyValue,
    required this.label,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.isFirstInSection = false,
    this.isLastInSection = false,
  });

  final String keyValue;
  final String label;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
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
                Text(
                  options[selectedIndex],
                  style: labelStyle,
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
