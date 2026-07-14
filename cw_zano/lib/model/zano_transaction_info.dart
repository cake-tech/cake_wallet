import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_zano/api/model/transfer.dart';
import 'package:cw_zano/zano_formatter.dart';

class ZanoTransactionInfo extends TransactionInfo {
  ZanoTransactionInfo({
    required this.id,
    required this.height,
    required this.direction,
    required this.date,
    required this.isPending,
    required this.amount,
    required this.fee,
    required this.confirmations,
    required this.tokenSymbol,
    required this.decimalPoint,
    required String assetId,
  }) {
    additionalInfo['assetId'] = assetId;
  }

  ZanoTransactionInfo.fromTransfer(Transfer transfer,
      {required int confirmations,
      required bool isIncome,
      required String assetId,
      required Money amount,
      this.tokenSymbol = 'ZANO',
      this.decimalPoint = ZanoFormatter.defaultDecimalPoint})
      : id = transfer.txHash,
        height = transfer.height,
        direction = isIncome ? TransactionDirection.incoming : TransactionDirection.outgoing,
        date = DateTime.fromMillisecondsSinceEpoch(transfer.timestamp * 1000),
        amount = amount,
        fee = Money.fromInt(transfer.fee, CryptoCurrency.zano),
        confirmations = confirmations,
        isPending = confirmations < 10,
        recipientAddress =
            transfer.remoteAddresses.isNotEmpty ? transfer.remoteAddresses.first : '' {
    additionalInfo = <String, dynamic>{
      'comment': transfer.comment,
      'assetId': assetId,
    };
  }

  String get assetId => additionalInfo["assetId"] as String;

  set assetId(String newId) => additionalInfo["assetId"] = newId;
  final String id;
  final int height;
  final TransactionDirection direction;
  final DateTime date;
  final bool isPending;
  final Money amount;
  final Money fee;
  final int confirmations;
  final int decimalPoint;
  late String recipientAddress;
  final String tokenSymbol;
  String? key;
}
