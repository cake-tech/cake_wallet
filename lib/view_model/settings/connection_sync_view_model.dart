import 'dart:async';

import 'package:cake_wallet/core/address_resolver/address_resolver_service.dart';
import 'package:cake_wallet/core/address_resolver/address_sources.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
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
  bool get lookupTwitter => _settingsStore.lookupsTwitter;

  @computed
  bool get lookupsZanoAlias => _settingsStore.lookupsZanoAlias;

  @computed
  bool get looksUpMastodon => _settingsStore.lookupsMastodon;

  @computed
  bool get looksUpYatService => _settingsStore.lookupsYatService;

  @computed
  bool get looksUpUnstoppableDomains => _settingsStore.lookupsUnstoppableDomains;

  @computed
  bool get looksUpOpenAlias => _settingsStore.lookupsOpenAlias;

  @computed
  bool get looksUpENS => _settingsStore.lookupsENS;

  @computed
  bool get lookupsZcashNames => _settingsStore.lookupsZcashNames;

  @computed
  bool get looksUpWellKnown => _settingsStore.lookupsWellKnown;

  @computed
  bool get lookupsNostr => _settingsStore.lookupsNostr;

  @computed
  bool get lookupsFio => _settingsStore.lookupsFio;

  @computed
  bool get lookupsBip353 => _settingsStore.lookupsBip353;

  @computed
  bool get lookupsThorChain => _settingsStore.lookupsThorChain;

  @computed
  bool get lookupsZcashAddress => _settingsStore.lookupsZcashAddress;

  @computed
  bool get lookupsLNUrlPay => _settingsStore.lookupsLNUrl;

  @computed
  ExchangeApiMode get exchangeStatus => _settingsStore.exchangeStatus;

  @computed
  FiatApiMode get fiatApiMode => _settingsStore.fiatApiMode;

  @computed
  bool get disableAutomaticExchangeStatusUpdates =>
      _settingsStore.disableAutomaticExchangeStatusUpdates;

  @computed
  bool get builtinTor => _settingsStore.currentBuiltinTor;

  List<AddressSource> get domainLookupSources => AddressResolverService.supportedSources;

  bool lookupValue(AddressSource source) {
    switch (source) {
      case AddressSource.twitter:
        return lookupTwitter;
      case AddressSource.mastodon:
        return looksUpMastodon;
      case AddressSource.yatRecord:
        return looksUpYatService;
      case AddressSource.unstoppableDomains:
        return looksUpUnstoppableDomains;
      case AddressSource.openAlias:
        return looksUpOpenAlias;
      case AddressSource.ens:
        return looksUpENS;
      case AddressSource.zcashName:
        return lookupsZcashNames;
      case AddressSource.zcashAddress:
        return lookupsZcashAddress;
      case AddressSource.wellKnown:
        return looksUpWellKnown;
      case AddressSource.zanoAlias:
        return lookupsZanoAlias;
      case AddressSource.bip353:
        return lookupsBip353;
      case AddressSource.fio:
        return lookupsFio;
      case AddressSource.lnurlPay:
        return lookupsLNUrlPay;
      case AddressSource.thorChain:
        return lookupsThorChain;
      case AddressSource.nostr:
        return lookupsNostr;
      case AddressSource.contact:
      case AddressSource.notParsed:
        return false;
    }
  }

  @action
  void setLookupValue(AddressSource source, bool value) {
    switch (source) {
      case AddressSource.twitter:
        _settingsStore.lookupsTwitter = value;
        break;
      case AddressSource.mastodon:
        _settingsStore.lookupsMastodon = value;
        break;
      case AddressSource.yatRecord:
        _settingsStore.lookupsYatService = value;
        break;
      case AddressSource.unstoppableDomains:
        _settingsStore.lookupsUnstoppableDomains = value;
        break;
      case AddressSource.openAlias:
        _settingsStore.lookupsOpenAlias = value;
        break;
      case AddressSource.ens:
        _settingsStore.lookupsENS = value;
        break;
      case AddressSource.zcashName:
        _settingsStore.lookupsZcashNames = value;
        break;
      case AddressSource.zcashAddress:
        _settingsStore.lookupsZcashAddress = value;
        break;
      case AddressSource.wellKnown:
        _settingsStore.lookupsWellKnown = value;
        break;
      case AddressSource.zanoAlias:
        _settingsStore.lookupsZanoAlias = value;
        break;
      case AddressSource.bip353:
        _settingsStore.lookupsBip353 = value;
        break;
      case AddressSource.fio:
        _settingsStore.lookupsFio = value;
        break;
      case AddressSource.lnurlPay:
        _settingsStore.lookupsLNUrl = value;
        break;
      case AddressSource.thorChain:
        _settingsStore.lookupsThorChain = value;
        break;
      case AddressSource.nostr:
        _settingsStore.lookupsNostr = value;
        break;
      case AddressSource.contact:
      case AddressSource.notParsed:
        break;
    }
  }

  @computed
  bool get hasPowNodes => [WalletType.nano, WalletType.banano].contains(_wallet.type);

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

  bool get hasRescan =>
      _wallet.hasRescan &&
      _wallet.type != WalletType.bitcoin &&
      _wallet.type != WalletType.litecoin;

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
