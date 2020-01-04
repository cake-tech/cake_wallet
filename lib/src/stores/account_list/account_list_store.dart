import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/monero/account.dart';
import 'package:cake_wallet/src/domain/monero/account_list.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'account_list_store.g.dart';

class AccountListStore = AcountListStoreBase with _$AccountListStore;

abstract class AcountListStoreBase with Store {
  @observable
  List<Account> accounts;

  @observable
  bool isValid;

  @observable
  String errorMessage;

  @observable
  bool isAccountCreating;

  AccountList _accountList;
  StreamSubscription<Wallet> _onWalletChangeSubscription;
  StreamSubscription<List<Account>> _onAccountsChangeSubscription;

  AcountListStoreBase({@required WalletService walletService}) {
    accounts = [];
    isAccountCreating = false;

    if (walletService.currentWallet != null) {
      _onWalletChanged(walletService.currentWallet);
    }

    _onWalletChangeSubscription =
        walletService.onWalletChange.listen(_onWalletChanged);
  }

  @override
  void dispose() {
    _onWalletChangeSubscription.cancel();

    if (_onAccountsChangeSubscription != null) {
      _onAccountsChangeSubscription.cancel();
    }

    super.dispose();
  }

  Future updateAccountList() async {
    await _accountList.refresh();
    accounts = _accountList.getAll();
  }

  Future addAccount({String label}) async {
    try {
      isAccountCreating = true;
      await _accountList.addAccount(label: label);
      await updateAccountList();
      isAccountCreating = false;
    } catch (e) {
      isAccountCreating = false;
    }
  }

  Future renameAccount({int index, String label}) async {
    await _accountList.setLabelSubaddress(accountIndex: index, label: label);
    await updateAccountList();
  }

  Future _onWalletChanged(Wallet wallet) async {
    if (_onAccountsChangeSubscription != null) {
      _onAccountsChangeSubscription.cancel();
    }

    if (wallet is MoneroWallet) {
      _accountList = wallet.getAccountList();
      _onAccountsChangeSubscription =
          _accountList.accounts.listen((accounts) => this.accounts = accounts);
      await updateAccountList();

      return;
    }

    print('Incorrect wallet type for this operation (AccountList)');
  }

  void validateAccountName(String value) {
    String p = '^[a-zA-Z0-9_]{1,15}\$';
    RegExp regExp = new RegExp(p);
    isValid = regExp.hasMatch(value);
    errorMessage = isValid ? null : S.current.error_text_account_name;
  }
}
