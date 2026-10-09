import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

part 'dash_wallet_addresses.g.dart';

class DashWalletAddresses = DashWalletAddressesBase with _$DashWalletAddresses;

abstract class DashWalletAddressesBase extends ElectrumWalletAddresses with Store {
  DashWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHdByTypeAndAccount,
    required super.sideHdByTypeAndAccount,
    required super.accountIndexes,
    required super.currentAccountIndex,
    required super.legacyMainHd,
    required super.legacySideHd,
    required super.network,
    required super.isHardwareWallet,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
    super.initialAddressPageType,
  }) : super(walletInfo);

  @override
  String getAddress({
    required int index,
    required Bip32Slip10Secp256k1 hd,
    BitcoinAddressType? addressType,
  }) =>
      generateP2PKHAddress(hd: hd, index: index, network: network);

  @override
  PaymentURI getPaymentUri(String amount) => DashURI(address: address, amount: amount);
}
