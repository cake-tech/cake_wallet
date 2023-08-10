import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/nano_account.dart';
import 'package:cw_nano/nano_account_list.dart';
// import 'package:cw_core/account.dart';
// import 'package:cw_core/subaddress.dart';
import 'package:mobx/mobx.dart';
import 'package:hive/hive.dart';

part 'nano_wallet_addresses.g.dart';

class NanoWalletAddresses = NanoWalletAddressesBase with _$NanoWalletAddresses;

abstract class NanoWalletAddressesBase extends WalletAddresses with Store {
  NanoWalletAddressesBase(WalletInfo walletInfo)
      : accountList = NanoAccountList(walletInfo.address),
        address = '',
        super(walletInfo);
  @override
  @observable
  String address;

  @observable
  NanoAccount? account;

  // NanoSubaddressList subaddressList;

  NanoAccountList accountList;

  @override
  Future<void> init() async {
    var box = await Hive.openBox<NanoAccount>(walletInfo.address);
    try {
      box.getAt(0);
    } catch (e) {
      box.add(NanoAccount(id: 0, label: "Primary Account", balance: "0"));
    }

    await accountList.update();
    print("####################");
    print(accountList.accounts);
    account = accountList.accounts.first;
    address = walletInfo.address;

    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    // try {
    //   addressesMap.clear();
    //   addressesMap[address] = '';
    //   await saveAddressesInBox();
    // } catch (e) {
    //   print(e.toString());
    // }
  }
}
