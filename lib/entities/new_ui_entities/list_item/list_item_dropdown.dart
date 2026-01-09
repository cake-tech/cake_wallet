import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:flutter/material.dart';

class ListItemDropdown extends ListItem {
  const ListItemDropdown({
    required super.keyValue,
    required super.label,
    this.trailingText,
    required this.onTap,
  });

  final String? trailingText;
  final VoidCallback onTap;
}
