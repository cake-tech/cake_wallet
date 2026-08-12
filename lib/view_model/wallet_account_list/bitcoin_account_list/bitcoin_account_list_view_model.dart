import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/amount_parsing_proxy.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/wallet_account_list/account_list_item.dart';
import 'package:cake_wallet/view_model/wallet_account_list/wallet_account_list_view_model.dart';
import 'package:collection/collection.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_account_list_view_model.g.dart';

class BitcoinAccountListViewModel = BitcoinAccountListViewModelBase
    with _$BitcoinAccountListViewModel;

abstract class BitcoinAccountListViewModelBase with Store implements WalletAccountListViewModel {
  BitcoinAccountListViewModelBase(this._wallet, this.settingsStore) {
    unawaited(_loadAccounts());

    reaction(
      (_) => bitcoin!.accountBalancesSnapshot(_wallet),
      (snapshot) => unawaited(_refreshBalances(snapshot)),
      equals: const MapEquality<int, Object>().equals,
    );

    reaction(
      (_) => settingsStore.balanceDisplayMode,
      (_) => unawaited(_recomputeBalanceStrings()),
    );
  }

  final SettingsStore settingsStore;
  final WalletBase _wallet;

  List<WalletInfoAccount>? _cachedStoredAccounts;
  Future<void>? _loadAccountsFuture;

  CryptoCurrency get currency => _wallet.currency;

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
    runInAction(() => selectedAccount = account);
    await reload();
  }

  @action
  Future<void> _loadAccounts() => _runLoad(() => _wallet.walletInfo.getAccounts());

  @action
  Future<void> _refreshBalances(Map<int, Object> balancesSnapshot) {
    final cached = _cachedStoredAccounts;
    final hasUnknownAccount = cached == null ||
        balancesSnapshot.keys
            .any((accountIndex) => !cached.any((a) => a.accountIndex == accountIndex));

    if (hasUnknownAccount) return _loadAccounts();
    return _runLoad(() async => cached);
  }


  @action
  Future<void> _recomputeBalanceStrings() {
    final cached = _cachedStoredAccounts;
    if (cached == null) return _loadAccounts();
    return _runLoad(() async => cached);
  }

  Future<void> _runLoad(Future<List<WalletInfoAccount>> Function() fetch) {
    final inProgress = _loadAccountsFuture;
    if (inProgress != null) {
      return inProgress;
    }

    final future = _applyAccounts(fetch);
    _loadAccountsFuture = future;
    return future.whenComplete(() => _loadAccountsFuture = null);
  }

  Future<void> _applyAccounts(Future<List<WalletInfoAccount>> Function() fetch) async {
    final storedAccounts = await fetch();
    _cachedStoredAccounts = storedAccounts;

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
      selectedAccount = items.isEmpty
          ? null
          : items.firstWhere(
              (account) => account.isSelected,
              orElse: () => items.first,
            );
    });
  }

  @override
  @action
  Future<void> reload() => _loadAccounts();

  String _balanceForAccount(int accountIndex) {
    if (settingsStore.balanceDisplayMode == BalanceDisplayMode.hiddenBalance) {
      return '●●●●●●';
    }
    final balance = bitcoin!.balanceForAccount(_wallet, accountIndex);

    return AmountParsingProxy(settingsStore.displayAmountsInSatoshi)
        .asDisplayStringWithSymbol(balance.available);
  }
}
