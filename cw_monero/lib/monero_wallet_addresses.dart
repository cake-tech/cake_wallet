import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/account.dart';
import 'package:cw_monero/monero_account_list.dart';
import 'package:cw_monero/monero_subaddress_list.dart';
import 'package:cw_core/subaddress.dart';
import 'package:mobx/mobx.dart';

part 'monero_wallet_addresses.g.dart';

class MoneroWalletAddresses = MoneroWalletAddressesBase
    with _$MoneroWalletAddresses;

abstract class MoneroWalletAddressesBase extends WalletAddresses with Store {
  MoneroWalletAddressesBase(WalletInfo walletInfo)
    : accountList = MoneroAccountList(),
      subaddressList = MoneroSubaddressList(),
      address = '',
      super(walletInfo);

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
      final _subaddressList = MoneroSubaddressList();

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
}