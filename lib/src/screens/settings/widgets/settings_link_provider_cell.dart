import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsLinkProviderCell extends StandardListRow {
  SettingsLinkProviderCell(
      {@required String title,
        @required this.icon,
        this.iconColor,
        @required this.link,
        @required this.linkTitle})
      : super(title: title, isSelected: false, onTap: (BuildContext context) => _launchUrl(link) );

  final String icon;
  final String link;
  final String linkTitle;
  final Color iconColor;

  @override
  Widget buildLeading(BuildContext context) =>
      icon != null ? Image.asset(icon, color: iconColor) : null;

  @override
  Widget buildTrailing(BuildContext context) => Text(linkTitle,
      style: TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: Palette.blueCraiola));

  static void _launchUrl(String url) async {
    if (await canLaunch(url)) await launch(url);
  }
}