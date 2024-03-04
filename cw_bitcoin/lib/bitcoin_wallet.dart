import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_core/encryption_file_utils.dart';
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
    required EncryptionFileUtils encryptionFileUtils,
    String? addressPageType,
    BasedUtxoNetwork? networkParam,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
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
            currency: CryptoCurrency.btc,
            encryptionFileUtils: encryptionFileUtils) {
    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      electrumClient: electrumClient,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      mainHd: hd,
      sideHd: bitcoin.HDWallet.fromSeed(seedBytes, network: networkType).derivePath("m/0'/1"),
      network: networkParam ?? network,
    );
    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }

  static Future<BitcoinWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required EncryptionFileUtils encryptionFileUtils,
    String? addressPageType,
    BasedUtxoNetwork? network,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
  }) async {
    return BitcoinWallet(
      mnemonic: mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialBalance: initialBalance,
      encryptionFileUtils: encryptionFileUtils,
      seedBytes: await mnemonicToSeedBytes(mnemonic),
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
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final snp = await ElectrumWalletSnapshot.load(encryptionFileUtils, name, walletInfo.type, password,
        walletInfo.network != null ? BasedUtxoNetwork.fromName(walletInfo.network!) : null);

    return BitcoinWallet(
      mnemonic: snp.mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp.addresses,
      initialBalance: snp.balance,
      seedBytes: await mnemonicToSeedBytes(snp.mnemonic),
      encryptionFileUtils: encryptionFileUtils,
      initialRegularAddressIndex: snp.regularAddressIndex,
      initialChangeAddressIndex: snp.changeAddressIndex,
      addressPageType: snp.addressPageType,
      networkParam: snp.network,
    );
  }
}
