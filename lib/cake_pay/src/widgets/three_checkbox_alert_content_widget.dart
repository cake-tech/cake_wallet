import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ThreeCheckboxAlert extends BaseAlertDialog {
  ThreeCheckboxAlert({
    required this.alertTitle,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.actionLeftButton,
    required this.actionRightButton,
    this.alertBarrierDismissible = true,
    Key? key,
  });

  final String alertTitle;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final Function(bool, bool, bool) actionRightButton;
  final bool alertBarrierDismissible;

  bool checkbox1 = false;
  void toggleCheckbox1() => checkbox1 = !checkbox1;
  bool checkbox2 = false;
  void toggleCheckbox2() => checkbox2 = !checkbox2;
  bool checkbox3 = false;
  void toggleCheckbox3() => checkbox3 = !checkbox3;

  bool showValidationMessage = true;

  @override
  String get titleText => alertTitle;

  @override
  bool get isDividerExists => true;

  @override
  String get leftActionButtonText => leftButtonText;

  @override
  String get rightActionButtonText => rightButtonText;

  @override
  VoidCallback get actionLeft => actionLeftButton;

  @override
  VoidCallback get actionRight => () {
    actionRightButton(checkbox1, checkbox2, checkbox3);
  };

  @override
  bool get barrierDismissible => alertBarrierDismissible;

  @override
  Widget content(BuildContext context) {
    return ThreeCheckboxAlertContent(
      checkbox1: checkbox1,
      toggleCheckbox1: toggleCheckbox1,
      checkbox2: checkbox2,
      toggleCheckbox2: toggleCheckbox2,
      checkbox3: checkbox3,
      toggleCheckbox3: toggleCheckbox3,
    );
  }
}

class ThreeCheckboxAlertContent extends StatefulWidget {
  ThreeCheckboxAlertContent({
    required this.checkbox1,
    required this.toggleCheckbox1,
    required this.checkbox2,
    required this.toggleCheckbox2,
    required this.checkbox3,
    required this.toggleCheckbox3,
    Key? key,
  }) : super(key: key);

  bool checkbox1;
  void Function() toggleCheckbox1;
  bool checkbox2;
  void Function() toggleCheckbox2;
  bool checkbox3;
  void Function() toggleCheckbox3;

  @override
  _ThreeCheckboxAlertContentState createState() => _ThreeCheckboxAlertContentState(
    checkbox1: checkbox1,
    toggleCheckbox1: toggleCheckbox1,
    checkbox2: checkbox2,
    toggleCheckbox2: toggleCheckbox2,
    checkbox3: checkbox3,
    toggleCheckbox3: toggleCheckbox3,
  );

  static _ThreeCheckboxAlertContentState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ThreeCheckboxAlertContentState>();
  }
}

class _ThreeCheckboxAlertContentState extends State<ThreeCheckboxAlertContent> {
  _ThreeCheckboxAlertContentState({
    required this.checkbox1,
    required this.toggleCheckbox1,
    required this.checkbox2,
    required this.toggleCheckbox2,
    required this.checkbox3,
    required this.toggleCheckbox3,
  });

  bool checkbox1;
  void Function() toggleCheckbox1;
  bool checkbox2;
  void Function() toggleCheckbox2;
  bool checkbox3;
  void Function() toggleCheckbox3;

  bool showValidationMessage = true;

  bool get areAllCheckboxesChecked => checkbox1 && checkbox2 && checkbox3;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StandardCheckbox(
            value: checkbox1,
            caption: S.of(context).cakepay_confirm_no_vpn,
            onChanged: (bool? value) {
              setState(() {
                checkbox1 = value ?? false;
                toggleCheckbox1();
                showValidationMessage = !areAllCheckboxesChecked;
              });
            },
          ),
          StandardCheckbox(
            value: checkbox2,
            caption: S.of(context).cakepay_confirm_voided_refund,
            onChanged: (bool? value) {
              setState(() {
                checkbox2 = value ?? false;
                toggleCheckbox2();
                showValidationMessage = !areAllCheckboxesChecked;
              });
            },
          ),
          StandardCheckbox(
            value: checkbox3,
            caption: S.of(context).cakepay_confirm_terms_agreed,
            onChanged: (bool? value) {
              setState(() {
                checkbox3 = value ?? false;
                toggleCheckbox3();
                showValidationMessage = !areAllCheckboxesChecked;
              });
            },
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => launchUrl(
              Uri.parse("https://cakepay.com/cakepay-web-terms.txt"),
              mode: LaunchMode.externalApplication,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                S.of(context).settings_terms_and_conditions,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w400,
                  color: Colors.blueAccent,
                  decoration: TextDecoration.none,
                  height: 1,
                ),
                softWrap: true,
              ),
            ),
          ),
          if (showValidationMessage)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Please confirm all checkboxes',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontFamily: 'Lato',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
