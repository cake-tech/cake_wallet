import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_decred/api/libdcrwallet.dart' as libdcrwallet;

class DecredWalletAddresses extends WalletAddresses {
  DecredWalletAddresses(WalletInfo walletInfo) : super(walletInfo);

  @override
  String get address {
    return libdcrwallet.currentReceiveAddress(walletInfo.name) ?? '';
  }

  String generateNewAddress() {
    // TODO: generate new external address with libdcrwallet.
    return "DsT4qJPPaYEuQRimfgvSKxKH3paysn1x3Nt";
  }

  List<String> addresses() {
    final currentAddress = libdcrwallet.currentReceiveAddress(walletInfo.name);
    return currentAddress == null ? [] : [currentAddress];
  }

  @override
  set address(String addr) {}

  @override
  Future<void> init() async {}

  @override
  Future<void> updateAddressesInBox() async {}

  @override
  Future<void> saveAddressesInBox() async {}
}
