import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:cw_bitcoin/litecoin_network.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:hex/hex.dart';

bitcoin.PaymentData generatePaymentData({required bitcoin.HDWallet hd, required int index}) =>
    PaymentData(pubkey: Uint8List.fromList(HEX.decode(hd.derive(index).pubKey!)));

bitcoin.ECPair generateKeyPair(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    bitcoin.ECPair.fromWIF(hd.derive(index).wif!,
        network: network == BitcoinNetwork.mainnet
            ? bitcoin.bitcoin
            : network == LitecoinNetwork.mainnet
                ? litecoinNetwork
                : bitcoin.bitcoin);

String generateP2WPKHAddress(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    P2wpkhAddress.fromPubkey(pubkey: hd.derive(index).pubKey!).toAddress(network);

String generateP2WSHAddress(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    P2wshAddress.fromPubkey(pubkey: hd.derive(index).pubKey!).toAddress(network);

String generateP2PKHAddress(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    P2pkhAddress.fromPubkey(pubkey: hd.derive(index).pubKey!).toAddress(network);

String generateP2TRAddress(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    P2trAddress.fromPubkey(pubkey: hd.derive(index).pubKey!).toAddress(network);
