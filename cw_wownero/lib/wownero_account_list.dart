import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wownero_amount_format.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_core/account.dart';
import 'package:cw_wownero/api/account_list.dart' as account_list;
import 'package:monero/wownero.dart' as wownero;

part 'wownero_account_list.g.dart';

class WowneroAccountList = WowneroAccountListBase with _$WowneroAccountList;

abstract class WowneroAccountListBase with Store {
  WowneroAccountListBase()
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

  List<Account> getAll() => account_list.getAllAccount().map((accountRow) {
        final balance = wownero.SubaddressAccountRow_getUnlockedBalance(accountRow);

        return Account(
          id: wownero.SubaddressAccountRow_getRowId(accountRow),
          label: wownero.SubaddressAccountRow_getLabel(accountRow),
          balance: wowneroAmountToString(amount: wownero.Wallet_amountFromString(balance)),
        );
      }).toList();

  Future<void> addAccount({required String label}) async {
    await account_list.addAccount(label: label);
    update();
  }

  Future<void> setLabelAccount({required int accountIndex, required String label}) async {
    await account_list.setLabelForAccount(accountIndex: accountIndex, label: label);
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
