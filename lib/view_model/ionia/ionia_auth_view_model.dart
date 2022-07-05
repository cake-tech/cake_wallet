import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';

part 'ionia_auth_view_model.g.dart';

class IoniaAuthViewModel  = IoniaAuthViewModelBase with _$IoniaAuthViewModel;

abstract class IoniaAuthViewModelBase with Store {

  IoniaAuthViewModelBase({this.ioniaService}):
  createUserState = IoniaCreateStateSuccess(),
        otpState = IoniaOtpSendDisabled(){
    

  }

  final IoniaService ioniaService;

  @observable
  IoniaCreateAccountState createUserState;

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
    createUserState = IoniaCreateStateLoading();
    try {
      await ioniaService.createUser(email);

      createUserState = IoniaCreateStateSuccess();
    } on Exception catch (e) {
      createUserState = IoniaCreateStateFailure(error: e.toString());
    }
  }

}