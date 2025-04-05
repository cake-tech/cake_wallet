import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_xelis/xelis_formatting.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;
import 'package:cw_core/format_amount.dart';

import 'dart:math';

class XelisTransactionInfo extends TransactionInfo {
  XelisTransactionInfo({
    required this.id,
    required this.height,
    required this.direction,
    required this.date,
    required this.xelAmount,
    required this.xelFee,
    this.decimals = 8,
    this.assetSymbol = "XEL",
    required this.to,
    required this.from,
  }) :
    amount = xelAmount.toInt(),
    fee = xelFee.toInt()
  ;

  final String id;
  final int amount;
  final int fee;
  final int height;
  final BigInt xelAmount;
  final BigInt xelFee;
  final DateTime date;
  final TransactionDirection direction;
  final int decimals;
  final String assetSymbol;
  final String? to;
  final String? from;

  String? _fiatAmount;

  @override
  String amountFormatted() {
    final amount = formatAmount((xelAmount / BigInt.from(10).pow(decimals)).toString());
    return '${amount.substring(0, min(10, amount.length))} $assetSymbol';
  }

  @override
  String feeFormatted() =>
    formatXelisAmountWithSymbol(fee, decimals: 8, symbol: 'XEL');

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) {
    _fiatAmount = formatAmount(amount);
  }

  static XelisTransactionInfo fromTransactionEntry(
    xelis_sdk.TransactionEntry entry
  ) {
    final txType = entry.txEntryType;

    late TransactionDirection direction;
    BigInt amount = BigInt.zero;
    BigInt fee = BigInt.zero;
    String? to;
    String? from;

    switch (txType) {
      case xelis_sdk.IncomingEntry():
        direction = TransactionDirection.incoming;

        amount = txType.transfers
          .map((t) => BigInt.from(t.amount))
          .fold(BigInt.zero, (a, b) => a + b);

        from = txType.from;
        break;

      case xelis_sdk.OutgoingEntry():
        direction = TransactionDirection.outgoing;

        amount = txType.transfers
          .map((t) => BigInt.from(t.amount))
          .fold(BigInt.zero, (a, b) => a + b);

        if (txType.transfers.isNotEmpty) {
          to = txType.transfers.first.destination;
        }

        fee = BigInt.from(txType.fee);
        break;

      case xelis_sdk.BurnEntry():
        direction = TransactionDirection.incoming;
        amount = BigInt.from(txType.amount);
        fee = BigInt.from(txType.fee);
        break;

      case xelis_sdk.CoinbaseEntry():
        direction = TransactionDirection.incoming;
        amount = BigInt.from(txType.reward);
        break;

      default:
        direction = TransactionDirection.outgoing;
        break;
    }

    return XelisTransactionInfo(
      id: entry.hash,
      height: entry.topoheight,
      direction: direction,
      date: entry.timestamp ?? DateTime.now(),
      xelAmount: amount,
      xelFee: fee,
      to: to,
      from: from,
      decimals: 8, // TODO: get decimals from entry.asset
      assetSymbol: "XEL", // TODO: get symbol from entry.asset
    );
  }

  Map<String, dynamic> toJson() => {
      'id': id,
      'height': height,
      'amount': xelAmount.toString(),
      'decimals': decimals,
      'fee': xelAmount.toString(),
      'direction': direction.index,
      'date': date.millisecondsSinceEpoch,
      'assetSymbol': assetSymbol,
      'to': to,
      'from': from,
    };
}