import 'dart:ui';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/themes/extensions/alert_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';

class AlertWithThreeActions extends BaseAlertDialog {
  AlertWithThreeActions({
    required this.alertTitle,
    required this.alertContent,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.centerButtonText,
    required this.actionLeftButton,
    required this.actionRightButton,
    required this.actionCenterButton,
    this.alertBarrierDismissible = true,
    this.isDividerExist = false,
    // this.leftActionColor,
    // this.rightActionColor,
  });

  final String alertTitle;
  final String alertContent;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final VoidCallback actionRightButton;
  final VoidCallback actionCenterButton;
  final bool alertBarrierDismissible;
  // final Color leftActionColor;
  // final Color rightActionColor;
  final bool isDividerExist;

  @override
  String get titleText => alertTitle;
  @override
  String get contentText => alertContent;
  @override
  String get leftActionButtonText => leftButtonText;
  @override
  String get rightActionButtonText => rightButtonText;
  @override
  VoidCallback get actionLeft => actionLeftButton;
  @override
  VoidCallback get actionRight => actionRightButton;
  @override
  bool get barrierDismissible => alertBarrierDismissible;
  @override
  bool get isDividerExists => isDividerExist;

  String centerButtonText;
  VoidCallback get actionCenter => actionCenterButton;

  @override
  Widget actionButtons(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: actionCenter,
          style: TextButton.styleFrom(
              backgroundColor: leftActionButtonColor ?? Theme.of(context).dialogBackgroundColor,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.zero))),
          child: Text(
            centerButtonText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontFamily: 'Lato',
              fontWeight: FontWeight.w600,
              color: leftActionButtonTextColor ??
                  Theme.of(context).extension<AlertTheme>()!.leftButtonTextColor,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Container(
          height: 60,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: TextButton(
                    onPressed: actionLeft,
                    style: TextButton.styleFrom(
                        backgroundColor:
                            leftActionButtonColor ?? Theme.of(context).dialogBackgroundColor,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.zero))),
                    child: Text(
                      leftActionButtonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color: leftActionButtonTextColor ??
                            Theme.of(context).extension<AlertTheme>()!.leftButtonTextColor,
                        decoration: TextDecoration.none,
                      ),
                    )),
              ),
              const VerticalSectionDivider(),
              Expanded(
                child: TextButton(
                    onPressed: actionRight,
                    style: TextButton.styleFrom(
                        backgroundColor:
                            rightActionButtonColor ?? Theme.of(context).dialogBackgroundColor,
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.zero))),
                    child: Text(
                      rightActionButtonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w600,
                        color: rightActionButtonTextColor ?? Theme.of(context).primaryColor,
                        decoration: TextDecoration.none,
                      ),
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
