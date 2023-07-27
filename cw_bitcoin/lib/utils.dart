import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:hex/hex.dart';

bitcoin.PaymentData generatePaymentData(
        {required bitcoin.HDWallet hd, required int index}) =>
    PaymentData(
        pubkey: Uint8List.fromList(HEX.decode(hd.derive(index).pubKey!)));

bitcoin.ECPair generateKeyPair(
        {required bitcoin.HDWallet hd,
        required int index,
        required bitcoin.NetworkType network}) =>
    bitcoin.ECPair.fromWIF(hd.derive(index).wif!, network: network);

String generateP2WPKHAddress(
        {required bitcoin.HDWallet hd,
        required int index,
        required bitcoin.NetworkType networkType}) =>
    bitcoin
        .P2WPKH(
            data: PaymentData(
                pubkey:
                    Uint8List.fromList(HEX.decode(hd.derive(index).pubKey!))),
            network: networkType)
        .data
        .address!;

String generateP2WPKHAddressByPath(
        {required bitcoin.HDWallet hd,
        required String path,
        required bitcoin.NetworkType networkType}) =>
    bitcoin
        .P2WPKH(
            data: PaymentData(
                pubkey:
                    Uint8List.fromList(HEX.decode(hd.derivePath(path).pubKey!))),
            network: networkType)
        .data
        .address!;

String generateP2PKHAddress(
        {required bitcoin.HDWallet hd,
        required int index,
        required bitcoin.NetworkType networkType}) =>
    bitcoin
        .P2PKH(
            data: PaymentData(
                pubkey:
                    Uint8List.fromList(HEX.decode(hd.derive(index).pubKey!))),
            network: networkType)
        .data
        .address!;
