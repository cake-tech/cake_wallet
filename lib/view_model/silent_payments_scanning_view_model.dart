import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/standard_checkbox.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_core/sync_status.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'silent_payments_scanning_view_model.g.dart';

class SilentPaymentsScanningViewModel = SilentPaymentsScanningViewModelBase
    with _$SilentPaymentsScanningViewModel;

abstract class SilentPaymentsScanningViewModelBase with Store {
  SilentPaymentsScanningViewModelBase(this.wallet) {
    silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);
    _silentPaymentsAlwaysScan = bitcoin!.getAlwaysScanning(wallet);

    reaction((_) => wallet.syncStatus, (SyncStatus syncStatus) {
      silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);
      _silentPaymentsAlwaysScan = bitcoin!.getAlwaysScanning(wallet);
    });
  }

  final WalletBase wallet;

  @observable
  bool doSingleScan = false;

  Future<bool> get isBitcoinMempoolAPIEnabled async =>
      wallet.type == WalletType.bitcoin && await bitcoin!.checkIfMempoolAPIIsEnabled(wallet);

  @action
  Future<List<String>> getSilentPaymentWallets() async {
    return bitcoin!.getSilentPaymentWallets(wallet);
  }

  @observable
  bool silentPaymentsScanningActive = false;

  @observable
  bool _silentPaymentsAlwaysScan = false;

  bool get silentPaymentsAlwaysScan => _silentPaymentsAlwaysScan;

  Future<void> setSilentPaymentsAlwaysScan(bool value) {
    return bitcoin!.setAlwaysScanning(wallet, value);
  }

  @action
  void allowSilentPaymentsScanning(bool allow) {
    bitcoin!.allowToSwitchNodesForScanning(wallet, allow);
  }

  @action
  void setSilentPaymentsScanning(bool active, [String? address]) {
    silentPaymentsScanningActive = active;

    bitcoin!.setScanningActive(wallet, active, address, true);
  }

  @action
  void rescan({required int rescanHeight, String? address}) {
    silentPaymentsScanningActive = true;

    bitcoin!.rescan(
      wallet,
      address: address,
      height: rescanHeight,
      doSingleScan: doSingleScan,
    );
  }

  @action
  Future<void> doScan(String walletChoice, [int? height]) async {
    if (height == null) {
      setSilentPaymentsScanning(true, walletChoice);
    } else {
      rescan(rescanHeight: height, address: walletChoice);
    }
  }

  Future<void> toggleSilentPaymentsScanning(BuildContext context, [int? height]) async {
    // Already scanning and toggled, set to false now
    if (silentPaymentsScanningActive) {
      return setSilentPaymentsScanning(false);
    }

    final wallets = await bitcoin!.getSilentPaymentWallets(wallet);
    String walletChoice = wallets.first;

    if (wallets.length > 1) {
      bool cancelled = false;

      await showPopUp<void>(
        context: context,
        builder: (BuildContext context) => DoubleCheckboxAlert(
          value1:
              '${wallets[0].substring(0, 9 + 5)}...${wallets[0].substring(wallets[0].length - 9, wallets[0].length)}',
          value2:
              '${wallets[1].substring(0, 9 + 5)}...${wallets[1].substring(wallets[1].length - 9, wallets[1].length)}',
          alertTitle: S.of(context).cakepay_confirm_purchase,
          leftButtonText: S.of(context).cancel,
          rightButtonText: S.of(context).confirm,
          actionLeftButton: () {
            cancelled = true;
            Navigator.of(context).pop();
          },
          actionRightButton: (choice) {
            walletChoice = wallets.firstWhere(
              (wallet) => wallet.startsWith(choice.substring(0, 9 + 5)),
            );
            Navigator.of(context).pop();
          },
        ),
      );

      if (cancelled) {
        return;
      }
    }

    late bool isElectrsSPEnabled;
    try {
      isElectrsSPEnabled =
          await bitcoin!.getNodeIsElectrsSPEnabled(wallet).timeout(const Duration(seconds: 3));
    } on TimeoutException {
      isElectrsSPEnabled = false;
    }

    final needsToSwitch = isElectrsSPEnabled == false;
    if (needsToSwitch) {
      return showPopUp<void>(
        context: context,
        builder: (BuildContext _dialogContext) => AlertWithTwoActions(
          alertTitle: S.of(_dialogContext).change_current_node_title,
          alertContent: S.of(_dialogContext).confirm_silent_payments_switch_node,
          rightButtonText: S.of(_dialogContext).confirm,
          leftButtonText: S.of(_dialogContext).cancel,
          actionRightButton: () async {
            Navigator.of(_dialogContext).pop();

            allowSilentPaymentsScanning(true);

            doScan(walletChoice, height);
          },
          actionLeftButton: () => Navigator.of(_dialogContext).pop(),
        ),
      );
    }

    doScan(walletChoice, height);
  }
}

