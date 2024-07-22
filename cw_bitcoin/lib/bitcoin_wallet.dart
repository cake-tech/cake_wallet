import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bip39/bip39.dart' as bip39;
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:cw_bitcoin/address_from_output.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_mnemonic.dart';
import 'package:cw_bitcoin/electrum_derivations.dart';
import 'package:cw_bitcoin/bitcoin_wallet_addresses.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_bitcoin/psbt_transaction_builder.dart';
import 'package:cw_bitcoin/silent_payments_wallet.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:ledger_bitcoin/ledger_bitcoin.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:mobx/mobx.dart';
import 'package:cw_bitcoin/utils.dart';

part 'bitcoin_wallet.g.dart';

class BitcoinWallet = BitcoinWalletBase with _$BitcoinWallet;

abstract class BitcoinWalletBase extends SilentPaymentsWallet {
  BitcoinWalletBase._({
    required super.mnemonic,
    required super.passphrase,
    required super.password,
    required super.walletInfo,
    required super.unspentCoinsInfo,
    required Uint8List seedBytes,
    required super.network,
    super.initialBalance,
    List<BitcoinAddressRecord>? initialAddresses,
    Map<String, int>? initialRegularAddressIndex,
    Map<String, int>? initialChangeAddressIndex,
    List<BitcoinSilentPaymentAddressRecord>? initialSilentAddresses,
    int initialSilentAddressIndex = 0,
    super.silentPaymentsAlwaysScanning = false,
  }) : super(
          currency: network == BitcoinNetwork.testnet ? CryptoCurrency.tbtc : CryptoCurrency.btc,
        ) {
    final masterHD = Bip32Slip10Secp256k1.fromSeed(
      // m / purpose' / coin_type' is the Master HD
      seedBytes,
      network.isMainnet ? Bip32Const.mainNetKeyNetVersions : Bip32Const.testNetKeyNetVersions,
    );

    // m / purpose' / coin_type' / account' is the Account HD
    accountHD = masterHD.derivePath(
      hardenedDerivationPath(walletInfo.derivationInfo!.derivationPath!),
    ) as Bip32Slip10Secp256k1;

    walletAddresses = BitcoinWalletAddresses(
      walletInfo,
      initialAddresses: initialAddresses,
      initialRegularAddressIndex: initialRegularAddressIndex,
      initialChangeAddressIndex: initialChangeAddressIndex,
      initialSilentAddresses: initialSilentAddresses,
      initialSilentAddressIndex: initialSilentAddressIndex,
      accountHD: accountHD,
      network: network,
    );

    autorun((_) {
      this.walletAddresses.isEnabledAutoGenerateSubaddress = this.isEnabledAutoGenerateSubaddress;
    });
  }

  static Future<BitcoinWallet> create({
    required String mnemonic,
    required String passphrase,
    required String password,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required BasedUtxoNetwork network,
  }) async {
    return BitcoinWallet._(
      mnemonic: mnemonic,
      passphrase: passphrase,
      password: password,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      network: network,
      seedBytes: await _getSeedBytesByDerivation(walletInfo, mnemonic, passphrase),
    );
  }

  static Future<BitcoinWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
    required bool silentPaymentsAlwaysScanning,
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
    walletInfo.derivationInfo!.derivationPath ??= electrum_path;
    walletInfo.derivationInfo!.derivationType ??= DerivationType.electrum;

