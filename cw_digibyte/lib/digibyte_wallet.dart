import 'dart:typed_data';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_bitcoin/bitcoin_amount_format.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:hive/hive.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
import 'package:ledger_bitcoin/psbt.dart';
import 'package:cw_bitcoin/psbt/transaction_builder.dart';
import 'package:mobx/mobx.dart';

class DigibyteWallet extends DigibyteWalletBase {
  DigibyteWallet({
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required EncryptionFileUtils encryptionFileUtils,
    Uint8List? seedBytes,
    String? mnemonic,
    String? xpub,
    String? passphrase,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    bool? alwaysScan,
  }) : super(
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        encryptionFileUtils: encryptionFileUtils,
        seedBytes: seedBytes,
        mnemonic: mnemonic,
        xpub: xpub,
        passphrase: passphrase,
        initialAddresses: initialAddresses,
        initialBalance: initialBalance,
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex,
        alwaysScan: alwaysScan,
      );
}

abstract class DigibyteWalletBase extends ElectrumWallet with Store {
  DigibyteWalletBase({
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required EncryptionFileUtils encryptionFileUtils,
    Uint8List? seedBytes,
    String? mnemonic,
    String? xpub,
    String? passphrase,
    List<BitcoinAddressRecord>? initialAddresses,
    ElectrumBalance? initialBalance,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    bool? alwaysScan,
  }) : super(
          mnemonic: mnemonic,
          password: password,
          passphrase: passphrase,
          xpub: xpub,
          walletInfo: walletInfo,
          unspentCoinsInfo: unspentCoinsInfo,
          network: DigibyteNetwork.mainnet,
          initialAddresses: initialAddresses,
          initialBalance: initialBalance,
          seedBytes: seedBytes,
          encryptionFileUtils: encryptionFileUtils,
          currency: CryptoCurrency.digibyte,
          alwaysScan: alwaysScan,
        );

  LedgerConnection? _ledgerConnection;
  BitcoinLedgerApp? _bitcoinLedgerApp;

  @override
  String formatCryptoAmount(String amount) {
    final amountInt = int.parse(amount);
    return bitcoinAmountToString(amount: amountInt);
  }

  @override
  void setLedgerConnection(LedgerConnection connection) {
    _ledgerConnection = connection;
    _bitcoinLedgerApp = BitcoinLedgerApp(
      _ledgerConnection!,
      derivationPath: walletInfo.derivationInfo!.derivationPath!,
    );
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
    final masterFingerprint = await _bitcoinLedgerApp!.getMasterFingerprint();

    final psbtReadyInputs = <PSBTReadyUtxoWithAddress>[];
    for (final utxo in utxos) {
      final rawTx = await electrumClient.getTransactionHex(
        hash: utxo.utxo.txHash,
      );
      final pubKeyInfo = publicKeys[utxo.ownerDetails.address.pubKeyHash()]!;

      psbtReadyInputs.add(PSBTReadyUtxoWithAddress(
        utxo: utxo.utxo,
        rawTx: rawTx,
        ownerDetails: utxo.ownerDetails,
        ownerDerivationPath: pubKeyInfo.derivationPath,
        ownerMasterFingerprint: masterFingerprint,
        ownerPublicKey: pubKeyInfo.publicKey,
      ));
    }

    final psbt = PSBTTransactionBuild(
      inputs: psbtReadyInputs,
      outputs: outputs,
      enableRBF: enableRBF,
    ).psbt;

    final rawHex = await _bitcoinLedgerApp!.signPsbt(psbt: psbt);
    return BtcTransaction.fromRaw(BytesUtils.toHexString(rawHex));
  }

  static Future<DigibyteWallet> create({
    required String mnemonic,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required EncryptionFileUtils encryptionFileUtils,
    String? passphrase,
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
          passphrase: passphrase ?? '',
        );
        break;
      case DerivationType.electrum:
      default:
        seedBytes = await mnemonicToSeedBytes(mnemonic, passphrase: passphrase ?? '');
        break;
    }
    return DigibyteWallet(
      mnemonic: mnemonic,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: initialAddresses,
      initialBalance: initialBalance,
      encryptionFileUtils: encryptionFileUtils,
      passphrase: passphrase,
      seedBytes: seedBytes,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
    );
  }

  static Future<DigibyteWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
    required bool alwaysScan,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);
    ElectrumWalletSnapshot? snp;
    try {
      snp = await ElectrumWalletSnapshot.load(
        encryptionFileUtils,
        name,
        walletInfo.type,
        password,
        DigibyteNetwork.mainnet,
      );
    } catch (_) {
      if (!hasKeysFile) rethrow;
    }

    final WalletKeysData keysData;
    if (!hasKeysFile) {
      keysData = WalletKeysData(
        mnemonic: snp!.mnemonic,
        xPub: snp.xpub,
        passphrase: snp.passphrase,
      );
    } else {
      keysData = await WalletKeysFile.readKeysFile(
        name,
        walletInfo.type,
        password,
        encryptionFileUtils,
      );
    }

    walletInfo.derivationInfo ??= DerivationInfo();
    walletInfo.derivationInfo!.derivationPath ??= snp?.derivationPath ?? electrum_path;
    walletInfo.derivationInfo!.derivationType ??= snp?.derivationType ?? DerivationType.electrum;

    Uint8List? seedBytes;
    final mnemonic = keysData.mnemonic;
    final passphrase = keysData.passphrase;

    if (mnemonic != null) {
      switch (walletInfo.derivationInfo?.derivationType) {
        case DerivationType.bip39:
          seedBytes = await bip39.mnemonicToSeed(
            mnemonic,
            passphrase: passphrase ?? '',
          );
          break;
        case DerivationType.electrum:
        default:
          seedBytes = await mnemonicToSeedBytes(mnemonic, passphrase: passphrase ?? '');
          break;
      }
    }

    return DigibyteWallet(
      mnemonic: keysData.mnemonic,
      xpub: keysData.xPub,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialAddresses: snp?.addresses,
      initialBalance: snp?.balance,
      seedBytes: seedBytes,
      passphrase: passphrase,
      encryptionFileUtils: encryptionFileUtils,
      initialRegularAddressIndex: snp?.regularAddressIndex,
      initialChangeAddressIndex: snp?.changeAddressIndex,
      alwaysScan: alwaysScan,
    );
  }
}
