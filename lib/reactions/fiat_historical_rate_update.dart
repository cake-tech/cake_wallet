import 'dart:async';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:hive/hive.dart';

Future<void> historicalRateUpdate(
    WalletBase wallet,
    SettingsStore settingsStore,
    FiatConversionStore fiatConversionStore,
    Box<TransactionDescription> transactionDescription) async {
  int accuracyMinutes = 0;

  switch (wallet.type) {
    case WalletType.monero:
    case WalletType.polygon:
    case WalletType.nano:
    case WalletType.solana:
    case WalletType.haven:
    case WalletType.tron:
      accuracyMinutes = 540; // 9 hours
      break;
    case WalletType.ethereum:
      accuracyMinutes = 360; // 6 hours
      break;
    case WalletType.bitcoin:
    case WalletType.bitcoinCash:
    case WalletType.litecoin:
      accuracyMinutes = 180; // 3 hours
      break;
    default:
      accuracyMinutes = 180; // 3 hours
  }

  final historicalRateStorageDurationMinutes = 86400; // 2 months
  final intervalCount = historicalRateStorageDurationMinutes ~/ accuracyMinutes;
  final totalAllowedAgeMinutes = historicalRateStorageDurationMinutes + accuracyMinutes;
  final currentTime = DateTime.now();

  final result = await FiatConversionService.fetchHistoricalPrice(
      crypto: wallet.currency,
      fiat: settingsStore.fiatCurrency,
      torOnly: settingsStore.fiatApiMode == FiatApiMode.torOnly,
      intervalCount: intervalCount,
      intervalMinutes: accuracyMinutes);

  if (result == null) return;

  Map<DateTime, double> convertedRates = {};

  result.forEach((key, value) {
    DateTime keyAsDateTime = DateTime.parse(key).toUtc();
    convertedRates[keyAsDateTime] = value as double;
  });

  final transactions = wallet.transactionHistory.transactions.values.toList();

  for (var tx in transactions) {
    final txAgeMinutes = currentTime.difference(tx.date).inMinutes;
    if (txAgeMinutes > totalAllowedAgeMinutes) continue;

    var description = transactionDescription.get(tx.id);
    final fiatName = settingsStore.fiatCurrency.toString();

    if (description == null ||
        description.historicalRates.isEmpty ||
        !description.historicalRates.containsKey(fiatName)) {
      try {
        List<DateTime> historyTimestamps = convertedRates.keys.toList();
        final txHistoryTimestamps = tx.date.toUtc();

        final closestTimestamp = findClosestTimestamp(historyTimestamps, txHistoryTimestamps);

        if (closestTimestamp != null &&
            txHistoryTimestamps.difference(closestTimestamp).abs() <=
                Duration(minutes: accuracyMinutes)) {
          final rate = convertedRates[closestTimestamp];

          if (rate != null) {
            description ??= TransactionDescription(id: tx.id);
            Map<String, String> rates = description.historicalRates;
            rates[fiatName] =
                (rate * AmountConverter.amountIntToDouble(wallet.currency, tx.amount)).toString();
            description.historicalRates = rates;
            await transactionDescription.put(tx.id, description);
          }
        }
      } catch (e) {
        print("Error fetching historical price: $e");
      }
    }
  }
}

DateTime? findClosestTimestamp(List<DateTime> timestamps, DateTime target) {
  DateTime? closest;
  for (var timestamp in timestamps) {
    if (closest == null ||
        (target.difference(timestamp).abs() < target.difference(closest).abs())) {
      closest = timestamp;
    }
  }
  return closest;
}
