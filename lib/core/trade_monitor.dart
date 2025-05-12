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
  TradeMonitor({
    required this.tradesStore,
    required this.settingsStore,
    required this.trades,
  });

  final TradesStore tradesStore;
  final Box<Trade> trades;
  final SettingsStore settingsStore;
  final Map<String, Timer> _tradeTimers = {};
  static const int _tradeCheckInterval = 1;

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

    for (final item in trades) {
      final trade = item.trade;

      if (trade.walletId != walletId) continue;

      final createdAt = trade.createdAt;
      if (createdAt == null) continue;

      if (now.difference(createdAt).inHours > 24) continue;

      if (_isFinalState(trade.state)) continue;

      if (!_tradeTimers.containsKey(trade.id)) {
        printV('Starting trade monitoring for ${trade.id}');
        _startTradeMonitoring(trade);
      }
    }
  }

  void _startTradeMonitoring(Trade trade) {
    if (_tradeTimers.containsKey(trade.id)) return;

    final provider = _getProviderByDescription(trade.provider);
    if (provider == null) {
      printV('No provider found for trade ${trade.id}');
      return;
    }

    _checkTradeStatus(trade);

    final timer = Timer.periodic(Duration(minutes: _tradeCheckInterval), (_) {
      _checkTradeStatus(trade);
    });

    _tradeTimers[trade.id] = timer;
  }

  Future<void> _checkTradeStatus(Trade trade) async {
    printV('Checking trade status for ${trade.id}');
    final provider = _getProviderByDescription(trade.provider);
    if (provider == null) {
      printV('No provider found for trade ${trade.id}');
      return;
    }

    final exchangeApiMode = settingsStore.exchangeStatus;

    if (exchangeApiMode == ExchangeApiMode.disabled) {
      printV('Exchange API mode is disabled');
      return;
    }

    if (exchangeApiMode == ExchangeApiMode.torOnly && !provider.supportsOnionAddress) {
      printV('Skipping ${trade.provider}, no TOR support');
      return;
    }

    try {
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
    } catch (e) {
      printV('Error fetching status for ${trade.id}: $e');
    }
  }

  void _cancelTradeTimer(String tradeId) {
    _tradeTimers[tradeId]?.cancel();
    _tradeTimers.remove(tradeId);
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
