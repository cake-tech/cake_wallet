import 'dart:ui';

import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class ConfirmModal extends StatelessWidget {
  ConfirmModal({
    @required this.alertTitle,
    @required this.alertContent,
    @required this.leftButtonText,
    @required this.rightButtonText,
    @required this.actionLeftButton,
    @required this.actionRightButton,
    this.leftActionColor,
    this.rightActionColor,
  });

  final String alertTitle;
  final Widget alertContent;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final VoidCallback actionRightButton;
  final Color leftActionColor;
  final Color rightActionColor;

  Widget actionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        ActionButton(
          buttonText: leftButtonText,
          action: actionLeftButton,
          backgoundColor: leftActionColor,
        ),
        Container(
          width: 1,
          height: 52,
          color: Theme.of(context).dividerColor,
        ),
        ActionButton(
          buttonText: rightButtonText,
          action: actionRightButton,
          backgoundColor: rightActionColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    width: 300, color: Theme.of(context).accentTextTheme.title.decorationColor, child: alertContent),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    @required this.buttonText,
    @required this.action,
    this.backgoundColor,
  });

  final String buttonText;
  final VoidCallback action;
  final Color backgoundColor;

  @override
  Widget build(BuildContext context) {
    return Flexible(
        child: Container(
      height: 52,
      padding: EdgeInsets.only(left: 6, right: 6),
      color: backgoundColor,
      child: ButtonTheme(
        minWidth: double.infinity,
        child: FlatButton(
            onPressed: action,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Text(
              buttonText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Lato',
                fontWeight: FontWeight.w600,
                color: backgoundColor != null ? Colors.white : Theme.of(context).primaryTextTheme.body1.backgroundColor,
                decoration: TextDecoration.none,
              ),
            )),
      ),
    ));
  }
}
