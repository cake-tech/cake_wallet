import 'package:cake_wallet/ionia/ionia.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:mobx/mobx.dart';
part 'ionia_view_model.g.dart';

class IoniaViewModel = IoniaViewModelBase with _$IoniaViewModel;

abstract class IoniaViewModelBase with Store {
  IoniaViewModelBase({this.ioniaService})
      : createUserState = IoniaCreateStateSuccess(),
        otpState = IoniaOtpSendDisabled() {
    _getAuthStatus().then((value) => isLoggedIn = value);
  }

  final IoniaService ioniaService;

  @observable
  IoniaCreateState createUserState;

  @observable
  IoniaOtpState otpState;

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
    } catch (e) {
      createUserState = IoniaCreateStateFailure(error: 'Something went wrong!');
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
}
