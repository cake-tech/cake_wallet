import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/address_resolver/yat/yat_store.dart';
import 'package:cake_wallet/core/key_service.dart';
import 'package:cake_wallet/view_model/dashboard/date_section_item.dart';
import "package:cw_core/balance_card_style_settings.dart";
import 'package:cake_wallet/core/trade_monitor.dart';
import 'package:cake_wallet/entities/auto_generate_subaddress_status.dart';
import 'package:cake_wallet/entities/balance_display_mode.dart';
import 'package:cake_wallet/entities/exchange_api_mode.dart';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/service_status.dart';
import 'package:cake_wallet/entities/sync_status_display_mode.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/order/order_provider_description.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/store/dashboard/order_filter_store.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/zcash/zcash.dart';
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/utils/proxy_wrapper.dart';
import 'package:cake_wallet/utils/tor.dart';
import 'package:cake_wallet/wownero/wownero.dart' as wow;
import 'package:cake_wallet/store/anonpay/anonpay_transactions_store.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/dashboard/orders_store.dart';
import 'package:cake_wallet/store/dashboard/payjoin_transactions_store.dart';
import 'package:cake_wallet/store/dashboard/trade_filter_store.dart';
import 'package:cake_wallet/store/dashboard/trades_store.dart';
import 'package:cake_wallet/store/dashboard/transaction_filter_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/dashboard/action_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/anonpay_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/balance_view_model.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:cake_wallet/view_model/dashboard/formatted_item_list.dart';
import 'package:cake_wallet/view_model/dashboard/order_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/payjoin_transaction_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/trade_list_item.dart';
import 'package:cake_wallet/view_model/dashboard/transaction_list_item.dart';
import 'package:cake_wallet/view_model/settings/sync_mode.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/card_design.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_history.dart';
import 'package:cw_core/transaction_info.dart';
import 'package:cw_core/utils/file.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:eth_sig_util/util/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_daemon/flutter_daemon.dart';
import 'package:mobx/mobx.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cake_wallet/reactions/wallet_connect.dart';
import 'package:cake_wallet/evm/evm.dart';

part 'dashboard_view_model.g.dart';

class DashboardViewModel = DashboardViewModelBase with _$DashboardViewModel;

