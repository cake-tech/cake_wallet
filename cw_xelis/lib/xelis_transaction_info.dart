import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_xelis/xelis_formatting.dart';
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;
import 'package:cw_core/format_amount.dart';
import 'package:cw_core/utils/print_verbose.dart';

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
  final int confirmations = 3; // static/unused atm, purely for compatibility

  String? _fiatAmount;

  @override
  String amountFormatted() {
    final List<String> formattedAssets = [];

    if (formattedAssets.length > 1) return ":MULTI:" + multiFormatted();

    final amount = (assetAmounts[0] / BigInt.from(10).pow(decimals[0])).toString();
    return '$amount ${assetSymbols[0]}';
  }

  String multiFormatted() {
    final List<String> formattedAssets = [];

    for (int i = 0; i < assetSymbols.length; i++) {
      final amount = (assetAmounts[i] / BigInt.from(10).pow(decimals[i])).toString();
      formattedAssets.add('$amount ${assetSymbols[i]}');
    }

    return formattedAssets.join('\n\n');
  }

  @override
  String feeFormatted() =>
    XelisFormatter.formatAmountWithSymbol(fee, decimals: 8, symbol: 'XEL');

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) {
    _fiatAmount = formatAmount(amount);
  }

  static Future<XelisTransactionInfo> fromTransactionEntry(
    xelis_sdk.TransactionEntry entry, {required x_wallet.XelisWallet wallet, required bool Function(String assetId) isAssetEnabled}
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
          if (!isAssetEnabled(asset)) continue;

          assetAmounts[asset] = (assetAmounts[asset] ?? BigInt.zero) + BigInt.from(transfer.amount);

          final meta = await wallet.getAssetMetadata(asset: asset);
          assetDecimals[asset] = meta.decimals;
          assetSymbolsMap[asset] = meta.ticker;
        }

        from = txType.from;
        break;

      case xelis_sdk.OutgoingEntry():
        direction = TransactionDirection.outgoing;

        final formattedTransfers = <String>[];

        for (final transfer in txType.transfers) {
          final asset = transfer.asset;
          if (!isAssetEnabled(asset)) continue;

          final meta = await wallet.getAssetMetadata(asset: asset);
          final formatted = XelisTransfer(meta: meta, amount: transfer.amount).format();
          
          assetDecimals[asset] = meta.decimals;
          assetSymbolsMap[asset] = meta.ticker;
          assetAmounts[asset] = (assetAmounts[asset] ?? BigInt.zero) + BigInt.from(transfer.amount);

          if (txType.transfers.length > 1) {
            formattedTransfers.add("${transfer.destination} [ $formatted ]");
          } else {
            formattedTransfers.add("${transfer.destination}");
          }          
        }

        to = formattedTransfers.join('\n\n');
        fee = BigInt.from(txType.fee);
        break;

      case xelis_sdk.BurnEntry():
        direction = TransactionDirection.outgoing;
        final asset = txType.asset;
        final meta = await wallet.getAssetMetadata(asset: asset);

        if (!isAssetEnabled(asset)) {
          break;
        }

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

      case xelis_sdk.InvokeContractEntry():
        direction = TransactionDirection.outgoing;

        for (final entry in txType.deposits.entries) {
          final asset = entry.key;
          final amount = entry.value;

          if (!isAssetEnabled(asset)) {
            continue;
          }

          assetAmounts[asset] = (assetAmounts[asset] ?? BigInt.zero) + BigInt.from(amount);

          final meta = await wallet.getAssetMetadata(asset: asset);
          assetDecimals[asset] = meta.decimals;
          assetSymbolsMap[asset] = meta.ticker;
        }

        fee = BigInt.from(txType.fee);
        to = "SCID:\n${txType.contract}\n\nChunk ID:\n${txType.chunkId}";
        break;

      case xelis_sdk.DeployContractEntry():
        direction = TransactionDirection.outgoing;

        final meta = await wallet.getAssetMetadata(asset: xelis_sdk.xelisAsset);

        assetAmounts[xelis_sdk.xelisAsset] = BigInt.zero;
        assetDecimals[xelis_sdk.xelisAsset] = meta.decimals;
        assetSymbolsMap[xelis_sdk.xelisAsset] = meta.ticker;
        fee = BigInt.from(txType.fee);

      default:
        direction = TransactionDirection.outgoing;
        break;
    }

    final filteredAssetIds = assetAmounts.keys.where(isAssetEnabled).toList();
    final assetIds = filteredAssetIds;
    final assetSymbols = assetIds.map((id) => assetSymbolsMap[id] ?? '???').toList();
    final decimals = assetIds.map((id) => assetDecimals[id] ?? 8).toList();
    final amounts = assetIds.map((id) => assetAmounts[id]!).toList();

    final xelAmount = assetAmounts[xelis_sdk.xelisAsset] ?? BigInt.zero;

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

  factory XelisTransactionInfo.fromJson(
    Map<String, dynamic> data, {
    required bool Function(String assetId) isAssetEnabled,
  }) {
    final allAssetIds = List<String>.from(data['assetIds']);
    final allAssetSymbols = List<String>.from(data['assetSymbols']);
    final allAssetAmounts = (data['assetAmounts'] as List)
        .map<BigInt>((val) => BigInt.parse(val.toString()))
        .toList();
    final allDecimals = List<int>.from(data['decimals']);

    final filteredIndices = <int>[];
    for (int i = 0; i < allAssetIds.length; i++) {
      if (isAssetEnabled(allAssetIds[i])) {
        filteredIndices.add(i);
      }
    }

    final assetIds = filteredIndices.map((i) => allAssetIds[i]).toList();
    final assetSymbols = filteredIndices.map((i) => allAssetSymbols[i]).toList();
    final assetAmounts = filteredIndices.map((i) => allAssetAmounts[i]).toList();
    final decimals = filteredIndices.map((i) => allDecimals[i]).toList();

    final xelAmount = assetAmounts.isNotEmpty ? assetAmounts[0] : BigInt.zero;

    return XelisTransactionInfo(
      id: data['id'] as String,
      height: data['height'] as int,
      decimals: decimals,
      assetAmounts: assetAmounts,
      xelAmount: xelAmount,
      xelFee: BigInt.parse(data['xelFee']),
      direction: parseTransactionDirectionFromInt(data['direction'] as int),
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
      assetSymbols: assetSymbols,
      assetIds: assetIds,
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