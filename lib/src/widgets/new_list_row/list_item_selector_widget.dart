import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListItemStyleWrapper(
        isFirstInSection: isFirstInSection,
        isLastInSection: isLastInSection,
        builder: (context, textStyle, labelStyle) {
          return Row(
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
          );
        });
  }
}
