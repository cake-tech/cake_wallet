import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/bip/bip/bip32/bip32.dart';
import 'package:cw_bitcoin/bitcoin_receive_page_option.dart';
import 'package:cw_bitcoin/electrum_wallet_addresses.dart';
import 'package:cw_bitcoin/lightning/lightning_addres_type.dart';
import 'package:cw_bitcoin/payjoin/manager.dart';
import 'package:cw_bitcoin/payjoin/payjoin_session_errors.dart';
import 'package:cw_bitcoin/utils.dart';
import 'package:cw_core/parse_fixed.dart';
import 'package:cw_core/payment_uris.dart';
import 'package:cw_core/receive_page_option.dart';
import 'package:cw_core/unspent_coin_type.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:mobx/mobx.dart';

import 'lightning/utils.dart';

part 'bitcoin_wallet_addresses.g.dart';

class BitcoinWalletAddresses = BitcoinWalletAddressesBase with _$BitcoinWalletAddresses;

abstract class BitcoinWalletAddressesBase extends ElectrumWalletAddresses with Store {
  BitcoinWalletAddressesBase(
    WalletInfo walletInfo, {
    required super.mainHdByTypeAndAccount,
    required super.sideHdByTypeAndAccount,
    required super.accountIndexes,
    required super.currentAccountIndex,
    required super.legacySideHd,
    required super.legacyMainHd,
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

  @observable
  String? payjoinEndpoint;

  @observable
  String? payjoinAddress;

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

  @action
  Future<void> initPayjoin() async {
    try {
      await payjoinManager.initPayjoin();
    } on PayjoinDirectoryUnreachableError catch (e) {
      printV(e);
    } catch (e) {
      printV(e);
      rethrow;
    }
  }

  @action
  Future<void> ensurePayjoinReceiver() => newPayjoinReceiver();

  @action
  Future<void> newPayjoinReceiver({bool shouldSaveRecipientAddress = false}) async {
    if (addressPageType == SilentPaymentsAddresType.p2sp ||
        addressPageType == LightningAddressType.p2l) {
      payjoinEndpoint = null;
      payjoinAddress = null;
      return;
    }

    if (!payjoinManager.canCreateReceiver) {
      printV("Skipping payjoin receiver creation: no spendable UTXOs available");
      payjoinEndpoint = null;
      payjoinAddress = null;
      return;
    }
    try {
      final address = this.address;
      final endpoint = await payjoinManager.initReceiver(
        address,
        isTestnet: false,
        retryCount: 0,
        shouldSaveRecipientAddress: shouldSaveRecipientAddress,
      );
      if (endpoint.isNotEmpty) {
        payjoinEndpoint = endpoint;
        payjoinAddress = address;
        await payjoinManager.spawnReceiver(
          pjEndpoint: endpoint,
          address: address,
        );
      }
    } on PayjoinDirectoryUnreachableError catch (e) {
      // Ignore Connectivity errors
      printV(e);
    } catch (e) {
      printV(e);
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
  PaymentURI getPaymentUri(String amount) {
    if (addressPageType is LightningAddressType && lightningWallet != null) {
      final lnUrl = getLnurlOfLightningAddress(address);
      return LightningPaymentRequest(address: address, lnURL: lnUrl, amount: amount);
    }
    final pjUri = payjoinAddress == address ? (payjoinEndpoint ?? "") : "";
    return BitcoinURI(address: address, amount: amount, pjUri: pjUri);
  }

  @override
  Future<PaymentURI> getPaymentRequestUri(String amount) async {
    if (addressPageType is LightningAddressType && lightningWallet != null) {
      final amountSats = amount.isNotEmpty ? tryParseFixed(amount, 8) : null;
      final lnUrl = getLnurlOfLightningAddress(address);
      if (amountSats == null) {
        return LightningPaymentRequest(address: address, lnURL: lnUrl, amount: amount);
      }
      final invoice = await lightningWallet!.getBolt11Invoice(amountSats, "Send to Cake Wallet");
      return LightningPaymentRequest(
          address: address, lnURL: lnUrl, amount: amount, bolt11Invoice: invoice);
    }
    return getPaymentUri(amount);
  }

  @override
  bool containsAddress(String address) =>
      super.containsAddress(address) || address == lightningAddress;

  @override
  String get addressForBuy {
    try {
      return super
          .allAddresses
          .firstWhere((e) =>
              e.accountIndex == currentAccountIndex &&
              e.type == SegwitAddresType.p2wpkh &&
              !e.isHidden &&
              !e.isUsed &&
              !hiddenAddresses.contains(e.address))
          .address;
    } catch (_) {
      return super.addressForBuy;
    }
  }

  @override
  String get addressForExchange {
    final current = getFreshAddress();
    final availableReceiveAddresses = receiveAddresses.where((element) =>
        !element.isUsed && !element.isHidden && !hiddenAddresses.contains(element.address));

    final bool isSilentPaymentsPage = addressPageType == SilentPaymentsAddresType.p2sp;
    final bool isLightningPage = addressPageType == LightningAddressType.p2l;

    if (isSilentPaymentsPage || isLightningPage) {
      final segwit = availableReceiveAddresses
          .where((e) => e.type == SegwitAddresType.p2wpkh)
          .map((e) => e.address)
          .toList();

      return segwit.isNotEmpty ? segwit.first : current;
    }
    return current;
  }
}
