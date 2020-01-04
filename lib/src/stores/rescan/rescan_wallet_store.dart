import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';

part 'rescan_wallet_store.g.dart';

class RescanWalletStore = RescanWalletStoreBase with _$RescanWalletStore;

enum RescanWalletState {
  rescaning, none
}

abstract class RescanWalletStoreBase with Store {
  @observable
  RescanWalletState state;
  
  WalletService _walletService;

  RescanWalletStoreBase({@required WalletService walletService}) {
    _walletService = walletService;
    state = RescanWalletState.none;
  }

  @action
  Future rescanCurrentWallet({int restoreHeight}) async {
    state = RescanWalletState.rescaning;
    await _walletService.rescan(restoreHeight: restoreHeight);
    state = RescanWalletState.none;
  }
}
