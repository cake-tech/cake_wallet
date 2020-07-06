import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';

class SettingsCellWithArrow extends StandardListRow {
  SettingsCellWithArrow({@required String title})
      : super(title: title, isSelected: false);

  @override
  Widget buildTrailing(BuildContext context) =>
      Image.asset('assets/images/select_arrow.png',
          color: Theme.of(context).primaryTextTheme.caption.color);
}