import 'package:cake_wallet/ionia/ionia.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:mobx/mobx.dart';
part 'ionia_view_model.g.dart';

class IoniaViewModel = IoniaViewModelBase with _$IoniaViewModel;

abstract class IoniaViewModelBase with Store {
  IoniaViewModelBase({this.ioniaService})
      : createUserState = IoniaCreateStateSuccess(),
        otpState = IoniaOtpSendDisabled(),
        cardState = IoniaNoCardState() {
    _getCard();
    _getAuthStatus().then((value) => isLoggedIn = value);
  }

  final IoniaService ioniaService;

  @observable
  IoniaCreateAccountState createUserState;

  @observable
  IoniaOtpState otpState;

  @observable
  IoniaCreateCardState createCardState;

  @observable
  IoniaFetchCardState cardState;

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

  Future<void> _getCard() async {
    cardState = IoniaFetchingCard();
    try {
      final card = await ioniaService.getCard();

      cardState = IoniaCardSuccess(card: card);
    } catch (_) {
      cardState = IoniaFetchCardFailure();
    }
  }
}
