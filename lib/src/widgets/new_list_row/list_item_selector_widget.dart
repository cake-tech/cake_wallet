import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/src/widgets/new_list_row/list_Item_style_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
    this.onTap,
  });

  final String keyValue;
  final String label;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isFirstInSection;
  final bool isLastInSection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListItemStyleWrapper(
        onTap: onTap,
        isFirstInSection: isFirstInSection,
        isLastInSection: isLastInSection,
        builder: (context, textStyle, labelStyle) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, style: textStyle)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  spacing: 8,
                  children: [
                    Text(
                      options[selectedIndex],
                      style: labelStyle,
                    ),
                    CakeImageWidget(
                      imageUrl: "assets/new-ui/chooser.svg",
                      colorFilter:
                          ColorFilter.mode(theme.colorScheme.onSurfaceVariant, BlendMode.srcIn),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }
}
