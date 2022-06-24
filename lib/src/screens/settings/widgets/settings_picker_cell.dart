import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';

class SettingsPickerCell<ItemType> extends StandardListRow {
  SettingsPickerCell(
      {@required String title,
      @required this.displayItem,
      this.selectedItem,
      this.items,
      this.onItemSelected})
      : super(
            title: title,
            isSelected: false,
            onTap: (BuildContext context) async {
              final selectedAtIndex = items.indexOf(selectedItem);

              await showPopUp<void>(
                  context: context,
                  builder: (_) => Picker(
                      items: items,
                      displayItem: displayItem,
                      selectedAtIndex: selectedAtIndex,
                      mainAxisAlignment: MainAxisAlignment.center,
                      onItemSelected: (ItemType item) =>
                          onItemSelected?.call(item)));
            });

  final ItemType selectedItem;
  final List<ItemType> items;
  final void Function(ItemType item) onItemSelected;
  final String Function(ItemType item) displayItem;

  @override
  Widget buildTrailing(BuildContext context) {
    return Text(
      displayItem?.call(selectedItem) ?? selectedItem.toString(),
      textAlign: TextAlign.right,
      style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).primaryTextTheme.overline.color),
    );
  }
}
