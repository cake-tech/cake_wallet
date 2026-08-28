import "dart:async";

import "package:bloc/bloc.dart";
import "package:collection/collection.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:cake_wallet/new-ui/viewmodels/transaction_history/date_ordered_list.dart";
import "package:cake_wallet/view_model/dashboard/formatted_item_list.dart";
import "package:cw_core/history_source.dart";
import "package:cw_core/json_transaction_history.dart";
import "package:rxdart/rxdart.dart";

part "transaction_history_event.dart";
part "transaction_history_state.dart";

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
    on<TransactionHistoryFilterToggled>(_onFilterToggled, transformer: sequential());
    on<TransactionHistoryAllFiltersToggled>(_onAllFiltersToggled, transformer: sequential());

    for (final source in sources) {
      final changes = source.emitter.changes;

      _subscriptions.add(
        changes
            .buffer(changes.debounceTime(Duration.zero))
            .where((journal) => journal.isNotEmpty)
            .listen((journal) => add(TransactionHistoryChanged(source, journal))),
      );
    }
  }

  static const _rebuildInsteadOfApplyingAbove = 16;

  final List<HistorySource> sources;
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

  List<HistoryFilter> get filters =>
      [for (final source in sources) ...source.filters.filters];

  Future<void> _onFilterToggled(
    TransactionHistoryFilterToggled event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    final owner = sources
        .firstWhereOrNull((source) => source.filters.allFilters.contains(event.filter));

    owner!.filters.toggleFilter(event.filter);

    emit(TransactionHistoryLoaded.from(sources));
  }

  Future<void> _onAllFiltersToggled(
    TransactionHistoryAllFiltersToggled event,
    Emitter<TransactionHistoryState> emit,
  ) async {
    for (final source in sources) {
      source.filters.setAllFilters(value: event.value);
    }

    emit(TransactionHistoryLoaded.from(sources));
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
      await source.dispose();
    }
    return super.close();
  }
}
