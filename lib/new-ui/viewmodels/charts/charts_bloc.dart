import 'package:bloc/bloc.dart';
import 'package:cake_wallet/new-ui/model/charts/price_data.dart';
import 'package:cake_wallet/new-ui/model/charts/price_store.dart';
import 'package:cake_wallet/new-ui/model/charts/util/chart_range.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:meta/meta.dart';

part 'charts_event.dart';

part 'charts_state.dart';

class ChartsBloc extends Bloc<ChartsEvent, ChartsState> {
  final PriceStore priceStore;
  final AppStore appStore;

  ChartsBloc({required this.priceStore, required this.appStore}) : super(ChartsInitial()) {
    on<RangeChanged>(_onRangeChanged);
    on<SortingCriteriumChanged>(_onSortingCriteriumChanged);
    on<CurrencyAdded>(_onCurrencyAdded);
    on<CurrencyRemoved>(_onCurrencyRemoved);
    on<CurrencyPinned>(_onCurrencyPinned);
    on<PageRefreshed>(_onPageRefreshed);
    on<PageLoadStarted>(_onPageLoadStarted);
    on<Init>(_init);
    add(Init());
}

  Future<void> _init(Init event, Emitter<ChartsState> emit) async {
    // TODO store the config data, load it here.
    emit(ChartsLoading(pinnedCurrency: CryptoCurrency.btc, currencies: [CryptoCurrency.btc, CryptoCurrency.xmr, CryptoCurrency.eth], range: ChartRange.all));
    add(PageLoadStarted());
  }



  Future<void> _onPageLoadStarted(PageLoadStarted event, Emitter<ChartsState> emit) async {
    if (state case ChartsStateWithData s) {
      final Map<CryptoCurrency, List<PriceData>> data = {};
      for (final curr in s.currencies) {
        data[curr] = await priceStore.getPrices(appStore.settingsStore.fiatCurrency, curr, s.range);
      }
      emit(ChartsLoaded(pinnedCurrency: s.pinnedCurrency, prices: data, range: s.range));
    } else {
      throw Exception("attempted price load without currency data");
    }
  }

  Future<void> _onRangeChanged(
    RangeChanged event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      emit(ChartsLoading(pinnedCurrency: s.pinnedCurrency, currencies: s.currencies, range: event.newRange));
      add(PageLoadStarted());
    }
  }

  Future<void> _onSortingCriteriumChanged(
    SortingCriteriumChanged event,
    Emitter<ChartsState> emit,
  ) async {
    //TODO sorting criteria ig?
  }

  Future<void> _onCurrencyAdded(
    CurrencyAdded event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      final newCurrencies = s.currencies..add(event.currency);
      emit(ChartsLoading(pinnedCurrency: s.pinnedCurrency, currencies: newCurrencies, range: s.range));
      add(PageLoadStarted());
    }
  }

  Future<void> _onCurrencyRemoved(
    CurrencyRemoved event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      final newCurrencies = s.currencies..remove(event.currency);
      emit(ChartsLoading(pinnedCurrency: s.pinnedCurrency, currencies: newCurrencies, range: s.range));
      add(PageLoadStarted());
    }
  }

  Future<void> _onCurrencyPinned(
    CurrencyPinned event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      emit(ChartsLoading(pinnedCurrency: event.currency, currencies: s.currencies, range: s.range));
      add(PageLoadStarted());
    }
  }

  Future<void> _onPageRefreshed(
    PageRefreshed event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      emit(ChartsLoading(pinnedCurrency: s.pinnedCurrency, currencies: s.currencies, range: s.range));
      add(PageLoadStarted());
    }
  }
}
