import 'dart:convert';

import 'package:cw_zano/api/exceptions/transfer_exception.dart';
import 'package:cw_zano/api/model/destination.dart';
import 'package:cw_zano/api/model/transfer_params.dart';
import 'package:cw_zano/api/model/transfer_result.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_zano/api/api_calls.dart' as calls;
import 'package:cw_zano/zano_wallet.dart';

class PendingZanoTransaction with PendingTransaction {
  PendingZanoTransaction(
      {required this.zanoWallet,
      required this.fee,
      required this.intAmount,
      //required this.stringAmount,
      required this.hWallet,
      required this.address,
      required this.assetId,
      required this.comment});

  final ZanoWalletBase zanoWallet;
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
    final params = TransferParams(
      destinations: [
        Destination(
          amount: intAmount.toString(),
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
    );
    final result = await zanoWallet.invokeMethod(hWallet, 'transfer', params);
    final map = jsonDecode(result);
    if (map['result'] != null && map['result']['result'] != null) {
      transferResult = TransferResult.fromJson(
        map['result']['result'] as Map<String, dynamic>,
      );
      await zanoWallet.fetchTransactions();
    } else if (map['result'] != null && map['result']['error'] != null) {
      final String code;
      if (map['result']['error']['code'] is int) {
        code = (map['result']['error']['code'] as int).toString();
      } else if (map['result']['error']['code'] is String) {
        code = map['result']['error']['code'] as String;
      } else {
        code = '';
      }
      final message = map['result']['error']['message'] as String;
      print('transfer error $code $message');
      throw TransferException(code, message);
    }
  }
}
