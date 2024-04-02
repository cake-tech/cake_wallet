import 'package:cake_wallet/ionia/cake_pay_states.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';

part 'ionia_auth_view_model.g.dart';

class IoniaAuthViewModel  = IoniaAuthViewModelBase with _$IoniaAuthViewModel;

abstract class IoniaAuthViewModelBase with Store {

  IoniaAuthViewModelBase({required this.ioniaService}):
    createUserState = CakePayAccountCreateStateInitial(),
    signInState = CakePayAccountCreateStateInitial(),
    otpState = CakePayOtpSendDisabled(),
    email = '',
    otp = '';

  final IoniaService ioniaService;

  @observable
  CakePayCreateAccountState createUserState;

  @observable
  CakePayCreateAccountState signInState;

  @observable
  CakePayOtpState otpState;

  @observable
  String email;

  @observable
  String otp;

  @action
  Future<void> verifyEmail(String code) async {
    try {
      otpState = CakePayOtpValidating();
      await ioniaService.verifyEmail(code);
      otpState = CakePayOtpSuccess();
    } catch (_) {
      otpState = CakePayOtpFailure(error: 'Invalid OTP. Try again');
    }
  }

  @action
  Future<void> createUser(String email) async {
    try {
      createUserState = CakePayAccountCreateStateLoading();
      await ioniaService.createUser(email);
      createUserState = CakePayAccountCreateStateSuccess();
    } catch (e) {
      createUserState = CakePayAccountCreateStateFailure(error: e.toString());
    }
  }


  @action
  Future<void> signIn(String email) async {
    try {
      signInState = CakePayAccountCreateStateLoading();
      await ioniaService.signIn(email);
      signInState = CakePayAccountCreateStateSuccess();
    } catch (e) {
      signInState = CakePayAccountCreateStateFailure(error: e.toString());
    }
  }

}