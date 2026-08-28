import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_zano/api/model/transfer.dart';
import 'package:cw_zano/zano_formatter.dart';

class ZanoTransactionInfo extends TransactionInfo {
  ZanoTransactionInfo({
    required super.id,
    required this.height,
    required super.direction,
    required super.date,
    required this.isPending,
    required super.amount,
    required Money super.fee,
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
      required super.amount,
      this.tokenSymbol = 'ZANO',
      this.decimalPoint = ZanoFormatter.defaultDecimalPoint})
      : height = transfer.height,

        confirmations = confirmations,
        isPending = confirmations < 10,
        recipientAddress =
            transfer.remoteAddresses.isNotEmpty ? transfer.remoteAddresses.first : '',
        super(
          id: transfer.txHash,
          fee: Money.fromInt(transfer.fee, CryptoCurrency.zano),
          direction: isIncome ? TransactionDirection.incoming : TransactionDirection.outgoing,
          date: DateTime.fromMillisecondsSinceEpoch(transfer.timestamp * 1000),
        ) {
    additionalInfo = <String, dynamic>{
      'comment': transfer.comment,
      'assetId': assetId,
    };
  }

  String get assetId => additionalInfo["assetId"] as String;

  set assetId(String newId) => additionalInfo["assetId"] = newId;
  final int height;
  final bool isPending;
  final int confirmations;
  final int decimalPoint;
  late String recipientAddress;
  final String tokenSymbol;
  String? key;

  @override
  int get neededConfirmations => 10;
}
