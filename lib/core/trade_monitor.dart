import 'dart:async';
import 'package:cake_wallet/exchange/provider/jupiter_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/near_Intents_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/pegaroute_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/simpleswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swapsxyz_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/chainflip_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/changenow_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/exolix_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/letsexchange_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/swaptrade_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/sideshift_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/stealth_ex_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/thorchain_exchange.provider.dart';
import 'package:cake_wallet/exchange/provider/trocador_exchange_provider.dart';
import 'package:cake_wallet/exchange/provider/xoswap_exchange_provider.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_trade_record.dart';

class TradeMonitor {
  static const int _tradeCheckIntervalMinutes = 5;
  static const int _maxTradeAgeHours = 24;

  TradeMonitor({
    required this.tradesStore,
    required this.appStore,
    required this.preferences,
    DateTime Function()? clock,
    ExchangeProvider? Function(ExchangeProviderDescription)? providerFactory,
  }) : _clock = clock ?? DateTime.now, _providerFactory = providerFactory;

  final TradesStore tradesStore;
  final AppStore appStore;
  final Map<String, Timer> _tradeTimers = {};
  final SharedPreferences preferences;
  final DateTime Function() _clock;
  final ExchangeProvider? Function(ExchangeProviderDescription)? _providerFactory;
  final Set<String> _checksInFlight = {};

  ExchangeProvider? _getProviderByDescription(ExchangeProviderDescription description) {
    if (_providerFactory != null) return _providerFactory(description);
    switch (description) {
      case ExchangeProviderDescription.changeNow:
        return ChangeNowExchangeProvider(settingsStore: appStore.settingsStore);
      case ExchangeProviderDescription.sideShift:
        return SideShiftExchangeProvider();
      case ExchangeProviderDescription.simpleSwap:
        return SimpleSwapExchangeProvider();
      case ExchangeProviderDescription.trocador:
        return TrocadorExchangeProvider();
      case ExchangeProviderDescription.exolix:
        return ExolixExchangeProvider();
      case ExchangeProviderDescription.thorChain:
        return ThorChainExchangeProvider();
      case ExchangeProviderDescription.swapTrade:
        return SwapTradeExchangeProvider();
      case ExchangeProviderDescription.letsExchange:
        return LetsExchangeExchangeProvider();
      case ExchangeProviderDescription.stealthEx:
        return StealthExExchangeProvider();
      case ExchangeProviderDescription.chainflip:
        return ChainflipExchangeProvider();
      case ExchangeProviderDescription.xoSwap:
        return XOSwapExchangeProvider();
      case ExchangeProviderDescription.swapsXyz:
        return SwapsXyzExchangeProvider();
      case ExchangeProviderDescription.jupiter:
        return JupiterExchangeProvider();
      case ExchangeProviderDescription.nearIntents:
        return NearIntentsExchangeProvider();
      case ExchangeProviderDescription.pegaRoute:
        return PegaRouteExchangeProvider();
    }
    return null;
  }

  void monitorActiveTrades(String walletId) {
    // Checks if the trade monitoring is permitted
    // i.e the user has not disabled the exchange api mode or the status updates
    final isTradeMonitoringPermitted = _isTradeMonitoringPermitted();
    if (!isTradeMonitoringPermitted) {
      _cancelMultipleTradeTimers(_tradeTimers.keys.where((id) => tradesStore.trades.any((item) =>
          item.trade.id == id && item.trade.provider == ExchangeProviderDescription.pegaRoute)).toList());
      return;
    }

    final trades = tradesStore.trades;
    final tradesToCancel = <String>[];

    for (final item in trades) {
      final trade = item.trade;

      final provider = _getProviderByDescription(trade.provider);

      // Multiple checks to see if to skip the trade, if yes, we cancel the timer if it exists
      if (_shouldSkipTrade(trade, walletId, provider)) {
        tradesToCancel.add(trade.id);
        continue;
      }

      if (_tradeTimers.containsKey(trade.id)) {
        continue;
      } else {
        _startTradeMonitoring(trade, provider!);
      }
    }

    // After going through the list of available trades, we cancel the timers in the tradesToCancel list
    _cancelMultipleTradeTimers(tradesToCancel);
  }

  bool _isTradeMonitoringPermitted() {
    final disableAutomaticExchangeStatusUpdates =
        appStore.settingsStore.disableAutomaticExchangeStatusUpdates;
    if (disableAutomaticExchangeStatusUpdates) {
      printV('Automatic exchange status updates are disabled');
      return false;
    }

    final exchangeApiMode = appStore.settingsStore.exchangeStatus;
    if (exchangeApiMode == ExchangeApiMode.disabled) {
      printV('Exchange API mode is disabled');
      return false;
    }

    return true;
  }

  bool _shouldSkipTrade(Trade trade, String walletId, ExchangeProvider? provider) {
    if (trade.walletId != walletId) {
      return true;
    }

    final createdAt = trade.createdAt;
    final fundedPegaroute = _isFundedPegaroute(trade);
    if (createdAt == null && !fundedPegaroute) {
      printV('Skipping trade ${trade.id} because it has no createdAt');
      return true;
    }

    if (!fundedPegaroute && createdAt != null &&
        _clock().difference(createdAt).inHours > _maxTradeAgeHours) {
      printV('Skipping trade ${trade.id} because it\'s older than ${_maxTradeAgeHours} hours');
      return true;
    }

    if (_isFinalStateForTrade(trade)) {
      return true;
    }

    if (provider == null) {
      printV('Skipping trade ${trade.id} because the provider is not supported');
      return true;
    }

    if (appStore.settingsStore.exchangeStatus == ExchangeApiMode.torOnly &&
        !provider.supportsOnionAddress) {
      printV('Skipping ${provider.description}, no TOR support');
      return true;
    }

    return false;
  }

