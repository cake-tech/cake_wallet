import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';

class SettingsLinkProviderCell extends StandardListRow {
  SettingsLinkProviderCell(
      {@required String title,
        @required this.icon,
        @required this.link,
        @required this.linkTitle})
      : super(title: title, isSelected: false);

  final String icon;
  final String link;
  final String linkTitle;

  @override
  Widget buildLeading(BuildContext context) =>
      icon != null ? Image.asset(icon) : null;

  @override
  Widget buildTrailing(BuildContext context) => Text(linkTitle,
      style: TextStyle(
          fontSize: 14.0, fontWeight: FontWeight.w500, color: Colors.blue));
}