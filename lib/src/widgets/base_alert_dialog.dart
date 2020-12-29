import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class BaseAlertDialog extends StatelessWidget {
  String get titleText => '';
  String get contentText => '';
  String get leftActionButtonText => '';
  String get rightActionButtonText => '';
  bool get isDividerExists => false;
  VoidCallback get actionLeft => () {};
  VoidCallback get actionRight => () {};
  bool get barrierDismissible => true;

  Widget title(BuildContext context) {
    return Text(
      titleText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w600,
        color: Theme.of(context).primaryTextTheme.title.color,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget content(BuildContext context) {
    return Text(
      contentText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        fontFamily: 'Lato',
        color: Theme.of(context).primaryTextTheme.title.color,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget actionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Flexible(
            child: Container(
              height: 52,
              padding: EdgeInsets.only(left: 6, right: 6),
              color: Theme.of(context).accentTextTheme.body2.decorationColor,
              child: ButtonTheme(
                minWidth: double.infinity,
                child: FlatButton(
                    onPressed: actionLeft,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    child: Text(
                      leftActionButtonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryTextTheme.body2
                            .backgroundColor,
                        decoration: TextDecoration.none,
                      ),
                    )),
              ),
            )
        ),
        Container(
          width: 1,
          height: 52,
          color: Theme.of(context).dividerColor,
        ),
        Flexible(
            child: Container(
              height: 52,
              padding: EdgeInsets.only(left: 6, right: 6),
              color: Theme.of(context).accentTextTheme.body1.backgroundColor,
              child: ButtonTheme(
                minWidth: double.infinity,
                child: FlatButton(
                    onPressed: actionRight,
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    child: Text(
                      rightActionButtonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryTextTheme.body1
                            .backgroundColor,
                        decoration: TextDecoration.none,
                      ),
                    )),
              ),
            )
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => barrierDismissible
      ? Navigator.of(context).pop()
      : null,
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration: BoxDecoration(color: PaletteDark.darkNightBlue.withOpacity(0.75)),
            child: Center(
              child: GestureDetector(
                onTap: () => null,
                child: ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  child: Container(
                    width: 300,
                    color: Theme.of(context).accentTextTheme.title.decorationColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
                              child: title(context),
                            ),
                            isDividerExists
                            ? Container(
                              height: 1,
                              color: Theme.of(context).dividerColor,
                            )
                            : Offstage(),
                            Padding(
                              padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
                              child: content(context),
                            )
                          ],
                        ),
                        Container(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        actionButtons(context)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}