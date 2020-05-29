import 'package:flutter/material.dart';

class SettingsLinktListRow extends StatelessWidget {
  SettingsLinktListRow(
      {@required this.onTaped, this.title, this.link, this.image});

  final VoidCallback onTaped;
  final String title;
  final String link;
  final Image image;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).accentTextTheme.title.backgroundColor,
      child: ListTile(
        contentPadding: EdgeInsets.only(left: 24.0, right: 24.0),
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
                    fontSize: 14.0,
                    color: Theme.of(context).primaryTextTheme.title.color),
              ),
            )
          ],
        ),
        trailing: Text(
          link,
          style: TextStyle(fontSize: 14.0, color: Colors.blue),
        ),
        onTap: onTaped,
      ),
    );
  }
}
