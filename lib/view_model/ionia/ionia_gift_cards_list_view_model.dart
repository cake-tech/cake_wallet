import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/ionia/cake_pay_card.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:mobx/mobx.dart';

part 'ionia_gift_cards_list_view_model.g.dart';

class IoniaGiftCardsListViewModel = IoniaGiftCardsListViewModelBase
    with _$IoniaGiftCardsListViewModel;

abstract class IoniaGiftCardsListViewModelBase with Store {
  IoniaGiftCardsListViewModelBase({
    required this.ioniaService,
  })  : cardState = IoniaNoCardState(),
        cakePayVendors = [],
        availableCountries = [],
        ioniaCategories = IoniaCategory.allCategories,
        selectedIndices = ObservableList<IoniaCategory>.of([IoniaCategory.all]),
        scrollOffsetFromTop = 0.0,
        merchantState = InitialIoniaMerchantLoadingState(),
        createCardState = IoniaCreateCardState(),
        searchString = '',
        ioniaMerchantList = <CakePayVendor>[] {}

  final IoniaService ioniaService;

  List<CakePayVendor> ioniaMerchantList;

  String searchString;

  @observable
  double scrollOffsetFromTop;

  @observable
  IoniaCreateCardState createCardState;

  @observable
  IoniaFetchCardState cardState;

  @observable
  IoniaMerchantState merchantState;

  @observable
  List<CakePayVendor> cakePayVendors;

  @observable
  List<String> availableCountries;

  @observable
  List<IoniaCategory> ioniaCategories;

  @observable
  ObservableList<IoniaCategory> selectedIndices;

  @action
  Future<void> createCard() async {
    try {
      createCardState = IoniaCreateCardLoading();
      await ioniaService.createCard();
      createCardState = IoniaCreateCardSuccess();
    } catch (e) {
      createCardState = IoniaCreateCardFailure(error: e.toString());
    }
  }

  @action
  void searchMerchant(String text) {
    if (text.isEmpty) {
      cakePayVendors = ioniaMerchantList;
      return;
    }
    searchString = text;
    ioniaService.getVendors(page: 1, country: 'USA').then((value) {
      cakePayVendors = value;
    });
  }

  Future<void> _getCard() async {
    cardState = IoniaFetchingCard();
    try {
      final card = await ioniaService.getCard();

      cardState = IoniaCardSuccess(card: card);
    } catch (_) {
      cardState = IoniaFetchCardFailure();
    }
  }

  void getVendors() {
    merchantState = IoniaLoadingMerchantState();
    ioniaService.getCountries().then((value) => availableCountries = value);
    final country = availableCountries.isEmpty ? 'USA' : availableCountries.first;

    ioniaService.getVendors(page: 1, country: country)
        .then((value) => cakePayVendors = ioniaMerchantList = value);
    merchantState = IoniaLoadedMerchantState();
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

  void setScrollOffsetFromTop(double scrollOffset) {
    scrollOffsetFromTop = scrollOffset;
  }
}
