import 'package:mobx/mobx.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/address_info.dart';
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;

part 'xelis_wallet_addresses.g.dart';

class XelisWalletAddresses = XelisWalletAddressesBase with _$XelisWalletAddresses;

abstract class XelisWalletAddressesBase extends WalletAddresses with Store {
  XelisWalletAddressesBase(this.walletInfo, this.wallet)
      : super(walletInfo);

  final WalletInfo walletInfo;
  final x_wallet.XelisWallet wallet;

  @observable
  String address = '';

  @override
  Future<void> init() async {
    address = wallet.getAddressStr();
    addressesMap[address] = '';
    addressInfos[0] = [
      AddressInfo(
        address: address,
        label: '',
        accountIndex: 0,
      )
    ];
    usedAddresses.add(address);
    await saveAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {}

  @override
  List<AddressInfo> getAddressInfos() => addressInfos[0] ?? [];

  @override
  set address(String addr) {
    this.address = addr;
  }

  @override
  Future<void> updateAddress(String addr, String label) async {
    final infos = addressInfos[0];
    if (infos == null) return;
    for (var info in infos) {
      if (info.address == addr) {
        info.label = label;
      }
    }
    await saveAddressesInBox();
  }

  @override
  Future<void> generateNewAddress(String label) async {
    // Xelis only uses one address, so this is a no-op or could optionally throw
    return;
  }
}
