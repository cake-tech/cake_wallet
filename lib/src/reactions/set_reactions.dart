import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/node.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/start_updating_price.dart';
import 'package:cake_wallet/src/stores/sync/sync_store.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/stores/authentication/authentication_store.dart';
import 'package:cake_wallet/src/stores/login/login_store.dart';

Timer _reconnectionTimer;
ReactionDisposer _connectToNodeDisposer;
ReactionDisposer _onSyncStatusChangeDisposer;
ReactionDisposer _onCurrentWalletChangeDisposer;

void setReactions(
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

void connectToNode({SettingsStore settingsStore, WalletStore walletStore}) {
  _connectToNodeDisposer?.call();

  _connectToNodeDisposer = reaction((_) => settingsStore.node,
      (Node node) async => await walletStore.connectToNode(node: node));
}

void onCurrentWalletChange(
    {WalletStore walletStore,
    SettingsStore settingsStore,
    PriceStore priceStore}) {
  _onCurrentWalletChangeDisposer?.call();

  reaction((_) => walletStore.name, (String _) {
    walletStore.connectToNode(node: settingsStore.node);
    startUpdatingPrice(settingsStore: settingsStore, priceStore: priceStore);
  });
}

void onSyncStatusChange(
    {SyncStore syncStore,
    WalletStore walletStore,
    SettingsStore settingsStore}) {
  _onSyncStatusChangeDisposer?.call();

  reaction((_) => syncStore.status, (SyncStatus status) async {
    if (status is ConnectedSyncStatus) {
      await walletStore.startSync();
    }

    // Reconnect to the node if the app is not started sync after 30 seconds
    if (status is StartingSyncStatus) {
      startReconnectionObserver(syncStore: syncStore, walletStore: walletStore);
    }
  });
}

void startReconnectionObserver({SyncStore syncStore, WalletStore walletStore}) {
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
