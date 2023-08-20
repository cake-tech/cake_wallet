import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_transaction_no_inputs_exception.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_transaction_wrong_balance_exception.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin_cash/src/pending_bitcoin_cash_transaction.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

import 'bitcoin_cash_base.dart';

part 'bitcoin_cash_wallet.g.dart';

class BitcoinCashWallet = BitcoinCashWalletBase with _$BitcoinCashWallet;

abstract class BitcoinCashWalletBase extends ElectrumWallet with Store {
  BitcoinCashWalletBase(
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
            currency: CryptoCurrency.bch) {
    walletAddresses = BitcoinCashWalletAddresses(walletInfo,
        electrumClient: electrumClient,
        initialAddresses: initialAddresses,
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex,
        mainHd: hd,
        sideHd: hd,
        //TODO: BCH: check if this is correct
        networkType: networkType);
  }

  static Future<BitcoinCashWallet> create(
      {required String mnemonic,
      required String password,
      required WalletInfo walletInfo,
      required Box<UnspentCoinsInfo> unspentCoinsInfo,
      List<BitcoinAddressRecord>? initialAddresses,
      ElectrumBalance? initialBalance,
      int initialRegularAddressIndex = 0,
      int initialChangeAddressIndex = 0}) async {
    return BitcoinCashWallet(
        mnemonic: mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: initialAddresses,
        initialBalance: initialBalance,
        seedBytes: await Mnemonic.toSeed(mnemonic),
        initialRegularAddressIndex: initialRegularAddressIndex,
        initialChangeAddressIndex: initialChangeAddressIndex);
  }

  static Future<BitcoinCashWallet> open({
    required String name,
    required WalletInfo walletInfo,
    required Box<UnspentCoinsInfo> unspentCoinsInfo,
    required String password,
  }) async {
    final snp = await ElectrumWallletSnapshot.load(name, walletInfo.type, password);
    return BitcoinCashWallet(
        mnemonic: snp.mnemonic,
        password: password,
        walletInfo: walletInfo,
        unspentCoinsInfo: unspentCoinsInfo,
        initialAddresses: snp.addresses,
        initialBalance: snp.balance,
        seedBytes: await Mnemonic.toSeed(snp.mnemonic),
        initialRegularAddressIndex: snp.regularAddressIndex,
        initialChangeAddressIndex: snp.changeAddressIndex);
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final transactionCredentials = credentials as BitcoinTransactionCredentials;

    const minAmount = 546;
    final inputs = <BitcoinUnspent>[];
    var allInputsAmount = 0;
    final outputs = transactionCredentials.outputs;
    final hasMultiDestination = outputs.length > 1;

    if (unspentCoins.isEmpty) {
      await updateUnspent();
    }

    for (final utx in unspentCoins) {
      if (utx.isSending) {
        allInputsAmount += utx.value;
        inputs.add(utx);
      }
    }

    if (inputs.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

    final int feeRate = transactionCredentials.feeRate != null
        ? transactionCredentials.feeRate!
        : BitcoinCashFeeRates.feeRate(transactionCredentials.priority!);

    final int allAmountFee =
        bitbox.BitcoinCash.getByteCount(inputs.length, transactionCredentials.outputs.length) *
            feeRate;

    final allAmount = allInputsAmount - allAmountFee;
    var credentialsAmount = 0;
    var amount = 0;
    var fee = 0;

    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll || item.formattedCryptoAmount! <= 0)) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      credentialsAmount = outputs.fold(0, (acc, value) {
        return acc + value.formattedCryptoAmount!;
      });

      print(credentialsAmount);

      if (allAmount - credentialsAmount < minAmount) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      amount = credentialsAmount;

