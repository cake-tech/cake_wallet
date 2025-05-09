import 'dart:async';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:hive/hive.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/exchange/provider/exchange_provider.dart';
import 'package:cake_wallet/exchange/trade.dart';
import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';

class SwapManager {
  SwapManager({
    required this.tradesStore,
    required this.settingsStore,
    Duration? pollingInterval,
  }) : _pollingInterval = pollingInterval ?? const Duration(minutes: 1) {
    _boxSub = tradesStore.tradesSource.watch().listen(_onBoxEvent);
  }

  WalletBase? _currentWallet;
  final TradesStore tradesStore;
  final Duration _pollingInterval;
  final SettingsStore settingsStore;
  Map<ExchangeProviderDescription, ExchangeProvider>? _providers;

  // Timer for periodic polling.
  Timer? _timer;

  // The map of trades we’re monitoring, keyed by trade ID.
  final Map<String, Trade> _activeSwaps = {};

  // Subscription to Hive box events (for new or updated Trade entries).
  late final StreamSubscription<BoxEvent> _boxSub;

  /// Set of trade states where polling is no longer needed.
  static final Set<TradeState> _finalStates = {
    // Completed or successful trades
    TradeState.completed,
    TradeState.success,
    TradeState.confirmed,
    TradeState.finished,

    // Expired or failed trades
    TradeState.expired,
    TradeState.failed,
    TradeState.notFound,
  };

  // Called on every Hive write; adds new non-final trades for polling.
  void _onBoxEvent(BoxEvent event) {
    if (event.deleted) return;
    final value = event.value;
    if (value is! Trade) return;
    final trade = value;

    // We only care about currently active trades for the current wallet
    if (_currentWallet == null || trade.walletId != _currentWallet!.id || _isFinal(trade.state)) {
      return;
    }

    final isNew = !_activeSwaps.containsKey(trade.id);

    _activeSwaps[trade.id] = trade;

    if (isNew) _ensureTimerRunning(immediate: false);
  }

  void start(WalletBase wallet, Map<ExchangeProviderDescription, ExchangeProvider> providers) {
    if (_currentWallet == wallet && _timer?.isActive == true) return;

    // Clear any previous state
    _timer?.cancel();
    _activeSwaps.clear();
    _currentWallet = wallet;
    _providers ??= providers;

    // We fetch any existing pending swaps from Hive.
    for (final item in tradesStore.trades) {
      final trade = item.trade;
      if (trade.walletId == wallet.id && !_isFinal(trade.state)) {
        _activeSwaps[trade.id] = trade;
      }
    }

    _ensureTimerRunning(immediate: true);
  }

  // Ensures the timer is running if there are swaps to poll.
  void _ensureTimerRunning({required bool immediate}) {
    if (_activeSwaps.isEmpty) return;

    if (_timer?.isActive != true) {
      if (immediate) _fetchPendingSwapsStatuses();

      _timer = Timer.periodic(_pollingInterval, (_) => _fetchPendingSwapsStatuses());
    }
  }

  // Polls each pending swap status and writes updates back to Hive.
  Future<void> _fetchPendingSwapsStatuses() async {
    if (_activeSwaps.isEmpty) {
      stop();
      return;
    }

    final exchangeApiMode = settingsStore.exchangeStatus;
    if (exchangeApiMode == ExchangeApiMode.disabled) return;

    for (final entry in _activeSwaps.entries.toList()) {
      final trade = entry.value;
      final provider = _providers?[trade.provider];

      if (provider == null) {
        printV('No provider found for ${trade.provider}');
        continue;
      }

      if (exchangeApiMode == ExchangeApiMode.torOnly && !provider.supportsOnionAddress) {
        printV('Skipping ${trade.provider}, no TOR support');
        continue;
      }

      try {
        final updated = await provider.findTradeById(id: trade.id);
        trade
          ..stateRaw = updated.state.raw
          ..receiveAmount = updated.receiveAmount
          ..outputTransaction = updated.outputTransaction;
        await trade.save();

        if (_isFinal(updated.state)) {
          _activeSwaps.remove(trade.id);
        }
      } catch (e) {
        printV('Error fetching status for ${trade.id}: $e');
      }
    }
  }

  // Returns true for any state where we no longer need to poll.
  bool _isFinal(TradeState state) => _finalStates.contains(state);

  // Stops polling and clears tracked swaps.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _activeSwaps.clear();
    _currentWallet = null;
  }

  // Cleans up resources when the app is closed.
  void dispose() {
    stop();
    _boxSub.cancel();
  }
}
