import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_xelis/xelis_formatting.dart';
import 'package:cw_xelis/src/api/wallet.dart' as x_wallet;
import 'package:xelis_dart_sdk/xelis_dart_sdk.dart' as xelis_sdk;
import 'package:cw_core/format_amount.dart';

class XelisTransactionInfo extends TransactionInfo {
  XelisTransactionInfo({
    required this.id,
    required this.height,
    required this.direction,
    required this.isPending,
    required this.date,
    required this.amount,
    required this.fee,
    required this.confirmations,
    this.decimals = 8,
    this.assetSymbol = "XEL",
    required this.to,
    required this.from,
    // this.additionalAssets = const {},
  }) {}

  final String id;
  final int amount;
  final bool isPending;
  final double solAmount;
  final String tokenSymbol;
  final DateTime blockTime;
  final TransactionDirection direction;
  final int? decimals;
  final String? assetSymbol;
  final String? to;
  final String? from;
  // final Map<String, BigInt> additionalAssets;

  String? _fiatAmount;

  @override
  Future<String> amountFormatted() =>
    formatAmountWithSymbol(amount, decimals: decimals, symbol: assetSymbol);

  @override
  Future<String> feeFormatted() =>
    formatAmountWithSymbol(fee, decimals: 8, symbol: assetSymbol);

  @override
  String fiatAmount() => _fiatAmount ?? '';

  @override
  void changeFiatAmount(String amount) {
    _fiatAmount = formatAmount(amount);
  }
}