import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
part 'ionia_view_model.g.dart';

class IoniaViewModel = IoniaViewModelBase with _$IoniaViewModel;

abstract class IoniaViewModelBase with Store {
  IoniaViewModelBase({this.ioniaService, this.ioniaMerchantSource})
      : createUserState = IoniaCreateStateSuccess(),
        otpState = IoniaOtpSendDisabled(),
        cardState = IoniaNoCardState(),
        enableCardPurchase = false,
        amount = '',
        tipAmount = 0.0,
        ioniaMerchants = [] , scrollOffsetFromTop = 0.0{
    if (ioniaMerchantSource.length > 0) {
      selectedMerchant = ioniaMerchantSource.getAt(0);
    }
    _getMerchants().then((value) {
      ioniaMerchants = value;
    });
    _getAuthStatus().then((value) => isLoggedIn = value);
  }

  final IoniaService ioniaService;

  Box<IoniaMerchant> ioniaMerchantSource;

  List<IoniaMerchant> ioniaMerchantList;

  String searchString;

  @observable
  IoniaMerchant selectedMerchant;

  @observable
  bool enableCardPurchase;

  @observable
  double scrollOffsetFromTop;

  @observable
  IoniaCreateAccountState createUserState;

  @observable
  IoniaOtpState otpState;

  @observable
  IoniaCreateCardState createCardState;

  @observable
  IoniaFetchCardState cardState;

  @observable
  List<IoniaMerchant> ioniaMerchants;

  @observable
  String amount;

  @computed
  double get giftCardAmount => double.parse(amount) + tipAmount;

  @observable
  double tipAmount;

  @observable
  String email;

  @observable
  String otp;

  @observable
  bool isLoggedIn;

  @action
  Future<void> createUser(String email) async {
    createUserState = IoniaCreateStateLoading();
    try {
      await ioniaService.createUser(email);

      createUserState = IoniaCreateStateSuccess();
    } on Exception catch (e) {
      createUserState = IoniaCreateStateFailure(error: e.toString());
    }
  }

  @action
  Future<void> verifyEmail(String code) async {
    try {
      otpState = IoniaOtpValidating();
      await ioniaService.verifyEmail(code);
      otpState = IoniaOtpSuccess();
    } catch (_) {
      otpState = IoniaOtpFailure(error: 'Invalid OTP. Try again');
    }
  }

  Future<bool> _getAuthStatus() async {
    return await ioniaService.isLogined();
  }

  @action
  Future<IoniaVirtualCard> createCard() async {
    createCardState = IoniaCreateCardLoading();
    try {
      final card = await ioniaService.createCard();
      createCardState = IoniaCreateCardSuccess();
      return card;
    } on Exception catch (e) {
      createCardState = IoniaCreateCardFailure(error: e.toString());
    }
    return null;
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

  Future<List<IoniaMerchant>> _getMerchants() async {
    return await ioniaService.getMerchants();
  }

  @action
  void selectMerchant(IoniaMerchant merchant) {
    if (ioniaMerchantSource.isNotEmpty) {
      ioniaMerchantSource.putAt(0, merchant);
    } else {
      ioniaMerchantSource.add(merchant);
    }
  }

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = input;
    final inputAmount = double.parse(input);
    final min = selectedMerchant.minimumCardPurchase;
    final max = selectedMerchant.maximumCardPurchase;
    if (inputAmount >= min && inputAmount <= max) {
      enableCardPurchase = true;
    } else {
      enableCardPurchase = false;
    }
  }

  @action
  void addTip(String tip) {
    tipAmount = double.parse(tip);
  void setScrollOffsetFromTop(double scrollOffset) {
    scrollOffsetFromTop = scrollOffset;
  }
}
}