abstract class DashboardViewModelBase with Store {
  DashboardViewModelBase(
      {required this.balanceViewModel,
      required this.tradeMonitor,
      required this.appStore,
      required this.tradesStore,
      required this.tradeFilterStore,
      required this.orderFilterStore,
      required this.transactionFilterStore,
      required this.settingsStore,
      required this.yatStore,
      required this.ordersStore,
      required this.anonpayTransactionsStore,
      required this.payjoinTransactionsStore,
      required this.sharedPreferences,
      required this.keyService})
      : hasTradeAction = true,
        hasSwapAction = true,
        isShowFirstYatIntroduction = false,
        isShowSecondYatIntroduction = false,
        isShowThirdYatIntroduction = false,
        filterItems = [],
        exchangeFilterItems = [],
        subname = '',
        name = appStore.wallet!.name,
        type = appStore.wallet!.type,
        transactions = ObservableList<TransactionListItem>(),
        cardDesigns = ObservableList<CardDesign>(),
        cardOrder = ObservableMap<int, int>(),
        wallet = appStore.wallet! {
    showDecredInfoCard = wallet.type == WalletType.decred &&
        (sharedPreferences.getBool(PreferencesKey.showDecredInfoCard) ?? true);

    name = wallet.name;
    type = wallet.type;
    isShowFirstYatIntroduction = false;
    isShowSecondYatIntroduction = false;
    isShowThirdYatIntroduction = false;
    unawaited(isBackgroundSyncEnabled());
    unawaited(isBatteryOptimizationEnabled());
    unawaited(_loadConstraints());
    final _wallet = wallet;

    loadFilterItems();

    if (_wallet.type == WalletType.monero) {
      subname = monero!.getCurrentAccount(_wallet).label;

      _onMoneroAccountChangeReaction = reaction(
          (_) => monero!.getMoneroWalletDetails(wallet).account,
          (Account account) => _onMoneroAccountChange(_wallet));

      _onMoneroBalanceChangeReaction = reaction(
          (_) => monero!.getMoneroWalletDetails(wallet).balance,
          (MoneroBalance balance) => _onMoneroTransactionsUpdate(_wallet));

      final _accountTransactions = _wallet.transactionHistory.transactions.values
          .where((tx) =>
              monero!.getTransactionInfoAccountId(tx) == monero!.getCurrentAccount(wallet).id)
          .toList();

      final sortedTransactions = [..._accountTransactions];
      sortedTransactions.sort((a, b) => a.date.compareTo(b.date));

      transactions = ObservableList.of(
        sortedTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            appStore: appStore,
            key: ValueKey('monero_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    } else if (_wallet.type == WalletType.wownero) {
      subname = wow.wownero!.getCurrentAccount(_wallet).label;

      _onMoneroAccountChangeReaction = reaction(
          (_) => wow.wownero!.getWowneroWalletDetails(wallet).account,
          (wow.Account account) => _onMoneroAccountChange(_wallet));

      _onMoneroBalanceChangeReaction = reaction(
          (_) => wow.wownero!.getWowneroWalletDetails(wallet).balance,
          (wow.WowneroBalance balance) => _onMoneroTransactionsUpdate(_wallet));

      final _accountTransactions = _wallet.transactionHistory.transactions.values
          .where((tx) =>
              wow.wownero!.getTransactionInfoAccountId(tx) ==
              wow.wownero!.getCurrentAccount(wallet).id)
          .toList();

      final sortedTransactions = [..._accountTransactions];
      sortedTransactions.sort((a, b) => a.date.compareTo(b.date));

      transactions = ObservableList.of(
        sortedTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            appStore: appStore,
            key: ValueKey('wownero_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    } else {
      final sortedTransactions = [...wallet.transactionHistory.transactions.values];
      sortedTransactions.sort((a, b) => a.date.compareTo(b.date));

      transactions = ObservableList.of(
        sortedTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            appStore: appStore,
            key: ValueKey('${_wallet.type.name}_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    }

    // TODO: nano sub-account generation is disabled:
    // if (_wallet.type == WalletType.nano || _wallet.type == WalletType.banano) {
    //   subname = nano!.getCurrentAccount(_wallet).label;
    // }

    _walletChangeDisposer?.reaction.dispose();
    _walletChangeDisposer = reaction((_) => appStore.wallet, (wallet) {
      _onWalletChange(wallet);
      _checkMweb();
      loadCardDesigns();
      showDecredInfoCard = wallet?.type == WalletType.decred &&
          sharedPreferences.getBool(PreferencesKey.showDecredInfoCard) != false;

      tradeMonitor.stopTradeMonitoring();
      tradeMonitor.monitorActiveTrades(wallet!.id);
    });

    _transactionDisposer?.reaction.dispose();
    _transactionDisposer = reaction((_) => _transactionsChangeSignature(),
        _transactionDisposerCallback,
        delay: 300, fireImmediately: true);

    if (hasSilentPayments) {
      silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);

      reaction((_) => wallet.syncStatus, (SyncStatus syncStatus) {
        silentPaymentsScanningActive = bitcoin!.getScanningActive(wallet);
      });
    }

    loadCardDesigns();

    _checkMweb();
    reaction((_) => settingsStore.mwebAlwaysScan, (bool value) => _checkMweb());

    reaction((_) => tradesStore.trades, (_) => tradeMonitor.monitorActiveTrades(wallet.id));

    tradeMonitor.monitorActiveTrades(wallet.id);
  }

  void loadFilterItems() {
    filterItems = [
      // FilterItem(
      //     value: () => transactionFilterStore.displayAll,
      //     caption: S.current.all_transactions,
      //     onChanged: transactionFilterStore.toggleAll),
      FilterItem(
          value: () => transactionFilterStore.displayOutgoing,
          caption: S.current.send,
          onChanged: transactionFilterStore.toggleOutgoing),
      FilterItem(
          value: () => transactionFilterStore.displayIncoming,
          caption: S.current.receive,
          onChanged: transactionFilterStore.toggleIncoming),
      if (appStore.wallet!.type == WalletType.bitcoin)
        FilterItem(
          value: () => transactionFilterStore.displaySilentPayments,
          caption: S.current.silent_payments,
          onChanged: transactionFilterStore.toggleSilentPayments,
        ),
      SwapFilterItem(
          enabledProviders: () => tradeFilterStore.enabledProvidersCount,
          allEnabled: () => tradeFilterStore.displayAllTrades,
          value: () => tradeFilterStore.enabledProvidersCount > 0,
          onChanged: () => tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.all)),
      FilterItem(
          value: () => orderFilterStore.displayCakePay,
          caption: 'Cake Pay',
          onChanged: () => orderFilterStore.toggleDisplayOrder(OrderProviderDescription.cakePay)),
    ];
    exchangeFilterItems = [
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.changeNow,
          value: () => tradeFilterStore.displayChangeNow,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.changeNow)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.sideShift,
          value: () => tradeFilterStore.displaySideShift,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.sideShift)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.simpleSwap,
          value: () => tradeFilterStore.displaySimpleSwap,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.simpleSwap)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.trocador,
          value: () => tradeFilterStore.displayTrocador,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.trocador)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.exolix,
          value: () => tradeFilterStore.displayExolix,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.exolix)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.chainflip,
          value: () => tradeFilterStore.displayChainflip,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.chainflip)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.thorChain,
          value: () => tradeFilterStore.displayThorChain,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.thorChain)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.letsExchange,
          value: () => tradeFilterStore.displayLetsExchange,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.letsExchange)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.stealthEx,
          value: () => tradeFilterStore.displayStealthEx,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.stealthEx)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.xoSwap,
          value: () => tradeFilterStore.displayXOSwap,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.xoSwap)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.swapTrade,
          value: () => tradeFilterStore.displaySwapTrade,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.swapTrade)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.swapsXyz,
          value: () => tradeFilterStore.displaySwapXyz,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.swapsXyz)),
      SwapProviderFilterItem(
          providerDescription: ExchangeProviderDescription.nearIntents,
          value: () => tradeFilterStore.displayNearIntents,
          onChanged: () =>
              tradeFilterStore.toggleDisplayExchange(ExchangeProviderDescription.nearIntents)),
    ];
  }

  bool _isTransactionDisposerCallbackRunning = false;
  bool _transactionDisposerCallbackQueued = false;

  // Tracks each tx's content as of the last time _runTransactionDisposerCallback
  // actually rendered it, keyed by identity (txHash_direction) - NOT read off
  // the live TransactionInfo object, because that object is frequently the
  // SAME shared reference already wrapped by an existing TransactionListItem
  // (electrum_wallet.dart mutates a re-scanned tx's fields in place rather
  // than replacing it). Comparing "existing wrapper's fields" against "the
  // freshly fetched tx's fields" is therefore comparing a value against
  // itself post-mutation and can never detect the change - confirmed via
  // device log: a re-confirmed silent payment match with newUnspents=0
  // updated confirmations/height/date on the shared object, the reaction
  // correctly re-ran, but the diff saw 0 new/removed items because both
  // sides of the comparison already reflected the post-mutation state, so
  // the ObservableList was never touched and the tile stayed stale until an
  // unrelated rebuild (a filter reset) forced everything to re-read fresh.
  // This separate, VM-owned snapshot is what makes the comparison meaningful.
  final Map<String, String> _lastTxContentByIdentity = {};

  @action
  void _reloadTransactions() {
    if (wallet.type == WalletType.monero || wallet.type == WalletType.wownero) {
      return; // Monero/Wownero transactions are handled separately
    }

    transactions.clear();

    transactions.addAll(
      wallet.transactionHistory.transactions.values.map(
        (transaction) => TransactionListItem(
          transaction: transaction,
          balanceViewModel: balanceViewModel,
          appStore: appStore,
          key: ValueKey('${wallet.type.name}_transaction_history_item_${transaction.id}_key'),
        ),
      ),
    );
  }

  @computed
  bool get isMigratingToIronwood =>
      wallet.type == WalletType.zcash && (zcash?.hasOrchardMigratableBalance(wallet) ?? false);

  @computed
  bool get isSyncHeavy {
    if ([
      WalletType.monero,
      WalletType.wownero,
      WalletType.decred,
      WalletType.zcash,
      WalletType.zano
    ].contains(wallet.type)) {
      return true;
    }

    if (wallet.type == WalletType.bitcoin && silentPaymentsScanningActive && hasSilentPayments) {
      return true;
    }

    if (wallet.type == WalletType.litecoin && mwebEnabled && hasMweb) {
      return true;
    }

    return false;
  }

  bool showBridge(CryptoCurrency currency) {
    if (!isEVMCompatibleChain(wallet.type)) return false;

    if (evm!.isUSDT0Token(wallet, currency)) return true;

    return false;
  }

  @action
  void changeAllFilterItems(bool value) {
    for (final item in filterItems) {
      if (item.value() != value) {
        item.onChanged();
      }
    }
    for (final item in exchangeFilterItems) {
      if (item.value() != value) {
        item.onChanged();
      }
    }
  }

  @action
  Future<void> loadCardDesigns() async {
    final accountStyleSettings =
        await BalanceCardStyleSettings.getAll(wallet.walletInfo.internalId);

    late final int numAccounts;
    if (wallet.type == WalletType.monero) {
      numAccounts = monero!.getAccountList(wallet).accounts.length;
    } else if (wallet.type == WalletType.wownero) {
      numAccounts = wow.wownero!.getAccountList(wallet).accounts.length;
    } else if (wallet.type == WalletType.bitcoin) {
      // bitcoin and lightning
      numAccounts = 2;
    } else {
      numAccounts = 1;
    }
    cardDesigns.clear();
    Map<int, int> newOrder = {};

    for (int i = 0; i < numAccounts; i++) {
      late final int index;
      if (balanceViewModel.hasAccounts) {
        index = i;
      } else if (wallet.type == WalletType.bitcoin && i == 1) {
        index = 0;
      } else {
        index = -1;
      }

      final setting = accountStyleSettings.where((e) => e.accountIndex == index).firstOrNull;

      late final CryptoCurrency curr;
      if (wallet.type == WalletType.bitcoin && i == 1) {
        curr = CryptoCurrency.btcln;
      } else {
        curr = wallet.currency;
      }

      cardDesigns.add(CardDesign.fromStyleSettings(setting, curr));
      if (setting?.cardOrder != null) {
        newOrder[setting!.cardOrder] = i;
      }
    }

    // making sure ALL accounts have numbers, even the ones that existed before this feature was a thing
    for (int i = 0; i < numAccounts; i++) {
      if (!newOrder.containsKey(i) && !(wallet.type != WalletType.bitcoin && i == 1)) {
        int free = 0;
        while (newOrder.containsValue(free)) {
          free++;
        }
        if (wallet.type == WalletType.bitcoin) {
          newOrder[free] = 0;
        } else {
          newOrder[free] = i;
        }
      }
    }
    cardOrder = newOrder.asObservable();
  }

  void _transactionDisposerCallback(String _) async {
    // A reaction firing WHILE a previous run is still in flight used to be
    // silently dropped here (a plain `if (running) return;`) - fine for a
    // same-frame re-trigger, but if two distinct scan matches landed close
    // enough together that the second trigger arrived mid-run, that second
    // signature change was lost for good unless something else changed
    // transactionHistory again later to re-trigger this reaction. Confirmed
    // causing exactly that: multiple silent payment receives found in the
    // same scan pass, only one of them ever made it into this view model's
    // `transactions` list. Queuing one more run (like updateBalance()'s own
    // _balanceUpdateInProgress/_balanceUpdateQueued pattern) instead of
    // dropping it guarantees a fresh re-read of the current
    // transactionHistory happens after the in-flight run finishes, so
    // nothing queued up during that window is ever silently lost.
    if (_isTransactionDisposerCallbackRunning) {
      _transactionDisposerCallbackQueued = true;
      return;
    }
    _isTransactionDisposerCallbackRunning = true;

    try {
      do {
        _transactionDisposerCallbackQueued = false;
        await _runTransactionDisposerCallback();
      } while (_transactionDisposerCallbackQueued);
    } finally {
      _isTransactionDisposerCallbackRunning = false;
    }
  }

  Future<void> _runTransactionDisposerCallback() async {
    await Future.delayed(Duration.zero);

    final currentAccountId = wallet.type == WalletType.monero
        ? monero!.getCurrentAccount(wallet).id
        : wallet.type == WalletType.wownero
            ? wow.wownero!.getCurrentAccount(wallet).id
            : null;
    final List<TransactionInfo> relevantTxs = [];

    for (final tx in appStore.wallet!.transactionHistory.transactions.values) {
      bool isRelevant = true;
      if (wallet.type == WalletType.monero) {
        isRelevant = monero!.getTransactionInfoAccountId(tx) == currentAccountId;
      } else if (wallet.type == WalletType.wownero) {
        isRelevant = wow.wownero!.getTransactionInfoAccountId(tx) == currentAccountId;
      }

      if (isRelevant) {
        relevantTxs.add(tx);
      }
    }
    // TODO(malik) update this in a saner way during the vm refactor
    String _txIdentityString(String txHash, TransactionDirection direction) =>
        "${txHash}_$direction";
    // Deliberately NOT derived from item.transaction (see
    // _lastTxContentByIdentity's doc comment above) - built fresh from the
    // just-fetched tx and compared against our own last-seen snapshot
    // instead of against the (possibly identical, possibly already-mutated)
    // live wrapper. Includes direction/isReceivedSilentPayment - a re-scanned
    // silent payment can flip both of these on an otherwise already-known tx
    // (an SP receive initially misclassified by the regular tx-history fetch
    // as an outgoing, non-SP tx before the SP scan resolves it) without
    // confirmations/amount/etc necessarily changing, so omitting them here
    // let a genuine, filter-relevant change go undetected.
    String _txContentSignature(TransactionInfo tx) =>
        "${tx.confirmations}_${tx.isPending}_${tx.amount}_${tx.height}_${tx.date}_${tx.fee}_"
        "${tx.direction}_${wallet.type == WalletType.bitcoin ? bitcoin?.txIsReceivedSilentPayment(tx) : null}";

    // Everything below must run inside a single MobX action: each
    // transactions[i]=... below opens/closes its own micro-batch via
    // ObservableList's own operator[]=, and a reaction scheduled from
    // mutations made outside of an action (this method resumes here after
    // an `await`, i.e. in a microtask with no enclosing action) was
    // confirmed via device log to not reliably reach Flutter's build phase -
    // the underlying data was already correct (confirmed via a separate
    // debug print inside the `items` getter itself) while the widget kept
    // rendering the stale, pre-update list until an unrelated observable
    // (a filter toggle) forced a rebuild. Wrapping the whole read-modify
    // batch in one runInAction collapses it into a single notification and
    // guarantees it's scheduled the same way any other MobX-driven UI
    // update is.
    runInAction(() {
      final existingIndexByIdentity = <String, int>{};
      for (var i = 0; i < transactions.length; i++) {
        final item = transactions[i];
        existingIndexByIdentity[
            _txIdentityString(item.transaction.txHash, item.transaction.direction)] = i;
      }

      final relevantIdentities = <String>{};
      final newTransactions = <TransactionListItem>[];

      for (final tx in relevantTxs) {
        final identity = _txIdentityString(tx.txHash, tx.direction);
        relevantIdentities.add(identity);

        final contentSignature = _txContentSignature(tx);
        final contentChanged = _lastTxContentByIdentity[identity] != contentSignature;
        _lastTxContentByIdentity[identity] = contentSignature;

        final existingIndex = existingIndexByIdentity[identity];
        if (existingIndex == null || contentChanged) {
          // A changed existing item is routed through the SAME
          // remove-then-add path as a genuinely new one (matched below by
          // identity, via newIdentities/removeWhere), rather than replaced
          // in place via `transactions[existingIndex] = ...`. That index
          // assignment - even wrapped in runInAction - was device-confirmed
          // to not reliably reach the rendered UI: a re-scanned silent
          // payment's isReceivedSilentPayment/direction flip landed
          // correctly in the underlying data (verified via a separate debug
          // print inside the `items` getter) but the on-screen list stayed
          // stale until an unrelated observable write (a filter toggle)
          // forced a rebuild. A brand-new addition via transactions.addAll()
          // has reliably reached the screen every time in the same testing,
          // so changed items now go through that same path instead. Order
          // doesn't matter here since formattedItemsList() unconditionally
          // re-sorts everything by date.
          newTransactions.add(TransactionListItem(
            transaction: tx,
            balanceViewModel: balanceViewModel,
            appStore: appStore,
            key: ValueKey('${wallet.type.name}_transaction_history_item_${tx.id}_key'),
          ));
        }
      }

      _lastTxContentByIdentity.removeWhere((identity, _) => !relevantIdentities.contains(identity));

      final newIdentities = newTransactions
          .map((item) => _txIdentityString(item.transaction.txHash, item.transaction.direction))
          .toSet();

      transactions.removeWhere((item) {
        if (wallet.type == WalletType.zcash) {
          return newTransactions.any(
            (n) => n.transaction.txHash == item.transaction.txHash,
          );
        }
        return newIdentities.contains(
          _txIdentityString(item.transaction.txHash, item.transaction.direction),
        );
      });

      transactions.addAll(newTransactions);
    });
  }

  void _checkMweb() {
    if (hasMweb) {
      mwebEnabled = bitcoin!.getMwebEnabled(wallet);
      balanceViewModel.mwebEnabled = mwebEnabled;
    }
  }

  @observable
  WalletType type;

  @observable
  String name;

  @observable
  ObservableList<TransactionListItem> transactions;

  @observable
  String subname;

  @observable
  bool isShowFirstYatIntroduction;

  @observable
  bool isShowSecondYatIntroduction;

  @observable
  bool isShowThirdYatIntroduction;

  @observable
  ObservableList<CardDesign> cardDesigns;

  @observable
  ObservableMap<int, int> cardOrder;

  @computed
  bool get isDarkTheme => appStore.themeStore.currentTheme.isDark;

  @computed
  String get address => wallet.walletAddresses.address;

  @computed
  bool get isTorEnabled => settingsStore.currentBuiltinTor;

  @computed
  SyncStatus get status => wallet.syncStatus;

  @computed
  bool get shouldShowMwebAd {
    return false;
    if (wallet.type != WalletType.litecoin) return false;

    if (mwebEnabled) return false;

    if (settingsStore.mwebAdDismissed) return false;

    return (Platform.isAndroid || Platform.isIOS) && !wallet.isHardwareWallet;
  }

  @action
  void dismissMwebAd(bool enableMweb) {
    if (enableMweb) setMwebEnabled();

    settingsStore.mwebAdDismissed = true;
  }

  @computed
  String get syncStatusText {
    var statusText = '';

    if (status is SyncingSyncStatus) {
      statusText = S.current.Blocks_remaining(status.toString());
    }

    if (status is FailedSyncStatus || status is LostConnectionSyncStatus) {
      statusText = S.current.please_try_to_connect_to_another_node;
    }

    if (status is ProcessingSyncStatus) {
      statusText = (status as ProcessingSyncStatus).message ?? S.current.processing;
    }

    return statusText;
  }

  @computed
  double get confirmationProgress {
    int received = 0;
    int needed = 0;

    for (final transaction in transactions) {
      if (transaction.neededConfirmations == 0) {
        continue;
      }

      if (transaction.transaction.confirmations >= transaction.neededConfirmations) {
        continue;
      }

      received += transaction.transaction.confirmations;
      needed += transaction.neededConfirmations;
    }
    if (needed == 0) {
      return 1;
    }
    return received / needed;
  }

  @computed
  BalanceDisplayMode get balanceDisplayMode => appStore.settingsStore.balanceDisplayMode;

  @computed
  @Deprecated("Replaced by showApps")
  bool get shouldShowMarketPlaceInDashboard =>
      appStore.settingsStore.shouldShowMarketPlaceInDashboard;

  @computed
  bool get showApps => appStore.settingsStore.shouldShowMarketPlaceInDashboard;

  @computed
  List<TradeListItem> get trades => tradesStore.trades.where((trade) {
        final isSameChain = trade.trade.chainId != null
            ? trade.trade.chainId == wallet.chainId
            : true; // returning default as true here so it falls back to the default checks if there's no chainId
        return trade.trade.walletId == wallet.id && isSameChain;
      }).toList();

  @computed
  bool get shouldShowBalanceHiddenMessage =>
      balanceDisplayMode == BalanceDisplayMode.hiddenBalance &&
      appStore.settingsStore.balanceHideCounter < 10;

  @computed
  List<OrderListItem> get orders =>
      ordersStore.orders.where((item) => item.order.walletId == wallet.id).toList();

  @computed
  List<AnonpayTransactionListItem> get anonpayTransactions => anonpayTransactionsStore.transactions
      .where((item) => item.transaction.walletId == wallet.id)
      .toList();

  @computed
  List<PayjoinTransactionListItem> get payjoinTransactions => payjoinTransactionsStore.transactions
      .where((item) => item.session.walletId == wallet.id)
      .toList();

  @computed
  double get price => balanceViewModel.price;

  @computed
  bool get isAutoGenerateSubaddressesEnabled =>
      settingsStore.autoGenerateSubaddressStatus != AutoGenerateSubaddressStatus.disabled;

  @computed
  List<ActionListItem> get items {
    final _items = <ActionListItem>[];

    _items.addAll(
        transactionFilterStore.filtered(transactions: [...transactions, ...anonpayTransactions]));
    _items.addAll(tradeFilterStore.filtered(trades: trades, wallet: wallet));
    _items.addAll(orderFilterStore.filtered(orders: orders, wallet: wallet));

    if (payjoinTransactions.isNotEmpty) {
      final _payjoinTransactions = payjoinTransactions;
      _items.forEach((e) {
        if (e is TransactionListItem &&
            _payjoinTransactions.any((t) => t.session.txId == e.transaction.id)) {
          _payjoinTransactions.firstWhere((t) => t.session.txId == e.transaction.id).transaction =
              e.transaction;
        }
      });
      _items.addAll(_payjoinTransactions);
      _items.removeWhere((e) => (e is TransactionListItem &&
          _payjoinTransactions.any((t) => t.session.txId == e.transaction.id)));
    }

    return formattedItemsList(_items);
  }

  static const shortHistoryLength = 3;

  @computed
  List<ActionListItem> get itemsShort =>
      items.where((item) => item is! DateSectionItem).take(shortHistoryLength).toList();

  @observable
  WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo> wallet;

  @computed
  bool get hasLightning =>
      wallet.type == WalletType.bitcoin && wallet.isSoftwareWallet && bitcoin!.useLightning(wallet);

  @computed
  bool get hasWalletConnect =>
      isWalletConnectCompatibleChain(wallet.type) && !wallet.isHardwareWallet;

  @computed
  bool get isTestnet => wallet.type == WalletType.bitcoin && bitcoin!.isTestnet(wallet);

  @computed
  bool get hasRescan => wallet.hasRescan;

  @computed
  bool get hasBackgroundSync => [
        WalletType.monero,
      ].contains(wallet.type);

  @computed
  bool get isMoneroViewOnly {
    if (wallet.type != WalletType.monero) return false;
    return monero!.isViewOnly();
  }

  @computed
  String? get getMoneroError {
    if (wallet.type != WalletType.monero) return null;
    try {
      monero!.monerocCheck();
    } catch (e) {
      return e.toString();
    }
    return null;
  }

  @computed
  String? get getWowneroError {
    if (wallet.type != WalletType.wownero) return null;
    try {
      wow.wownero!.wownerocCheck();
    } catch (e) {
      return e.toString();
    }
    return null;
  }

  List<String> get isMoneroWalletBrokenReasons {
    if (wallet.type != WalletType.monero) return [];
    final keys = monero!.getKeys(wallet);
    List<String> errors = [
      // leaving these commented out for now, I'll be able to fix that properly in the airgap update
      // to not cause work duplication, this will do the job as well, it will be slightly less precise
      // about what happened - but still enough.
      // if (keys['privateSpendKey'] == List.generate(64, (index) => "0").join("")) "Private spend key is 0",
      if (keys['privateViewKey'] == List.generate(64, (index) => "0").join("") &&
          !wallet.isHardwareWallet)
        "private view key is 0",
      // if (keys['publicSpendKey'] == List.generate(64, (index) => "0").join("")) "public spend key is 0",
      if (keys['publicViewKey'] == List.generate(64, (index) => "0").join(""))
        "public view key is 0",
      // if (wallet.seed == null) "wallet seed is null",
      // if (wallet.seed == "") "wallet seed is empty",
      // if (monero!.getSubaddressList(wallet).getAll(wallet)[0].address ==
      //     "41d7FXjswpK1111111111111111111111111111111111111111111111111111111111111111111111111111112KhNi4")
      // "primary address is invalid, you won't be able to receive / spend funds",
    ];
    return errors;
  }

  @computed
  bool get showZcashMissingFundsCard {
    if (wallet.type != WalletType.zcash) return false;
    if (!settingsStore.showZcashMissingFundsCard) return false;
    return zcash!.showMissingFundsCard(wallet);
  }

  @computed
  bool get hasSilentPayments =>
      wallet.type == WalletType.bitcoin &&
      (bitcoin!.getWalletKeys(wallet)["privateKey"] ?? "").isNotEmpty &&
      !wallet.isHardwareWallet;

  @computed
  bool get showSilentPaymentsCard => hasSilentPayments && settingsStore.silentPaymentsCardDisplay;

  @computed
  bool get isEVMWallet => isEVMCompatibleChain(wallet.type);

  @computed
  List<ChainInfo> get availableChains {
    if (!isEVMWallet) return [];
    return evm!.getAllChains();
  }

  @computed
  ChainInfo? get currentChain {
    if (!isEVMWallet) return null;
    return evm!.getCurrentChain(wallet);
  }

  @action
  Future<void> selectChain(int chainId) async {
    if (!isEVMWallet) return;

    final node = appStore.settingsStore.getCurrentNode(wallet.type, chainId: chainId);

    await evm!.selectChain(wallet, chainId, node: node);
  }

  final KeyService keyService;
  final SharedPreferences sharedPreferences;

  @observable
  bool silentPaymentsScanningActive = false;

  @action
  void setSilentPaymentsScanning(bool active) {
    silentPaymentsScanningActive = active;

    if (hasSilentPayments) {
      bitcoin!.setScanningActive(wallet, active);
    }
  }

  @computed
  bool get hasMweb =>
      wallet.type == WalletType.litecoin &&
      (Platform.isIOS || Platform.isAndroid) &&
      !wallet.isHardwareWallet;

  @computed
  bool get showMwebCard => hasMweb && settingsStore.mwebCardDisplay && !mwebEnabled;

  @observable
  bool mwebEnabled = false;

  @observable
  late bool showDecredInfoCard;

  @computed
  bool get showPayjoinCard =>
      wallet.type == WalletType.bitcoin &&
      settingsStore.showPayjoinCard &&
      !settingsStore.usePayjoin &&
      DeviceInfo.instance.isMobile;

  @observable
  bool backgroundSyncEnabled = false;

  @action
  Future<bool> isBackgroundSyncEnabled() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final resp = await FlutterDaemon().getBackgroundSyncStatus();
    backgroundSyncEnabled = resp;
    return resp;
  }

  @action
  void toggleSwitchStatusDisplayMode() {
    if (status is SyncingSyncStatus &&
        !((status as SyncingSyncStatus).shouldShowBlocksRemaining())) {
      if (settingsStore.syncStatusDisplayMode == SyncStatusDisplayMode.eta) {
        settingsStore.syncStatusDisplayMode = SyncStatusDisplayMode.blocksRemaining;
      } else {
        settingsStore.syncStatusDisplayMode = SyncStatusDisplayMode.eta;
      }
    }
  }

  @observable
  late bool backgroundSyncNotificationsEnabled =
      sharedPreferences.getBool(PreferencesKey.backgroundSyncNotificationsEnabled) ?? false;

  @action
  Future<void> setBackgroundSyncNotificationsEnabled(bool value) async {
    if (!value) {
      backgroundSyncNotificationsEnabled = false;
      sharedPreferences.setBool(PreferencesKey.backgroundSyncNotificationsEnabled, false);
      return;
    }
    PermissionStatus permissionStatus = await Permission.notification.status;
    if (permissionStatus != PermissionStatus.granted) {
      final resp = await Permission.notification.request();
      if (resp == PermissionStatus.denied) {
        throw Exception("Notification permission denied");
      }
    }
    backgroundSyncNotificationsEnabled = value;
    await sharedPreferences.setBool(PreferencesKey.backgroundSyncNotificationsEnabled, value);
  }

  bool get hasBgsyncNetworkConstraints => Platform.isAndroid;

  bool get hasBgsyncBatteryNotLowConstraints => Platform.isAndroid;

  bool get hasBgsyncChargingConstraints => Platform.isAndroid;

  bool get hasBgsyncDeviceIdleConstraints => Platform.isAndroid;

  @observable
  bool backgroundSyncNetworkUnmetered = false;

  @observable
  bool backgroundSyncBatteryNotLow = false;

  @observable
  bool backgroundSyncCharging = false;

  @observable
  bool backgroundSyncDeviceIdle = false;

  Future<void> _loadConstraints() async {
    if (Platform.isAndroid) {
      backgroundSyncNetworkUnmetered = await FlutterDaemon().getNetworkType();
      backgroundSyncBatteryNotLow = await FlutterDaemon().getBatteryNotLow();
      backgroundSyncCharging = await FlutterDaemon().getRequiresCharging();
      backgroundSyncDeviceIdle = await FlutterDaemon().getDeviceIdle();
    }
  }

  @action
  Future<void> setBackgroundSyncNetworkUnmetered(bool value) async {
    backgroundSyncNetworkUnmetered = value;
    await FlutterDaemon().setNetworkType(value);
    if (await isBackgroundSyncEnabled()) {
      await enableBackgroundSync();
    }
  }

  @action
  Future<void> setBackgroundSyncBatteryNotLow(bool value) async {
    backgroundSyncBatteryNotLow = value;
    await FlutterDaemon().setBatteryNotLow(value);
    if (await isBackgroundSyncEnabled()) {
      await enableBackgroundSync();
    }
  }

  @action
  Future<void> setBackgroundSyncCharging(bool value) async {
    backgroundSyncCharging = value;
    await FlutterDaemon().setRequiresCharging(value);
    if (await isBackgroundSyncEnabled()) {
      await enableBackgroundSync();
    }
  }

  @action
  Future<void> setBackgroundSyncDeviceIdle(bool value) async {
    backgroundSyncDeviceIdle = value;
    await FlutterDaemon().setDeviceIdle(value);
    if (await isBackgroundSyncEnabled()) {
      await enableBackgroundSync();
    }
  }

  bool get hasBatteryOptimization => Platform.isAndroid;

  @observable
  bool batteryOptimizationEnabled = false;

  @action
  Future<bool> isBatteryOptimizationEnabled() async {
    if (!hasBatteryOptimization) {
      return false;
    }
    final resp = await FlutterDaemon().isBatteryOptimizationDisabled();
    batteryOptimizationEnabled = !resp;
    if (batteryOptimizationEnabled && await isBackgroundSyncEnabled()) {
      // If the battery optimization is enabled, we need to disable the background sync
      await disableBackgroundSync();
    }
    return resp;
  }

  @action
  Future<void> disableBatteryOptimization() async {
    final resp = await FlutterDaemon().requestDisableBatteryOptimization();
    unawaited((() async {
      // android doesn't return if the permission was granted, so we need to poll it,
      // minute should be enough for the fallback method (opening settings and changing the permission)
      for (var i = 0; i < 4 * 60; i++) {
        await Future.delayed(Duration(milliseconds: 250));
        await isBatteryOptimizationEnabled();
      }
    })());
  }

  @action
  Future<void> enableBackgroundSync() async {
    if (hasBatteryOptimization && batteryOptimizationEnabled) {
      disableBackgroundSync();
      return;
    }
    final resp = await FlutterDaemon()
        .startBackgroundSync(settingsStore.currentSyncMode.frequency.inMinutes);
    printV("Background sync enabled: $resp");
    backgroundSyncEnabled = true;
  }

  @action
  Future<void> disableBackgroundSync() async {
    final resp = await FlutterDaemon().stopBackgroundSync();
    printV("Background sync disabled: $resp");
    backgroundSyncEnabled = false;
  }

  @computed
  bool get hasEnabledMwebBefore => settingsStore.hasEnabledMwebBefore;

  @action
  double getShadowSpread() {
    double spread = 0;
    if (!appStore.themeStore.currentTheme.isDark)
      spread = 0;
    else if (appStore.themeStore.currentTheme.isDark) spread = 0;
    return spread;
  }

  @action
  double getShadowBlur() {
    double blur = 0;
    if (!appStore.themeStore.currentTheme.isDark)
      blur = 0;
    else if (appStore.themeStore.currentTheme.isDark) blur = 0;
    return blur;
  }

  @action
  void setMwebEnabled() {
    if (!hasMweb) {
      return;
    }

    settingsStore.hasEnabledMwebBefore = true;
    mwebEnabled = true;
    bitcoin!.setMwebEnabled(wallet, true);
    balanceViewModel.mwebEnabled = true;
    settingsStore.mwebAlwaysScan = true;
  }

  @action
  void dismissMweb() {
    settingsStore.mwebCardDisplay = false;
    balanceViewModel.mwebEnabled = false;
    settingsStore.mwebAlwaysScan = false;
    mwebEnabled = false;
    bitcoin!.setMwebEnabled(wallet, false);
  }

  @action
  Future<void> rescanInternalChangeZcash() async {
    await zcash!.rescanInternalChange(wallet);
  }

  @action
  void dismissZcash() {
    settingsStore.showZcashMissingFundsCard = false;
  }

  @action
  void dismissDecredInfoCard() {
    showDecredInfoCard = false;
    sharedPreferences.setBool(PreferencesKey.showDecredInfoCard, false);
  }

  @action
  void dismissPayjoin() {
    settingsStore.showPayjoinCard = false;
  }

  @action
  void enablePayjoin() {
    settingsStore.usePayjoin = true;
    settingsStore.showPayjoinCard = false;
    bitcoin!.updatePayjoinState(wallet, true);
  }

  BalanceViewModel balanceViewModel;

  TradeMonitor tradeMonitor;

  AppStore appStore;

  SettingsStore settingsStore;

  YatStore yatStore;

  TradesStore tradesStore;

  OrdersStore ordersStore;

  TradeFilterStore tradeFilterStore;

  OrderFilterStore orderFilterStore;

  AnonpayTransactionsStore anonpayTransactionsStore;

  TransactionFilterStore transactionFilterStore;

  PayjoinTransactionsStore payjoinTransactionsStore;

  // Map<String, List<FilterItem>> filterItems;

  List<FilterItem> filterItems;

  List<FilterItem> exchangeFilterItems;

  bool get isBuyEnabled => settingsStore.isBitcoinBuyEnabled;

  bool get shouldShowYatPopup => settingsStore.shouldShowYatPopup;

  @action
  void furtherShowYatPopup(bool shouldShow) => settingsStore.shouldShowYatPopup = shouldShow;

  @computed
  bool get isEnabledSwapAction => settingsStore.exchangeStatus != ExchangeApiMode.disabled;

  @computed
  bool get canSend => wallet.canSend();

  @observable
  bool hasSwapAction;

  @computed
  bool get isEnabledTradeAction => !settingsStore.disableTradeOption;

  @observable
  bool hasTradeAction;

  @computed
  bool get isEnabledBulletinAction => !settingsStore.disableBulletin;

  ReactionDisposer? _onMoneroAccountChangeReaction;

  ReactionDisposer? _onMoneroBalanceChangeReaction;

  ReactionDisposer? _transactionDisposer;

  ReactionDisposer? _walletChangeDisposer;

  ReactionDisposer? _chainChangeDisposer;

  @computed
  bool get hasPowNodes => [WalletType.nano, WalletType.banano].contains(wallet.type);

  @computed
  bool get hasSignMessages {
    if (wallet.isHardwareWallet) {
      return false;
    }
    switch (wallet.type) {
      case WalletType.monero:
      case WalletType.litecoin:
      case WalletType.bitcoin:
      case WalletType.bitcoinCash:
      case WalletType.ethereum:
      case WalletType.polygon:
      case WalletType.base:
      case WalletType.arbitrum:
      case WalletType.bsc:
      case WalletType.solana:
      case WalletType.nano:
      case WalletType.banano:
      case WalletType.tron:
      case WalletType.wownero:
      case WalletType.decred:
      case WalletType.dogecoin:
        return true;
      case WalletType.zano:
      case WalletType.haven:
      case WalletType.zcash:
      case WalletType.none:
        return false;
    }
  }

  bool get showRepWarning {
    if (wallet.type != WalletType.nano) {
      return false;
    }

    if (!settingsStore.shouldShowRepWarning) {
      return false;
    }

    return !nano!.isRepOk(wallet);
  }

  Future<void> reconnect() async {
    int? chainId;
    if (isEVMWallet) {
      chainId = evm!.getSelectedChainId(wallet);
    }

    final node = appStore.settingsStore.getCurrentNode(wallet.type, chainId: chainId);
    await wallet.connectToNode(node: node);
    if (hasPowNodes) {
      final powNode = settingsStore.getCurrentPowNode(wallet.type);
      await wallet.connectToPowNode(node: powNode);
    }

    if (hasSilentPayments) {
      bitcoin!.setScanningActive(wallet, silentPaymentsScanningActive);
    }
  }

  @action
  void _onWalletChange(
      WalletBase<Balance, TransactionHistoryBase<TransactionInfo>, TransactionInfo>? wallet) {
    if (wallet == null) {
      return;
    }

    this.wallet = wallet;
    type = wallet.type;
    name = wallet.name;
    loadFilterItems();

    if (wallet.type == WalletType.monero) {
      subname = monero!.getCurrentAccount(wallet).label;

      _onMoneroAccountChangeReaction?.reaction.dispose();
      _onMoneroBalanceChangeReaction?.reaction.dispose();

      _onMoneroAccountChangeReaction = reaction(
          (_) => monero!.getMoneroWalletDetails(wallet).account,
          (Account account) => _onMoneroAccountChange(wallet));

      _onMoneroBalanceChangeReaction = reaction(
          (_) => monero!.getMoneroWalletDetails(wallet).balance,
          (MoneroBalance balance) => _onMoneroTransactionsUpdate(wallet));

      _onMoneroTransactionsUpdate(wallet);
    } else if (wallet.type == WalletType.wownero) {
      subname = wow.wownero!.getCurrentAccount(wallet).label;

      _onMoneroAccountChangeReaction?.reaction.dispose();
      _onMoneroBalanceChangeReaction?.reaction.dispose();

      _onMoneroAccountChangeReaction = reaction(
          (_) => wow.wownero!.getWowneroWalletDetails(wallet).account,
          (wow.Account account) => _onMoneroAccountChange(wallet));

      _onMoneroBalanceChangeReaction = reaction(
          (_) => wow.wownero!.getWowneroWalletDetails(wallet).balance,
          (wow.WowneroBalance balance) => _onMoneroTransactionsUpdate(wallet));

      _onMoneroTransactionsUpdate(wallet);
    } else {
      // FIX-ME: Check for side effects
      // subname = null;
      subname = '';

      _reloadTransactions();
    }

    _transactionDisposer?.reaction.dispose();

    if (isEVMCompatibleChain(wallet.type)) {
      _chainChangeDisposer?.reaction.dispose();
      _chainChangeDisposer = reaction((_) {
        // Access selectedChainId through proxy to track chain changes
        return evm!.getSelectedChainId(wallet);
      }, (_) {
        // When chain switches, reload transactions for the new chain
        _reloadTransactions();
      });
    } else {
      _chainChangeDisposer?.reaction.dispose();
      _chainChangeDisposer = null;
    }

    _transactionDisposer = reaction((_) => _transactionsChangeSignature(),
        _transactionDisposerCallback,
        delay: 300, fireImmediately: true);
  }

  // A content signature for appStore.wallet!.transactionHistory.transactions
  // that changes whenever ANY per-tx field the UI cares about changes -
  // unlike the previous `length * confirmations` trigger this replaced,
  // which only reliably caught brand new/removed txids. `confirmations` is
  // a plain (non-@observable) field, so reading it inside a reaction never
  // registers as a dependency at all - and even ignoring that, a same-key
  // remove-then-readd (used elsewhere to force MobX to notice an in-place
  // mutation on an ObservableMap) leaves `length` net unchanged, so that
  // trigger could silently never fire for a tx whose fields were updated
  // without the key count changing. Confirmed causing exactly this: a
  // silent-payment receive already present in transactionHistory at wallet
  // load never made it into this view model's own `transactions` list, and
  // only appeared after toggling a filter forced an unrelated recompute -
  // `fireImmediately: true` below additionally guarantees at least one
  // correct sync happens right after setup, self-healing that regardless
  // of whether anything changes again afterward.
  String _transactionsChangeSignature() {
    final txs = appStore.wallet?.transactionHistory.transactions;
    if (txs == null || txs.isEmpty) return '';
    final isBitcoin = wallet.type == WalletType.bitcoin;
    final buffer = StringBuffer();
    for (final tx in txs.values) {
      buffer
        ..write(tx.id)
        ..write(':')
        ..write(tx.confirmations)
        ..write(':')
        ..write(tx.isPending)
        ..write(':')
        ..write(tx.amount)
        ..write(':')
        ..write(isBitcoin ? bitcoin!.txSilentPaymentUnspentsCount(tx) : -1)
        ..write('|');
    }
    final signature = buffer.toString();
    return signature;
  }

  @action
  void _onMoneroAccountChange(WalletBase wallet) {
    if (wallet.type == WalletType.monero) {
      subname = monero!.getCurrentAccount(wallet).label;
    } else if (wallet.type == WalletType.wownero) {
      subname = wow.wownero!.getCurrentAccount(wallet).label;
    }
    _onMoneroTransactionsUpdate(wallet);
  }

  @action
  void _onMoneroTransactionsUpdate(WalletBase wallet) {
    transactions.clear();
    if (wallet.type == WalletType.monero) {
      final _accountTransactions = monero!
          .getTransactionHistory(wallet)
          .transactions
          .values
          .where((tx) =>
              monero!.getTransactionInfoAccountId(tx) == monero!.getCurrentAccount(wallet).id)
          .toList();

      transactions.addAll(
        _accountTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            appStore: appStore,
            key: ValueKey('monero_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    } else if (wallet.type == WalletType.wownero) {
      final _accountTransactions = wow.wownero!
          .getTransactionHistory(wallet)
          .transactions
          .values
          .where((tx) =>
              wow.wownero!.getTransactionInfoAccountId(tx) ==
              wow.wownero!.getCurrentAccount(wallet).id)
          .toList();

      transactions.addAll(
        _accountTransactions.map(
          (transaction) => TransactionListItem(
            transaction: transaction,
            balanceViewModel: balanceViewModel,
            appStore: appStore,
            key: ValueKey('wownero_transaction_history_item_${transaction.id}_key'),
          ),
        ),
      );
    }
  }

  @action
  Future<void> setSyncMode(SyncMode syncMode) async {
    settingsStore.currentSyncMode = syncMode;
    await enableBackgroundSync();
  }

  @computed
  bool get syncAll => settingsStore.currentSyncAll;

  @computed
  bool get builtinTor => settingsStore.currentBuiltinTor;

  @action
  void setBuiltinTor(bool value, BuildContext context) {
    if (value) {
      unawaited(
        showPopUp<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
              alertTitle: S.of(context).tor_connection,
              alertContent: S.of(context).tor_experimental,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop(true),
            );
          },
        ),
      );
    }
    settingsStore.currentBuiltinTor = value;
    if (value) {
      unawaited(ensureTorStarted(context: context).then((_) async {
        if (settingsStore.currentBuiltinTor == false)
          return; // return when tor got disabled in the meantime;
        int? chainId;
        if (isEVMWallet) {
          chainId = evm!.getSelectedChainId(wallet);
        }
        await wallet.connectToNode(
            node: appStore.settingsStore.getCurrentNode(wallet.type, chainId: chainId));
      }));
    } else {
      unawaited(ensureTorStopped(context: context).then((_) async {
        if (settingsStore.currentBuiltinTor == true)
          return; // return when tor got enabled in the meantime;
        int? chainId;
        if (isEVMWallet) {
          chainId = evm!.getSelectedChainId(wallet);
        }
        await wallet.connectToNode(
            node: appStore.settingsStore.getCurrentNode(wallet.type, chainId: chainId));
      }));
    }
  }

  @action
  void setSyncAll(bool value) => settingsStore.currentSyncAll = value;

  Future<List<String>> checkForHavenWallets() async {
    final walletInfos = await WalletInfo.getAll();
    return walletInfos
        .where((element) => element.type == WalletType.haven)
        .map((e) => e.name)
        .toList();
  }

  Future<List<String>> checkAffectedWallets() async {
    try {
      // await load file
      final vulnerableSeedsString = await rootBundle
          .loadString('assets/text/cakewallet_weak_bitcoin_seeds_hashed_sorted_version1.txt');
      final vulnerableSeeds = vulnerableSeedsString.split("\n");

      List<String> affectedWallets = [];
      final walletInfos = await WalletInfo.getAll();
      for (var walletInfo in walletInfos) {
        if (walletInfo.type == WalletType.bitcoin) {
          final password = await keyService.getWalletPassword(walletName: walletInfo.name);
          final path = await pathForWallet(name: walletInfo.name, type: walletInfo.type);
          final jsonSource = await read(path: path, password: password);
          final data = json.decode(jsonSource) as Map;
          final mnemonic = data['mnemonic'] as String?;

          if (mnemonic == null) continue;

          final hash = await Cryptography.instance.sha256().hash(utf8.encode(mnemonic));
          final seedSha = bytesToHex(hash.bytes);

          if (vulnerableSeeds.contains(seedSha)) {
            affectedWallets.add(walletInfo.name);
          }
        }
      }

      return affectedWallets;
    } catch (_) {
      return [];
    }
  }

  static ServicesResponse? cachedServicesResponse;

  Future<ServicesResponse> getServicesStatus() async {
    if (cachedServicesResponse != null) {
      return cachedServicesResponse!;
    }
    cachedServicesResponse = await _getServicesStatus();
    return cachedServicesResponse!;
  }

  Future<ServicesResponse> _getServicesStatus() async {
    try {
      if (isEnabledBulletinAction) {
        final res = await ProxyWrapper().get(
          clearnetUri: Uri.https(
            "service-api.cakewallet.com",
            "/v1/active-notices",
            {'key': secrets.fiatApiKey},
          ),
          onionUri: Uri.http(
            "jpirgl4lrwzjgdqj2nsv3g7twhp2efzty5d3cnypktyczzqfc5qcwwyd.onion",
            "/v1/active-notices",
            {'key': secrets.fiatApiKey},
          ),
        );
        if (res.statusCode < 200 || res.statusCode >= 300) {
          throw res.body;
        }

        final oldSha = sharedPreferences.getString(PreferencesKey.serviceStatusShaKey);

        final hash = await Cryptography.instance.sha256().hash(utf8.encode(res.body));
        final currentSha = bytesToHex(hash.bytes);

        final hasUpdates = oldSha != currentSha;

        return ServicesResponse.fromJson(
          json.decode(res.body) as Map<String, dynamic>,
          hasUpdates,
          currentSha,
        );
      } else {
        return ServicesResponse([], false, '');
      }
    } catch (e) {
      return ServicesResponse([], false, '');
    }
  }

  bool isSilentPaymentTx(TransactionInfo tx) =>
      wallet.type == WalletType.bitcoin && (bitcoin?.txIsReceivedSilentPayment(tx) ?? false);

  String getTransactionType(TransactionInfo tx) {
    if (wallet.type == WalletType.bitcoin) {
      if (tx.isReplaced == true) return ' (replaced)';
    }

    if (wallet.chainId == 1 && tx.evmSignatureName == 'approval')
      return ' (${tx.evmSignatureName})';

    return '';
  }

  Future<void> refreshDashboard() async {
    reconnect();
  }
}
