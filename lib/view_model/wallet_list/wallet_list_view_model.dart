import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/core/wallet_service.dart';
import 'package:cake_wallet/bitcoin/bitcoin_wallet_service.dart';
import 'package:cake_wallet/monero/monero_wallet_service.dart';
import 'package:cake_wallet/view_model/wallet_list/wallet_list_item.dart';
import 'package:cake_wallet/src/domain/common/wallet_type.dart';
import 'package:cake_wallet/src/domain/common/wallet_info.dart';

part 'wallet_list_view_model.g.dart';

class WalletListViewModel = WalletListViewModelBase with _$WalletListViewModel;

abstract class WalletListViewModelBase with Store {
  WalletListViewModelBase(
      this._walletInfoSource, this._appStore, this._keyService) {
    wallets = ObservableList<WalletListItem>();
    wallets.addAll(_walletInfoSource.values.map((info) => WalletListItem(
        name: info.name,
        type: info.type,
        isCurrent: info.name == _appStore.wallet.name &&
            info.type == _appStore.wallet.type)));
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
    final walletService = _getWalletService(wallet.type);
    _appStore.wallet = await walletService.openWallet(wallet.name, password);
  }

  @action
  Future<void> remove(WalletListItem wallet) async {}

  WalletService _getWalletService(WalletType type) {
    switch (type) {
      case WalletType.monero:
        return MoneroWalletService();
      case WalletType.bitcoin:
        return BitcoinWalletService();
      default:
        return null;
    }
  }
}
