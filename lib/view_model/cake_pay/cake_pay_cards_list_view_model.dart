import 'package:cake_wallet/cake_pay/cake_pay_service.dart';
import 'package:cake_wallet/cake_pay/cake_pay_states.dart';
import 'package:cake_wallet/cake_pay/cake_pay_vendor.dart';
import 'package:cake_wallet/entities/country.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:mobx/mobx.dart';

part 'cake_pay_cards_list_view_model.g.dart';

class CakePayCardsListViewModel = CakePayCardsListViewModelBase with _$CakePayCardsListViewModel;

abstract class CakePayCardsListViewModelBase with Store {
  CakePayCardsListViewModelBase({
    required this.cakePayService,
    required this.settingsStore,
  })  : cardState = CakePayCardsStateNoCards(),
        cakePayVendors = [],
        availableCountries = [],
        page = 1,
        displayPrepaidCards = true,
        displayGiftCards = true,
        displayDenominationsCards = true,
        displayCustomValueCards = true,
        scrollOffsetFromTop = 0.0,
        vendorsState = InitialCakePayVendorLoadingState(),
        createCardState = CakePayCreateCardState(),
        searchString = '',
        CakePayVendorList = <CakePayVendor>[] {
    initialization();
  }

  static Country _getInitialCountry(FiatCurrency fiatCurrency) {
    if (fiatCurrency.countryCode == 'eur') {
      return Country.deu;
    }
    return Country.fromCode(fiatCurrency.countryCode) ?? Country.usa;
  }

  void initialization() async {
    await getCountries();
    getVendors();
  }

  final CakePayService cakePayService;
  final SettingsStore settingsStore;

  List<CakePayVendor> CakePayVendorList;

  Map<String, List<FilterItem>> get createFilterItems => {
        S.current.filter_by: [
          FilterItem(
              value: () => displayPrepaidCards,
              caption: S.current.prepaid_cards,
              onChanged: togglePrepaidCards),
          FilterItem(
              value: () => displayGiftCards,
              caption: S.current.gift_cards,
              onChanged: toggleGiftCards),
        ],
        S.current.value_type: [
          FilterItem(
              value: () => displayDenominationsCards,
              caption: S.current.denominations,
              onChanged: toggleDenominationsCards),
          FilterItem(
              value: () => displayCustomValueCards,
              caption: S.current.custom_value,
              onChanged: toggleCustomValueCards),
        ],
      };

  String searchString;
  int page;

  late Country _initialSelectedCountry;
  late bool _initialDisplayPrepaidCards;
  late bool _initialDisplayGiftCards;
  late bool _initialDisplayDenominationsCards;
  late bool _initialDisplayCustomValueCards;

  @observable
  double scrollOffsetFromTop;

  @observable
  CakePayCreateCardState createCardState;

  @observable
  CakePayCardsState cardState;

  @observable
  CakePayVendorState vendorsState;

  @observable
  bool hasMoreDataToFetch = true;

  @observable
  bool isLoadingNextPage = false;

  @observable
  List<CakePayVendor> cakePayVendors;

  @observable
  List<Country> availableCountries;

  @observable
  bool displayPrepaidCards;

  @observable
  bool displayGiftCards;

  @observable
  bool displayDenominationsCards;

  @observable
  bool displayCustomValueCards;

  @computed
  Country get selectedCountry =>
      settingsStore.selectedCakePayCountry ?? _getInitialCountry(settingsStore.fiatCurrency);

  @computed
  bool get shouldShowCountryPicker => settingsStore.selectedCakePayCountry == null && availableCountries.isNotEmpty;


  bool get hasFiltersChanged {
    return selectedCountry != _initialSelectedCountry ||
        displayPrepaidCards != _initialDisplayPrepaidCards ||
        displayGiftCards != _initialDisplayGiftCards ||
        displayDenominationsCards != _initialDisplayDenominationsCards ||
        displayCustomValueCards != _initialDisplayCustomValueCards;
  }


  Future<void> getCountries() async {
    availableCountries = await cakePayService.getCountries();
  }

  @action
  Future<void> getVendors({
    String? text,
    int? currentPage,
  }) async {
    vendorsState = CakePayVendorLoadingState();
    searchString = text ?? '';
    var newVendors = await cakePayService.getVendors(
        country: Country.getCakePayName(selectedCountry),
        page: currentPage ?? page,
        search: searchString,
        giftCards: displayGiftCards,
        prepaidCards: displayPrepaidCards,
        custom: displayCustomValueCards,
        onDemand: displayDenominationsCards);

    cakePayVendors = CakePayVendorList = newVendors;
    vendorsState = CakePayVendorLoadedState();
  }

  @action
  Future<void> fetchNextPage() async {
    if (vendorsState is CakePayVendorLoadingState || !hasMoreDataToFetch || isLoadingNextPage) {
      return;
    }

    isLoadingNextPage = true;
    page++;
    try {
      var newVendors = await cakePayService.getVendors(
          country: Country.getCakePayName(selectedCountry),
          page: page,
          search: searchString,
          giftCards: displayGiftCards,
          prepaidCards: displayPrepaidCards,
          custom: displayCustomValueCards,
          onDemand: displayDenominationsCards);

      cakePayVendors.addAll(newVendors);
    } catch (error) {
      if (error.toString().contains('detail":"Invalid page."')) {
        hasMoreDataToFetch = false;
      }
    } finally {
      isLoadingNextPage = false;
    }
  }

  Future<bool> isCakePayUserAuthenticated() async {
    return await cakePayService.isLogged();
  }

  void resetLoadingNextPageState() {
    hasMoreDataToFetch = true;
    page = 1;
  }

  void storeInitialFilterStates() {
    _initialSelectedCountry = selectedCountry;
    _initialDisplayPrepaidCards = displayPrepaidCards;
    _initialDisplayGiftCards = displayGiftCards;
    _initialDisplayDenominationsCards = displayDenominationsCards;
    _initialDisplayCustomValueCards = displayCustomValueCards;
  }

  @action
  void setSelectedCountry(Country country) {
    // just so it triggers the reaction even when selecting the default country
    settingsStore.selectedCakePayCountry = null;
    settingsStore.selectedCakePayCountry = country;
  }

  @action
  void togglePrepaidCards() => displayPrepaidCards = !displayPrepaidCards;

  @action
  void toggleGiftCards() => displayGiftCards = !displayGiftCards;

  @action
  void toggleDenominationsCards() => displayDenominationsCards = !displayDenominationsCards;

  @action
  void toggleCustomValueCards() => displayCustomValueCards = !displayCustomValueCards;

  void setScrollOffsetFromTop(double scrollOffset) {
    scrollOffsetFromTop = scrollOffset;
  }
}
