import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
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
    return ListItemStyleWrapper(
      isFirstInSection: isFirstInSection,
      isLastInSection: isLastInSection,
      builder: (context, textStyle, labelStyle) {
        return InkWell(
          onTap: onTap,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
