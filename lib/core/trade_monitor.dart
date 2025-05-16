import 'dart:async';
import 'package:cake_wallet/exchange/provider/simpleswap_exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
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

class TradeMonitor {
  static const int _tradeCheckIntervalMinutes = 1;
  static const int _maxTradeAgeHours = 24;
  
  TradeMonitor({
    required this.tradesStore,
    required this.settingsStore,
    required this.trades,
  });

  final TradesStore tradesStore;
  final Box<Trade> trades;
  final SettingsStore settingsStore;
  final Map<String, Timer> _tradeTimers = {};

  ExchangeProvider? _getProviderByDescription(ExchangeProviderDescription description) {
    switch (description) {
      case ExchangeProviderDescription.changeNow:
        return ChangeNowExchangeProvider(settingsStore: settingsStore);
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
    final now = DateTime.now();
    final trades = tradesStore.trades;
    final tradesToCancel = <String>[];

    for (final item in trades) {
      final trade = item.trade;
      
      if (_shouldCancelTradeTimer(trade, walletId, now)) {
        if (_tradeTimers.containsKey(trade.id)) {
          tradesToCancel.add(trade.id);
        }
        continue;
      }

      if (!_tradeTimers.containsKey(trade.id)) {
        printV('Starting trade monitoring for ${trade.id}');
        _startTradeMonitoring(trade);
      }
    }

    _cancelTradeTimers(tradesToCancel);
  }

  bool _shouldCancelTradeTimer(Trade trade, String walletId, DateTime now) {
    if (trade.walletId != walletId) return true;
    
    final createdAt = trade.createdAt;
    if (createdAt == null) return true;
    
    if (now.difference(createdAt).inHours > _maxTradeAgeHours) return true;
    
    return _isFinalState(trade.state);
  }

  void _startTradeMonitoring(Trade trade) {
    if (_tradeTimers.containsKey(trade.id)) return;

    _checkTradeStatus(trade);

    final timer = Timer.periodic(
      Duration(minutes: _tradeCheckIntervalMinutes), 
      (_) => _checkTradeStatus(trade)
    );

    _tradeTimers[trade.id] = timer;
  }

  Future<void> _checkTradeStatus(Trade trade) async {
    printV('Checking trade status for ${trade.id}');
    
    if (_isTradeOld(trade)) {
      printV('The trade ${trade.id} is older than $_maxTradeAgeHours hours, we will cancel the timer');
      _cancelTradeTimer(trade.id);
      return;
    }

    final provider = _getProviderByDescription(trade.provider);
    if (provider == null) {
      printV('No provider found for trade ${trade.id}');
      return;
    }

    if (!_isExchangeModeEnabled(provider)) {
      return;
    }

    try {
      await _updateTradeStatus(trade, provider);
    } catch (e) {
      printV('Error fetching status for ${trade.id}: $e');
    }
  }

  bool _isTradeOld(Trade trade) {
    final now = DateTime.now();
    final createdAt = trade.createdAt;
    return createdAt != null && now.difference(createdAt).inHours > _maxTradeAgeHours;
  }

  bool _isExchangeModeEnabled(ExchangeProvider provider) {
    final exchangeApiMode = settingsStore.exchangeStatus;

    if (exchangeApiMode == ExchangeApiMode.disabled) {
      printV('Exchange API mode is disabled');
      return false;
    }

    if (exchangeApiMode == ExchangeApiMode.torOnly && !provider.supportsOnionAddress) {
      printV('Skipping ${provider.description}, no TOR support');
      return false;
    }

    return true;
  }

  Future<void> _updateTradeStatus(Trade trade, ExchangeProvider provider) async {
    final updated = await provider.findTradeById(id: trade.id);
    trade
      ..stateRaw = updated.state.raw
      ..receiveAmount = updated.receiveAmount
      ..outputTransaction = updated.outputTransaction;
    printV('Trade ${trade.id} updated: ${trade.state}');
    await trade.save();

    if (_isFinalState(updated.state)) {
      printV('Trade ${trade.id} is in final state');
      _cancelTradeTimer(trade.id);
    }
  }

  void _cancelTradeTimer(String tradeId) {
    _tradeTimers[tradeId]?.cancel();
    _tradeTimers.remove(tradeId);
  }

  void _cancelTradeTimers(List<String> tradeIds) {
    for (final tradeId in tradeIds) {
      _cancelTradeTimer(tradeId);
    }
  }

  void cancelAllTradeTimers() {
    for (final timer in _tradeTimers.values) {
      timer.cancel();
    }
    _tradeTimers.clear();
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

  void dispose() {
    cancelAllTradeTimers();
  }
}
