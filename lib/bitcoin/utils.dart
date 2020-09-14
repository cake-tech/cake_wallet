import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:bitcoin_flutter/src/payments/index.dart' show PaymentData;
import 'package:hex/hex.dart';

bitcoin.PaymentData generatePaymentData(
        {@required bitcoin.HDWallet hd, @required int index}) =>
    PaymentData(
        pubkey: Uint8List.fromList(HEX.decode(hd.derive(index).pubKey)));

bitcoin.ECPair generateKeyPair(
        {@required bitcoin.HDWallet hd,
        @required int index,
        bitcoin.NetworkType network}) =>
    bitcoin.ECPair.fromWIF(hd.derive(index).wif,
        network: network ?? bitcoin.bitcoin);

String generateAddress({@required bitcoin.HDWallet hd, @required int index}) =>
    bitcoin
        .P2WPKH(
            data: PaymentData(
                pubkey:
                    Uint8List.fromList(HEX.decode(hd.derive(index).pubKey))))
        .data
        .address;
