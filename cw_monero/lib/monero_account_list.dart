import 'package:mobx/mobx.dart';
import 'package:cw_core/account.dart';
import 'package:cw_monero/api/account_list.dart' as account_list;

part 'monero_account_list.g.dart';

class MoneroAccountList = MoneroAccountListBase with _$MoneroAccountList;

abstract class MoneroAccountListBase with Store {
  MoneroAccountListBase()
      : accounts = ObservableList<Account>(),
        _isRefreshing = false,
        _isUpdating = false {
    refresh();
    print(account_list.accountSizeNative());
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

  List<Account> getAll() => account_list
      .getAllAccount()
      .map((accountRow) => Account(
        id: accountRow.getId(),
        label: accountRow.getLabel()))
      .toList();

  Future addAccount({String label}) async {
    await account_list.addAccount(label: label);
    update();
  }

  Future setLabelAccount({int accountIndex, String label}) async {
    await account_list.setLabelForAccount(
        accountIndex: accountIndex, label: label);
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
      print(e);
      rethrow;
    }
  }
}
