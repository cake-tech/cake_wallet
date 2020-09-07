import 'package:flutter/foundation.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';

class PickerListItem<ItemType> extends SettingsListItem {
  PickerListItem(
      {@required String title,
        @required this.selectedItem,
        @required this.setItem,
        @required this.items,
        this.isAlwaysShowScrollThumb = false})
      : super(title);

  final ItemType Function() selectedItem;
  final Function(ItemType value) setItem;
  final List<ItemType> items;
  final bool isAlwaysShowScrollThumb;
}
