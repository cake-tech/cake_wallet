import 'package:flutter/foundation.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';
import 'package:flutter/material.dart';

class PickerListItem<ItemType extends Object> extends SettingsListItem {
  PickerListItem(
      {required String title,
      required this.selectedItem,
      required this.items,
      this.displayItem,
      this.images,
      this.searchHintText,
      this.isGridView = false,
      void Function(ItemType item)? onItemSelected,
      bool Function(ItemType item, String searchText)? matchingCriteria})
      : _onItemSelected = onItemSelected,
        _matchingCriteria = matchingCriteria,
        super(title);

  final ItemType Function() selectedItem;
  final List<ItemType> items;
  final String Function(ItemType item)? displayItem;
  final void Function(ItemType item)? _onItemSelected;
  final List<Image>? images;
  final String? searchHintText;
  final bool isGridView;
  final bool Function(ItemType, String)? _matchingCriteria;

  void onItemSelected(dynamic item) {
    if (item is ItemType) {
      _onItemSelected?.call(item);
    }
  }

  bool matchingCriteria(dynamic item, String searchText) {
    if (item is ItemType) {
      return _matchingCriteria?.call(item, searchText) ?? false;
    }
    return true;
  }
}
