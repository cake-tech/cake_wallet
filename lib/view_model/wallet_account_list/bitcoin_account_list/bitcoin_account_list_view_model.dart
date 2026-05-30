import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/wallet_account_list/wallet_account_list_view_model.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_account_list_view_model.g.dart';

class BitcoinAccountListViewModel = BitcoinAccountListViewModelBase
    with _$BitcoinAccountListViewModel;

abstract class BitcoinAccountListViewModelBase with Store implements WalletAccountListViewModel {
  BitcoinAccountListViewModelBase(this._wallet, this.settingsStore) : scrollOffsetFromTop = 0 {
    _setDefaultAccountUntilStorageLoads();
    _loadAccounts();

    if (_wallet is ElectrumWallet) {
      reaction(
        (_) => (_wallet as ElectrumWallet)
            .accountBalances
            .entries
            .map((entry) =>
                '${entry.key}:${entry.value.confirmed}:${entry.value.unconfirmed}:${entry.value.frozen}')
            .join('|'),
        (_) => _loadAccounts(),
      );
    }
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
    _loadAccounts();
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

    unawaited(() async {

      await bitcoin!.setCurrentAccount(_wallet, account.id);

      if (_wallet is ElectrumWallet) {
        final electrumWallet = _wallet as ElectrumWallet;
        final walletAddresses = electrumWallet.walletAddresses;

        final receiveAddresses = walletAddresses.receiveAddresses;

        if (receiveAddresses.isNotEmpty) {
          final first = receiveAddresses.first;
        }
      }
    }());
  }

  @action
  void _loadAccounts() {
    _wallet.walletInfo.getAccounts().then((storedAccounts) {
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
  void reload() {
    _loadAccounts();
  }

  String _balanceForAccount(int accountIndex) {
    final balance = bitcoin!.balanceForAccount(_wallet, accountIndex);
    final formattedBalance = balance.fullAvailableBalance.toString();
    return formattedBalance;
  }
}
