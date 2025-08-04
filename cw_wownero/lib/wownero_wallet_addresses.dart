import 'package:cw_core/account.dart';
import 'package:cw_core/address_info.dart';
import 'package:cw_core/subaddress.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_wownero/api/transaction_history.dart';
import 'package:cw_wownero/api/subaddress_list.dart' as subaddress_list;
import 'package:cw_wownero/api/wallet.dart';
import 'package:cw_wownero/wownero_account_list.dart';
import 'package:cw_wownero/wownero_subaddress_list.dart';
import 'package:cw_wownero/wownero_transaction_history.dart';
import 'package:mobx/mobx.dart';

part 'wownero_wallet_addresses.g.dart';

class WowneroWalletAddresses = WowneroWalletAddressesBase with _$WowneroWalletAddresses;

abstract class WowneroWalletAddressesBase extends WalletAddresses with Store {
  WowneroWalletAddressesBase(
      WalletInfo walletInfo, WowneroTransactionHistory wowneroTransactionHistory)
      : accountList = WowneroAccountList(),
        _wowneroTransactionHistory = wowneroTransactionHistory,
        subaddressList = WowneroSubaddressList(),
        address = '',
        super(walletInfo);

  final WowneroTransactionHistory _wowneroTransactionHistory;
  @override
  @observable
  String address;

  @override
  String get primaryAddress => getAddress(accountIndex: account?.id ?? 0, addressIndex: 0);

  @override
  String get latestAddress {
    var addressIndex = subaddress_list.numSubaddresses(account?.id??0) - 1;
    var address = getAddress(accountIndex: account?.id??0, addressIndex: addressIndex);
    while (hiddenAddresses.contains(address)) {
      addressIndex++;
      address = getAddress(accountIndex: account?.id??0, addressIndex: addressIndex);
    }
    return address;
  }

  @override
  String get addressForExchange {
    var addressIndex = subaddress_list.numSubaddresses(account?.id??0) - 1;
    var address = getAddress(accountIndex: account?.id??0, addressIndex: addressIndex);
    while (hiddenAddresses.contains(address) || manualAddresses.contains(address)) {
      addressIndex++;
      address = getAddress(accountIndex: account?.id??0, addressIndex: addressIndex);
    }
    return address;
  }
  @observable
  Account? account;

  @observable
  Subaddress? subaddress;

  WowneroSubaddressList subaddressList;

  WowneroAccountList accountList;
  
  @override
  Set<String> usedAddresses = Set();

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
      final _subaddressList = WowneroSubaddressList();

      addressesMap.clear();
      addressInfos.clear();

      accountList.accounts.forEach((account) {
        _subaddressList.update(accountIndex: account.id);
        _subaddressList.subaddresses.forEach((subaddress) {
          addressesMap[subaddress.address] = subaddress.label;
          addressInfos[account.id] ??= [];
          addressInfos[account.id]?.add(AddressInfo(
              address: subaddress.address, label: subaddress.label, accountIndex: account.id));
        });
      });

      await saveAddressesInBox();
    } catch (e) {
      printV(e.toString());
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

  Future<void> updateUsedSubaddress() async {
    final transactions = _wowneroTransactionHistory.transactions.values.toList();

    transactions.forEach((element) {
      final accountIndex = element.accountIndex;
      final addressIndex = element.addressIndex;
      usedAddresses.add(getAddress(accountIndex: accountIndex, addressIndex: addressIndex));
    });
  }

  Future<void> updateUnusedSubaddress(
      {required int accountIndex, required String defaultLabel}) async {
    await subaddressList.updateWithAutoGenerate(
        accountIndex: accountIndex,
        defaultLabel: defaultLabel,
        usedAddresses: usedAddresses.toList());
    subaddress = (subaddressList.subaddresses.isEmpty) ? Subaddress(id: 0, address: address, label: defaultLabel, balance: '0', txCount: 0) : subaddressList.subaddresses.last;
    address = subaddress!.address;
  }

  @override
  bool containsAddress(String address) =>
      addressInfos[account?.id ?? 0]?.any((it) => it.address == address) ?? false;
}
