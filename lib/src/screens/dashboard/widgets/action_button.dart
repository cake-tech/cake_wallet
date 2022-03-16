import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  ActionButton(
      {@required this.image,
        @required this.title,
        this.route,
        this.onClick,
        this.alignment = Alignment.center});

  final Image image;
  final String title;
  final String route;
  final Alignment alignment;
  final void Function() onClick;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              if (route?.isNotEmpty ?? false) {
                Navigator.of(context, rootNavigator: true).pushNamed(route);
              } else {
                onClick?.call();
              }
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  shape: BoxShape.circle),
              child: image,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).accentTextTheme.display3
                    .backgroundColor),
          )
        ],
      ),
    );
  }
}