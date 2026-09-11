import 'package:cw_core/account.dart';
import 'package:mobx/mobx.dart';

part 'bitcoin_account_list.g.dart';

class BitcoinAccountList = BitcoinAccountListBase with _$BitcoinAccountList;

abstract class BitcoinAccountListBase with Store {
  BitcoinAccountListBase() : accounts = ObservableList<Account>() {
    update();
  }

  @observable
  ObservableList<Account> accounts;

  @action
  Future<void> update() async {
    if (accounts.isEmpty) {
      accounts.add(Account(id: 0, label: 'Account 0'));
    }
  }

  @action
  Future<Account> addAccount({required String label}) async {
    final newAccount = Account(
      id: accounts.length,
      label: label,
    );

    accounts.add(newAccount);
    return newAccount;
  }

  @action
  Future<void> setLabelAccount({required int accountIndex, required String label}) async {
    final accountListIndex = accounts.indexWhere((account) => account.id == accountIndex);

    if (accountListIndex == -1) {
      return;
    }

    accounts[accountListIndex] = accounts[accountListIndex].copyWith(label: label);
  }
}
