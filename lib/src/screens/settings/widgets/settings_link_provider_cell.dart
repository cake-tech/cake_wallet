import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsLinkProviderCell extends StandardListRow {
  SettingsLinkProviderCell(
      {@required String title,
        @required this.icon,
        @required this.link,
        @required this.linkTitle})
      : super(title: title, isSelected: false, onTap: (BuildContext context) => _launchUrl(link) );

  final String icon;
  final String link;
  final String linkTitle;

  @override
  Widget buildLeading(BuildContext context) =>
      icon != null ? Image.asset(icon) : null;

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