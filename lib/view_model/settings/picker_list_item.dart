import 'package:flutter/foundation.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';
import 'package:flutter/material.dart';

class PickerListItem<ItemType> extends SettingsListItem {
  PickerListItem(
      {@required String title,
      @required this.selectedItem,
      @required this.items,
      this.displayItem,
      this.images,
      this.searchHintText,
      void Function(ItemType item) onItemSelected})
      : _onItemSelected = onItemSelected,
        super(title);

  final ItemType Function() selectedItem;
  final List<ItemType> items;
  final String Function(ItemType item) displayItem;
  final void Function(ItemType item) _onItemSelected;
  final List<Image> images;
  final String searchHintText;

  void onItemSelected(dynamic item) {
    if (item is ItemType) {
      _onItemSelected?.call(item);
    }
  }
}
