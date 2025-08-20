import 'dart:async';

import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';

part 'monero_background_sync.g.dart';

class DevMoneroBackgroundSync = DevMoneroBackgroundSyncBase with _$DevMoneroBackgroundSync;

abstract class DevMoneroBackgroundSyncBase with Store {
  DevMoneroBackgroundSyncBase(WalletBase wallet) : wallet = wallet;

  final WalletBase wallet;

  @observable
  Timer? refreshTimer;

  @observable
  String? localBlockHeight;

  @observable
  String? nodeBlockHeight;

  @observable
  String? primaryAddress;

  @observable
  String? publicViewKey;

  @observable
  String? privateViewKey;

  @observable
  String? publicSpendKey;

  @observable
  String? privateSpendKey;

  @observable
  String? passphrase;

  @observable
  String? seed;

  @observable
  String? seedLegacy;

  @observable
  int tick = -1;

  @observable
  bool isBackgroundSyncing = false;

  Future<void> _setValues() async {
    localBlockHeight = (await monero!.getCurrentHeight()).toString();
    nodeBlockHeight = (await monero!.getNodeHeight(wallet)).toString();
    final keys = monero!.keys(wallet);
    primaryAddress = keys.primaryAddress;
    publicViewKey = keys.publicViewKey;
    privateViewKey = keys.privateViewKey;
    publicSpendKey = keys.publicSpendKey;
    privateSpendKey = keys.privateSpendKey;
    passphrase = keys.passphrase;
    seed = monero!.seed(wallet);
    seedLegacy = monero!.seedLegacy(wallet, "English");
    tick = refreshTimer?.tick ?? -1;
    isBackgroundSyncing = monero!.isBackgroundSyncRunning(wallet);
  }

  @action
  Future<void> manualRescan() async {
    await monero!.rescan(wallet, height: await monero!.getNodeHeight(wallet) - 10000);
  }

  @action
  void startRefreshTimer() {
    refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      await _setValues();
    });
  }

  @action
  void stopRefreshTimer() {
    refreshTimer?.cancel();
    refreshTimer = null;
  }

  @action
  void startBackgroundSync() {
    monero!.startBackgroundSync(wallet);
  }

  @action
  Future<void> stopBackgroundSync() async {
    final keyService = getIt.get<KeyService>();
    await monero!
        .stopBackgroundSync(wallet, await keyService.getWalletPassword(walletName: wallet.name));
  }
}
