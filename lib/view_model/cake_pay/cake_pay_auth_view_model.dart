import 'package:cake_wallet/cake_pay/src/cake_pay_states.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:mobx/mobx.dart';

part 'cake_pay_auth_view_model.g.dart';

class CakePayAuthViewModel = CakePayAuthViewModelBase with _$CakePayAuthViewModel;

abstract class CakePayAuthViewModelBase with Store {
  CakePayAuthViewModelBase({required this.cakePayService})
      : userVerificationState = CakePayUserVerificationStateInitial(),
        otpState = CakePayOtpSendDisabled(),
        email = '',
        otp = '';

  final CakePayService cakePayService;

  @observable
  CakePayUserVerificationState userVerificationState;

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
      await cakePayService.verifyEmail(code);
      otpState = CakePayOtpSuccess();
    } catch (_) {
      otpState = CakePayOtpFailure(error: 'Invalid OTP. Try again');
    }
  }

  @action
  Future<void> logIn(String email) async {
    try {
      userVerificationState = CakePayUserVerificationStateLoading();
      await cakePayService.logIn(email);
      userVerificationState = CakePayUserVerificationStateSuccess();
    } catch (e) {
      userVerificationState = CakePayUserVerificationStateFailure(error: e.toString());
    }
  }
}
