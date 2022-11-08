import 'package:flutter/material.dart';
import 'package:cake_wallet/view_model/settings/settings_list_item.dart';

class RegularListItem extends SettingsListItem {
  RegularListItem({required String title, this.handler}) : super(title);

  final void Function(BuildContext context)? handler;
}