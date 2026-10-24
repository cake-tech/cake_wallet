import "package:cake_wallet/view_model/wallet_account_list/account_list_item.dart";
import "package:collection/collection.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/wallet_base.dart";
import "package:mobx/mobx.dart";

part "wallet_account_list_view_model.g.dart";

class WalletAccountListViewModel = WalletAccountListViewModelBase with _$WalletAccountListViewModel;

abstract class WalletAccountListViewModelBase with Store {
  WalletAccountListViewModelBase(this._wallet);

  final WalletBase _wallet;

  CryptoCurrency get currency => _wallet.currency;

  @computed
  List<AccountListItem> get accounts => [
        for (final account in _wallet.walletAccounts)
          AccountListItem(
            id: account.index,
            label: account.label,
            balance: account.balance.total,
            isSelected: account.index == _wallet.currentAccountIndex,
          ),
      ];

  @computed
  AccountListItem? get selectedAccount => accounts.firstWhereOrNull((item) => item.isSelected);

  Future<void> reload() async {}

  Future<void> select(AccountListItem item) => _wallet.setCurrentAccount(item.id);
}
