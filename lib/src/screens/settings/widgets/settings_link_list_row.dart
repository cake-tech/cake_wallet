import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class SettingsLinktListRow extends StatelessWidget {
  final VoidCallback onTaped;
  final String title;
  final String link;
  final Image image;

  SettingsLinktListRow({@required this.onTaped, this.title, this.link, this.image});

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Theme.of(context).accentTextTheme.headline.backgroundColor,
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 20.0, right: 20.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            image != null ? image : Offstage(),
            Container(
              padding: image != null ? EdgeInsets.only(left: 10) : null,
              child: Text(
                title,
                style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryTextTheme.title.color
                ),
              ),
            )
          ],
        ),
        trailing: Text(
          link,
          style:
          TextStyle(fontSize: 14.0, color: Palette.cakeGreen),
        ),
        onTap: onTaped,
      ),
    );
  }

}