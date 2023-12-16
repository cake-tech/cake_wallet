import 'dart:convert';

import 'package:cw_zano/api/model/destination.dart';
import 'package:cw_zano/api/model/transfer_params.dart';
import 'package:cw_zano/api/model/transfer_result.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_zano/api/calls.dart' as calls;
import 'package:cw_zano/zano_wallet.dart';

class PendingZanoTransaction with PendingTransaction {
  PendingZanoTransaction(
      {required this.fee,
      required this.intAmount,
      //required this.stringAmount,
      required this.hWallet,
      required this.address,
      required this.assetId,
      required this.comment});

  final int hWallet;
  final int intAmount;
  //final String stringAmount;
  final int fee;
  final String address;
  final String assetId;
  final String comment;

  final CryptoCurrency cryptoCurrency = CryptoCurrency.zano;

  @override
  String get id => transferResult != null ? transferResult!.txHash : '';

  @override
  String get hex => '';

  @override
  String get amountFormatted {
    return AmountConverter.amountIntToString(cryptoCurrency, intAmount);
  }

  @override
  String get feeFormatted => AmountConverter.amountIntToString(cryptoCurrency, fee);

  TransferResult? transferResult;

  @override
  Future<void> commit() async {
    final result = await calls.transfer(
        hWallet,
        TransferParams(
          destinations: [
            Destination(
              amount: intAmount.toString(), //stringAmount,
              address: address,
              assetId: assetId,
            )
          ],
          fee: fee,
          mixin: zanoMixin,
          paymentId: '',
          comment: comment,
          pushPayer: false,
          hideReceiver: false,
        ));
    print('transfer result $result');
    final map = jsonDecode(result);
    if (map["result"] != null && map["result"]["result"] != null ) {
      transferResult = TransferResult.fromJson(
        map["result"]["result"] as Map<String, dynamic>,
      );
    }
    // try {
    //   zano_transaction_history.commitTransactionFromPointerAddress(
    //       address: pendingTransactionDescription.pointerAddress);
    // } catch (e) {
    //   final message = e.toString();

    //   if (message.contains('Reason: double spend')) {
    //     throw DoubleSpendException();
    //   }

    //   rethrow;
    // }
  }
}
