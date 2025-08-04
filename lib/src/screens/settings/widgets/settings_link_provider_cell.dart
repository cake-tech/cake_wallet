import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsLinkProviderCell extends StandardListRow {
  SettingsLinkProviderCell(
      {required String title,
      required this.link,
      required this.linkTitle,
      this.icon,
      this.iconColor})
      : super(title: title, isSelected: false, onTap: (BuildContext context) => _launchUrl(link));

  final String link;
  final String linkTitle;
  final String? icon;
  final Color? iconColor;

  @override
  Widget? buildLeading(BuildContext context) =>
      icon != null ? Image.asset(icon!, color: iconColor, height: 24, width: 24) : null;

  @override
  Widget buildTrailing(BuildContext context) => Text(
        linkTitle,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
      );

  static void _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {}
  }
}
