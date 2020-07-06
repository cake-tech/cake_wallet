import 'package:flutter/foundation.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';

class PickerListItem<ItemType> extends SettingsListItem {
  PickerListItem(
      {@required String title,
        @required this.selectedItem,
        @required this.items})
      : super(title);

  final ItemType Function() selectedItem;
  final List<ItemType> items;
}