    return BitcoinWallet._(
      mnemonic: snp.mnemonic,
      password: password,
      passphrase: snp.passphrase,
      walletInfo: walletInfo,
      unspentCoinsInfo: unspentCoinsInfo,
      initialSilentAddresses: snp.silentAddresses,
      initialSilentAddressIndex: snp.silentAddressIndex,
      initialBalance: snp.balance,
      seedBytes: await _getSeedBytesByDerivation(walletInfo, snp.mnemonic, snp.passphrase),
      initialRegularAddressIndex: snp.regularAddressIndex,
      initialChangeAddressIndex: snp.changeAddressIndex,
      network: network,
      silentPaymentsAlwaysScanning: silentPaymentsAlwaysScanning,
    );
  }

  Ledger? _ledger;
  LedgerDevice? _ledgerDevice;
  BitcoinLedgerApp? _bitcoinLedgerApp;

  void setLedger(Ledger setLedger, LedgerDevice setLedgerDevice) {
    _ledger = setLedger;
    _ledgerDevice = setLedgerDevice;
    _bitcoinLedgerApp =
        BitcoinLedgerApp(_ledger!, derivationPath: walletInfo.derivationInfo!.derivationPath!);
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

    final psbt =
        PSBTTransactionBuild(inputs: psbtReadyInputs, outputs: outputs, enableRBF: enableRBF);

    return BtcTransaction.fromRaw(BytesUtils.toHexString(
      await _bitcoinLedgerApp!.signPsbt(_ledgerDevice!, psbt: psbt.psbt),
    ));
  }

  @override
  Future<String> signMessage(String message, {String? address = null}) async {
    if (walletInfo.isHardwareWallet) {
      final addressEntry = address != null
          ? walletAddresses.allAddresses.firstWhere((element) => element.address == address)
          : null;
      final index = addressEntry?.index ?? 0;
      final isChange = addressEntry?.isHidden == true ? 1 : 0;
      final accountPath = walletInfo.derivationInfo?.derivationPath;
      final derivationPath = accountPath != null ? "$accountPath/$isChange/$index" : null;

      final signature = await _bitcoinLedgerApp!.signMessage(_ledgerDevice!,
          message: ascii.encode(message), signDerivationPath: derivationPath);

      return base64Encode(signature);
    } else {
      return walletAddresses.signMessage(message, address: address);
    }
  }

  Future<bool> canReplaceByFee(String hash) async {
    final verboseTransaction = await electrumClient.getTransactionRaw(hash: hash);
    final confirmations = verboseTransaction['confirmations'] as int? ?? 0;
    final transactionHex = verboseTransaction['hex'] as String?;

    if (confirmations > 0) return false;

    if (transactionHex == null) {
      return false;
    }

    return BtcTransaction.fromRaw(transactionHex)
        .inputs
        .any((element) => element.sequence == BitcoinOpCodeConst.TYPE_REPLACE_BY_FEE);
  }

  Future<bool> isChangeSufficientForFee(String txId, int newFee) async {
    final bundle = await getTransactionExpanded(hash: txId);
    final outputs = bundle.originalTransaction.outputs;

    final changeAddresses = walletAddresses.allAddresses.where((element) => element.isHidden);

    // look for a change address in the outputs
    final changeOutput = outputs.firstWhereOrNull((output) => changeAddresses.any(
        (element) => element.address == addressFromOutputScript(output.scriptPubKey, network)));

    var allInputsAmount = 0;

    for (int i = 0; i < bundle.originalTransaction.inputs.length; i++) {
      final input = bundle.originalTransaction.inputs[i];
      final inputTransaction = bundle.ins[i];
      final vout = input.txIndex;
      final outTransaction = inputTransaction.outputs[vout];
      allInputsAmount += outTransaction.amount.toInt();
    }

    int totalOutAmount = bundle.originalTransaction.outputs
        .fold<int>(0, (previousValue, element) => previousValue + element.amount.toInt());

    var currentFee = allInputsAmount - totalOutAmount;

    int remainingFee = (newFee - currentFee > 0) ? newFee - currentFee : newFee;

    return changeOutput != null && changeOutput.amount.toInt() - remainingFee >= 0;
  }

  Future<PendingBitcoinTransaction> replaceByFee(String hash, int newFee) async {
    try {
      final bundle = await getTransactionExpanded(hash: hash);

      final utxos = <UtxoWithAddress>[];
      List<ECPrivate> privateKeys = [];

      var allInputsAmount = 0;

      // Add inputs
      for (var i = 0; i < bundle.originalTransaction.inputs.length; i++) {
        final input = bundle.originalTransaction.inputs[i];
        final inputTransaction = bundle.ins[i];
        final vout = input.txIndex;
        final outTransaction = inputTransaction.outputs[vout];
        final address = addressFromOutputScript(outTransaction.scriptPubKey, network);
        allInputsAmount += outTransaction.amount.toInt();

        final addressRecord =
            walletAddresses.allAddresses.firstWhere((element) => element.address == address);

        final btcAddress = BitcoinBaseAddress.fromString(addressRecord.address, network);
        final privkey = generateECPrivate(
          addressRecord.isHidden ? walletAddresses.sideHd : walletAddresses.mainHd,
          addressRecord.index,
        );

        privateKeys.add(privkey);

        utxos.add(
          UtxoWithAddress(
            utxo: BitcoinUtxo(
              txHash: input.txId,
              value: outTransaction.amount,
              vout: vout,
              scriptType: BitcoinAddressType.fromAddress(btcAddress),
            ),
            ownerDetails:
                UtxoAddressDetails(publicKey: privkey.getPublic().toHex(), address: btcAddress),
          ),
        );
      }

      int totalOutAmount = bundle.originalTransaction.outputs
          .fold<int>(0, (previousValue, element) => previousValue + element.amount.toInt());

      var currentFee = allInputsAmount - totalOutAmount;
      int remainingFee = newFee - currentFee;

      final outputs = <BitcoinOutput>[];

      // Add outputs and deduct the fees from it
      for (int i = bundle.originalTransaction.outputs.length - 1; i >= 0; i--) {
        final out = bundle.originalTransaction.outputs[i];
        final address = addressFromOutputScript(out.scriptPubKey, network);
        final btcAddress = BitcoinBaseAddress.fromString(address, network);

        int newAmount;
        if (out.amount.toInt() >= remainingFee) {
          newAmount = out.amount.toInt() - remainingFee;
          remainingFee = 0;

          // if new amount of output is less than dust amount, then don't add this output as well
          if (newAmount <= _dustAmount) {
            continue;
          }
        } else {
          remainingFee -= out.amount.toInt();
          continue;
        }

        outputs.add(BitcoinOutput(address: btcAddress, value: BigInt.from(newAmount)));
      }

      final changeAddresses = walletAddresses.allAddresses.where((element) => element.isHidden);

      // look for a change address in the outputs
      final changeOutput = outputs.firstWhereOrNull((output) =>
          changeAddresses.any((element) => element.address == output.address.toAddress(network)));

      // deduct the change amount from the output amount
      if (changeOutput != null) {
        totalOutAmount -= changeOutput.value.toInt();
      }

      final txb = BitcoinTransactionBuilder(
        utxos: utxos,
        outputs: outputs,
        fee: BigInt.from(newFee),
        network: network,
        enableRBF: true,
      );

      final transaction = txb.buildTransaction((txDigest, utxo, publicKey, sighash) {
        final key =
            privateKeys.firstWhereOrNull((element) => element.getPublic().toHex() == publicKey);

        if (key == null) {
          throw Exception("Cannot find private key");
        }

        if (utxo.utxo.isP2tr()) {
          return key.signTapRoot(txDigest, sighash: sighash);
        } else {
          return key.signInput(txDigest, sigHash: sighash);
        }
      });

      return PendingBitcoinTransaction(
        transaction,
        type,
        electrumClient: electrumClient,
        amount: totalOutAmount,
        fee: newFee,
        network: network,
        hasChange: changeOutput != null,
        feeRate: newFee.toString(),
      )..addListener((transaction) async {
          transactionHistory.addOne(transaction);
          await updateBalance();
        });
    } catch (e) {
      throw e;
    }
  }
}

Future<Uint8List> _getSeedBytesByDerivation(
  WalletInfo walletInfo,
  String mnemonic,
  String passphrase,
) async {
  late Uint8List seedBytes;

  switch (walletInfo.derivationInfo?.derivationType) {
    case DerivationType.bip39:
      seedBytes = bip39.mnemonicToSeed(mnemonic, passphrase: passphrase);
      break;
    case DerivationType.electrum:
    default:
      seedBytes = await mnemonicToSeedBytes(mnemonic);
      break;
  }

  return seedBytes;
}
