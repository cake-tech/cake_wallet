import 'package:flutter/material.dart';
import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';

class ListItemToggle extends ListItem {
  const ListItemToggle({
    required super.keyValue,
    required super.label,
    this.subtitle,
    this.iconPath,
    required this.value,
    required this.onChanged,
    this.leadingEndWidget,
  });

  final String? subtitle;
  final String? iconPath;
  final ValueChanged<bool> onChanged;
  final Widget? leadingEndWidget;
  final bool value;
}
