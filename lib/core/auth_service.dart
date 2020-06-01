import 'package:flutter/foundation.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/core/setup_pin_code_state.dart';

part 'auth_service.g.dart';

class AuthService = AuthServiceBase with _$AuthService;

abstract class AuthServiceBase with Store {
  @observable
  SetupPinCodeState setupPinCodeState;

  Future<void> setupPinCode({@required String pin}) async {}

  Future<bool> authenticate({@required String pin}) async {
    return false;
  }

  void resetSetupPinCodeState() =>
      setupPinCodeState = InitialSetupPinCodeState();
}
