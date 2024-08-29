import 'package:cake_wallet/cake_pay/cake_pay_service.dart';
import 'package:cake_wallet/cake_pay/cake_pay_states.dart';
import 'package:cake_wallet/cake_pay/cake_pay_vendor.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/dashboard/dropdown_filter_item.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:mobx/mobx.dart';

part 'cake_pay_cards_list_view_model.g.dart';

class CakePayCardsListViewModel = CakePayCardsListViewModelBase with _$CakePayCardsListViewModel;

abstract class CakePayCardsListViewModelBase with Store {
  CakePayCardsListViewModelBase({
    required this.cakePayService,
  })  : cardState = CakePayCardsStateNoCards(),
        cakePayVendors = [],
        availableCountries = [],
        page = 1,
        selectedCountry = 'USA',
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

  void initialization() async {
    await getCountries();
    selectedCountry = availableCountries.first;
    getVendors();
  }

  final CakePayService cakePayService;

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
        S.current.countries: [
          DropdownFilterItem(
            items: availableCountries,
            caption: '',
            selectedItem: selectedCountry,
            onItemSelected: (String value) => setSelectedCountry(value),
          ),
        ]
      };

  String searchString;

  int page;

  late String _initialSelectedCountry;

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
  List<String> availableCountries;

  @observable
  bool displayPrepaidCards;

  @observable
  bool displayGiftCards;

  @observable
  bool displayDenominationsCards;

  @observable
  bool displayCustomValueCards;

  @observable
  String selectedCountry;

  bool get hasFiltersChanged =>
      selectedCountry != _initialSelectedCountry ||
      displayPrepaidCards != _initialDisplayPrepaidCards ||
      displayGiftCards != _initialDisplayGiftCards ||
      displayDenominationsCards != _initialDisplayDenominationsCards ||
      displayCustomValueCards != _initialDisplayCustomValueCards;

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
        country: selectedCountry,
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
    if (vendorsState is CakePayVendorLoadingState || !hasMoreDataToFetch || isLoadingNextPage)
      return;

    isLoadingNextPage = true;
    page++;
    try {
      var newVendors = await cakePayService.getVendors(
          country: selectedCountry,
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
  void setSelectedCountry(String country) => selectedCountry = country;

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
