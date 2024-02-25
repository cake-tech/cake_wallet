import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'solana_wallet_addresses.g.dart';

class SolanaWalletAddresses = SolanaWalletAddressesBase with _$SolanaWalletAddresses;

abstract class SolanaWalletAddressesBase extends WalletAddresses with Store {
  SolanaWalletAddressesBase(WalletInfo walletInfo)
      : address = '',
        super(walletInfo);

  @override
  String address;

  @override
  Future<void> init() async {
    address = walletInfo.address;
    await updateAddressesInBox();
  }

  @override
  Future<void> updateAddressesInBox() async {
    try {
      addressesMap.clear();
      addressesMap[address] = '';
      await saveAddressesInBox();
    } catch (e) {
      print(e.toString());
    }
  }
}
