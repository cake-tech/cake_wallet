import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'silent_payments_scanning_view_model.g.dart';

class SilentPaymentsScanningViewModel = SilentPaymentsScanningViewModelBase
    with _$SilentPaymentsScanningViewModel;

abstract class SilentPaymentsScanningViewModelBase with Store {
  SilentPaymentsScanningViewModelBase(this.wallet) {
    if (wallet.type == WalletType.bitcoin) {
      silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);
      _silentPaymentsAlwaysScan = bitcoin!.getAlwaysScanning(wallet);

      reaction((_) => (wallet as dynamic).silentPaymentsScanningActive, (_) {
        silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);
      });
      reaction((_) => (wallet as dynamic).alwaysScan, (_) {
        _silentPaymentsAlwaysScan = bitcoin!.getAlwaysScanning(wallet);
      });
    }
  }

  final WalletBase wallet;

  @observable
  bool doSingleScan = false;

  Future<bool> get isBitcoinMempoolAPIEnabled async =>
      wallet.type == WalletType.bitcoin && await bitcoin!.checkIfMempoolAPIIsEnabled(wallet);

  @action
  Future<List<String>> getSilentPaymentWallets() async {
    if (wallet.type != WalletType.bitcoin) {
      return [];
    }

    return bitcoin!.getSilentPaymentWallets(wallet);
  }

  @observable
  bool silentPaymentsScanningActive = false;

  bool getSilentPaymentsScanningActive() {
    return bitcoin!.getScanningActive(wallet);
  }

  @observable
  bool _silentPaymentsAlwaysScan = false;

  bool get silentPaymentsAlwaysScan => _silentPaymentsAlwaysScan;

  @action
  Future<void> setSilentPaymentsAlwaysScan(bool value) async {
    if (wallet.type == WalletType.bitcoin) {
      await bitcoin!.setAlwaysScanning(wallet, value);

      silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);
      _silentPaymentsAlwaysScan = bitcoin!.getAlwaysScanning(wallet);
    }
  }

  @action
  void allowSilentPaymentsScanning(bool allow) {
    if (wallet.type == WalletType.bitcoin) {
      bitcoin!.allowToSwitchNodesForScanning(wallet, allow);
    }
  }

  @action
  void setSilentPaymentsScanning(bool active) {
    if (wallet.type != WalletType.bitcoin) {
      return;
    }

    silentPaymentsScanningActive = active;

    bitcoin!.setScanningActive(wallet, active, true);
  }

  @action
  void rescan({required int rescanHeight}) {
    if (wallet.type != WalletType.bitcoin) {
      return;
    }

    silentPaymentsScanningActive = true;

    bitcoin!.rescan(
      wallet,
      height: rescanHeight,
      doSingleScan: doSingleScan,
    );
  }

  @action
  Future<void> doScan(
    BuildContext context, [
    int? height,
    bool? pop,
  ]) async {
    // if (pop == true) {
    //   Navigator.of(context).pop();
    // }

    if (height == null) {
      setSilentPaymentsScanning(true);
    } else {
      rescan(rescanHeight: height);
    }
  }

  Future<bool> toggleSilentPaymentsScanning(BuildContext context, [int? height, bool? pop]) async {
    if (wallet.type != WalletType.bitcoin) {
      return false;
    }

    // Already scanning and toggled, set to false now
    if (silentPaymentsScanningActive) {
      setSilentPaymentsScanning(false);
      return false;
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
      await showPopUp<void>(
        context: context,
        builder: (BuildContext _dialogContext) => AlertWithTwoActions(
          alertTitle: S.of(_dialogContext).change_current_node_title,
          alertContent: S.of(_dialogContext).confirm_silent_payments_switch_node,
          rightButtonText: S.of(_dialogContext).confirm,
          leftButtonText: S.of(_dialogContext).cancel,
          actionRightButton: () async {
            Navigator.of(_dialogContext).pop();

            allowSilentPaymentsScanning(true);

            doScan(context, height, pop);
          },
          actionLeftButton: () => Navigator.of(_dialogContext).pop(),
        ),
      );

      return true;
    }

    doScan(context, height, pop);
    return true;
  }
}
