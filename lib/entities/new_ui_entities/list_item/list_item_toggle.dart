import 'package:flutter/material.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';

class ListItemToggle extends ListItem {
  const ListItemToggle({
    required super.keyValue,
    required super.label,
    required this.value,
    required this.onChanged,
  });

  final ValueChanged<bool> onChanged;
  final bool value;
}
