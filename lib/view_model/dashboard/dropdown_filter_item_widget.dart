import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/menu_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:flutter/material.dart';

class DropdownFilterList extends StatefulWidget {
  DropdownFilterList({
    Key? key,
    required this.items,
    required this.caption,
    required this.selectedItem,
    required this.onItemSelected,
  }) : super(key: key);

  final List<String> items;
  final String caption;
  final String selectedItem;
  final Function(String) onItemSelected;

  @override
  _DropdownFilterListState createState() => _DropdownFilterListState();
}

class _DropdownFilterListState extends State<DropdownFilterList> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.selectedItem;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).extension<SyncIndicatorTheme>()!.syncedBackgroundColor,
              border: Border.all(
                color: Theme.of(context).extension<FilterTheme>()!.checkboxBoundsColor,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              dropdownColor: Theme.of(context).extension<CakeMenuTheme>()!.backgroundColor,
              isExpanded: true,
              items: widget.items
                  .map((item) => DropdownMenuItem<String>(
                        alignment: Alignment.center,
                        value: item,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(item),
                        ),
                      ))
                  .toList(),
              value: selectedValue,
              onChanged: (newValue) {
                setState(() => selectedValue = newValue);
                widget.onItemSelected(newValue!);
              },
            ),
          ),
        ],
      ),
    );
  }
}
