import 'package:cake_wallet/entities/new_ui_entities/list_item/list_item.dart';
import 'package:flutter/material.dart';

class ListItemRegularRow extends ListItem {
  const ListItemRegularRow({
    required super.keyValue,
    required super.label,
    this.subtitle,
    this.trailingText,
    this.iconPath,
    this.badgeIconPath,
    this.onTap,
    this.trailingIconPath,
    this.showArrow = true,
    this.bottomWidget,
    this.trailingWidget,
    this.truncateTrailingText = false,
    this.foregroundColor,
    this.trailingIconSize,
    this.copyableText,
    this.leadingIconErrorWidget,
    this.leadingIconSize,
    this.badgeIconSize,
    this.iconColor,
  });

  final String? subtitle;
  final String? trailingText;
  final String? iconPath;
  final String? trailingIconPath;
  final String? badgeIconPath;
  final String? copyableText;
  final VoidCallback? onTap;
  final bool showArrow;
  final Widget? bottomWidget;
  final Widget? trailingWidget;
  final bool truncateTrailingText;
  final Color? foregroundColor;
  final double? trailingIconSize;
  final Widget? leadingIconErrorWidget;
  final double? leadingIconSize;
  final double? badgeIconSize;
  final Color? iconColor;
}
