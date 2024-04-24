import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/themes/extensions/picker_theme.dart';
import 'package:flutter/material.dart';

class DropdownFilterList extends StatefulWidget {
  DropdownFilterList({
    Key? key,
    required this.items,
    this.itemPrefix,
    this.textStyle,
    required this.caption,
    required this.selectedItem,
    required this.onItemSelected,
  }) : super(key: key);

  final List<String> items;
  final String? itemPrefix;
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
    return DropdownButtonHideUnderline(
      child: Container(
        child: DropdownButton<String>(
          isExpanded: true,
          icon: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.arrow_drop_down, color: Theme.of(context).extension<PickerTheme>()!.searchIconColor),
              ],
            ),
          ),
          dropdownColor: Theme.of(context).extension<PickerTheme>()!.searchBackgroundFillColor,
          borderRadius: BorderRadius.circular(10),
          items: widget.items
              .map((item) => DropdownMenuItem<String>(
                    alignment: Alignment.bottomCenter,
                    value: item,
                    child: AutoSizeText('${widget.itemPrefix ?? ''} $item', style: widget.textStyle),
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
