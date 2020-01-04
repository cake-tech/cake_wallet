import 'package:flutter/material.dart';

class SettingRawWidgetListRow extends StatelessWidget {
  final WidgetBuilder widgetBuilder;

  SettingRawWidgetListRow({@required this.widgetBuilder});

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Theme.of(context).accentTextTheme.headline.backgroundColor,
      child: widgetBuilder(context) ?? Container(),
    );
  }
}
