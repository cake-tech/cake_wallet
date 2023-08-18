import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:cw_bitcoin/bitcoin_address_record.dart';
import 'package:cw_bitcoin/bitcoin_unspent.dart';
import 'package:cw_bitcoin/electrum_balance.dart';
import 'package:cw_bitcoin/electrum_wallet.dart';
import 'package:cw_bitcoin/electrum_wallet_snapshot.dart';
import 'package:cw_bitcoin/pending_bitcoin_transaction.dart';
import 'package:cw_core/crypto_currency.dart';
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
    Future<PendingBitcoinTransaction> createTransaction(Object credentials,
        [List<Object>? unspents, Object? wallet]) async {

    //   final utxoSigningData = await fetchBuildTxData(unspents as List<BitcoinUnspent>, wallet as BitcoinCashWalletBase);
    //   final builder = bitbox.Bitbox.transactionBuilder(testnet: false);
    //   final utxosToUse = unspents as List<UnspentCash>;
    //   final _wallet = wallet as BitcoinCashWallet;
    //   print('unspents: ${unspents.first.address}');
    //
    //   List<bitbox.Utxo> _utxos = [];
    //   for (var element in utxosToUse) {
    //     _utxos.add(bitbox.Utxo(element.hash, element.vout,
    //         bitbox.BitcoinCash.fromSatoshi(element.value), element.value, 0, 1));
    //   }
    //
    //   final signatures = <Map>[];
    //   int totalBalance = 0;
    //
    //   _utxos.forEach((bitbox.Utxo utxo) {
    //     // add the utxo as an input for the transaction
    //     builder.addInput(utxo.txid, utxo.vout);
    //
    //     final ec = utxoSigningData.firstWhere((e) => e.utxo.hash == utxo.txid).keyPair!;
    //
    //     final bitboxEC = bitbox.ECPair.fromWIF(ec.toWIF());
    //
    //     // add a signature to the list to be used later
    //     signatures
    //         .add({"vin": signatures.length, "key_pair": bitboxEC, "original_amount": utxo.satoshis});
    //
    //     totalBalance += utxo.satoshis;
    //   });
    //
    //   // set an address to send the remaining balance to
    //   final outputAddress = "13Hvge9HRduGiXMfcJHFn6sggequmaKqsZ";
    //
    //   // if there is an unspent balance, create a spending transaction
    //   if (totalBalance > 0 && outputAddress != "") {
    //     // calculate the fee based on number of inputs and one expected output
    //     final fee = bitbox.BitcoinCash.getByteCount(signatures.length, 1);
    //
    //     // calculate how much balance will be left over to spend after the fee
    //     final sendAmount = totalBalance - fee;
    //
    //     // add the output based on the address provided in the testing data
    //     builder.addOutput(outputAddress, sendAmount);
    //
    //     // sign all inputs
    //     signatures.forEach((signature) {
    //       builder.sign(signature["vin"], signature["key_pair"], signature["original_amount"]);
    //     });
    //
    //     // build the transaction
    //     final tx = builder.build();
    //
    //     // broadcast the transaction
    //     final result = await electrumClient.broadcastTransaction(transactionRaw: tx.toHex());
    //
    //     // Yatta!
    //     print("Transaction broadcasted: $result");
    //   }
      return PendingBitcoinTransaction(bitcoin.Transaction(), type,
          electrumClient: electrumClient, amount: 1, fee: 1);
    }

  }
