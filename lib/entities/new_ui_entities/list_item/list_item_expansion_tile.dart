import "package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart";
import "package:flutter/material.dart";


class ListItemExpansionTile extends ListItem {
  const ListItemExpansionTile({
    required super.keyValue,
    required super.label,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.children,
    this.subtitle,
    this.trailingText,
    this.iconPath,
    this.foregroundColor,
    this.onTap,
    this.trailingWidget,
  });

  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final List<ListItem> children;
  final String? subtitle;
  final String? trailingText;
  final String? iconPath;
  final Color? foregroundColor;
  final VoidCallback? onTap;
  final Widget? trailingWidget;
}
