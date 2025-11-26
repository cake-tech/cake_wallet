import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:flutter/material.dart';

class ListItemCheckbox extends ListItem {
  const ListItemCheckbox({
    required super.keyValue,
    required super.label,
    required this.value,
    required this.onChanged,
  });

  final ValueChanged<bool> onChanged;
  final bool value;
}
