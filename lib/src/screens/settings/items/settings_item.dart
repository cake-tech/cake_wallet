import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/settings/attributes.dart';

class SettingsItem {
  SettingsItem(
      {required this.onTaped,
      required this.title,
      required this.link,
      required this.image,
      required this.widget,
      required this.attribute,
      required this.widgetBuilder});

  final VoidCallback onTaped;
  final String title;
  final String link;
  final Image image;
  final Widget widget;
  final Attributes attribute;
  final WidgetBuilder widgetBuilder;
}
