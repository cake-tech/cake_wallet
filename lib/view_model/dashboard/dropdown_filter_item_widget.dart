import 'package:flutter/material.dart';

class DropdownFilterList extends StatelessWidget {
  const DropdownFilterList({
    Key? key,
    required this.items,
    required this.selectedItem,
    required this.onItemSelected,
    this.itemPrefix,
  }) : super(key: key);

  final List<String> items;
  final String selectedItem;
  final String? itemPrefix;
  final ValueChanged<String> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
          isDense: true,
          dropdownColor: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(10),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Text(
                  '${itemPrefix ?? ''} $item',
                  style: Theme.of(context).textTheme.titleMedium!,
                  maxLines: 1,
                ),
              )
              .toList(),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${itemPrefix ?? ''} $item',
                    style: (const TextStyle()).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
                ),
              )
              .toList(),
          value: selectedItem,
          onChanged: (value) {
            if (value != null) onItemSelected(value);
          },
          icon: Icon(Icons.keyboard_arrow_down_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
