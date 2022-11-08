import 'package:mobx/mobx.dart';
import 'package:cw_core/account.dart';
import 'package:cw_core/account_list.dart';
import 'package:cw_haven/api/account_list.dart' as account_list;

part 'haven_account_list.g.dart';

class HavenAccountList = HavenAccountListBase with _$HavenAccountList;

abstract class HavenAccountListBase extends AccountList<Account> with Store {
  HavenAccountListBase()
      : accounts = ObservableList<Account>(),
        _isRefreshing = false,
        _isUpdating = false {
    refresh();
  }

  @override
  @observable
  ObservableList<Account> accounts;
  bool _isRefreshing;
  bool _isUpdating;

  @override
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

  @override
  List<Account> getAll() => account_list
      .getAllAccount()
      .map((accountRow) => Account(
        id: accountRow.getId(),
        label: accountRow.getLabel()))
      .toList();
  
  @override
  Future<void> addAccount({required String label}) async {
    await account_list.addAccount(label: label);
    update();
  }

  @override
  Future<void> setLabelAccount({required int accountIndex, required String label}) async {
    await account_list.setLabelForAccount(
        accountIndex: accountIndex, label: label);
    update();
  }

  @override
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
