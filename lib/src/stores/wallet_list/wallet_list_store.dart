import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/wallet_description.dart';
import 'package:cake_wallet/src/domain/services/wallet_list_service.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';

part 'wallet_list_store.g.dart';

class WalletListStore = WalletListStoreBase with _$WalletListStore;

abstract class WalletListStoreBase with Store {
  @observable
  List<WalletDescription> wallets;

  WalletListService _walletListService;
  WalletService _walletService;

  WalletListStoreBase(
      {@required WalletListService walletListService,
      @required WalletService walletService}) {
    _walletListService = walletListService;
    _walletService = walletService;
    wallets = [];
    walletListService.getAll().then((walletList) => wallets = walletList);
  }

  bool isCurrentWallet(WalletDescription wallet) {
    return _walletService.description?.name == wallet.name;
  }

  @action
  Future updateWalletList() async {
    wallets = await _walletListService.getAll();
  }

  @action
  Future loadWallet(WalletDescription wallet) async {
    await _walletListService.openWallet(wallet.name);
  }

  @action
  Future remove(WalletDescription wallet) async {
    await _walletListService.remove(wallet);
    await updateWalletList();
  }
}
