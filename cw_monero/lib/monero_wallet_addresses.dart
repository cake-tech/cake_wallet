import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/account.dart';
import 'package:cw_monero/monero_account_list.dart';
import 'package:cw_monero/monero_subaddress_list.dart';
import 'package:cw_core/subaddress.dart';
import 'package:cw_monero/monero_transaction_history.dart';
import 'package:mobx/mobx.dart';

part 'monero_wallet_addresses.g.dart';

class MoneroWalletAddresses = MoneroWalletAddressesBase
    with _$MoneroWalletAddresses;

abstract class MoneroWalletAddressesBase extends WalletAddresses with Store {
  MoneroWalletAddressesBase(WalletInfo walletInfo, MoneroTransactionHistory moneroTransactionHistory)
    : accountList = MoneroAccountList(),
      _moneroTransactionHistory = moneroTransactionHistory,
      subaddressList = MoneroSubaddressList(moneroTransactionHistory),
      address = '',
      super(walletInfo);

  final MoneroTransactionHistory _moneroTransactionHistory;
  @override
  @observable
  String address;
  
  @observable
  Account? account;

  @observable
  Subaddress? subaddress;

  MoneroSubaddressList subaddressList;

  MoneroAccountList accountList;

  @override
  Future<void> init() async {
    accountList.update();
    account = accountList.accounts.first;
    updateSubaddressList(accountIndex: account?.id ?? 0);
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    try {
      final _subaddressList = MoneroSubaddressList(_moneroTransactionHistory);

      addressesMap.clear();

      accountList.accounts.forEach((account) {
        _subaddressList.update(accountIndex: account.id);
        _subaddressList.subaddresses.forEach((subaddress) {
          addressesMap[subaddress.address] = subaddress.label;
        });
      });

      await saveAddressesInBox();
    } catch (e) {
      print(e.toString());
    }
  }

  bool validate() {
    accountList.update();
    final accountListLength = accountList.accounts.length ?? 0;

    if (accountListLength <= 0) {
      return false;
    }

    subaddressList.update(accountIndex: accountList.accounts.first.id);
    final subaddressListLength = subaddressList.subaddresses.length ?? 0;

    if (subaddressListLength <= 0) {
      return false;
    }

    return true;
  }

  void updateSubaddressList({required int accountIndex}) {
    subaddressList.update(accountIndex: accountIndex);
    subaddress = subaddressList.subaddresses.first;
    address = subaddress!.address;
  }

  Future<void> updateUnusedSubaddress({required int accountIndex, required String defaultLabel}) async {
     await subaddressList.updateWithAutoGenerate(accountIndex: accountIndex, defaultLabel: defaultLabel);
    subaddress = subaddressList.subaddresses.first;
    address = subaddress!.address;
  }
}