      if (transactionCredentials.feeRate != null) {
        fee = calculateEstimatedFeeWithFeeRate(transactionCredentials.feeRate!, amount,
            outputsCount: outputs.length + 1);
      } else {
        fee = calculateEstimatedFee(transactionCredentials.priority, amount,
            outputsCount: outputs.length + 1);
      }
    } else {
      final output = outputs.first;
      credentialsAmount = !output.sendAll ? output.formattedCryptoAmount! : 0;

      if (credentialsAmount > allAmount) {
        throw BitcoinTransactionWrongBalanceException(currency);
      }

      amount = output.sendAll || allAmount - credentialsAmount < minAmount
          ? allAmount
          : credentialsAmount;

      if (output.sendAll || amount == allAmount) {
        fee = allAmountFee;
      } else if (transactionCredentials.feeRate != null) {
        fee = calculateEstimatedFeeWithFeeRate(transactionCredentials.feeRate!, amount);
      } else {
        fee = calculateEstimatedFee(transactionCredentials.priority, amount);
      }
    }

    if (fee == 0) {
      throw BitcoinTransactionWrongBalanceException(currency);
    }

    final totalAmount = amount + fee;

    if (totalAmount > balance[currency]!.confirmed || totalAmount > allInputsAmount) {
      throw BitcoinTransactionWrongBalanceException(currency);
    }

    // final changeAddress = await walletAddresses.getChangeAddress(); TODO: BCH: implement change address
    var leftAmount = totalAmount;
    var totalInputAmount = 0;

    inputs.clear();

    for (final utx in unspentCoins) {
      if (utx.isSending) {
        leftAmount = leftAmount - utx.value;
        totalInputAmount += utx.value;
        inputs.add(utx);

        if (leftAmount <= 0) {
          break;
        }
      }
    }

    if (inputs.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

    if (amount <= 0 || totalInputAmount < totalAmount) {
      throw BitcoinTransactionWrongBalanceException(currency);
    }

    final builder = bitbox.Bitbox.transactionBuilder(testnet: false);
    final _wallet = hd;

    final utxoSigningData = await fetchBuildTxData(inputs, _wallet);

    List<bitbox.Utxo> _utxos = [];
    for (var element in inputs) {
      _utxos.add(bitbox.Utxo(element.hash, element.vout,
          bitbox.BitcoinCash.fromSatoshi(element.value), element.value, 0, 1));
    }

    final signatures = <Map>[];
    int totalBalance = 0;

    _utxos.forEach((bitbox.Utxo utxo) {
      builder.addInput(utxo.txid, utxo.vout);

      final ec = utxoSigningData.firstWhere((e) => e.utxo.hash == utxo.txid).keyPair!;

      final bitboxEC = bitbox.ECPair.fromWIF(ec.toWIF());

      signatures
          .add({"vin": signatures.length, "key_pair": bitboxEC, "original_amount": utxo.satoshis});

      totalBalance += utxo.satoshis;
    });

    outputs.forEach((item) {
      final outputAmount = hasMultiDestination ? item.formattedCryptoAmount : amount;
      final outputAddress = item.isParsedAddress ? item.extractedAddress! : item.address;
      builder.addOutput(outputAddress, outputAmount!);
    });

    signatures.forEach((signature) {
      builder.sign(signature["vin"], signature["key_pair"], signature["original_amount"]);
    });

    // build the transaction
    final tx = builder.build();
    return PendingBitcoinCashTransaction(tx, type,
        electrumClient: electrumClient, amount: amount, fee: fee)
      ..addListener((transaction) async {
        transactionHistory.addOne(transaction);
        await updateBalance();
      });
  }

  Future<List<SigningData>> fetchBuildTxData(
      List<BitcoinUnspent> utxosToUse, HDWallet wallet) async {
    // Initialize the list to store signing data
    List<SigningData> signingData = [];

    try {
      // Iterate over UTXOs to populate the addresses and fetch transaction details
      for (var i = 0; i < utxosToUse.length; i++) {
        final txid = utxosToUse[i].hash;
        final tx = await electrumClient.getTransactionRaw(
            hash: txid); //TODO: BCH: replace with getting from local storage if possible

        // Iterate through transaction outputs to find corresponding addresses
        for (final output in tx["vout"] as List) {
          // Handle each transaction output
          await handleTransactionOutput(output, utxosToUse[i]);
        }

        // Determine address type and create signing data object
        signingData.add(SigningData(
            derivePathType: DerivePathType.bch44,
            utxo: utxosToUse[i])); //TODO: BCH: hardcoded DerivePathType.bch44

        // Determine public key (pubKey) and Wallet Import Format (wif) here
        // TODO: You need to implement logic to determine pubKey and wif
        String? pubKey = wallet.pubKey;
        String? wif = wallet.wif;

        // Then call the preparePaymentData function
        preparePaymentData(
            signingData[i], pubKey, wif, bitcoincash); //TODO: BCH: hardcoded bitcoincash
      }

      // Return the signing data for later use
      return signingData;
    } catch (e) {
      print(e);
      rethrow;
    }
  }

