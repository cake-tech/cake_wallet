import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/wallet_account_list/wallet_account_list_view_model.dart';
import 'package:cw_bitcoin/bitcoin_wallet.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart' show WalletBase;
import 'package:mobx/mobx.dart';

part 'bitcoin_account_list_view_model.g.dart';

class BitcoinAccountListViewModel = BitcoinAccountListViewModelBase
    with _$BitcoinAccountListViewModel;

abstract class BitcoinAccountListViewModelBase with Store implements WalletAccountListViewModel {
  BitcoinAccountListViewModelBase(this._wallet, this.settingsStore) : scrollOffsetFromTop = 0 {
    _loadAccounts();
  }

  final WalletBase _wallet;
  final SettingsStore settingsStore;

  CryptoCurrency get currency => _wallet.currency;

  @observable
  double scrollOffsetFromTop;

  @action
  void setScrollOffsetFromTop(double scrollOffsetFromTop) {
    this.scrollOffsetFromTop = scrollOffsetFromTop;
  }

  @override
  @observable
  ObservableList<AccountListItem> accounts = ObservableList<AccountListItem>();

  @override
  @observable
  AccountListItem? selectedAccount;

  @override
  @action
  void select(AccountListItem account) {
    selectedAccount = account;

    // TODO: connect this to Bitcoin selected account storage/service.
    // Expected behavior:
    // 1. Save selected account index.
    // 2. Update wallet derivation/account context.
    // 3. Refresh receive/change addresses for selected account.
  }

  @action
  void _loadAccounts() {
    // TODO: load accounts from Bitcoin account storage/service.
    // Temporary fallback: Bitcoin account 0.
    final defaultAccount = AccountListItem(
      id: 0,
      label: 'Account 0',
      balance: null,
      isSelected: true,
    );

    accounts = ObservableList<AccountListItem>.of([defaultAccount]);
    selectedAccount = defaultAccount;
  }

  @action
  void reload() {
    _loadAccounts();
  }
}
