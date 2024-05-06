import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:convert/convert.dart';

import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/psbt_transaction_builder.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:hive/hive.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:bip39/bip39.dart' as bip39;

part 'bitcoin_wallet.g.dart';

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends ElectrumWallet with Store {
  BitcoinWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    Uint8List? seedBytes,
    String? mnemonic,
    String? xpub,
    String? addressPageType,
    BasedUtxoNetwork? networkParam,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    String? passphrase,
  }) : super(
      mnemonic: mnemonic,
      passphrase: passphrase,
      xpub: xpub,
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
    // in a standard BIP44 wallet, mainHd derivation path = m/84'/0'/0'/0 (account 0, index unspecified here)
    // the sideHd derivation path = m/84'/0'/0'/1 (account 1, index unspecified here)
    // String derivationPath = walletInfo.derivationInfo!.derivationPath!;
    // String sideDerivationPath = derivationPath.substring(0, derivationPath.length - 1) + "1";
    // final hd = bitcoin.HDWallet.fromSeed(seedBytes, network: networkType);
    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      electrumClient: electrumClient,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      mainHd: hd,
      sideHd: accountHD.derive(1),
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
    String? passphrase,
    String? addressPageType,
    BasedUtxoNetwork? network,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
  }) async {
    late Uint8List seedBytes;

    switch (walletInfo.derivationInfo?.derivationType) {
      case DerivationType.bip39:
        seedBytes = await bip39.mnemonicToSeed(
          mnemonic,
          passphrase: passphrase ?? "",
        );
        break;
      case DerivationType.electrum:
      default:
        seedBytes = await mnemonicToSeedBytes(mnemonic);
        break;
    }
    return BitcoinWallet(
      mnemonic: mnemonic,
      passphrase: passphrase ?? "",
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
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
    final network = walletInfo.network != null
        ? BasedUtxoNetwork.fromName(walletInfo.network!)
        : BitcoinNetwork.mainnet;
    final snp = await ElectrumWalletSnapshot.load(name, walletInfo.type, password, network);

    walletInfo.derivationInfo ??= DerivationInfo(
      derivationType: snp.derivationType ?? DerivationType.electrum,
      derivationPath: snp.derivationPath,
    );

    // set the default if not present:
    walletInfo.derivationInfo!.derivationPath = snp.derivationPath ?? "m/0'/0";
    walletInfo.derivationInfo!.derivationType = snp.derivationType ?? DerivationType.electrum;

    Uint8List? seedBytes = null;

    if (snp.mnemonic != null) {
      switch (walletInfo.derivationInfo!.derivationType) {
        case DerivationType.electrum:
          seedBytes = await mnemonicToSeedBytes(snp.mnemonic!);
          break;
        case DerivationType.bip39:
        default:
          seedBytes = await bip39.mnemonicToSeed(
            snp.mnemonic!,
            passphrase: snp.passphrase ?? '',
          );
          break;
      }
    }

    return BitcoinWallet(
      mnemonic: snp.mnemonic,
      xpub: snp.xpub,
      password: password,
      passphrase: snp.passphrase,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp.addresses,
      initialBalance: snp.balance,
      seedBytes: seedBytes,
      initialRegularAddressIndex: snp.regularAddressIndex,
      initialChangeAddressIndex: snp.changeAddressIndex,
      addressPageType: snp.addressPageType,
      networkParam: network,
    );
  }

  Ledger? _ledger;
  LedgerDevice? _ledgerDevice;
  BitcoinLedgerApp? _bitcoinLedgerApp;

  void setLedger(Ledger setLedger, LedgerDevice setLedgerDevice) {
    _ledger = setLedger;
    _ledgerDevice = setLedgerDevice;
    _bitcoinLedgerApp = BitcoinLedgerApp(_ledger!, derivationPath: walletInfo.derivationInfo!.derivationPath!);
  }

  @override
  Future<BtcTransaction> buildHardwareWalletTransaction({
    required List<BitcoinBaseOutput> outputs,
    required BigInt fee,
    required BasedUtxoNetwork network,
    required List<UtxoWithAddress> utxos,
    required Map<String, PublicKeyWithDerivationPath> publicKeys,
    String? memo,
    bool enableRBF = false,
    BitcoinOrdering inputOrdering = BitcoinOrdering.bip69,
    BitcoinOrdering outputOrdering = BitcoinOrdering.bip69,
  }) async {
    final masterFingerprint = await _bitcoinLedgerApp!.getMasterFingerprint(_ledgerDevice!);

    final psbtReadyInputs = <PSBTReadyUtxoWithAddress>[];
    for (final utxo in utxos) {
      final rawTx = await electrumClient.getTransactionHex(hash: utxo.utxo.txHash);
      final publicKeyAndDerivationPath = publicKeys[utxo.ownerDetails.address.pubKeyHash()]!;

      psbtReadyInputs.add(PSBTReadyUtxoWithAddress(
          utxo: utxo.utxo,
          rawTx: rawTx,
          ownerDetails: utxo.ownerDetails,
          ownerDerivationPath: publicKeyAndDerivationPath.derivationPath,
          ownerMasterFingerprint: masterFingerprint,
          ownerPublicKey: publicKeyAndDerivationPath.publicKey,
      ));
    }

    final psbt = PSBTTransactionBuild(inputs: psbtReadyInputs, outputs: outputs, enableRBF: enableRBF);

    final rawHex = await _bitcoinLedgerApp!.signPsbt(_ledgerDevice!, psbt: psbt.psbt);
    return BtcTransaction.fromRaw(hex.encode(rawHex));
  }
}
