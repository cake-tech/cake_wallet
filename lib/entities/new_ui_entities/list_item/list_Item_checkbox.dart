import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:flutter/material.dart';

class ListItemCheckbox extends ListItem {
  const ListItemCheckbox({
    required super.keyValue,
    required super.label,
    this.subtitle,
    this.iconPath,
    this.onTap,
    this.showArrow = false,
    required this.value,
    required this.onChanged,
  });

  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;
  final bool value;
  final String? subtitle;
  final String? iconPath;
  final bool showArrow;
}
