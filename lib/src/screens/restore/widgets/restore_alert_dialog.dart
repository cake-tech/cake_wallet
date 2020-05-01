import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class RestoreAlertDialog extends BaseAlertDialog {
  RestoreAlertDialog({
    @required this.restoreTitle,
    @required this.restoreContent,
    @required this.restoreButtonText,
    @required this.restoreButtonAction,
  });

  final String restoreTitle;
  final String restoreContent;
  final String restoreButtonText;
  final VoidCallback restoreButtonAction;

  @override
  String get titleText => restoreTitle;

  @override
  String get contentText => restoreContent;

  @override
  Widget actionButtons(BuildContext context) {
    return Container(
      width: 300,
      height: 52,
      padding: EdgeInsets.only(left: 12, right: 12),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24)
          ),
          color: Colors.white
      ),
      child: ButtonTheme(
        minWidth: double.infinity,
        child: FlatButton(
            onPressed: restoreButtonAction,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Text(
              restoreButtonText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
                decoration: TextDecoration.none,
              ),
            )),
      ),
    );
  }

}