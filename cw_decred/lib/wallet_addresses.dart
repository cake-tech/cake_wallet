import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_decred/api/dcrlibwallet.dart';

class DecredWalletAddresses extends WalletAddresses {
  DecredWalletAddresses(WalletInfo walletInfo, SPVWallet spv)
      : this.spv = spv,
        super(walletInfo);

  final SPVWallet spv;

  @override
  String get address {
    return this.spv.newAddress();
  }

  String generateNewAddress() {
    return this.spv.newAddress();
  }

  List<String> addresses() {
    return this.spv.addresses();
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
