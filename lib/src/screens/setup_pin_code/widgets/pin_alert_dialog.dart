import 'dart:ui';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PinAlertDialog extends BaseAlertDialog {
  PinAlertDialog({
    @required this.pinTitleText,
    @required this.pinContentText,
    @required this.pinActionButtonText,
    @required this.pinAction,
    @required this.pinBarrierDismissible
  });

  final String pinTitleText;
  final String pinContentText;
  final String pinActionButtonText;
  final VoidCallback pinAction;
  final bool pinBarrierDismissible;

  @override
  String get titleText => pinTitleText;
  @override
  String get contentText => pinContentText;
  @override
  bool get barrierDismissible => pinBarrierDismissible;

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
            onPressed: pinAction,
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            child: Text(
              pinActionButtonText,
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