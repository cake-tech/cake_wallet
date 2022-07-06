import 'dart:ui';

import 'package:cake_wallet/palette.dart';
import 'package:flutter/material.dart';

class IoniaConfirmModal extends StatelessWidget {
  IoniaConfirmModal({
    @required this.alertTitle,
    @required this.alertContent,
    @required this.leftButtonText,
    @required this.rightButtonText,
    @required this.actionLeftButton,
    @required this.actionRightButton,
    this.leftActionColor,
    this.rightActionColor,
    this.hideActions = false,
  });

  final String alertTitle;
  final Widget alertContent;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final VoidCallback actionRightButton;
  final Color leftActionColor;
  final Color rightActionColor;
  final bool hideActions;

  Widget actionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        IoniaActionButton(
          buttonText: leftButtonText,
          action: actionLeftButton,
          backgoundColor: leftActionColor,
        ),
        Container(
          width: 1,
          height: 52,
          color: Theme.of(context).dividerColor,
        ),
        IoniaActionButton(
          buttonText: rightButtonText,
          action: actionRightButton,
          backgoundColor: rightActionColor,
        ),
      ],
    );
  }

  Widget title(BuildContext context) {
    return Text(
      alertTitle,
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
                  width: 327,
                  color: Theme.of(context).accentTextTheme.title.decorationColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: title(context),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 8),
                        child: Container(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      alertContent,
                      actionButtons(context),
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

class IoniaActionButton extends StatelessWidget {
  const IoniaActionButton({
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
