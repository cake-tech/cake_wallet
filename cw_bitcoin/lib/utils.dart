import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:hex/hex.dart';

bitcoin.PaymentData generatePaymentData({required bitcoin.HDWallet hd, required int index}) =>
    PaymentData(pubkey: Uint8List.fromList(HEX.decode(hd.derive(index).pubKey!)));

ECPrivate generateECPrivate(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    ECPrivate.fromWif(hd.derive(index).wif!, netVersion: network.wifNetVer);

String generateP2WPKHAddress(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    ECPublic.fromHex(hd.derive(index).pubKey!).toP2wpkhAddress().toAddress(network);

String generateP2SHAddress(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    ECPublic.fromHex(hd.derive(index).pubKey!).toP2wpkhInP2sh().toAddress(network);

String generateP2WSHAddress(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    ECPublic.fromHex(hd.derive(index).pubKey!).toP2wshAddress().toAddress(network);

String generateP2PKHAddress(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    ECPublic.fromHex(hd.derive(index).pubKey!).toP2pkhAddress().toAddress(network);

String generateP2TRAddress(
        {required bitcoin.HDWallet hd, required int index, required BasedUtxoNetwork network}) =>
    ECPublic.fromHex(hd.derive(index).pubKey!).toTaprootAddress().toAddress(network);
