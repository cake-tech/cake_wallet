import 'package:flutter/foundation.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';
import 'package:flutter/material.dart';

class LinkListItem extends SettingsListItem {
  LinkListItem(
      {required String title,
        required this.link,
        required this.linkTitle,
        this.icon,
        this.hasIconColor = false})
      : super(title);

  final String? icon;
  final String link;
  final String linkTitle;
  final bool hasIconColor;
}