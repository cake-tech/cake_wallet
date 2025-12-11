import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monerolws/api/wallet_manager.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/account.dart';
import 'package:cw_monerolws/api/account_list.dart' as account_list;
import 'package:monerolws/src/monerolws.dart'; // needs to point to a file in my repo

part 'lws_account_list.g.dart';

class MoneroAccountList = MoneroAccountListBase with _$MoneroAccountList;

abstract class MoneroAccountListBase with Store {
  MoneroAccountListBase()
      : accounts = ObservableList<Account>(),
        _isRefreshing = false,
        _isUpdating = false {
    refresh();
  }

  @observable
  ObservableList<Account> accounts;
  bool _isRefreshing;
  bool _isUpdating;

  void update() async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      refresh();
      final accounts = getAll();

      if (accounts.isNotEmpty) {
        this.accounts.clear();
        this.accounts.addAll(accounts);
      }

      _isUpdating = false;
    } catch (e) {
      _isUpdating = false;
      rethrow;
    }
  }

  static Map<int, List<Account>> cachedAccounts = {};

  List<Account> getAll() {
    final allAccounts = account_list.getAllAccount();
    final currentCount = allAccounts.length;
    cachedAccounts[account_list.currentWallet!.ffiAddress()] ??= [];

    if (cachedAccounts[account_list.currentWallet!.ffiAddress()]!.length == currentCount) {
      return cachedAccounts[account_list.currentWallet!.ffiAddress()]!;
    }

    cachedAccounts[account_list.currentWallet!.ffiAddress()] = allAccounts.map((accountRow) {
      final balance = accountRow.getUnlockedBalance();

      return Account(
        id: accountRow.getRowId(),
        label: accountRow.getLabel(),
        balance: moneroAmountToString(amount: account_list.currentWallet!.amountFromString(balance)),
      );
    }).toList();

    return cachedAccounts[account_list.currentWallet!.ffiAddress()]!;
  }

  void addAccount({required String label}) {
    account_list.addAccount(label: label);
    update();
  }

  void setLabelAccount({required int accountIndex, required String label}) {
    account_list.setLabelForAccount(accountIndex: accountIndex, label: label);
    update();
  }

  void refresh() {
    if (_isRefreshing) {
      return;
    }

    try {
      _isRefreshing = true;
      account_list.refreshAccounts();
      _isRefreshing = false;
    } catch (e) {
      _isRefreshing = false;
      printV(e);
      rethrow;
    }
  }
}
