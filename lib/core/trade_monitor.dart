import 'dart:async';
import 'package:cake_wallet/exchange/provider/simpleswap_exchange_provider.dart';
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
import 'package:hive/hive.dart';
import 'package:cake_wallet/store/app_store.dart';

class TradeMonitor {
  static const int _tradeCheckIntervalMinutes = 5;
  static const int _maxTradeAgeHours = 24;

  TradeMonitor({
    required this.tradesStore,
    required this.trades,
    required this.appStore,
  });

  final TradesStore tradesStore;
  final Box<Trade> trades;
  final AppStore appStore;
  final Map<String, Timer> _tradeTimers = {};

  ExchangeProvider? _getProviderByDescription(ExchangeProviderDescription description) {
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
        return ThorChainExchangeProvider(tradesStore: trades);
      case ExchangeProviderDescription.swapTrade:
        return SwapTradeExchangeProvider();
      case ExchangeProviderDescription.letsExchange:
        return LetsExchangeExchangeProvider();
      case ExchangeProviderDescription.stealthEx:
        return StealthExExchangeProvider();
      case ExchangeProviderDescription.chainflip:
        return ChainflipExchangeProvider(tradesStore: trades);
      case ExchangeProviderDescription.xoSwap:
        return XOSwapExchangeProvider();
    }
    return null;
  }

  void monitorActiveTrades(String walletId) {
    // Checks if the trade monitoring is permitted
    // i.e the user has not disabled the exchange api mode or the status updates
    final isTradeMonitoringPermitted = _isTradeMonitoringPermitted();
    if (!isTradeMonitoringPermitted) {
      return;
    }

    final now = DateTime.now();
    final trades = tradesStore.trades;
    final tradesToCancel = <String>[];

    for (final item in trades) {
      final trade = item.trade;

      // We check to see if the api mode is tor and if the provider supports onion address
      final provider = _getProviderByDescription(trade.provider);
      if (provider == null || !_isExchangeApiModePermitted(provider)) {
        printV('Skipping trade ${trade.id} because the provider is not supported');
        continue;
      }

      // Next, we check to see if there's an ongoing timer monitoring this trade
      // If yes, we check to see if the trade timer should be cancelled
      // If yes, we add the timer to the list of timers to cancel
      // If no, we start a new timer for this trade
      if (_tradeTimers.containsKey(trade.id)) {
        if (_shouldCancelTradeTimer(trade, walletId, now)) {
          tradesToCancel.add(trade.id);
        }
        continue;
      } else {
        printV('Starting trade monitoring for ${trade.id}');
        _startTradeMonitoring(trade, provider);
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

  bool _isExchangeApiModePermitted(ExchangeProvider provider) {
    final exchangeApiMode = appStore.settingsStore.exchangeStatus;

    if (exchangeApiMode == ExchangeApiMode.torOnly && !provider.supportsOnionAddress) {
      printV('Skipping ${provider.description}, no TOR support');
      return false;
    }

    return true;
  }

  bool _shouldCancelTradeTimer(Trade trade, String walletId, DateTime now) {
    if (trade.walletId != walletId) return true;

    final createdAt = trade.createdAt;
    if (createdAt == null) return true;

    if (now.difference(createdAt).inHours > _maxTradeAgeHours) return true;

    return _isFinalState(trade.state);
  }

  void _startTradeMonitoring(Trade trade, ExchangeProvider provider) {
    final timer = Timer.periodic(
      Duration(minutes: _tradeCheckIntervalMinutes),
      (_) => _checkTradeStatus(trade, provider),
    );

    _checkTradeStatus(trade, provider);

    _tradeTimers[trade.id] = timer;
  }

  Future<void> _checkTradeStatus(Trade trade, ExchangeProvider provider) async {
    try {
      final updated = await provider.findTradeById(id: trade.id);
      trade
        ..stateRaw = updated.state.raw
        ..receiveAmount = updated.receiveAmount ?? trade.receiveAmount
        ..outputTransaction = updated.outputTransaction ?? trade.outputTransaction;
      printV('Trade ${trade.id} updated: ${trade.state}');
      await trade.save();

      // If the updated trade is in a final state, we cancel the timer
      if (_isFinalState(updated.state)) {
        printV('Trade ${trade.id} is in final state');
        _cancelSingleTradeTimer(trade.id);
      }
    } catch (e) {
      printV('Error fetching status for ${trade.id}: $e');
    }
  }

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
  void pauseTradeMonitoring() {
    _cancelMultipleTradeTimers(_tradeTimers.keys.toList());
  }
}
