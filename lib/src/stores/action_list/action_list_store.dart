import 'dart:async';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/domain/monero/monero_transaction_info.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter/foundation.dart';
import 'package:cake_wallet/src/domain/monero/account.dart';
import 'package:cake_wallet/src/domain/common/transaction_history.dart';
import 'package:cake_wallet/src/domain/common/transaction_info.dart';
import 'package:cake_wallet/src/domain/common/wallet.dart';
import 'package:cake_wallet/src/domain/services/wallet_service.dart';
import 'package:cake_wallet/src/domain/monero/monero_wallet.dart';
import 'package:cake_wallet/src/domain/common/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/monero/monero_amount_format.dart';
import 'package:cake_wallet/src/domain/monero/transaction_description.dart';
import 'package:cake_wallet/src/stores/price/price_store.dart';
import 'package:cake_wallet/src/stores/settings/settings_store.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_display_mode.dart';
import 'package:cake_wallet/src/stores/action_list/action_list_item.dart';
import 'package:cake_wallet/src/stores/action_list/date_section_item.dart';
import 'package:cake_wallet/src/stores/action_list/trade_filter_store.dart';
import 'package:cake_wallet/src/stores/action_list/trade_list_item.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_filter_store.dart';
import 'package:cake_wallet/src/stores/action_list/transaction_list_item.dart';

part 'action_list_store.g.dart';

class ActionListStore = ActionListBase with _$ActionListStore;

abstract class ActionListBase with Store {
  ActionListBase(
      {@required WalletService walletService,
      @required SettingsStore settingsStore,
      @required PriceStore priceStore,
      @required this.transactionFilterStore,
      @required this.tradeFilterStore,
      @required this.transactionDescriptions,
      @required this.tradesSource}) {
    trades = List<TradeListItem>();
    _transactions = List<TransactionListItem>();
    _walletService = walletService;
    _settingsStore = settingsStore;
    _priceStore = priceStore;

    if (walletService.currentWallet != null) {
      _onWalletChanged(walletService.currentWallet);
    }

    _onWalletChangeSubscription =
        walletService.onWalletChange.listen(_onWalletChanged);

    _onTransactionDescriptions = transactionDescriptions
        .watch()
        .listen((_) async => await _updateTransactionsList());

    _onTradesChanged =
        tradesSource.watch().listen((_) async => await updateTradeList());

    updateTradeList();
  }

  static List<ActionListItem> formattedItemsList(List<ActionListItem> items) {
    final formattedList = List<ActionListItem>();
    DateTime lastDate;
    items.sort((a, b) => b.date.compareTo(a.date));

    for (int i = 0; i < items.length; i++) {
      final transaction = items[i];

      if (lastDate == null) {
        lastDate = transaction.date;
        formattedList.add(DateSectionItem(transaction.date));
        formattedList.add(transaction);
        continue;
      }

      final isCurrentDay = lastDate.year == transaction.date.year &&
          lastDate.month == transaction.date.month &&
          lastDate.day == transaction.date.day;

      if (isCurrentDay) {
        formattedList.add(transaction);
        continue;
      }

      lastDate = transaction.date;
      formattedList.add(DateSectionItem(transaction.date));
      formattedList.add(transaction);
    }

    return formattedList;
  }

  @computed
  List<TransactionListItem> get transactions {
    final symbol = PriceStoreBase.generateSymbolForPair(
        fiat: _settingsStore.fiatCurrency, crypto: CryptoCurrency.xmr);
    final price = _priceStore.prices[symbol];

    _transactions.forEach((item) {
      final tx = item.transaction;

      if (tx is MoneroTransactionInfo) {
        final amount = calculateFiatAmountRaw(
            cryptoAmount: moneroAmountToDouble(amount: tx.amount),
            price: price);
        tx.changeFiatAmount(amount);
      }
    });

    return _transactions;
  }

  @observable
  List<TransactionListItem> _transactions;

  @observable
  List<TradeListItem> trades;

  @computed
  List<ActionListItem> get items {
    final _items = List<ActionListItem>();

    if (_settingsStore.actionlistDisplayMode
        .contains(ActionListDisplayMode.transactions)) {
      _items
          .addAll(transactionFilterStore.filtered(transactions: transactions));
    }

    if (_settingsStore.actionlistDisplayMode
        .contains(ActionListDisplayMode.trades)) {
      _items.addAll(tradeFilterStore.filtered(trades: trades));
    }

    return formattedItemsList(_items);
  }

  @computed
  int get totalCount => transactions.length + trades.length;

  TransactionFilterStore transactionFilterStore;
  TradeFilterStore tradeFilterStore;
  Box<TransactionDescription> transactionDescriptions;
  Box<Trade> tradesSource;

  WalletService _walletService;
  TransactionHistory _history;
  SettingsStore _settingsStore;
  PriceStore _priceStore;
  Account _account;
  StreamSubscription<Wallet> _onWalletChangeSubscription;
  StreamSubscription<List<TransactionInfo>> _onTransactionsChangeSubscription;
  StreamSubscription<Account> _onAccountChangeSubscription;
  StreamSubscription<BoxEvent> _onTransactionDescriptions;
  StreamSubscription<BoxEvent> _onTradesChanged;

  // @override
  // void dispose() {
  //   if (_onTransactionsChangeSubscription != null) {
  //     _onTransactionsChangeSubscription.cancel();
  //   }

  //   if (_onAccountChangeSubscription != null) {
  //     _onAccountChangeSubscription.cancel();
  //   }

  //   _onTransactionDescriptions?.cancel();
  //   _onWalletChangeSubscription.cancel();
  //   _onTradesChanged?.cancel();
  //   super.dispose();
  // }

  @action
  Future updateTradeList() async => this.trades =
      tradesSource.values.map((trade) => TradeListItem(trade: trade)).toList();

  Future _updateTransactionsList() async {
    final _transactions = await _history.getAll();
    await _setTransactions(_transactions);
  }

  Future _onWalletChanged(Wallet wallet) async {
    if (_onTransactionsChangeSubscription != null) {
      await _onTransactionsChangeSubscription.cancel();
    }

    if (_onAccountChangeSubscription != null) {
      await _onAccountChangeSubscription.cancel();
    }

    _history = wallet.getHistory();
    _onTransactionsChangeSubscription = _history.transactions
        .listen((transactions) => _setTransactions(transactions));

    if (wallet is MoneroWallet) {
      _account = wallet.account;
      _onAccountChangeSubscription = wallet.onAccountChange.listen((account) {
        _account = account;
        _updateTransactionsList();
      });
    }

    await _updateTransactionsList();
  }

  Future _setTransactions(List<TransactionInfo> transactions) async {
    final wallet = _walletService.currentWallet;
    List<TransactionInfo> sortedTransactions = transactions.map((transaction) {
      if (transaction is MoneroTransactionInfo) {
        if (transactionDescriptions.values.isNotEmpty) {
          final description = transactionDescriptions.values.firstWhere(
              (desc) => desc.id == transaction.id,
              orElse: () => null);

          if (description != null && description.recipientAddress != null) {
            transaction.recipientAddress = description.recipientAddress;
          }
        }

        return transaction;
      }

      return transaction;
    }).toList();

    if (wallet is MoneroWallet) {
      sortedTransactions = transactions
          .where((tx) => tx is MoneroTransactionInfo
              ? tx.accountIndex == _account.id
              : false)
          .toList();
    }

    this._transactions = sortedTransactions
        .map((transaction) => TransactionListItem(transaction: transaction))
        .toList();
  }
}
