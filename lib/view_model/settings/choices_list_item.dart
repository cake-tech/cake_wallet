import 'package:cake_wallet/view_model/settings/settings_list_item.dart';

class ChoicesListItem<ItemType> extends SettingsListItem {
  ChoicesListItem(
      {required String title,
      required this.selectedItem,
      required this.items,
      String Function(ItemType item)? displayItem,
      void Function(ItemType item)? onItemSelected})
      : _onItemSelected = onItemSelected,
        _displayItem = displayItem,
        super(title);

  final ItemType selectedItem;
  final List<ItemType> items;
  final String Function(ItemType item)? _displayItem;
  final void Function(ItemType item)? _onItemSelected;

  void onItemSelected(dynamic item) {
    if (item is ItemType) {
      _onItemSelected?.call(item);
    }
  }

  String displayItem(dynamic item) {
    if (item is ItemType && _displayItem != null) {
      return _displayItem!.call(item);
    }
    return item.toString();
  }
}
