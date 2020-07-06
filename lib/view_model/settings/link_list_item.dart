import 'package:flutter/foundation.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';

class LinkListItem extends SettingsListItem {
  LinkListItem(
      {@required String title,
        @required this.link,
        @required this.linkTitle,
        this.icon})
      : super(title);

  final String icon;
  final String link;
  final String linkTitle;
}