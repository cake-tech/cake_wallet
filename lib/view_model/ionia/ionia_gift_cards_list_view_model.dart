import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:cake_wallet/entities/priority_for_wallet_type.dart';
import 'package:cake_wallet/ionia/ionia_category.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'ionia_gift_cards_list_view_model.g.dart';

class IoniaGiftCardsListViewModel = IoniaGiftCardsListViewModelBase
    with _$IoniaGiftCardsListViewModel;

abstract class IoniaGiftCardsListViewModelBase with Store {
  IoniaGiftCardsListViewModelBase({
    required this.ioniaService,
  })  : cardState = IoniaNoCardState(),
        ioniaMerchants = [],
        ioniaCategories = IoniaCategory.allCategories,
        selectedIndices = ObservableList<IoniaCategory>.of([IoniaCategory.all]),
        scrollOffsetFromTop = 0.0,
        isLoggedIn = false,
        merchantState = InitialIoniaMerchantLoadingState(),
        createCardState = IoniaCreateCardState(),
        searchString = '',
        ioniaMerchantList = <IoniaMerchant>[] {
    _getAuthStatus().then((value) => isLoggedIn = value);
  }

  static const _ioniaMerchantListUpdateDurationInHours = 12;

  static List<IoniaMerchant> _ioniaMerchantListCache = [];

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
  bool isLoggedIn;

  @observable
  List<IoniaCategory> ioniaCategories;

  @observable
  ObservableList<IoniaCategory> selectedIndices;

  Future<bool> _getAuthStatus() async {
    return await ioniaService.isLogined();
  }

  @action
  Future<void> createCard() async {
    try {
      createCardState = IoniaCreateCardLoading();
      final card = await ioniaService.createCard();
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

  Future<void> getMerchants() async {
    final sharedPrefs = await SharedPreferences.getInstance();

    final lastMerchantListCacheUpdate = DateTime.tryParse(
            sharedPrefs.getString(PreferencesKey.lastMerchantListCacheUpdate) ?? '') ??
        DateTime.now().subtract(Duration(hours: _ioniaMerchantListUpdateDurationInHours));

    final durationSinceLastUpdate = DateTime.now().difference(lastMerchantListCacheUpdate).inHours;

    if (_ioniaMerchantListCache.isEmpty ||
        !selectedIndices.contains(IoniaCategory.all) ||
        durationSinceLastUpdate > _ioniaMerchantListUpdateDurationInHours) {
      merchantState = IoniaLoadingMerchantState();
      try {
        final value = await ioniaService.getMerchantsByFilter(categories: selectedIndices);
        value.sort((a, b) => a.legalName.toLowerCase().compareTo(b.legalName.toLowerCase()));
        ioniaMerchants = ioniaMerchantList = value;
        if (selectedIndices.contains(IoniaCategory.all)) {
          _ioniaMerchantListCache = value;
          await sharedPrefs.setString(
              PreferencesKey.lastMerchantListCacheUpdate, DateTime.now().toString());
        }
        merchantState = IoniaLoadedMerchantState();
      } catch (error) {
        merchantState = IoniaErrorMerchantState(error.toString());
      }
    } else {
      ioniaMerchants = ioniaMerchantList = _ioniaMerchantListCache;
      merchantState = IoniaLoadedMerchantState();
    }
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
