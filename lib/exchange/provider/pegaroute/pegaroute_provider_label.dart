import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'pegaroute_trade_record.dart';
import 'pegaroute_provider_preferences.dart';

String tradeProviderDisplayName(Trade trade) {
  if (trade.provider != ExchangeProviderDescription.pegaRoute) return trade.provider.toString();
  if (trade.internalId <= 0) return trade.provider.title;
  try {
    final record = PegarouteTradeRecord.read(trade);
    final provider = PegarouteProviderPreferences.providers[trade.providerName];
    if (provider == null) return trade.provider.title;
    final subprovider = record.route['subprovider'] as String?;
    final suffix = subprovider == null || subprovider.isEmpty ? '' : ' (via $subprovider)';
    return '${trade.provider.title} via $provider$suffix';
  } catch (_) { return trade.provider.title; }
}
