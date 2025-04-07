import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_xelis/xelis_formatting.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;
import 'package:cw_core/format_amount.dart';

import 'dart:math';

class XelisTxRecipient {
  final String address;
  final String amount;
  final bool isChange;

  const XelisTxRecipient({
    required this.address,
    required this.amount,
    required this.isChange,
  });
}

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
    this.assetId = xelis_sdk.xelisAsset,
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
  final String assetId;
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

  static Future<XelisTransactionInfo> fromTransactionEntry(
    xelis_sdk.TransactionEntry entry, {required x_wallet.XelisWallet wallet}
  ) async {
    final txType = entry.txEntryType;

    late TransactionDirection direction;
    BigInt amount = BigInt.zero;
    BigInt fee = BigInt.zero;
    String? to;
    String? from;

    String asset = xelis_sdk.xelisAsset;
    switch (txType) {
      case xelis_sdk.IncomingEntry():
        direction = TransactionDirection.incoming;

        amount = txType.transfers
          .map((t) => BigInt.from(t.amount))
          .fold(BigInt.zero, (a, b) => a + b);

        from = txType.from;
        asset = txType.transfers.first.asset;
        break;

      case xelis_sdk.OutgoingEntry():
        direction = TransactionDirection.outgoing;

        asset = txType.transfers.first.asset;
        amount = txType.transfers
            .map((t) => BigInt.from(t.amount))
            .fold(BigInt.zero, (a, b) => a + b);

        if (txType.transfers.isNotEmpty) {
          final firstRecipient = txType.transfers.first.destination;
          final recipientCount = txType.transfers.length;

          to = recipientCount > 1
              ? '$firstRecipient + ${recipientCount - 1} more'
              : firstRecipient;
        }

        fee = BigInt.from(txType.fee);
        break;

      case xelis_sdk.BurnEntry():
        direction = TransactionDirection.outgoing;
        amount = BigInt.from(txType.amount);
        fee = BigInt.from(txType.fee);
        asset = txType.asset;
        break;

      case xelis_sdk.CoinbaseEntry():
        direction = TransactionDirection.incoming;
        amount = BigInt.from(txType.reward);
        break;

      default:
        direction = TransactionDirection.outgoing;
        break;
    }

    final metadata = await wallet.getAssetMetadata(asset: asset);

    return XelisTransactionInfo(
      id: entry.hash,
      height: entry.topoheight,
      direction: direction,
      date: entry.timestamp ?? DateTime.now(),
      xelAmount: amount,
      xelFee: fee,
      to: to,
      from: from,
      decimals: metadata.decimals,
      assetSymbol: metadata.ticker,
      assetId: asset,
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
      'assetId': assetId,
      'to': to,
      'from': from,
    };
}