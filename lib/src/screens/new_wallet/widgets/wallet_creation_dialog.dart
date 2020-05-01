import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class WalletCreationDialog extends BaseAlertDialog {
  WalletCreationDialog({
    @required this.dialogTitle,
    @required this.dialogContent,
    @required this.dialogButtonText,
    @required this.dialogButtonAction,
  });

  final String dialogTitle;
  final String dialogContent;
  final String dialogButtonText;
  final VoidCallback dialogButtonAction;

  @override
  String get titleText => dialogTitle;

  @override
  String get contentText => dialogContent;

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
            onPressed: dialogButtonAction,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Text(
              dialogButtonText,
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