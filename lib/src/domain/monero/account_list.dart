import 'package:rxdart/rxdart.dart';
import 'package:cw_monero/account_list.dart' as account_list;
import 'package:cake_wallet/src/domain/monero/account.dart';

class AccountList {
  AccountList() {
    _isRefreshing = false;
    _isUpdating = false;
    _accounts = BehaviorSubject<List<Account>>();
  }

  Observable<List<Account>> get accounts => _accounts.stream;

  BehaviorSubject<List<Account>> _accounts;
  bool _isRefreshing;
  bool _isUpdating;

  Future update() async {
    if (_isUpdating) {
      return;
    }

    try {
      _isUpdating = true;
      refresh();
      final accounts = getAll();
      _accounts.add(accounts);
      _isUpdating = false;
    } catch (e) {
      _isUpdating = false;
      rethrow;
    }
  }

  List<Account> getAll() {
    return account_list
        .getAllAccount()
        .map((accountRow) => Account.fromRow(accountRow))
        .toList();
  }

  Future addAccount({String label}) async {
    await account_list.addAccount(label: label);
    await update();
  }

  Future setLabelSubaddress({int accountIndex, String label}) async {
    await account_list.setLabelForAccount(
        accountIndex: accountIndex, label: label);
    await update();
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
