import 'package:cake_wallet/ionia/cake_pay_states.dart';
import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/view_model/dashboard/dropdown_filter_item.dart';
import 'package:cake_wallet/view_model/dashboard/filter_item.dart';
import 'package:mobx/mobx.dart';

part 'ionia_gift_cards_list_view_model.g.dart';

class IoniaGiftCardsListViewModel = IoniaGiftCardsListViewModelBase
    with _$IoniaGiftCardsListViewModel;

abstract class IoniaGiftCardsListViewModelBase with Store {
  IoniaGiftCardsListViewModelBase({
    required this.ioniaService,
  })  : cardState = CakePayCardsStateNoCards(),
        cakePayVendors = [],
        availableCountries = [],
        filterItems = {},
        displayPrepaidCards = true,
        displayGiftCards = true,
        displayDenominationsCards = true,
        displayCustomValueCards = true,
        ioniaCategories = IoniaCategory.allCategories,
        selectedIndices = ObservableList<IoniaCategory>.of([IoniaCategory.all]),
        scrollOffsetFromTop = 0.0,
        merchantState = InitialCakePayVendorLoadingState(),
        createCardState = CakePayCreateCardState(),
        searchString = '',
        CakePayVendorList = <CakePayVendor>[] {
    filterItems = {
      'Filter Option': [
        FilterItem(
            value: () => displayPrepaidCards,
            caption: 'S.current.all_transactions',
            onChanged: togglePrepaidCards),
        FilterItem(
            value: () => displayGiftCards,
            caption: 'S.current.incoming',
            onChanged: toggleGiftCards),
      ],
      'Value Type': [
        FilterItem(
            value: () => displayDenominationsCards,
            caption: 'S.current.all_trades',
            onChanged: toggleDenominationsCards),
        FilterItem(
            value: () => displayCustomValueCards,
            caption: 'ExchangeProviderDescription.changeNow.title',
            onChanged: toggleCustomValueCards),
      ],
      'Countries': [
        DropdownFilterItem(
          items: availableCountries,
          caption: 'S.current.all_trades',
          selectedItem: selectedCountry ??= 'USA',
          onItemSelected: (String value) => getVendors(),
        ),
      ]
    };
  }

  final IoniaService ioniaService;

  List<CakePayVendor> CakePayVendorList;

  Map<String, List<FilterItem>> filterItems;

  String searchString;

  @observable
  double scrollOffsetFromTop;

  @observable
  CakePayCreateCardState createCardState;

  @observable
  CakePayCardsState cardState;

  @observable
  CakePayVendorState merchantState;

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
      await ioniaService.createCard();
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
    ioniaService.getVendors(page: 1, country: 'USA').then((value) {
      cakePayVendors = value;
    });
  }

  Future<void> _getCard() async {
    cardState = CakePayCardsStateFetching();
    try {
      final card = await ioniaService.getCard();

      cardState = CakePayCardsStateSuccess(card: card);
    } catch (_) {
      cardState = CakePayCardsStateFailure();
    }
  }



  void getVendors() async {
    merchantState = CakePayVendorLoadingState();
    if (availableCountries.isEmpty) {
      availableCountries = await ioniaService.getCountries();
    }

    selectedCountry = availableCountries.isNotEmpty ? availableCountries.first : 'USA';

    ioniaService
        .getVendors(page: 1, country: selectedCountry!)
        .then((value) => cakePayVendors = CakePayVendorList = value);
    merchantState = CakePayVendorLoadedState();
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
