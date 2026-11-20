import 'package:cake_wallet/cake_pay/src/cake_pay_states.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:cake_wallet/cake_pay/src/services/cake_pay_api.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cake_pay_auth_view_model.g.dart';

class CakePayAuthViewModel = CakePayAuthViewModelBase with _$CakePayAuthViewModel;

abstract class CakePayAuthViewModelBase with Store {
  CakePayAuthViewModelBase({required this.cakePayService, required this.sharedPreferences})
      : userVerificationState = CakePayUserVerificationStateInitial(),
        otpState = CakePayOtpSendDisabled(),
        email = '',
        otp = '';

  final CakePayService cakePayService;
  final SharedPreferences sharedPreferences;

  bool get useStagingServer => CakePayApi.useStaging;

  /// Accounts and tokens belong to a single server, so switching drops the local session.
  Future<void> setUseStagingServer(bool staging) async {
    if (!CakePayApi.canSelectServer || staging == CakePayApi.useStaging) {
      return;
    }

    await CakePayApi.saveServerChoice(sharedPreferences, staging);
    await cakePayService.logout();
  }

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
