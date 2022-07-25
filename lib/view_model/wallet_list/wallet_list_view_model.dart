import 'package:cake_wallet/core/wallet_loading_service.dart';
import 'package:cake_wallet/view_model/wallet_new_vm.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/wallet_service.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cake_wallet/wallet_types.g.dart';

part 'wallet_list_view_model.g.dart';

class WalletListViewModel = WalletListViewModelBase with _$WalletListViewModel;

abstract class WalletListViewModelBase with Store {
  WalletListViewModelBase(this._walletInfoSource, this._appStore,
      this._walletLoadingService) {
    wallets = ObservableList<WalletListItem>();
    _updateList();
  }

  @observable
  ObservableList<WalletListItem> wallets;

  final AppStore _appStore;
  final Box<WalletInfo> _walletInfoSource;
  final WalletLoadingService _walletLoadingService;

  WalletType get currentWalletType => _appStore.wallet.type;

  @action
  Future<void> loadWallet(WalletListItem walletItem) async {
    final wallet = await _walletLoadingService.load(walletItem.type, walletItem.name);
    _appStore.changeCurrentWallet(wallet);
    _updateList();
  }

  @action
  Future<void> remove(WalletListItem wallet) async {
    final walletService = getIt.get<WalletService>(param1: wallet.type);
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
            info.type == _appStore.wallet.type,
        isEnabled: availableWalletTypes.contains(info.type))));
  }
}
