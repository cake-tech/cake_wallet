import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class SettingRawWidgetListRow extends StatelessWidget {
  SettingRawWidgetListRow({@required this.widgetBuilder});

  final WidgetBuilder widgetBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PaletteDark.menuList,
      child: widgetBuilder(context) ?? Container(),
    );
  }
}
