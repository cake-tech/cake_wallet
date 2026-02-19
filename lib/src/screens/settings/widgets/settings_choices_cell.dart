import 'package:cake_wallet/view_model/settings/choices_list_item.dart';
import 'package:flutter/material.dart';

class SettingsChoicesCell extends StatelessWidget {
  const SettingsChoicesCell(this.choicesListItem,
      {this.useGenericColor = true, this.padding, Key? key})
      : super(key: key);

  final ChoicesListItem<dynamic> choicesListItem;
  final bool useGenericColor;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final items = choicesListItem.items;
    final selectedIndex = items.indexOf(choicesListItem.selectedItem);
    final itemCount = items.length;

    return Container(
      color: useGenericColor ? Theme.of(context).colorScheme.surface : null,
      padding: padding ?? const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (choicesListItem.title.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  choicesListItem.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: useGenericColor
                    ? null
                    : Border.all(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        width: 1.5,
                      ),
                color: useGenericColor
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : null,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / itemCount;
                  return Stack(
                    children: [
                      if (selectedIndex >= 0)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          left: selectedIndex * itemWidth,
                          top: 0,
                          bottom: 0,
                          width: itemWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      Row(
                        children: items.map((dynamic e) {
                          final isSelected = choicesListItem.selectedItem == e;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => choicesListItem.onItemSelected.call(e),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                color: Colors.transparent,
                                child: Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeInOut,
                                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.onPrimary
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontWeight:
                                              isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                    child: Text(choicesListItem.displayItem.call(e)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}