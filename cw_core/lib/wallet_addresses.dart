import 'package:cw_core/address_info.dart';
import 'package:cw_core/wallet_info.dart';

abstract class WalletAddresses {
  WalletAddresses(this.walletInfo)
      : addressesMap = {},
        allAddressesMap = {},
        addressInfos = {},
        usedAddresses = {},
        hiddenAddresses = walletInfo.hiddenAddresses?.toSet() ?? {},
        manualAddresses = walletInfo.manualAddresses?.toSet() ?? {};

  final WalletInfo walletInfo;

  String get address;

  String? get primaryAddress => null;

  set address(String address);

  Map<String, String> addressesMap;
  Map<String, String> allAddressesMap;

  Map<String, String> get usableAddressesMap {
    final tmp = addressesMap.map((key, value) => MapEntry(key, value)); // copy address map
    tmp.removeWhere((key, value) => hiddenAddresses.contains(key));
    return tmp;
  }

  Map<String, String> get usableAllAddressesMap {
    final tmp = allAddressesMap.map((key, value) => MapEntry(key, value)); // copy address map
    tmp.removeWhere((key, value) => hiddenAddresses.contains(key));
    return tmp;
  }

  Map<int, List<AddressInfo>> addressInfos;

  Set<String> usedAddresses;

  Set<String> hiddenAddresses;

  Set<String> manualAddresses;

  Future<void> init();

  Future<void> updateAddressesInBox();

  Future<void> saveAddressesInBox() async {
    try {
      walletInfo.address = address;
      walletInfo.addresses = addressesMap;
      walletInfo.addressInfos = addressInfos;
      walletInfo.usedAddresses = usedAddresses.toList();
      walletInfo.hiddenAddresses = hiddenAddresses.toList();
      walletInfo.manualAddresses = manualAddresses.toList();

      if (walletInfo.isInBox) {
        await walletInfo.save();
      }
    } catch (e) {
      print(e.toString());
    }
  }

  bool containsAddress(String address) =>
      addressesMap.containsKey(address) || allAddressesMap.containsKey(address);
}
