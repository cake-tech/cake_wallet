import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class AlertWithOneAction extends BaseAlertDialog {
  AlertWithOneAction({
    @required this.alertTitle,
    @required this.alertContent,
    @required this.buttonText,
    @required this.buttonAction,
    this.alertBarrierDismissible = true
  });

  final String alertTitle;
  final String alertContent;
  final String buttonText;
  final VoidCallback buttonAction;
  final bool alertBarrierDismissible;

  @override
  String get titleText => alertTitle;

  @override
  String get contentText => alertContent;

  @override
  bool get barrierDismissible => alertBarrierDismissible;

  @override
  Widget actionButtons(BuildContext context) {
    return Container(
      width: 300,
      height: 52,
      padding: EdgeInsets.only(left: 12, right: 12),
      color: Theme.of(context).accentTextTheme.body2.color,
      child: ButtonTheme(
        minWidth: double.infinity,
        child: FlatButton(
            onPressed: buttonAction,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Text(
              buttonText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                decoration: TextDecoration.none,
              ),
            )),
      ),
    );
  }
}