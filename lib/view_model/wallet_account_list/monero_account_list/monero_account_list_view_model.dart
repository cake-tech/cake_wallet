import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_account_list/wallet_account_list_view_model.dart';
import 'package:cake_wallet/wownero/wownero.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_list_item.dart';
import 'package:cake_wallet/monero/monero.dart';

part 'monero_account_list_view_model.g.dart';

class MoneroAccountListViewModel = MoneroAccountListViewModelBase with _$MoneroAccountListViewModel;

abstract class MoneroAccountListViewModelBase with Store implements WalletAccountListViewModel {
  MoneroAccountListViewModelBase(this._wallet, this.settingsStore);

  final SettingsStore settingsStore;

  @override
  AccountListItem? get selectedAccount => selected;

  CryptoCurrency get currency => _wallet.currency;

  @computed
  List<AccountListItem> get accounts {
    final hideBalance = settingsStore.balanceDisplayMode == BalanceDisplayMode.hiddenBalance;
    if (_wallet.type == WalletType.monero) {
      return monero!
          .getAccountList(_wallet)
          .accounts
          .map((acc) => AccountListItem(
              label: acc.label,
              id: acc.id,
              balance: hideBalance ? '●●●●●●' : acc.balance,
              isSelected: acc.id == monero!.getCurrentAccount(_wallet).id))
          .toList();
    }

    if (_wallet.type == WalletType.wownero) {
      return wownero!
          .getAccountList(_wallet)
          .accounts
          .map((acc) => AccountListItem(
              label: acc.label,
              id: acc.id,
              balance: hideBalance ? '●●●●●●' : acc.balance,
              isSelected: acc.id == wownero!.getCurrentAccount(_wallet).id))
          .toList();
    }

    throw Exception('Unexpected wallet type: ${_wallet.type} for monero');
  }

  @computed
  AccountListItem get selected {
    final currentId = monero!.getCurrentAccount(_wallet).id;
    return accounts.firstWhere((item) => item.id == currentId);
  }

  final WalletBase _wallet;

  @override
  Future<void> reload() async {}

  @override
  Future<void> select(AccountListItem item) async {
    if (_wallet.type == WalletType.monero) {
      monero!.setCurrentAccount(
        _wallet,
        item.id,
        item.label,
        item.balance,
      );
    }

    if (_wallet.type == WalletType.wownero) {
      wownero!.setCurrentAccount(
        _wallet,
        item.id,
        item.label,
        item.balance,
      );
    }
  }
}
