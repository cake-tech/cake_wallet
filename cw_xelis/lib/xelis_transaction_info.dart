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

class XelisTransfer {
  final x_wallet.XelisAssetMetadata meta;
  final int amount;

  XelisTransfer({
    required this.meta,
    required this.amount
  });

  String format() {
    final amountDouble = (BigInt.from(amount) / BigInt.from(10).pow(meta.decimals)).toString();
    return '${formatAmount(amountDouble)} ${meta.ticker}';
  }
}

class XelisTransactionInfo extends TransactionInfo {
  XelisTransactionInfo({
    required this.id,
    required this.height,
    required this.direction,
    required this.date,
    required this.xelAmount,
    required this.xelFee,
    required this.decimals,
    required this.assetSymbols,
    required this.assetIds,
    required this.assetAmounts,
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
  final List<BigInt> assetAmounts;
  final List<int> decimals;
  final List<String> assetSymbols;
  final List<String> assetIds;
  final String? to;
  final String? from;

  String? _fiatAmount;

  @override
  String amountFormatted() {
    final List<String> formattedAssets = [];

    if (formattedAssets.length > 1) return ":MULTI:" + multiFormatted();

    final amount = (assetAmounts[0] / BigInt.from(10).pow(decimals[0])).toString();
    return '${formatAmount(amount)} ${assetSymbols[0]}';
  }

  String multiFormatted() {
    final List<String> formattedAssets = [];

    for (int i = 0; i < assetSymbols.length; i++) {
      final amount = (assetAmounts[i] / BigInt.from(10).pow(decimals[i])).toString();
      formattedAssets.add('${formatAmount(amount)} ${assetSymbols[i]}');
    }

    return formattedAssets.join('\n\n');
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

    final Map<String, BigInt> assetAmounts = {};
    final Map<String, int> assetDecimals = {};
    final Map<String, String> assetSymbolsMap = {};

    switch (txType) {
      case xelis_sdk.IncomingEntry():
        direction = TransactionDirection.incoming;

        for (final transfer in txType.transfers) {
          final asset = transfer.asset;
          assetAmounts[asset] = (assetAmounts[asset] ?? BigInt.zero) + BigInt.from(transfer.amount);

          final meta = await wallet.getAssetMetadata(asset: asset);
          assetDecimals[asset] = meta.decimals;
          assetSymbolsMap[asset] = meta.ticker;
        }

        from = txType.from;
        break;

      case xelis_sdk.OutgoingEntry():
        direction = TransactionDirection.outgoing;

        List<XelisTransfer> localTransfers = [];

        for (final transfer in txType.transfers) {
          final asset = transfer.asset;
          assetAmounts[asset] = (assetAmounts[asset] ?? BigInt.zero) + BigInt.from(transfer.amount);

          final meta = await wallet.getAssetMetadata(asset: asset);
          localTransfers.add(
            XelisTransfer(
              meta: meta,
              amount: transfer.amount
            )
          );
          assetDecimals[asset] = meta.decimals;
          assetSymbolsMap[asset] = meta.ticker;
        }

        final formattedTransfers = txType.transfers
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final t = entry.value;
            return "${t.destination} ( ${localTransfers[index].format()} )";
          })
          .where((transfer) => transfer.isNotEmpty)
          .toList();

        to = formattedTransfers.join('\n\n');

        fee = BigInt.from(txType.fee);
        break;

      case xelis_sdk.BurnEntry():
        direction = TransactionDirection.outgoing;
        final asset = txType.asset;
        final meta = await wallet.getAssetMetadata(asset: asset);

        assetAmounts[asset] = BigInt.from(txType.amount);
        assetDecimals[asset] = meta.decimals;
        assetSymbolsMap[asset] = meta.ticker;

        to = "Burned";

        fee = BigInt.from(txType.fee);
        break;

      case xelis_sdk.CoinbaseEntry():
        direction = TransactionDirection.incoming;
        final meta = await wallet.getAssetMetadata(asset: xelis_sdk.xelisAsset);

        assetAmounts[xelis_sdk.xelisAsset] = BigInt.from(txType.reward);
        assetDecimals[xelis_sdk.xelisAsset] = meta.decimals;
        assetSymbolsMap[xelis_sdk.xelisAsset] = meta.ticker;
        break;

      default:
        direction = TransactionDirection.outgoing;
        break;
    }

    final assetIds = assetAmounts.keys.toList();
    final assetSymbols = assetIds.map((id) => assetSymbolsMap[id] ?? '???').toList();
    final decimals = assetIds.map((id) => assetDecimals[id] ?? 8).toList();
    final amounts = assetIds.map((id) => assetAmounts[id]!).toList();

    final xelAmount = amounts[0] ?? BigInt.zero;

    return XelisTransactionInfo(
      id: entry.hash,
      height: entry.topoheight,
      direction: direction,
      date: entry.timestamp ?? DateTime.now(),
      xelAmount: xelAmount,
      xelFee: fee,
      to: to,
      from: from,
      decimals: decimals,
      assetSymbols: assetSymbols,
      assetIds: assetIds,
      assetAmounts: amounts,
    );
  }

  factory XelisTransactionInfo.fromJson(Map<String, dynamic> data) {
    return XelisTransactionInfo(
      id: data['id'] as String,
      height: data['height'] as int,
      decimals: List<int>.from(data['decimals']),
      assetAmounts: (data['assetAmounts'] as List)
          .map<BigInt>((val) => BigInt.parse(val.toString()))
          .toList(),
      xelAmount: BigInt.parse(data['xelAmount']),
      xelFee: BigInt.parse(data['xelFee']),
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      assetSymbols: List<String>.from(data['assetSymbols']),
      assetIds: List<String>.from(data['assetIds']),
      to: data['to'],
      from: data['from'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'height': height,
    'decimals': decimals,
    'assetSymbols': assetSymbols,
    'assetIds': assetIds,
    'assetAmounts': assetAmounts.map((e) => e.toString()).toList(),
    'xelAmount': xelAmount.toString(),
    'xelFee': xelFee.toString(),
    'direction': direction.index,
    'date': date.millisecondsSinceEpoch,
    'to': to,
    'from': from,
  };
}