class DoubleCheckboxAlert extends BaseAlertDialog {
  DoubleCheckboxAlert({
    required this.alertTitle,
    required this.leftButtonText,
    required this.rightButtonText,
    required this.actionLeftButton,
    required this.actionRightButton,
    required this.value1,
    required this.value2,
    this.alertBarrierDismissible = true,
    Key? key,
  });

  final String alertTitle;
  final String leftButtonText;
  final String rightButtonText;
  final VoidCallback actionLeftButton;
  final Function(String) actionRightButton;
  final bool alertBarrierDismissible;

  bool checkbox1 = false;
  void toggleCheckbox1() => checkbox1 = !checkbox1;
  bool checkbox2 = false;
  void toggleCheckbox2() => checkbox2 = !checkbox2;

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

  String choice = '';

  void setChoice(String value) {
    choice = value;
  }

  @override
  VoidCallback get actionRight => () {
        actionRightButton(choice);
      };

  @override
  bool get barrierDismissible => alertBarrierDismissible;

  String value1;
  String value2;

  @override
  Widget content(BuildContext context) {
    return CheckboxAlertContent(
      checkbox1: checkbox1,
      value1: value1,
      toggleCheckbox1: toggleCheckbox1,
      checkbox2: checkbox2,
      value2: value2,
      toggleCheckbox2: toggleCheckbox2,
      setChoice: setChoice,
    );
  }
}

class CheckboxAlertContent extends StatefulWidget {
  CheckboxAlertContent({
    required this.checkbox1,
    required this.value1,
    required this.toggleCheckbox1,
    required this.checkbox2,
    required this.value2,
    required this.toggleCheckbox2,
    required this.setChoice,
    Key? key,
  }) : super(key: key);

  bool checkbox1;
  String value1;
  void Function() toggleCheckbox1;
  bool checkbox2;
  String value2;
  void Function() toggleCheckbox2;

  void Function(String) setChoice;

  @override
  _CheckboxAlertContentState createState() => _CheckboxAlertContentState(
        checkbox1: checkbox1,
        value1: value1,
        toggleCheckbox1: toggleCheckbox1,
        checkbox2: checkbox2,
        value2: value2,
        toggleCheckbox2: toggleCheckbox2,
        setChoice: setChoice,
      );

  static _CheckboxAlertContentState? of(BuildContext context) {
    return context.findAncestorStateOfType<_CheckboxAlertContentState>();
  }
}

class _CheckboxAlertContentState extends State<CheckboxAlertContent> {
  _CheckboxAlertContentState({
    required this.checkbox1,
    required this.value1,
    required this.toggleCheckbox1,
    required this.checkbox2,
    required this.value2,
    required this.toggleCheckbox2,
    required this.setChoice,
  });

  bool checkbox1;
  String value1;
  void Function() toggleCheckbox1;
  bool checkbox2;
  String value2;
  void Function() toggleCheckbox2;

  void Function(String) setChoice;

  bool showValidationMessage = true;

  bool get areAllCheckboxesChecked => checkbox1 && checkbox2;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StandardCheckbox(
            value: checkbox1,
            caption: value1,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  setChoice(value1);
                  checkbox1 = value!;
                  checkbox2 = !checkbox1;
                  toggleCheckbox1();
                  showValidationMessage = !areAllCheckboxesChecked;
                }
              });
            },
          ),
          StandardCheckbox(
            value: checkbox2,
            caption: value2,
            onChanged: (bool? value) {
              setState(() {
                if (value == true) {
                  setChoice(value2);
                  checkbox2 = value!;
                  checkbox1 = !checkbox2;
                  toggleCheckbox2();
                  showValidationMessage = !areAllCheckboxesChecked;
                }
              });
            },
          ),
          if (showValidationMessage)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Please select one option',
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
