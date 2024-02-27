import 'package:cw_core/address_info.dart';
import 'package:cw_core/wallet_info.dart';

abstract class WalletAddresses {
  WalletAddresses(this.walletInfo)
    : addressesMap = {},
      addressInfos = {};

  final WalletInfo walletInfo;

  String get address;

  String? get primaryAddress => null;

  set address(String address);

  Map<String, String> addressesMap;

  Map<int, List<AddressInfo>> addressInfos;

  Set<String> usedAddresses = {};

  Future<void> init();

  Future<void> updateAddressesInBox();

  Future<void> saveAddressesInBox() async {
    try {
      walletInfo.address = address;
      walletInfo.addresses = addressesMap;
      walletInfo.addressInfos = addressInfos;
      walletInfo.usedAddresses = usedAddresses.toList();

      if (walletInfo.isInBox) {
        await walletInfo.save();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  bool containsAddress(String address) => addressesMap.containsKey(address);
}
