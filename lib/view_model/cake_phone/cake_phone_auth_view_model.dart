import 'dart:async';
import 'package:cake_wallet/entities/preferences_key.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/providers/cake_phone_provider.dart';
import 'package:cake_wallet/core/execution_state.dart';

part 'cake_phone_auth_view_model.g.dart';

class CakePhoneAuthViewModel = CakePhoneAuthViewModelBase with _$CakePhoneAuthViewModel;

abstract class CakePhoneAuthViewModelBase with Store {
  CakePhoneAuthViewModelBase(this._cakePhoneProvider, this._secureStorage) {
    state = InitialExecutionState();
  }

  @observable
  ExecutionState state;

  final CakePhoneProvider _cakePhoneProvider;
  final FlutterSecureStorage _secureStorage;

  @action
  Future<void> auth(String email) async {
    state = IsExecutingState();

    final isSuccessfullyAuthenticated = await _cakePhoneProvider.authenticate(email);

    if (isSuccessfullyAuthenticated) {
      state = ExecutedSuccessfullyState();
    } else {
      state = FailureState("");
    }
  }

  @action
  Future<void> verify(String email, String code) async {
    final String token = await _cakePhoneProvider.verifyEmail(email: email, code: code);

    if (token != null) {
      state = ExecutedSuccessfullyState();
      await _secureStorage.write(key: PreferencesKey.cakePhoneTokenKey, value: token);
    } else {
      state = FailureState("");
    }
  }
}
