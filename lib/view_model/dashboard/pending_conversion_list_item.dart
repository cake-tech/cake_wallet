import 'package:cake_wallet/entities/pending_conversion.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/entities/conversion_display.dart';
import 'package:cake_wallet/entities/conversion_status.dart';

/// A [PendingConversion] wrapped for [DashboardViewModel.items] - see [PendingConversion]'s own
/// doc comment for why this exists alongside the wallet's real transaction history.
class PendingConversionListItem extends ActionListItem {
  PendingConversionListItem({required this.conversion, required super.key});

  final PendingConversion conversion;

  @override
  DateTime get date => conversion.createdAt;

  /// [PendingConversion.amountOutBaseUnits]/[amountOutDecimals] rendered as a plain decimal
  /// string - no [Currency] is available here (see [PendingConversion]'s own doc comment), so
  /// this can't go through `Money`/`amountParsingProxy` like a real transaction row does.
  String get formattedAmount {
    final raw = BigInt.parse(conversion.amountOutBaseUnits);
    final divisor = BigInt.from(10).pow(conversion.amountOutDecimals);
    final whole = raw ~/ divisor;
    if (conversion.amountOutDecimals == 0) return whole.toString();
    final fraction =
        (raw % divisor).toString().padLeft(conversion.amountOutDecimals, '0');
    final trimmedFraction = fraction.replaceAll(RegExp(r'0+$'), '');
    return trimmedFraction.isEmpty ? '$whole' : '$whole.$trimmedFraction';
  }

  /// Always pending by construction - this item only exists between commit and the real
  /// transaction record showing up, and [PendingConversionStore.reconcile] removes it as soon
  /// as that record reaches a terminal status.
  ConversionDisplay get display => ConversionDisplay(
        status: ConversionStatus.pending,
        fromTicker: conversion.fromTicker,
        toTicker: conversion.toTicker,
        toIsToken: conversion.toIsToken,
      );
}
