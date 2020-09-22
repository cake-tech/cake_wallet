import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/entities/wallet_info.dart';

part 'wallet_list_view_model.g.dart';

class WalletListViewModel = WalletListViewModelBase with _$WalletListViewModel;

abstract class WalletListViewModelBase with Store {
  WalletListViewModelBase(
      this._walletInfoSource, this._appStore, this._keyService) {
    wallets = ObservableList<WalletListItem>();
    _updateList();
  }

  @observable
  ObservableList<WalletListItem> wallets;

  final AppStore _appStore;
  final Box<WalletInfo> _walletInfoSource;
  final KeyService _keyService;

  @action
  Future<void> loadWallet(WalletListItem wallet) async {
    final password =
        await _keyService.getWalletPassword(walletName: wallet.name);
    final walletService = getIt.get<WalletService>();
    _appStore.wallet = await walletService.openWallet(wallet.name, password);
  }

  @action
  Future<void> remove(WalletListItem wallet) async {
    final walletService = getIt.get<WalletService>();
    await walletService.remove(wallet.name);
    await _walletInfoSource.delete(wallet.key);
    _updateList();
  }

  void _updateList() {
    wallets.clear();
    wallets.addAll(_walletInfoSource.values.map((info) => WalletListItem(
        name: info.name,
        type: info.type,
        key: info.key,
        isCurrent: info.name == _appStore.wallet.name &&
            info.type == _appStore.wallet.type)));
  }
}
