import 'package:cake_wallet/view_model/dashboard/filter_item.dart';

class DropdownFilterItem extends FilterItem {
  DropdownFilterItem({
    required String caption,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
  }) : super(
          value: () => false,
          caption: caption,
          onChanged: (_) {},
        );

  final List<String> items;
  final String selectedItem;
  final Function(String) onItemSelected;
}
