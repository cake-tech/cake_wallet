import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:cake_wallet/themes/extensions/sync_indicator_theme.dart';
import 'package:flutter/material.dart';

class DropdownFilterList extends StatefulWidget {
  DropdownFilterList({
    Key? key,
    required this.items,
    this.textStyle,
    required this.caption,
    required this.selectedItem,
    required this.onItemSelected,
  }) : super(key: key);

  final List<String> items;
  final TextStyle? textStyle;
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<PickerTheme>()!.searchBackgroundFillColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Theme.of(context).extension<PickerTheme>()!.searchBackgroundFillColor,
          borderRadius: BorderRadius.circular(10),
          isExpanded: true,
          items: widget.items
              .map((item) => DropdownMenuItem<String>(
                    alignment: Alignment.center,
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(item, style: widget.textStyle),
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
    );
  }
}
