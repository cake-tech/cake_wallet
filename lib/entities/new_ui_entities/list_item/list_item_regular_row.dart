import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:flutter/material.dart';

class ListItemRegularRow extends ListItem {
  const ListItemRegularRow({
    required super.keyValue,
    required super.label,
    this.subtitle,
    this.trailingText,
    this.iconPath,
    this.onTap,
    this.trailingIconPath,
    this.showArrow = true,
    this.truncateTrailingText = false,
    this.foregroundColor,
    this.trailingIconSize
  });

  final String? subtitle;
  final String? trailingText;
  final String? iconPath;
  final String? trailingIconPath;
  final VoidCallback? onTap;
  final bool showArrow;
  final bool truncateTrailingText;
  final Color? foregroundColor;
  final double? trailingIconSize;
}
