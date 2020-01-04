import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';

part 'wallet_keys_store.g.dart';

class WalletKeysStore = WalletKeysStoreBase with _$WalletKeysStore;

abstract class WalletKeysStoreBase with Store {
  @observable
  String publicViewKey;

  @observable
  String privateViewKey;

  @observable
  String publicSpendKey;

  @observable
  String privateSpendKey;

  WalletKeysStoreBase({@required WalletService walletService}) {
    publicViewKey = '';
    privateViewKey = '';
    publicSpendKey = '';
    privateSpendKey = '';

    if (walletService.currentWallet != null) {
      walletService.getKeys().then((keys) {
        publicViewKey = keys['publicViewKey'];
        privateViewKey = keys['privateViewKey'];
        publicSpendKey = keys['publicSpendKey'];
        privateSpendKey = keys['privateSpendKey'];
      });
    }
  }
}
