import 'dart:io';

import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:cw_lightning/.secrets.g.dart' as secrets;

part 'lightning_wallet.g.dart';

class LightningWallet = LightningWalletBase with _$LightningWallet;

abstract class LightningWalletBase extends ElectrumWallet with Store {
  LightningWalletBase(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      required Uint8List seedBytes,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumBalance? initialBalance,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0})
      : super(
            mnemonic: mnemonic,
            password: password,
            walletInfo: walletInfo,
            unspentCoinsInfo: unspentCoinsInfo,
            networkType: bitcoin.bitcoin,
            initialAddresses: initialAddresses,
            initialBalance: initialBalance,
            seedBytes: seedBytes,
            currency: CryptoCurrency.btc) {
    walletAddresses = BitcoinWalletAddresses(walletInfo,
        electrumClient: electrumClient,
        initialAddresses: initialAddresses,
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex,
        mainHd: hd,
        sideHd: bitcoin.HDWallet.fromSeed(seedBytes, network: networkType).derivePath("m/0'/1"),
        networkType: networkType);

    // initialize breeze:
    setupBreeze(seedBytes);

    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }

  static Future<LightningWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumBalance? initialBalance,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0}) async {
    return LightningWallet(
        mnemonic: mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: initialAddresses,
        initialBalance: initialBalance,
        seedBytes: await mnemonicToSeedBytes(mnemonic),
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex);
  }

  static Future<LightningWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
  }) async {
    final snp = await ElectrumWallletSnapshot.load(name, walletInfo.type, password);
    return LightningWallet(
        mnemonic: snp.mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: snp.addresses,
        initialBalance: snp.balance,
        seedBytes: await mnemonicToSeedBytes(snp.mnemonic),
        initialRegularAddressIndex: snp.regularAddressIndex,
        initialChangeAddressIndex: snp.changeAddressIndex);
  }

  Future<void> setupBreeze(Uint8List seedBytes) async {
    // // Initialize SDK logs listener
    // final sdk = BreezSDK();
    // sdk.initialize();

    // NodeConfig breezNodeConfig = NodeConfig.greenlight(
    //   config: GreenlightNodeConfig(
    //     partnerCredentials: null,
    //     inviteCode: secrets.breezInviteCode,
    //   ),
    // );
    // Config breezConfig = await sdk.defaultConfig(
    //   envType: EnvironmentType.Production,
    //   apiKey: secrets.breezApiKey,
    //   nodeConfig: breezNodeConfig,
    // );
    
    // // Customize the config object according to your needs
    // String workingDir = (await getApplicationDocumentsDirectory()).path;
    // workingDir = "$workingDir/wallets/lightning/${walletInfo.name}/breez/";
    // new Directory(workingDir).createSync(recursive: true);
    // breezConfig = breezConfig.copyWith(workingDir: workingDir);
    // await sdk.connect(config: breezConfig, seed: seedBytes);

    // print("initialized: ${(await sdk.isInitialized())}");
  }
}
