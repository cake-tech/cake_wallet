import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/wallet_description.dart';

part 'wallet_list_store.g.dart';

class WalletListStore = WalletListStoreBase with _$WalletListStore;

abstract class WalletListStoreBase with Store {
  WalletListStoreBase() : wallets = ObservableList<WalletDescription>();

  @observable
  ObservableList<WalletDescription> wallets;
}