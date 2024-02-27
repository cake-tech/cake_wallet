import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';

part 'bitcoin_wallet.g.dart';

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends ElectrumWallet with Store {
  BitcoinWalletBase({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required Uint8List seedBytes,
    String? addressPageType,
    BasedUtxoNetwork? networkParam,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
    SilentPaymentOwner? silentAddress,
  }) : super(
            mnemonic: mnemonic,
            password: password,
            walletInfo: walletInfo,
            unspentCoinsInfo: unspentCoinsInfo,
            networkType: networkParam == null
                ? bitcoin.bitcoin
                : networkParam == BitcoinNetwork.mainnet
                    ? bitcoin.bitcoin
                    : bitcoin.testnet,
            initialAddresses: initialAddresses,
            initialBalance: initialBalance,
            seedBytes: seedBytes,
            currency: CryptoCurrency.btc) {
    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      initialSilentAddresses: initialSilentAddresses,
      initialSilentAddressIndex: initialSilentAddressIndex,
      silentAddress: silentAddress,
      mainHd: hd,
      sideHd: bitcoin.HDWallet.fromSeed(seedBytes, network: networkType).derivePath("m/0'/1"),
      network: networkParam ?? network,
    );
    hasSilentPaymentsScanning = addressPageType == SilentPaymentsAddresType.p2sp.toString();

    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });

    reaction((_) => walletAddresses.addressPageType, (BitcoinAddressType addressPageType) {
      final prev = hasSilentPaymentsScanning;
      hasSilentPaymentsScanning = addressPageType == SilentPaymentsAddresType.p2sp;
      if (prev != hasSilentPaymentsScanning) {
        startSync();
      }
    });
  }

  static Future<BitcoinWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    String? addressPageType,
    BasedUtxoNetwork? network,
    List<BitcoinAddressRecord>? initialAddresses,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    int initialSilentAddressIndex = 0,
  }) async {
    final seedBytes = await mnemonicToSeedBytes(mnemonic);
    return BitcoinWallet(
      mnemonic: mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialSilentAddresses: initialSilentAddresses,
      initialSilentAddressIndex: initialSilentAddressIndex,
      silentAddress: await SilentPaymentOwner.fromPrivateKeys(
          b_scan: ECPrivate.fromHex(bitcoin.HDWallet.fromSeed(
            seedBytes,
            network: network == BitcoinNetwork.testnet ? bitcoin.testnet : bitcoin.bitcoin,
          ).derivePath(SCAN_PATH).privKey!),
          b_spend: ECPrivate.fromHex(bitcoin.HDWallet.fromSeed(
            seedBytes,
            network: network == BitcoinNetwork.testnet ? bitcoin.testnet : bitcoin.bitcoin,
          ).derivePath(SPEND_PATH).privKey!),
          hrp: network == BitcoinNetwork.testnet ? 'tsp' : 'sp'),
      initialBalance: initialBalance,
      seedBytes: seedBytes,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      addressPageType: addressPageType,
      networkParam: network,
    );
  }

  static Future<BitcoinWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
  }) async {
    final snp = await ElectrumWalletSnapshot.load(name, walletInfo.type, password,
        walletInfo.network != null ? BasedUtxoNetwork.fromName(walletInfo.network!) : null);

    final seedBytes = await mnemonicToSeedBytes(snp.mnemonic);
    return BitcoinWallet(
      mnemonic: snp.mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp.addresses,
      initialSilentAddresses: snp.silentAddresses,
      initialSilentAddressIndex: snp.silentAddressIndex,
      silentAddress: await SilentPaymentOwner.fromPrivateKeys(
          b_scan: ECPrivate.fromHex(bitcoin.HDWallet.fromSeed(
            seedBytes,
            network: snp.network == BitcoinNetwork.testnet ? bitcoin.testnet : bitcoin.bitcoin,
          ).derivePath(SCAN_PATH).privKey!),
          b_spend: ECPrivate.fromHex(bitcoin.HDWallet.fromSeed(
            seedBytes,
            network: snp.network == BitcoinNetwork.testnet ? bitcoin.testnet : bitcoin.bitcoin,
          ).derivePath(SPEND_PATH).privKey!),
          hrp: snp.network == BitcoinNetwork.testnet ? 'tsp' : 'sp'),
      initialBalance: snp.balance,
      seedBytes: seedBytes,
      initialRegularAddressIndex: snp.regularAddressIndex,
      initialChangeAddressIndex: snp.changeAddressIndex,
      addressPageType: snp.addressPageType,
      networkParam: snp.network,
    );
  }
}
