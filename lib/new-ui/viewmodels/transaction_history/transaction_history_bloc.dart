import "dart:async";

import "package:bloc/bloc.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/new-ui/viewmodels/transaction_history/date_ordered_list.dart";
import "package:cake_wallet/view_model/dashboard/formatted_item_list.dart";
import "package:cw_core/history_source.dart";
import "package:rxdart/rxdart.dart";

part "transaction_history_event.dart";
part "transaction_history_state.dart";

/// Merges every history source into one list the UI can render.
///
/// Sources announce item-level changes; this turns bursts of them into a list,
/// applying them incrementally where that beats rebuilding. It holds no
/// source-specific logic — what a row is, and whether it belongs, are both the
/// source's business.
class TransactionHistoryBloc extends Bloc<TransactionHistoryEvent, TransactionHistoryState> {
  TransactionHistoryBloc({
    required this.sources,
    required this.appStore,
    required this.fiatConversionStore,
  }) : super(
          sources.any((source) => source.emitter.hasLoaded)
              ? TransactionHistoryLoaded.from(sources)
              : const TransactionHistoryNotLoaded(),
        ) {
    on<TransactionHistoryChanged>(_onChanged, transformer: sequential());
    on<TransactionHistoryRefreshed>(_onRefreshed, transformer: sequential());

    for (final source in sources) {
      final changes = source.emitter.changes;

      // A source emits one event per mutation, so a full load arrives as
      // thousands. Buffer until the burst settles — unlike a periodic window
      // this arms a timer only when something changed, so idling costs nothing.
      _subscriptions.add(
        changes
            .buffer(changes.debounceTime(Duration.zero))
            .where((journal) => journal.isNotEmpty)
            .listen((journal) => add(TransactionHistoryChanged(source, journal))),
      );
    }
  }

  /// Above this many insertions a full rebuild is cheaper than applying them
  /// one at a time: an id we have never seen cannot be located by binary
  /// search, so each insertion costs a scan. The two are even around log2(n).
  static const _rebuildInsteadOfApplyingAbove = 16;

  final List<HistorySource> sources;

  /// Exposed so a widget rendering the list needs only this bloc: rows read the
  /// wallet, and fiat conversion, from here.
  final AppStore appStore;
  final FiatConversionStore fiatConversionStore;

  FiatCurrency get fiat => appStore.settingsStore.fiatCurrency;

  final List<StreamSubscription<List<HistoryChange>>> _subscriptions = [];

  Future<void> _onChanged(
    TransactionHistoryChanged event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    final current = state;

    var insertions = 0;
    var rebuild = current is! TransactionHistoryLoaded;

    for (final change in event.journal) {
      switch (change) {
        // The source was emptied, or it just finished loading. Either way its
        // own state is authoritative and enumerating deltas is wasted work.
        case HistoryReset():
          rebuild = true;
        case ItemAdded():
          insertions++;
        case ItemUpdated():
        case ItemRemoved():
          break;
      }
    }

    if (rebuild || insertions > _rebuildInsteadOfApplyingAbove) {
      emit(TransactionHistoryLoaded.from(sources));
      return;
    }

    emit((current as TransactionHistoryLoaded).applying(event.source, event.journal));
  }

  Future<void> _onRefreshed(
    TransactionHistoryRefreshed event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    if (!sources.any((source) => source.emitter.hasLoaded)) {
      return;
    }

    emit(TransactionHistoryLoaded.from(sources));
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    for (final source in sources) {
      await source.emitter.dispose();
    }
    return super.close();
  }
}
