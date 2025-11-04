import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'dogecoin_wallet_addresses.g.dart';

class DogeCoinWalletAddresses = DogeCoinWalletAddressesBase with _$DogeCoinWalletAddresses;

abstract class DogeCoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  DogeCoinWalletAddressesBase(WalletInfo walletInfo, {
    required super.mainHd,
    required super.sideHd,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
    super.initialAddressPageType
  }) : super(walletInfo);

  @override
  String getAddress({required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType}) =>
      generateP2PKHAddress(hd: hd, index: index, network: network);

  @override
  PaymentURI getPaymentUri(String amount) => DogeURI(amount: amount, address: address);
}
