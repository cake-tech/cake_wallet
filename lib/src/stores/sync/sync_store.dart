import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/sync_status.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';

part 'sync_store.g.dart';

class SyncStore = SyncStoreBase with _$SyncStore;

abstract class SyncStoreBase with Store {
  @observable
  SyncStatus status;

  StreamSubscription<Wallet> _onWalletChangeSubscription;
  StreamSubscription<SyncStatus> _onSyncStatusChangeSubscription;

  SyncStoreBase(
      {SyncStatus syncStatus = const NotConnectedSyncStatus(),
      @required WalletService walletService}) {
    status = syncStatus;

    if (walletService.currentWallet != null) {
      _onWalletChanged(walletService.currentWallet);
    }

    _onWalletChangeSubscription =
        walletService.onWalletChange.listen(_onWalletChanged);
  }

  @override
  void dispose() {
    if (_onSyncStatusChangeSubscription != null) {
      _onSyncStatusChangeSubscription.cancel();
    }

    _onWalletChangeSubscription.cancel();
    super.dispose();
  }

  void _onWalletChanged(Wallet wallet) {
    if (_onSyncStatusChangeSubscription != null) {
      _onSyncStatusChangeSubscription.cancel();
    }

    _onSyncStatusChangeSubscription =
        wallet.syncStatus.listen((status) => this.status = status);
  }
}
