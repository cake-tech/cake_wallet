import 'package:flutter/material.dart';

class SettingRawWidgetListRow extends StatelessWidget {
  SettingRawWidgetListRow({@required this.widgetBuilder});

  final WidgetBuilder widgetBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).accentTextTheme.title.backgroundColor,
      child: widgetBuilder(context) ?? Container(),
    );
  }
}
