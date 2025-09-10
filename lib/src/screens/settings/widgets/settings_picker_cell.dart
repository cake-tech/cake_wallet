import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';

class SettingsPickerCell<ItemType> extends StandardListRow {
  SettingsPickerCell({
    required String title,
    required this.selectedItem,
    required this.items,
    this.displayItem,
    this.images,
    this.searchHintText,
    this.isGridView = false,
    this.matchingCriteria,
    this.onItemSelected,
    required this.currentTheme,
    Key? key,
  }) : super(
          title: title,
          isSelected: false,
          key: key,
          onTap: (BuildContext context) async {
            final selectedAtIndex = items.indexOf(selectedItem);

            await showPopUp<void>(
              context: context,
              builder: (_) => Picker(
                currentTheme: currentTheme,
                items: items,
                displayItem: displayItem,
                selectedAtIndex: selectedAtIndex,
                mainAxisAlignment: MainAxisAlignment.start,
                onItemSelected: (ItemType item) => onItemSelected?.call(item),
                images: images ?? const <Image>[],
                isSeparated: false,
                hintText: searchHintText,
                isGridView: isGridView,
                matchingCriteria: matchingCriteria,
              ),
            );
          },
        );

  final ItemType selectedItem;
  final List<ItemType> items;
  final void Function(ItemType item)? onItemSelected;
  final String Function(ItemType item)? displayItem;
  final List<Image>? images;
  final String? searchHintText;
  final bool isGridView;
  final bool Function(ItemType, String)? matchingCriteria;
  final MaterialThemeBase currentTheme;
  
  @override
  Widget buildTrailing(BuildContext context) {
    return Text(
      displayItem?.call(selectedItem) ?? selectedItem.toString(),
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
