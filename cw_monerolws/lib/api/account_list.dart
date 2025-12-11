import 'dart:async';

import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monerolws/api/wallet.dart';
import 'package:cw_monerolws/lws_account_list.dart';
import 'package:monero/src/lws_wallet2.dart'; // imported from git
import 'package:monero/src/monero.dart'; // imported from git

Wallet2Wallet? currentWallet = null;
bool get isViewOnly => int.tryParse(currentWallet!.secretSpendKey()) == 0;

int _wlptrForW = 0;
Wallet2WalletListener? _wlptr = null;

Wallet2WalletListener? getWlptr() {
  if (currentWallet == null) return null;
  if (_wlptrForW == currentWallet!.ffiAddress()) {
    return _wlptr;
  } else {
    _wlptrForW = currentWallet!.ffiAddress();
    _wlptr = currentWallet!.getWalletListener();
    return _wlptr;
  }
}

Wallet2SubaddressAccount? subaddressAccount;

bool isUpdating = false;

void refreshAccounts() {
  try {
    isUpdating = true;
    subaddressAccount = currentWallet?.subaddressAccount();
    subaddressAccount?.refresh();
    isUpdating = false;
  } catch (e) {
    isUpdating = false;
    rethrow;
  }
}

List<Wallet2SubaddressAccountRow> getAllAccount() {
  // final size = monero.Wallet_numSubaddressAccounts(wptr!);
  refreshAccounts();
  int size = subaddressAccount!.getAll_size();
  if (size == 0) {
    currentWallet!.addSubaddressAccount();
    currentWallet!.status();
    return [];
  }
  return List.generate(size, (index) {
    return subaddressAccount!.getAll_byIndex(index);
  });
}

void addAccount({required String label}) {
  currentWallet!.addSubaddressAccount(label: label);
  unawaited(store());
}

void setLabelForAccount({required int accountIndex, required String label}) {
  subaddressAccount!.setLabel(accountIndex: accountIndex, label: label);
  MoneroAccountListBase.cachedAccounts[currentWallet!.ffiAddress()] = [];
  refreshAccounts();
  unawaited(store());
}