  void _startTradeMonitoring(Trade trade, ExchangeProvider provider) {
    final timer = Timer.periodic(
      Duration(minutes: _tradeCheckIntervalMinutes),
      (_) => _checkTradeStatus(trade, provider),
    );

    _tradeTimers[trade.id] = timer;
    _checkTradeStatus(trade, provider);
  }

  Future<void> _checkTradeStatus(Trade trade, ExchangeProvider provider) async {
    final isPegaroute = trade.provider == ExchangeProviderDescription.pegaRoute;
    if (isPegaroute) {
      if (!_isTradeMonitoringPermitted() || provider is! PegaRouteExchangeProvider) {
        _cancelSingleTradeTimer(trade.id);
        return;
      }
      // A timer may have captured the row before funding. Reread its bound
      // identity rather than applying the age/terminal gate to that stale copy.
      try { trade = await provider.store.latest(trade); }
      catch (_) { _cancelSingleTradeTimer(trade.id); return; }
      if (!_isTradeMonitoringPermitted() ||
          _shouldSkipTrade(trade, appStore.wallet?.id ?? '', provider)) {
        _cancelSingleTradeTimer(trade.id);
        return;
      }
    }
    final lastUpdatedAtFromPrefs = preferences.getString('trade_${trade.id}_updated_at');

    if (lastUpdatedAtFromPrefs != null) {
      final lastUpdatedAtDateTime = isPegaroute
          ? DateTime.tryParse(lastUpdatedAtFromPrefs) : DateTime.parse(lastUpdatedAtFromPrefs);
      final timeSinceLastUpdate = lastUpdatedAtDateTime == null ? _tradeCheckIntervalMinutes
          : _clock().difference(lastUpdatedAtDateTime).inMinutes;

      if (timeSinceLastUpdate < _tradeCheckIntervalMinutes) {
        printV(
          'Skipping trade ${trade.id} status update check because it was updated less than ${_tradeCheckIntervalMinutes} minutes ago ($timeSinceLastUpdate minutes ago)',
        );
        return;
      }
    }

    if (isPegaroute && !_checksInFlight.add(trade.id)) return;
    try {
      final updated = await provider.findTradeById(id: trade.id);
      if (isPegaroute) {
        // Another stale generic save could erase Pegaroute's already-persisted funding claim.
        trade = updated;
      } else {
        trade.mergeFindTradeByIdResult(updated);
        await trade.save();
      }
      printV('Trade ${trade.id} updated: ${trade.state}');

      await preferences.setString('trade_${trade.id}_updated_at', _clock().toIso8601String());
      printV('Trade ${trade.id} updated at: ${_clock().toIso8601String()}');

      // If the updated trade is in a final state, we cancel the timer
      if (_isFinalStateForTrade(updated)) {
        printV('Trade ${trade.id} is in final state');
        _cancelSingleTradeTimer(trade.id);
      }
    } catch (e) {
      printV('Error fetching status for ${trade.id}: $e');
    } finally {
      if (isPegaroute) _checksInFlight.remove(trade.id);
    }
  }

  bool _isFundedPegaroute(Trade trade) {
    if (trade.provider != ExchangeProviderDescription.pegaRoute || trade.txId == null) return false;
    try { return PegarouteTradeRecord.read(trade).attempt != null; }
    catch (_) { return false; }
  }

  bool _isFinalStateForTrade(Trade trade) =>
      trade.provider == ExchangeProviderDescription.pegaRoute
          ? const {'success', 'failed', 'refunded'}.contains(trade.stateRaw)
          : _isFinalState(trade.state);

  bool _isFinalState(TradeState state) {
    return {
      TradeState.completed.raw,
      TradeState.success.raw,
      TradeState.confirmed.raw,
      TradeState.settled.raw,
      TradeState.finished.raw,
      TradeState.expired.raw,
      TradeState.failed.raw,
      TradeState.notFound.raw,
    }.contains(state.raw);
  }

  void _cancelSingleTradeTimer(String tradeId) {
    if (_tradeTimers.containsKey(tradeId)) {
      _tradeTimers[tradeId]?.cancel();
      _tradeTimers.remove(tradeId);
      printV('Trade timer for ${tradeId} cancelled');
    }
  }

  void _cancelMultipleTradeTimers(List<String> tradeIds) {
    for (final tradeId in tradeIds) {
      _cancelSingleTradeTimer(tradeId);
    }
  }

  /// This is called when the app is brought back to foreground.
  void resumeTradeMonitoring() {
    if (appStore.wallet != null) {
      monitorActiveTrades(appStore.wallet!.id);
    }
  }

  /// There's no need to run the trade checks when the app is in background.
  /// We only want to update the trade status when the app is in foreground.
  /// This helps to reduce the battery usage, network usage and enhance overall privacy.
  ///
  /// This is called when the app is sent to background or when the app is closed.
  void stopTradeMonitoring() {
    printV('Stopping trade monitoring');
    _cancelMultipleTradeTimers(_tradeTimers.keys.toList());
  }
}
