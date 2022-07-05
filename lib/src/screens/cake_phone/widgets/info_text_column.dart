import 'package:flutter/material.dart';

class InfoTextColumn extends StatelessWidget {
  const InfoTextColumn({
    Key key,
    @required this.title,
    @required this.subtitle,
    this.isReversed = false,
    this.padding,
  }) : super(key: key);

  final String title;
  final String subtitle;
  final bool isReversed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: isReversed ? subtitleTextStyle(context) : titleTextStyle(context),
        ),
        Padding(
          padding: padding ?? const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: isReversed ? titleTextStyle(context) : subtitleTextStyle(context),
          ),
        ),
      ],
    );
  }

  TextStyle subtitleTextStyle(BuildContext context) => TextStyle(
        fontSize: 12,
        color: Theme.of(context).accentTextTheme.subhead.color,
      );

  TextStyle titleTextStyle(BuildContext context) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).primaryTextTheme.title.color,
      );
}
