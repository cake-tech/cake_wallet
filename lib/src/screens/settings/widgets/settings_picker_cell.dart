import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/generated/i18n.dart';

class SettingsPickerCell<ItemType> extends StandardListRow {
  SettingsPickerCell({@required String title, this.selectedItem, this.items,
    this.setItem, this.isAlwaysShowScrollThumb})
      : super(
      title: title,
      isSelected: false,
      onTap: (BuildContext context) async {
        final selectedAtIndex = items.indexOf(selectedItem);

        await showDialog<void>(
            context: context,
            builder: (_) => Picker(
                items: items,
                selectedAtIndex: selectedAtIndex,
                title: S.current.please_select,
                mainAxisAlignment: MainAxisAlignment.center,
                isAlwaysShowScrollThumb: isAlwaysShowScrollThumb,
                onItemSelected: (ItemType value) => setItem(value)));
      });

  final ItemType selectedItem;
  final List<ItemType> items;
  final Function(ItemType) setItem;
  final bool isAlwaysShowScrollThumb;

  @override
  Widget buildTrailing(BuildContext context) {
    return Text(
      selectedItem.toString(),
      textAlign: TextAlign.right,
      style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).primaryTextTheme.overline.color),
    );
  }
}