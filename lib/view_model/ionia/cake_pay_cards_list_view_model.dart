import 'package:cake_wallet/ionia/cake_pay_service.dart';
import 'package:cake_wallet/ionia/cake_pay_states.dart';
import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';
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
        displayPrepaidCards = true,
        displayGiftCards = true,
        displayDenominationsCards = true,
        displayCustomValueCards = true,
        ioniaCategories = IoniaCategory.allCategories,
        selectedIndices = ObservableList<IoniaCategory>.of([IoniaCategory.all]),
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
            selectedItem: selectedCountry ??= 'USA',
            onItemSelected: (String value) => setSelectedCountry(value),
          ),
        ]
      };

  String searchString;

  @observable
  double scrollOffsetFromTop;

  @observable
  CakePayCreateCardState createCardState;

  @observable
  CakePayCardsState cardState;

  @observable
  CakePayVendorState vendorsState;

  @observable
  String? selectedCountry;

  @observable
  List<CakePayVendor> cakePayVendors;

  @observable
  List<String> availableCountries;

  @observable
  List<IoniaCategory> ioniaCategories;

  @observable
  ObservableList<IoniaCategory> selectedIndices;

  @observable
  bool displayPrepaidCards;

  @observable
  bool displayGiftCards;

  @observable
  bool displayDenominationsCards;

  @observable
  bool displayCustomValueCards;

  @action
  Future<void> createCard() async {
    try {
      createCardState = CakePayCreateCardStateLoading();
      await cakePayService.createCard();
      createCardState = CakePayCreateCardStateSuccess();
    } catch (e) {
      createCardState = CakePayCreateCardStateFailure(error: e.toString());
    }
  }

  @action
  void searchMerchant(String text) {
    if (text.isEmpty) {
      cakePayVendors = CakePayVendorList;
      return;
    }
    searchString = text;
    cakePayService.getVendors(page: 1, country: 'USA').then((value) {
      cakePayVendors = value;
    });
  }

  Future<void> getCountries() async {
    availableCountries = await cakePayService.getCountries();
  }

  void getVendors() async {
    vendorsState = CakePayVendorLoadingState();
    cakePayService
        .getVendors(page: 1, country: selectedCountry!)
        .then((value) => cakePayVendors = CakePayVendorList = value);
    vendorsState = CakePayVendorLoadedState();
  }

  Future<bool> isCakePayUserAuthenticated() async {
    return await cakePayService.isLogged();
  }

  @action
  void setSelectedFilter(IoniaCategory category) {
    if (category == IoniaCategory.all) {
      selectedIndices.clear();
      selectedIndices.add(category);
      return;
    }

    if (category != IoniaCategory.all) {
      selectedIndices.remove(IoniaCategory.all);
    }

    if (selectedIndices.contains(category)) {
      selectedIndices.remove(category);

      if (selectedIndices.isEmpty) {
        selectedIndices.add(IoniaCategory.all);
      }
      return;
    }
    selectedIndices.add(category);
  }

  @action
  void onSearchFilter(String text) {
    if (text.isEmpty) {
      ioniaCategories = IoniaCategory.allCategories;
    } else {
      ioniaCategories = IoniaCategory.allCategories
          .where(
            (e) => e.title.toLowerCase().contains(text.toLowerCase()),
          )
          .toList();
    }
  }

  @action
  void resetIoniaCategories() {
    ioniaCategories = IoniaCategory.allCategories;
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
