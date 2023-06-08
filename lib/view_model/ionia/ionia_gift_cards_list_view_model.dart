import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:mobx/mobx.dart';
part 'ionia_gift_cards_list_view_model.g.dart';

class IoniaGiftCardsListViewModel = IoniaGiftCardsListViewModelBase with _$IoniaGiftCardsListViewModel;

abstract class IoniaGiftCardsListViewModelBase with Store {
  IoniaGiftCardsListViewModelBase({
    required this.ioniaService,
  })  :
        cardState = IoniaNoCardState(),
        ioniaMerchants = [],
        ioniaCategories = IoniaCategory.allCategories,
        selectedIndices = ObservableList<IoniaCategory>.of([IoniaCategory.all]),
        scrollOffsetFromTop = 0.0,
        merchantState = InitialIoniaMerchantLoadingState(),
        createCardState = IoniaCreateCardState(),
        searchString = '',
        ioniaMerchantList = <IoniaMerchant>[] {
  }

  final IoniaService ioniaService;

  List<IoniaMerchant> ioniaMerchantList;

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
  List<IoniaMerchant> ioniaMerchants;

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
      ioniaMerchants = ioniaMerchantList;
      return;
    }
    searchString = text;
    ioniaService.getMerchantsByFilter(search: searchString).then((value) {
      ioniaMerchants = value;
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

  
  void getMerchants() {
    merchantState = IoniaLoadingMerchantState();
    ioniaService.getMerchantsByFilter(categories: selectedIndices).then((value) {
      value.sort((a, b) => a.legalName.toLowerCase().compareTo(b.legalName.toLowerCase()));
      ioniaMerchants = ioniaMerchantList = value;
      merchantState = IoniaLoadedMerchantState();
    });
    
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
          .where((e) => e.title.toLowerCase().contains(text.toLowerCase()),)
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
