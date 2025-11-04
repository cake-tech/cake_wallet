import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32.dart';
import 'package:cw_bitcoin/bitcoin_receive_page_option.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/lightning/lightning_addres_type.dart';
import 'package:cw_bitcoin/payjoin/manager.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/parse_fixed.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';
import 'package:payjoin_flutter/receive.dart' as payjoin;

part 'bitcoin_wallet_addresses.g.dart';

class BitcoinWalletAddresses = BitcoinWalletAddressesBase with _$BitcoinWalletAddresses;

abstract class BitcoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHd,
    required super.sideHd,
    required super.network,
    required super.isHardwareWallet,
    required this.payjoinManager,
    super.initialAddresses,
    super.initialRegularAddressIndex,
    super.initialChangeAddressIndex,
    super.initialSilentAddresses,
    super.initialSilentAddressIndex = 0,
    super.masterHd,
    super.lightningWallet,
  }) : super(walletInfo);

  final PayjoinManager payjoinManager;

  payjoin.Receiver? currentPayjoinReceiver;

  @observable
  String? payjoinEndpoint = null;

  @override
  String getAddress(
      {required int index,
      required Bip32Slip10Secp256k1 hd,
      BitcoinAddressType? addressType,
      UnspentCoinType coinTypeToSpendFrom = UnspentCoinType.any}) {
    if (addressType == P2pkhAddressType.p2pkh)
      return generateP2PKHAddress(hd: hd, index: index, network: network);

    if (addressType == SegwitAddresType.p2tr)
      return generateP2TRAddress(hd: hd, index: index, network: network);

    if (addressType == SegwitAddresType.p2wsh)
      return generateP2WSHAddress(hd: hd, index: index, network: network);

    if (addressType == P2shAddressType.p2wpkhInP2sh)
      return generateP2SHAddress(hd: hd, index: index, network: network);

    return generateP2WPKHAddress(hd: hd, index: index, network: network);
  }

  bool _isPayjoinConnectivityError(String error) =>
      ["error sending request for url", "Instance of 'FfiIoError'"].any((e) => error.contains(e));

  @action
  Future<void> initPayjoin() async {
    try {
      await payjoinManager.initPayjoin();
      currentPayjoinReceiver = await payjoinManager.getUnusedReceiver(primaryAddress);
      payjoinEndpoint = (await currentPayjoinReceiver?.pjUri())?.pjEndpoint();

      payjoinManager.resumeSessions();
    } catch (e) {
      printV(e);
      // Ignore Connectivity errors
      if (!_isPayjoinConnectivityError(e.toString())) rethrow;
    }
  }

  @action
  Future<void> newPayjoinReceiver() async {
    try {
      currentPayjoinReceiver = await payjoinManager.getUnusedReceiver(primaryAddress);
      payjoinEndpoint = (await currentPayjoinReceiver?.pjUri())?.pjEndpoint();

      payjoinManager.spawnReceiver(receiver: currentPayjoinReceiver!);
    } catch (e) {
      printV(e);
      // Ignore Connectivity errors
      if (!_isPayjoinConnectivityError(e.toString())) rethrow;
    }
  }

  @override
  List<ReceivePageOption> get receivePageOptions {
    if (isHardwareWallet) {
      return [
        ...BitcoinReceivePageOption.allViewOnly,
        ...ReceivePageOptions.where((element) => element != ReceivePageOption.mainnet)
      ];
    }
    return [
      ...BitcoinReceivePageOption.all,
      ...ReceivePageOptions.where((element) => element != ReceivePageOption.mainnet)
    ];
  }

  @override
  PaymentURI getPaymentUri(String amount) =>
      BitcoinURI(address: address, amount: amount, pjUri: payjoinEndpoint ?? '');

  Future<PaymentURI> getPaymentRequestUri(String amount) async {
    if (addressPageType is LightningAddressType && lightningWallet != null) {
      final amountSats = amount.isNotEmpty ? parseFixed(amount, 9) : null;
      final invoice = await lightningWallet!.getBolt11Invoice(amountSats, "Send to Cake Wallet");
      return LightningPaymentRequest(address: address, amount: amount, bolt11Invoice: invoice);
    }
    print(amount);
    return getPaymentUri(amount);
  }
}
