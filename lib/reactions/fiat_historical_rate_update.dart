import 'dart:async';
import 'package:cake_wallet/core/fiat_conversion_service.dart';
import 'package:cake_wallet/entities/fiat_api_mode.dart';
import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:hive/hive.dart';

Future<void> historicalRateUpdate(
    AppStore appStore,
    SettingsStore settingsStore,
    FiatConversionStore fiatConversionStore,
    Box<TransactionDescription> transactionDescription) async {
  final transactions = appStore.wallet!.transactionHistory.transactions.values.toList();

  const int batchSize = 10;
  const Duration delayBetweenBatches = Duration(milliseconds: 2);

  int nextBatchStart = 0;

  for (int i = 0; i < transactions.length; i += batchSize) {
    final batch = transactions.skip(i).take(batchSize);

    bool needsProcessing = batch.any((tx) {
      var description = transactionDescription.get(tx.id);
      final fiatName = settingsStore.fiatCurrency.toString();
      return description == null ||
          description.historicalRates.isEmpty ||
          !description.historicalRates.containsKey(fiatName);
    });

    if (needsProcessing) {
      await Future.wait(batch.map((tx) async {
        var description = transactionDescription.get(tx.id);
        final fiatName = settingsStore.fiatCurrency.toString();

        if (description == null ||
            description.historicalRates.isEmpty ||
            !description.historicalRates.containsKey(fiatName)) {
          try {
            final result = await FiatConversionService.fetchHistoricalPrice(
                crypto: appStore.wallet!.currency,
                fiat: settingsStore.fiatCurrency,
                torOnly: settingsStore.fiatApiMode == FiatApiMode.torOnly,
                date: tx.date);

            if (result == null) return;

            description ??= TransactionDescription(id: tx.id);
            Map<String, String> rates = description.historicalRates;
            rates[fiatName] = result.toStringAsFixed(4);
            description.historicalRates = rates;
            await transactionDescription.put(tx.id, description);
          } catch (e) {
            print("Error fetching historical price: $e");
          }
        }
      }));

      nextBatchStart = i + batchSize;
      if (nextBatchStart < transactions.length) {
        await Future.delayed(delayBetweenBatches);
      }
    }
  }
}
