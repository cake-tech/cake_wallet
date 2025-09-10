import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';

class SettingsPriorityPickerCell<ItemType> extends StandardListRow {
  SettingsPriorityPickerCell(
      {required String title,
      required this.selectedItem,
      required this.items,
      this.displayItem,
      this.images,
      this.searchHintText,
      this.isGridView = false,
      this.matchingCriteria,
      this.customValue,
      this.maxValue,
      this.customItemIndex,
      this.onItemSelected,
      required this.currentTheme})
      : super(
            title: title,
            isSelected: false,
            onTap: (BuildContext context) async {
              var selectedAtIndex = items.indexOf(selectedItem);
              double sliderValue = customValue ?? 0.0;

              await showPopUp<void>(
                context: context,
                builder: (BuildContext context) {
                  return StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Picker(
                        currentTheme: currentTheme,
                        items: items,
                        displayItem: (ItemType item) => displayItem!(item, sliderValue.round()),
                        selectedAtIndex: selectedAtIndex,
                        customItemIndex: customItemIndex,
                        maxValue: maxValue,
                        headerEnabled: false,
                        closeOnItemSelected: false,
                        mainAxisAlignment: MainAxisAlignment.center,
                        sliderValue: sliderValue,
                        onSliderChanged: (double newValue) =>
                            setState(() => sliderValue = newValue),
                        onItemSelected: (ItemType priority) {
                          setState(() => selectedAtIndex = items.indexOf(priority));
                          onItemSelected?.call(priority, sliderValue);
                        },
                      );
                    },
                  );
                },
              );
              onItemSelected?.call(items[selectedAtIndex], sliderValue);
            });

  final ItemType selectedItem;
  final List<ItemType> items;
  final void Function(ItemType item, double customValue)? onItemSelected;
  final String Function(ItemType item, int value)? displayItem;
  final List<Image>? images;
  final String? searchHintText;
  final bool isGridView;
  final bool Function(ItemType, String)? matchingCriteria;
  double? customValue;
  double? maxValue;
  int? customItemIndex;
  final MaterialThemeBase currentTheme;

  @override
  Widget buildTrailing(BuildContext context) {
    return Text(
      displayItem?.call(selectedItem, customValue?.round() ?? 0) ?? selectedItem.toString(),
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
