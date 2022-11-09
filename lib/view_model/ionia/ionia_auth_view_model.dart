import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';

part 'ionia_auth_view_model.g.dart';

class IoniaAuthViewModel  = IoniaAuthViewModelBase with _$IoniaAuthViewModel;

abstract class IoniaAuthViewModelBase with Store {

  IoniaAuthViewModelBase({required this.ioniaService}):
    createUserState = IoniaInitialCreateState(),
    signInState = IoniaInitialCreateState(),
    otpState = IoniaOtpSendDisabled(),
    email = '',
    otp = '';

  final IoniaService ioniaService;

  @observable
  IoniaCreateAccountState createUserState;

  @observable
  IoniaCreateAccountState signInState;

  @observable
  IoniaOtpState otpState;

  @observable
  String email;

  @observable
  String otp;

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

  @action
  Future<void> createUser(String email) async {
    try {
      createUserState = IoniaCreateStateLoading();
      await ioniaService.createUser(email);
      createUserState = IoniaCreateStateSuccess();
    } catch (e) {
      createUserState = IoniaCreateStateFailure(error: e.toString());
    }
  }


  @action
  Future<void> signIn(String email) async {
    try {
      signInState = IoniaCreateStateLoading();
      await ioniaService.signIn(email);
      signInState = IoniaCreateStateSuccess();
    } catch (e) {
      signInState = IoniaCreateStateFailure(error: e.toString());
    }
  }

}