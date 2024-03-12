import 'dart:convert';

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
    return libdcrwallet.newExternalAddress(walletInfo.name) ?? '';
  }

  List<String> addresses() {
    final res = libdcrwallet.addresses(walletInfo.name);
    final addrs = (json.decode(res) as List<dynamic>).cast<String>();
    return addrs;
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
