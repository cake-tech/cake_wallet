import "dart:async";

import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/store/dashboard/transaction_filter_store.dart";
import "package:cw_core/history_source.dart";
import "package:cw_core/transaction_history.dart";
import "package:cw_core/transaction_info.dart";
import "package:cw_core/wallet_type.dart";

/// A pass-through over the wallet's own history: it already announces per-item
/// changes keyed by the transaction id, which is also the item id.
class TransactionChangeEmitter extends ChangeEmitter {
  TransactionChangeEmitter(this._history);

  final TransactionHistory<TransactionInfo> _history;

  @override
  Stream<HistoryChange> get changes => _history.changes;

  @override
  bool get hasLoaded => _history.hasLoaded;

  @override
  ActionListItem? byId(String id) => _history.transactions[id];

  @override
  Iterable<ActionListItem> get items => _history.transactions.values;

  /// The history belongs to the wallet, which closes it — this emitter owns
  /// nothing of its own.
  @override
  Future<void> dispose() async {}
}

class TransactionHistoryFilters extends HistoryFilters {
  TransactionHistoryFilters({required this.appStore, required this.filterStore});

  final AppStore appStore;
  final TransactionFilterStore filterStore;

  @override
  bool relevant(ActionListItem item) {
    if (item is! TransactionInfo) {
      return false;
    }

    return _inCurrentAccount(item) && filterStore.relevant(item);
  }

  /// Monero and wownero keep every account's transactions in one history, so
  /// the account has to be filtered rather than the history split.
  bool _inCurrentAccount(TransactionInfo transaction) {
    final wallet = appStore.wallet;

    if (wallet == null || wallet.type != WalletType.monero) {
      return true;
    }

    return monero!.getTransactionInfoAccountId(transaction) ==
        monero!.getCurrentAccount(wallet).id;
  }
}

HistorySource transactionHistorySource({
  required AppStore appStore,
  required TransactionFilterStore filterStore,
}) =>
    HistorySource(
      emitter: TransactionChangeEmitter(appStore.wallet!.transactionHistory),
      filters: TransactionHistoryFilters(appStore: appStore, filterStore: filterStore),
    );
