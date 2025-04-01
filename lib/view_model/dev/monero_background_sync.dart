import 'dart:async';

import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cw_monero/monero_wallet.dart';
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
    final w = (wallet as MoneroWallet);
    localBlockHeight = (await monero!.getCurrentHeight()).toString();
    nodeBlockHeight = (await w.getNodeHeight()).toString();
    final keys = w.keys;
    primaryAddress = keys.primaryAddress;
    publicViewKey = keys.publicViewKey;
    privateViewKey = keys.privateViewKey;
    publicSpendKey = keys.publicSpendKey;
    privateSpendKey = keys.privateSpendKey;
    passphrase = keys.passphrase;
    seed = w.seed;
    seedLegacy = w.seedLegacy("English");
    tick = refreshTimer?.tick ?? -1;
    isBackgroundSyncing = w.isBackgroundSyncRunning;
  }

  @action
  Future<void> manualRescan() async {
    final w = (wallet as MoneroWallet);
    await wallet.rescan(height: await w.getNodeHeight() - 10000);
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
    final w = (wallet as MoneroWallet);
    w.startBackgroundSync();
  }

  @action
  Future<void> stopBackgroundSync() async {
    final w = (wallet as MoneroWallet);
    final keyService = getIt.get<KeyService>();
    await w.stopBackgroundSync(await keyService.getWalletPassword(walletName: wallet.name));
  }
}
