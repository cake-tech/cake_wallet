import 'dart:convert';

import 'package:cw_core/pending_transaction.dart';
import 'package:cw_zano/api/exceptions/transfer_exception.dart';
import 'package:cw_zano/api/model/destination.dart';
import 'package:cw_zano/api/model/transfer_params.dart';
import 'package:cw_zano/api/model/transfer_result.dart';
import 'package:cw_zano/zano_formatter.dart';
import 'package:cw_zano/zano_wallet.dart';

class PendingZanoTransaction with PendingTransaction {
  PendingZanoTransaction({
    required this.zanoWallet,
    required this.destinations,
    required this.fee,
    required this.comment,
    required this.assetId,
    required this.ticker,
    this.decimalPoint = ZanoFormatter.defaultDecimalPoint,
    required this.amount,
  });

  final ZanoWalletBase zanoWallet;
  final List<Destination> destinations;
  final BigInt fee;
  final String comment;
  final String assetId;
  final String ticker;
  final int decimalPoint;
  final BigInt amount;

  @override
  String get id => transferResult?.txHash ?? '';

  @override
  String get hex => '';

  @override
  String get amountFormatted => '${ZanoFormatter.bigIntAmountToString(amount, decimalPoint)} $ticker';

  @override
  String get feeFormatted => '${ZanoFormatter.bigIntAmountToString(fee)} ZANO';

  TransferResult? transferResult;

  @override
  Future<void> commit() async {
    final params = TransferParams(
      destinations: destinations,
      fee: fee,
      mixin: zanoMixinValue,
      paymentId: '',
      comment: comment,
      pushPayer: false,
      hideReceiver: true,
    );
    final result = await zanoWallet.invokeMethod('transfer', params);
    final map = jsonDecode(result);
    final resultMap = map['result'] as Map<String, dynamic>?;
    if (resultMap != null) {
      final transferResultMap = resultMap['result'] as Map<String, dynamic>?;
      if (transferResultMap != null) {
        transferResult = TransferResult.fromJson(transferResultMap);
        print('transfer success hash ${transferResult!.txHash}');
        await zanoWallet.fetchTransactions();
      } else {
        final errorCode = resultMap['error']['code'];
        final code = errorCode is int ? errorCode.toString() : errorCode as String? ?? '';
        final message = resultMap['error']['message'] as String? ?? '';
        print('transfer error $code $message');
        throw TransferException(code, message);
      }
    }
  }

  
}
