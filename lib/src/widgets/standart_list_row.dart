import 'package:flutter/material.dart';

class StandartListRow extends StatelessWidget {
  StandartListRow(
      {this.title,
      this.value,
      this.isDrawTop = false,
      this.isDrawBottom = false});

  final String title;
  final String value;
  final bool isDrawTop;
  final bool isDrawBottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        isDrawTop
            ? Container(
                width: double.infinity,
                height: 1,
                color: Theme.of(context).dividerColor,
              )
            : Offstage(),
        Container(
          width: double.infinity,
          color: Theme.of(context).accentTextTheme.title.backgroundColor,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).primaryTextTheme.caption.color),
                      textAlign: TextAlign.left),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context)
                                .primaryTextTheme
                                .title
                                .color)),
                  )
                ]),
          ),
        ),
        isDrawBottom
            ? Container(
                width: double.infinity,
                height: 1,
                color: Theme.of(context).dividerColor,
              )
            : Offstage(),
      ],
    );
  }
}
