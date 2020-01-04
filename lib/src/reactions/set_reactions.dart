import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/start_updating_price.dart';
import 'package:cake_wallet/src/stores/sync/sync_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/stores/authentication/authentication_store.dart';
import 'package:cake_wallet/src/stores/login/login_store.dart';

setReactions(
    {@required SettingsStore settingsStore,
    @required PriceStore priceStore,
    @required SyncStore syncStore,
    @required WalletStore walletStore,
    @required WalletService walletService,
    @required AuthenticationStore authenticationStore,
    @required LoginStore loginStore}) {
  connectToNode(settingsStore: settingsStore, walletStore: walletStore);
  onSyncStatusChange(
      syncStore: syncStore,
      walletStore: walletStore,
      settingsStore: settingsStore);
  onCurrentWalletChange(
      walletStore: walletStore,
      settingsStore: settingsStore,
      priceStore: priceStore);
  autorun((_) async {
    if (authenticationStore.state == AuthenticationState.allowed) {
      await loginStore.loadCurrentWallet();
      authenticationStore.state = AuthenticationState.readyToLogin;
    }
  });
}

connectToNode({SettingsStore settingsStore, WalletStore walletStore}) =>
    reaction((_) => settingsStore.node,
        (node) async => await walletStore.connectToNode(node: node));

onSyncStatusChange(
        {SyncStore syncStore,
        WalletStore walletStore,
        SettingsStore settingsStore}) =>
    reaction((_) => syncStore.status, (status) async {
      if (status is ConnectedSyncStatus) {
        await walletStore.startSync();
      }

      // Reconnect to the node if the app is not started sync after 30 seconds
      if (status is StartingSyncStatus) {
        await startReconnectionObserver(
            syncStore: syncStore, walletStore: walletStore);
      }
    });

Timer _reconnectionTimer;

startReconnectionObserver({SyncStore syncStore, WalletStore walletStore}) {
  if (_reconnectionTimer != null) {
    _reconnectionTimer.cancel();
  }

  _reconnectionTimer = Timer.periodic(Duration(minutes: 1), (_) async {
    try {
      final isConnected = await walletStore.isConnected();

      if (!isConnected) {
        await walletStore.reconnect();
      }
    } catch (e) {
      print(e);
    }
  });
}

onCurrentWalletChange(
        {WalletStore walletStore,
        SettingsStore settingsStore,
        PriceStore priceStore}) =>
    reaction((_) => walletStore.name, (_) {
      walletStore.connectToNode(node: settingsStore.node);
      startUpdatingPrice(settingsStore: settingsStore, priceStore: priceStore);
    });
