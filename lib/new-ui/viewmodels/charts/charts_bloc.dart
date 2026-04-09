import 'package:bloc/bloc.dart';
import 'package:cake_wallet/new-ui/model/charts/charts_asset.dart';
import 'package:cake_wallet/new-ui/model/charts/price_data.dart';
import 'package:cake_wallet/new-ui/model/charts/util/price_data_sort_criteria.dart';
import 'package:cake_wallet/new-ui/model/charts/price_store.dart';
import 'package:cake_wallet/new-ui/model/charts/util/chart_range.dart';
import 'package:cake_wallet/new-ui/model/charts/util/price_change_data.dart';
import 'package:cake_wallet/new-ui/model/charts/util/price_change_direction.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/foundation.dart';

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
    final assets = await ChartsAsset.get();

    if(assets.isEmpty) {
      // generally this shouldn't happen, but i wanna make sure we can recover from a broken db
      assets.add(ChartsAsset(asset: CryptoCurrency.btc, isFavorite: true));
      assets.first.insert();
    }
    
    if(assets.firstWhereOrNull((item)=>item.isFavorite) == null) {
      assets.first = ChartsAsset(asset: assets.first.asset, isFavorite: true);
      assets.first.insert();
    }

    emit(ChartsLoading(
        pinnedCurrency: assets.firstWhere((item) => item.isFavorite).asset,
        currencies: assets.map((item) => item.asset).toList(),
        range: ChartRange.all,
        sortCriterium: PriceDataSortCriterium.all.first));
    add(PageLoadStarted());
  }



  Future<void> _onPageLoadStarted(PageLoadStarted event, Emitter<ChartsState> emit) async {
    if (state case ChartsStateWithData s) {
      final Map<CryptoCurrency, List<PriceData>> data = {};
      for (final curr in s.currencies) {
        data[curr] = await priceStore.getPrices(appStore.settingsStore.fiatCurrency, curr, s.range);
      }
      emit(ChartsLoaded(pinnedCurrency: s.pinnedCurrency, prices: data, range: s.range, sortCriterium: s.sortCriterium));
    } else {
      throw Exception("attempted price load without currency data");
    }
  }

  Future<void> _onRangeChanged(
    RangeChanged event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      emit(s.toLoading().copyWith(range: event.newRange));
      add(PageLoadStarted());
    }
  }

  Future<void> _onSortingCriteriumChanged(
    SortingCriteriumChanged event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      emit(s.copyWith(sortCriterium: event.newCriterium));
    }
  }

  Future<void> _onCurrencyAdded(
    CurrencyAdded event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      final newCurrencies = s.currencies..add(event.currency);
      await ChartsAsset(asset: event.currency, isFavorite: false).insert();
      emit(s.toLoading().copyWith(currencies: newCurrencies));
      add(PageLoadStarted());
    }
  }

  Future<void> _onCurrencyRemoved(
    CurrencyRemoved event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      final newCurrencies = s.currencies..remove(event.currency);

      if(newCurrencies.isEmpty) {
        throw Exception("removed the last currency ${(kDebugMode) ? "- your ui should block this! what did you do?" : ""}");
      }


      final CryptoCurrency newPin;
      if(s.pinnedCurrency == event.currency) {
          newPin = newCurrencies.first;
          await ChartsAsset(asset: s.pinnedCurrency, isFavorite: false).insert();
          await ChartsAsset(asset: newPin, isFavorite: true).insert();
      } else {
        newPin = s.pinnedCurrency;
      }

      await ChartsAsset(asset: event.currency, isFavorite: false).remove();


      emit(s.toLoading().copyWith(currencies: newCurrencies, pinnedCurrency: newPin));
      add(PageLoadStarted());
    }
  }

  Future<void> _onCurrencyPinned(
    CurrencyPinned event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      if(s.pinnedCurrency == event.currency) {
        return;
      }
      await ChartsAsset(asset: s.pinnedCurrency, isFavorite: false).insert();
      await ChartsAsset(asset: event.currency, isFavorite: true).insert();
      emit(s.toLoading().copyWith(pinnedCurrency: event.currency));
      add(PageLoadStarted());
    }
  }

  Future<void> _onPageRefreshed(
    PageRefreshed event,
    Emitter<ChartsState> emit,
  ) async {
    if(state case ChartsStateWithData s) {
      emit(s.toLoading());
      add(PageLoadStarted());
    }
  }
}
