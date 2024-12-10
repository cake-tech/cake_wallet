import 'package:cw_core/wallet_addresses_with_account.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/account.dart';
import 'package:cw_salvium/api/wallet.dart';
import 'package:cw_salvium/salvium_account_list.dart';
import 'package:cw_salvium/salvium_subaddress_list.dart';
import 'package:cw_core/subaddress.dart';
import 'package:mobx/mobx.dart';

part 'salvium_wallet_addresses.g.dart';

class SalviumWalletAddresses = SalviumWalletAddressesBase
    with _$SalviumWalletAddresses;

abstract class SalviumWalletAddressesBase extends WalletAddressesWithAccount<Account> with Store {
  SalviumWalletAddressesBase(WalletInfo walletInfo)
    : accountList = SalviumAccountList(),
      subaddressList = SalviumSubaddressList(),
      address = '',
      super(walletInfo);

  @override
  @observable
  String address;
  
  String get primaryAddress => address;
  
  // @override
  @observable
  Account? account;

  @observable
  Subaddress? subaddress;

  SalviumSubaddressList subaddressList;
  
  SalviumAccountList accountList;

  @override
  Future<void> init() async {
    accountList.update();
    account = accountList.accounts.isEmpty ? Account(id: 0, label: "Primary address") : accountList.accounts.first;
    updateSubaddressList(accountIndex: account?.id ?? 0);
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    try {
      final _subaddressList = SalviumSubaddressList();

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
    final accountListLength = accountList.accounts.length;

    if (accountListLength <= 0) {
      return false;
    }

    subaddressList.update(accountIndex: accountList.accounts.first.id);
    final subaddressListLength = subaddressList.subaddresses.length;

    if (subaddressListLength <= 0) {
      return false;
    }

    return true;
  }

  void updateSubaddressList({required int accountIndex}) {
    subaddressList.update(accountIndex: accountIndex);
    address = subaddressList.subaddresses.isNotEmpty
        ? subaddressList.subaddresses.first.address
        : getAddress();
  }

  @override
  bool containsAddress(String address) =>
      addressInfos[account?.id ?? 0]?.any((it) => it.address == address) ?? false;
}
