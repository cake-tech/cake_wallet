import 'package:cake_wallet/cake_pay/cake_pay_service.dart';
import 'package:cake_wallet/cake_pay/cake_pay_states.dart';
import 'package:cake_wallet/cake_pay/cake_pay_vendor.dart';
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
        'Filter Option': [
          FilterItem(
              value: () => displayPrepaidCards,
              caption: 'Prepaid Cards',
              onChanged: togglePrepaidCards),
          FilterItem(
              value: () => displayGiftCards, caption: 'Gift Cards', onChanged: toggleGiftCards),
        ],
        'Value Type': [
          FilterItem(
              value: () => displayDenominationsCards,
              caption: 'Denominations',
              onChanged: toggleDenominationsCards),
          FilterItem(
              value: () => displayCustomValueCards,
              caption: 'Custom Value',
              onChanged: toggleCustomValueCards),
        ],
        'Countries': [
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

  @observable
  double scrollOffsetFromTop;

  @observable
  CakePayCreateCardState createCardState;

  @observable
  CakePayCardsState cardState;

  @observable
  CakePayVendorState vendorsState;

  @observable
  String selectedCountry;

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

  Future<void> getCountries() async {
    availableCountries = await cakePayService.getCountries();
  }

  @action
  Future<void> getVendors({String? text}) async {
    vendorsState = CakePayVendorLoadingState();
    searchString = text ?? '';
    cakePayService
        .getVendors(
            country: selectedCountry,
            page: page,
            search: searchString,
            giftCards: displayGiftCards,
            prepaidCards: displayPrepaidCards,
            custom: displayCustomValueCards,
            onDemand: displayDenominationsCards)
        .then((value) => cakePayVendors = CakePayVendorList = value);
    vendorsState = CakePayVendorLoadedState();
  }

  Future<bool> isCakePayUserAuthenticated() async {
    return await cakePayService.isLogged();
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
