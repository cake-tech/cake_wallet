import 'dart:ui';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:flutter/cupertino.dart';

class ReconnectAlertDialog extends BaseAlertDialog {
  ReconnectAlertDialog({
    @required this.reconnectTitleText,
    @required this.reconnectContentText,
    @required this.reconnectLeftActionButtonText,
    @required this.reconnectRightActionButtonText,
    @required this.reconnectActionLeft,
    @required this.reconnectActionRight
  });

  final String reconnectTitleText;
  final String reconnectContentText;
  final String reconnectLeftActionButtonText;
  final String reconnectRightActionButtonText;
  final VoidCallback reconnectActionLeft;
  final VoidCallback reconnectActionRight;

  @override
  String get titleText => reconnectTitleText;
  @override
  String get contentText => reconnectContentText;
  @override
  String get leftActionButtonText => reconnectLeftActionButtonText;
  @override
  String get rightActionButtonText => reconnectRightActionButtonText;
  @override
  VoidCallback get actionLeft => reconnectActionLeft;
  @override
  VoidCallback get actionRight => reconnectActionRight;
}