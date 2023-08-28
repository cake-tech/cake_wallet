import 'package:bitbox/bitbox.dart' as bitbox;
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_transaction_credentials.dart';
import 'package:cw_bitcoin/bitcoin_transaction_no_inputs_exception.dart';
import 'package:cw_bitcoin/bitcoin_transaction_priority.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin_cash/src/pending_bitcoin_cash_transaction.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/foundation.dart';
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
        sideHd: bitcoin.HDWallet.fromSeed(seedBytes, network: bitcoinCashNetworkType)
            .derivePath("m/44'/145'/0'/1"),
        networkType: networkType);
  }

  static bitcoin.NetworkType bitcoinCashNetworkType = bitcoin.NetworkType(
      messagePrefix: '\x18Bitcoin Signed Message:\n',
      bech32: 'bc',
      bip32: bitcoin.Bip32Type(
        public: 0x0488b21e,
        private: 0x0488ade4,
      ),
      pubKeyHash: 0x00,
      scriptHash: 0x05,
      wif: 0x80);

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
  Future<PendingBitcoinCashTransaction> createTransaction(Object credentials) async {
    const minAmount = 546;
    final transactionCredentials = credentials as BitcoinTransactionCredentials;
    final outputs = transactionCredentials.outputs;
    final hasMultiDestination = outputs.length > 1;
    final builder = bitbox.Bitbox.transactionBuilder(testnet: false);

    var allInputsAmount = 0;
    var inputs = <BitcoinUnspent>[];

    if (unspentCoins.isEmpty) await updateUnspent();

    inputs = unspentCoins.where((element) => element.isSending).toList();
    allInputsAmount = inputs.fold(0, (prev, element) => prev + element.value);

    if (inputs.isEmpty) throw BitcoinTransactionNoInputsException();

    inputs.forEach((BitcoinUnspent utx) => builder.addInput(utx.hash, utx.vout));

    final allAmountFee = transactionCredentials.feeRate != null
        ? feeAmountWithFeeRate(transactionCredentials.feeRate!, inputs.length, outputs.length)
        : feeAmountForPriority(transactionCredentials.priority!, inputs.length, outputs.length);

    final allAmount = allInputsAmount - allAmountFee;


    //allInputsAmount - transactionCredentials.outputs.fold(0, (prev, element) => prev + element.value);


// Calculate the amount to send and change
    final sendAmount = transactionCredentials.outputs[0].formattedCryptoAmount!;
    final outputAddress = transactionCredentials.outputs[0].isParsedAddress
        ? transactionCredentials.outputs[0].extractedAddress
        : transactionCredentials.outputs[0].address;
    final fee = bitbox.BitcoinCash.getByteCount(inputs.length, 2);
    final changeAmount = allInputsAmount - sendAmount - fee;

// Add output for the recipient
    builder.addOutput(outputAddress, sendAmount);

// Add change output if there is change
    if (changeAmount > 0) {
      final changeAddress = await walletAddresses.getChangeAddress();
      builder.addOutput(changeAddress, changeAmount);
    }

// Sign all inputs after adding all outputs
    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final keyPair = generateKeyPair(
          hd: input.bitcoinAddressRecord.isHidden ? walletAddresses.sideHd : walletAddresses.mainHd,
          index: input.bitcoinAddressRecord.index,
          network: bitcoinCashNetworkType);
      builder.sign(i, keyPair, input.value);
    }

    // Build the transaction
    final tx = builder.build();

    return PendingBitcoinCashTransaction(tx, type,
        electrumClient: electrumClient, amount: sendAmount, fee: fee);
  }

  bitbox.ECPair generateKeyPair(
          {required bitcoin.HDWallet hd,
          required int index,
          required bitcoin.NetworkType network}) =>
      bitbox.ECPair.fromWIF(hd.derive(index).wif!);

  @override
  int feeAmountForPriority(BitcoinTransactionPriority priority, int inputsCount, int outputsCount) =>
      feeRate(priority) * bitbox.BitcoinCash.getByteCount(inputsCount, outputsCount);

  int feeAmountWithFeeRate(int feeRate, int inputsCount, int outputsCount) =>
      feeRate * bitbox.BitcoinCash.getByteCount(inputsCount, outputsCount);

  @override
  int feeRate(TransactionPriority priority) {
    if (priority is BitcoinCashTransactionPriority) {
      switch (priority) {
        case BitcoinCashTransactionPriority.slow:
          return 1;
        case BitcoinCashTransactionPriority.medium:
          return 5;
        case BitcoinCashTransactionPriority.fast:
          return 10;
      }
    }

    return 0;
  }
}

