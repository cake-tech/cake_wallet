import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/account.dart';
import 'package:cw_nano/nano_account_list.dart';
import 'package:cw_core/subaddress.dart';
import 'package:mobx/mobx.dart';

part 'monero_wallet_addresses.g.dart';

class NanoWalletAddresses = NanoWalletAddressesBase
    with _$NanoWalletAddresses;

abstract class NanoWalletAddressesBase extends WalletAddresses with Store {
  NanoWalletAddressesBase(WalletInfo walletInfo)
    : accountList = NanoAccountList(),
      address = '',
      super(walletInfo);

  @override
  @observable
  String address;
  
  @observable
  Account? account;


  NanoAccountList accountList;

  @override
  Future<void> init() async {
    accountList.update();
    account = accountList.accounts.first;
  }

  bool validate() {
    accountList.update();
    final accountListLength = accountList.accounts.length ?? 0;

    if (accountListLength <= 0) {
      return false;
    }

    return true;
  }
}