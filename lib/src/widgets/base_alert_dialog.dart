import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class BaseAlertDialog extends StatelessWidget {
  String get titleText => '';
  String get contentText => '';
  String get leftActionButtonText => '';
  String get rightActionButtonText => '';
  VoidCallback get actionLeft => () {};
  VoidCallback get actionRight => () {};

  Widget title(BuildContext context) {
    return Text(
      titleText,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
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
        fontWeight: FontWeight.w600,
        color: Colors.white,
        decoration: TextDecoration.none,
      ),
    );
  }

  Widget actionButtons(BuildContext context) {
    return Container(
      width: 300,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24)
        ),
        color: Colors.white
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Flexible(
            child: Container(
              padding: EdgeInsets.only(left: 12, right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24)),
              ),
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
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                      decoration: TextDecoration.none,
                    ),
                  )),
              ),
            )
          ),
          Container(
            height: 52,
            width: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          Flexible(
            child: Container(
              padding: EdgeInsets.only(left: 12, right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(24)),
              ),
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
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                        decoration: TextDecoration.none,
                      ),
                    )),
              ),
            )
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration: BoxDecoration(color: PaletteDark.historyPanel.withOpacity(0.75)),
            child: Center(
              child: GestureDetector(
                onTap: () => null,
                child: Container(
                  width: 300,
                  height: 257,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    color: PaletteDark.menuHeader
                  ),
                  child: Column(
                    //mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                        width: 300,
                        height: 77,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24)
                          ),
                        ),
                        child: Center(
                          child: title(context),
                        ),
                      ),
                      Container(
                        width: 300,
                        height: 1,
                        color: PaletteDark.menuList,
                      ),
                      Container(
                        width: 300,
                        height: 127,
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: content(context),
                        ),
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
    );
  }
}