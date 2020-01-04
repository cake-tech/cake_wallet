import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';

part 'wallet_seed_store.g.dart';

class WalletSeedStore = WalletSeedStoreBase with _$WalletSeedStore;

abstract class WalletSeedStoreBase with Store {
  @observable
  String name;

  @observable
  String seed;

  WalletSeedStoreBase({@required WalletService walletService}) {
    seed = '';

    if (walletService.currentWallet != null) {
      walletService.getSeed().then((seed) => this.seed = seed);
      walletService.getName().then((name) => this.name = name);
    }
  }
}
