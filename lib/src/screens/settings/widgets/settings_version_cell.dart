import 'package:flutter/material.dart';

class SettingsVersionCell extends StatelessWidget {
  SettingsVersionCell({@required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).primaryTextTheme.overline.color
            ),
          )
        ],
      ),
    );
  }
}