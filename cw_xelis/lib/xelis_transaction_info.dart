import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_xelis/xelis_formatting.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;
import 'package:cw_core/format_amount.dart';

class XelisTransactionInfo extends TransactionInfo {
  XelisTransactionInfo({
    required this.id,
    required this.height,
    required this.direction,
    required this.date,
    required this.amount,
    required this.fee,
    this.decimals = 8,
    this.assetSymbol = "XEL",
    required this.to,
    required this.from,
    // this.additionalAssets = const {},
  });

  final String id;
  final int amount;
  final int fee;
  final int height;
  final DateTime date;
  final TransactionDirection direction;
  final int decimals;
  final String assetSymbol;
  final String? to;
  final String? from;
  // final Map<String, BigInt> additionalAssets;

  String? _fiatAmount;

  @override
  String amountFormatted() =>
    formatXelisAmountWithSymbol(amount, decimals: decimals, symbol: assetSymbol);

  @override
  String feeFormatted() =>
    formatXelisAmountWithSymbol(fee, decimals: 8, symbol: assetSymbol);

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
    int amount = 0;
    int fee = 0;
    String? to;
    String? from;

    switch (txType) {
      case xelis_sdk.IncomingEntry():
        direction = TransactionDirection.incoming;

        amount = txType.transfers
          .map((t) => t.amount)
          .fold(0, (a, b) => a + b)
          .toInt();

        from = txType.from;
        break;

      case xelis_sdk.OutgoingEntry():
        direction = TransactionDirection.outgoing;

        amount = txType.transfers
          .map((t) => t.amount)
          .fold(0, (a, b) => a + b)
          .toInt();

        if (txType.transfers.isNotEmpty) {
          to = txType.transfers.first.destination;
        }

        fee = txType.fee.toInt();
        break;

      case xelis_sdk.BurnEntry():
        direction = TransactionDirection.incoming;
        amount = txType.amount.toInt();
        fee = txType.fee.toInt();
        break;

      case xelis_sdk.CoinbaseEntry():
        direction = TransactionDirection.incoming;
        amount = txType.reward.toInt();
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
      amount: amount,
      fee: fee,
      to: to,
      from: from,
      decimals: 8, // TODO: get decimals from entry.asset
      assetSymbol: "XEL", // TODO: get symbol from entry.asset
    );
  }
}