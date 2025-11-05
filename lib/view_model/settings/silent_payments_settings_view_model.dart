import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/encryption_log_utils.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';
import 'package:path_provider/path_provider.dart';

part 'silent_payments_settings_view_model.g.dart';

class SilentPaymentsSettingsViewModel = SilentPaymentsSettingsViewModelBase
    with _$SilentPaymentsSettingsViewModel;

abstract class SilentPaymentsSettingsViewModelBase with Store {
  SilentPaymentsSettingsViewModelBase(this._settingsStore, this._wallet);

  final SettingsStore _settingsStore;
  final WalletBase _wallet;

  @computed
  bool get silentPaymentsCardDisplay => _settingsStore.silentPaymentsCardDisplay;

  @computed
  bool get silentPaymentsAlwaysScan => bitcoin!.getIsAlwaysScanningSP(_wallet);

  @action
  void setSilentPaymentsCardDisplay(bool value) {
    _settingsStore.silentPaymentsCardDisplay = value;
  }

  @action
  void setSilentPaymentsAlwaysScan(bool value) {
    bitcoin!.setIsAlwaysScanningSP(_wallet, value);
    if (value) bitcoin!.setScanningActive(_wallet, true);
  }

  Future<String> getAbbreviatedLogs() async {
    final appSupportPath = (await getApplicationSupportDirectory()).path;
    final fpath = "$appSupportPath/logs/debug.log";
    final logsFile = File(fpath);
    if (!logsFile.existsSync()) {
      return "";
    }
    final logs = await EncryptionLogUtil.read(path: fpath);
    // return last 10000 characters:
    return logs.substring(logs.length > 10000 ? logs.length - 10000 : 0);
  }
}
