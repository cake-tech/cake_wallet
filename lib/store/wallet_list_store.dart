import 'package:mobx/mobx.dart';

part 'wallet_list_store.g.dart';

class WalletListStore = WalletListStoreBase with _$WalletListStore;

abstract class WalletListStoreBase with Store {
  @observable
  Object state;
}