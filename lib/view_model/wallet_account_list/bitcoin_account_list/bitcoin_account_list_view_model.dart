import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/amount_parsing_proxy.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/wallet_account_list/wallet_account_list_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_account_list_view_model.g.dart';

class BitcoinAccountListViewModel = BitcoinAccountListViewModelBase
    with _$BitcoinAccountListViewModel;

abstract class BitcoinAccountListViewModelBase with Store implements WalletAccountListViewModel {
  BitcoinAccountListViewModelBase(this._wallet, this.settingsStore) : scrollOffsetFromTop = 0 {
    _setDefaultAccountUntilStorageLoads();
    unawaited(_loadAccounts());

    reaction(
      (_) => bitcoin!.accountBalancesKey(_wallet),
      (_) => unawaited(_loadAccounts()),
    );

    reaction(
      (_) => settingsStore.displayAmountsInSatoshi,
      (_) => unawaited(_loadAccounts()),
    );

    reaction(
      (_) => settingsStore.balanceDisplayMode,
      (_) => unawaited(_loadAccounts()),
    );
  }

  final SettingsStore settingsStore;
  final WalletBase _wallet;

  CryptoCurrency get currency => _wallet.currency;

  @observable
  double scrollOffsetFromTop;

  @action
  void setScrollOffsetFromTop(double scrollOffsetFromTop) {
    this.scrollOffsetFromTop = scrollOffsetFromTop;
  }

  void init() {
    unawaited(_loadAccounts());
  }

  @override
  @observable
  ObservableList<AccountListItem> accounts = ObservableList<AccountListItem>();

  @override
  @observable
  AccountListItem? selectedAccount;

  @override
  @action
  Future<void> select(AccountListItem account) async {
    await bitcoin!.setCurrentAccount(_wallet, account.id);
    runInAction(() {
      selectedAccount = account;
    });
    await reload();
  }

  @action
  Future<void> _loadAccounts() async {
    final storedAccounts = await _wallet.walletInfo.getAccounts();
    final items = storedAccounts
        .map((account) => AccountListItem(
              id: account.accountIndex,
              label: account.label,
              balance: _balanceForAccount(account.accountIndex),
              isSelected: account.isSelected,
            ))
        .toList();

    runInAction(() {
      accounts = ObservableList<AccountListItem>.of(items);
      selectedAccount = accounts.firstWhere(
        (account) => account.isSelected,
        orElse: () => accounts.first,
      );
    });
  }

  void _setDefaultAccountUntilStorageLoads() {
    final defaultAccount = AccountListItem(
      id: 0,
      label: 'Account 0',
      balance: _balanceForAccount(0),
      isSelected: true,
    );

    accounts = ObservableList<AccountListItem>.of([defaultAccount]);
    selectedAccount = defaultAccount;
  }

  @override
  @action
  Future<void> reload() {
    return _loadAccounts();
  }

  String _balanceForAccount(int accountIndex) {
    if (settingsStore.balanceDisplayMode == BalanceDisplayMode.hiddenBalance) {
      return '●●●●●●';
    }
    final balance = bitcoin!.balanceForAccount(_wallet, accountIndex);

    return AmountParsingProxy(settingsStore.displayAmountsInSatoshi)
        .asDisplayStringWithSymbol(balance.available);
  }
}
