import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class StandartListRow extends StatelessWidget {
  final String title;
  final String value;

  StandartListRow({this.title, this.value});

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title,
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).primaryTextTheme.overline.color),
                textAlign: TextAlign.left),
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      color: Palette.wildDarkBlue)),
            )
          ]),
    );
  }
}
