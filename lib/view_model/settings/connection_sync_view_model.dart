import 'dart:async';

import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/tron/tron.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/utils/tor.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

part 'connection_sync_view_model.g.dart';

class ConnectionSyncViewModel = ConnectionSyncViewModelBase with _$ConnectionSyncViewModel;

abstract class ConnectionSyncViewModelBase with Store {
  ConnectionSyncViewModelBase(this._settingsStore, this._wallet);

  final SettingsStore _settingsStore;
  final WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> _wallet;

  @computed
  ExchangeApiMode get exchangeStatus => _settingsStore.exchangeStatus;

  @computed
  FiatApiMode get fiatApiMode => _settingsStore.fiatApiMode;

  @computed
  bool get disableAutomaticExchangeStatusUpdates =>
      _settingsStore.disableAutomaticExchangeStatusUpdates;

  @computed
  bool get builtinTor => _settingsStore.currentBuiltinTor;


  @computed
  bool get hasPowNodes => [WalletType.nano, WalletType.banano].contains(_wallet.type);

  @computed
  bool get isWalletConnectCompatible =>
      isWalletConnectCompatibleChain(_wallet.type) && !_wallet.isHardwareWallet;

  @computed
  bool get useMempoolFeeAPI => _settingsStore.useMempoolFeeAPI;

  @computed
  bool get canUseMempoolFeeAPI => _wallet.type == WalletType.bitcoin;

  @computed
  bool get useBlinkProtection => _settingsStore.useBlinkProtection;

  bool get canUseBlinkProtection => canSupportBlinkProtection(_wallet.chainId);

  @computed
  bool get useEtherscan => _settingsStore.useEtherscan;

  @computed
  bool get usePolygonScan => _settingsStore.usePolygonScan;

  @computed
  bool get useBaseScan => _settingsStore.useBaseScan;

  @computed
  bool get useArbiScan => _settingsStore.useArbiScan;

  @computed
  bool get useBscScan => _settingsStore.useBscScan;

  @computed
  bool get useTronGrid => _settingsStore.useTronGrid;

  @computed
  bool get canUseEtherscan => _wallet.chainId == 1;

  @computed
  bool get canUsePolygonScan => _wallet.chainId == 137;

  @computed
  bool get canUseBaseScan => _wallet.chainId == 8453;

  @computed
  bool get canUseArbiScan => _wallet.chainId == 42161;

  @computed
  bool get canUseBscScan => _wallet.chainId == 56;

  @computed
  bool get canUseTronGrid => _wallet.type == WalletType.tron;

  @action
  void setUseMempoolFeeAPI(bool value) => _settingsStore.useMempoolFeeAPI = value;

  @action
  void setDisableAutomaticExchangeStatusUpdates(bool value) =>
      _settingsStore.disableAutomaticExchangeStatusUpdates = value;

  @action
  void setFiatMode(FiatApiMode fiatApiMode) => _settingsStore.fiatApiMode = fiatApiMode;

  @action
  void setExchangeApiMode(ExchangeApiMode value) => _settingsStore.exchangeStatus = value;

  @action
  void setUseBlinkProtection(bool value) => _settingsStore.useBlinkProtection = value;

  @action
  void setUseEtherscan(bool value) {
    _settingsStore.useEtherscan = value;
    evm!.updateScanProviderUsageState(_wallet, value);
  }

  @action
  void setUsePolygonScan(bool value) {
    _settingsStore.usePolygonScan = value;
    evm!.updateScanProviderUsageState(_wallet, value);
  }

  @action
  void setUseBaseScan(bool value) {
    _settingsStore.useBaseScan = value;
    evm!.updateScanProviderUsageState(_wallet, value);
  }

  @action
  void setUseTronGrid(bool value) {
    _settingsStore.useTronGrid = value;
    tron!.updateTronGridUsageState(_wallet, value);
  }

  @action
  void setUseArbiScan(bool value) {
    _settingsStore.useArbiScan = value;
    evm!.updateScanProviderUsageState(_wallet, value);
  }

  @action
  void setUseBscScan(bool value) {
    _settingsStore.useBscScan = value;
    evm!.updateScanProviderUsageState(_wallet, value);
  }

  @action
  void setBuiltinTor(bool value, BuildContext context) {
    if (value) {
      unawaited(
        showPopUp<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
              alertTitle: S.of(context).tor_connection,
              alertContent: S.of(context).tor_experimental,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop(true),
            );
          },
        ),
      );
    }
    _settingsStore.currentBuiltinTor = value;
    if (value) {
      unawaited(ensureTorStarted(context: context).then((_) async {
        if (_settingsStore.currentBuiltinTor == false) return;
        int? chainId;
        if (isEVMCompatibleChain(_wallet.type)) {
          chainId = evm!.getSelectedChainId(_wallet);
        }
        await _wallet.connectToNode(
            node: _settingsStore.getCurrentNode(_wallet.type, chainId: chainId));
      }));
    } else {
      unawaited(ensureTorStopped(context: context).then((_) async {
        if (_settingsStore.currentBuiltinTor == true) return;
        int? chainId;
        if (isEVMCompatibleChain(_wallet.type)) {
          chainId = evm!.getSelectedChainId(_wallet);
        }
        await _wallet.connectToNode(
            node: _settingsStore.getCurrentNode(_wallet.type, chainId: chainId));
      }));
    }
  }
}