// Function to handle each transaction output
  Future<void> handleTransactionOutput(Map output, BitcoinUnspent utxo) async {
    final n = output["n"];
    if (n != null && n == utxo.vout) {
      String address = output["scriptPubKey"]?["addresses"]?[0] as String? ??
          output["scriptPubKey"]["address"] as String;

      // Convert to Cash Address format if needed
      if (bitbox.Address.detectFormat(address) != bitbox.Address.formatCashAddr) {
        try {
          address = bitbox.Address.toCashAddress(address);
        } catch (_) {
          rethrow;
        }
      }

      // Update UTXO with the new address
      utxo.updateAddress(address); // Make sure 'address' is mutable or create a method to update it
    }
  }

// Function to prepare payment data
  void preparePaymentData(
      SigningData sd, String? pubKey, String? wif, bitcoin.NetworkType _network) {
    if (wif != null && pubKey != null) {
      PaymentData data; // Removed 'final' modifier
      final Uint8List? redeemScript;

      switch (sd.derivePathType) {
        case DerivePathType.bip44:
        case DerivePathType.bch44:
          data = P2PKH(
            data: PaymentData(
              pubkey: Uint8List.fromList(HEX.decode(pubKey)),
            ),
            network: _network,
          ).data;
          redeemScript = null;
          break;

        default:
          throw Exception("DerivePathType unsupported");
      }

      final keyPair = ECPair.fromWIF(
        wif,
        network: _network,
      );

      sd.redeemScript = redeemScript;
      sd.output = data.output;
      sd.keyPair = keyPair;
    }
  }
}

class SigningData {
  SigningData({
    required this.derivePathType,
    required this.utxo,
    this.output,
    this.keyPair,
    this.redeemScript,
  });

  final DerivePathType derivePathType;
  final BitcoinUnspent utxo;
  Uint8List? output;
  ECPair? keyPair;
  Uint8List? redeemScript;
}

enum DerivePathType {
  bip44,
  bch44,
  bip49,
  bip84,
  eth,
  eCash44,
}

// Bitcoincash Network
final bitcoincash = bitcoin.NetworkType(
    messagePrefix: '\x18Bitcoin Signed Message:\n',
    bech32: 'bc',
    bip32: bitcoin.Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
    pubKeyHash: 0x00,
    scriptHash: 0x05,
    wif: 0x80);

final bitcoincashtestnet = bitcoin.NetworkType(
    messagePrefix: '\x18Bitcoin Signed Message:\n',
    bech32: 'tb',
    bip32: bitcoin.Bip32Type(public: 0x043587cf, private: 0x04358394),
    pubKeyHash: 0x6f,
    scriptHash: 0xc4,
    wif: 0xef);

class BitcoinCashFeeRates {
  static const int highPriority = 10;
  static const int mediumPriority = 5;
  static const int lowPriority = 1;

  static int feeRate(BitcoinTransactionPriority priority) {
    switch (priority) {
      case BitcoinTransactionPriority.fast:
        return highPriority;
      case BitcoinTransactionPriority.medium:
        return mediumPriority;
      case BitcoinTransactionPriority.slow:
        return lowPriority;
      default:
        throw Exception("Unknown priority level");
    }
  }
}
